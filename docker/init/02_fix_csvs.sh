#!/bin/bash
set -e

echo ">>> Iniciando limpieza de CSVs con Python..."

python3 << 'PYEOF'
import csv
import os
import unicodedata

CSV_DIR = "/csv"

INT_COLUMNS = {
    "mundial.csv": ["anio", "equipos", "partidos_jugados", "goles_total"],
    "seleccion.csv": ["seleccion_id"],
    "seleccion_alias.csv": ["seleccion_id"],
    "jugador.csv": ["jugador_id"],
    "entrenador.csv": ["entrenador_id"],
    "partido.csv": [
        "partido_id", "anio", "local_seleccion_id", "visitante_seleccion_id",
        "goles_local", "goles_visitante", "penales_local", "penales_visitante"
    ],
    "aparicion_partido.csv": ["partido_id", "seleccion_id", "jugador_id"],
    "direccion_tecnica_partido.csv": ["partido_id", "seleccion_id", "entrenador_id"],
    "gol.csv": ["gol_id", "partido_id", "seleccion_id", "jugador_id"],
    "tarjeta.csv": ["tarjeta_id", "partido_id", "seleccion_id", "jugador_id"],
    "cambio.csv": ["cambio_id", "partido_id", "seleccion_id", "jugador_sale_id", "jugador_entra_id"],
    "penal.csv": ["penal_id", "partido_id", "seleccion_id", "orden", "jugador_id"],
    "grupo.csv": ["anio", "seleccion_id", "posicion", "pts", "pj", "pg", "pe", "pp", "gf", "gc", "dif"],
    "posicion_final.csv": ["anio", "posicion", "seleccion_id"],
    "goleador.csv": ["anio", "jugador_id", "seleccion_id", "goles"],
    "premio_jugador.csv": ["anio", "jugador_id", "seleccion_id"],
    "premio_seleccion.csv": ["anio", "seleccion_id"],
    "plantel_jugador.csv": ["anio", "seleccion_id", "jugador_id"],
    "plantel_entrenador.csv": ["anio", "seleccion_id", "entrenador_id"],
    "participacion_mundial.csv": ["anio", "seleccion_id", "posicion", "pts", "pj", "pg", "pe", "pp", "gf", "gc", "dif"],
    "resolucion_identidad_jugador.csv": ["source_event_id", "partido_id", "seleccion_id"],
}

BOOL_COLUMNS = {
    "partido.csv": ["tiempo_extra", "definicion_penales"],
    "aparicion_partido.csv": ["es_capitan"],
    "gol.csv": ["es_penal", "es_autogol"],
    "grupo.csv": ["clasificado"],
    "participacion_mundial.csv": ["participo"],
}

PRIMARY_KEYS = {
    "mundial.csv": ["anio"],
    "seleccion.csv": ["seleccion_id"],
    "seleccion_alias.csv": ["alias_nombre"],
    "jugador.csv": ["jugador_id"],
    "entrenador.csv": ["entrenador_id"],
    "partido.csv": ["partido_id"],
    "aparicion_partido.csv": ["partido_id", "seleccion_id", "jugador_id", "seccion"],
    "direccion_tecnica_partido.csv": ["partido_id", "seleccion_id", "entrenador_id"],
    "gol.csv": ["gol_id"],
    "tarjeta.csv": ["tarjeta_id"],
    "cambio.csv": ["cambio_id"],
    "penal.csv": ["penal_id"],
    "grupo.csv": ["anio", "grupo", "seleccion_id"],
    "posicion_final.csv": ["anio", "posicion"],
    "goleador.csv": ["anio", "jugador_id"],
    "premio_jugador.csv": ["anio", "premio", "jugador_id"],
    "premio_seleccion.csv": ["anio", "premio", "seleccion_id"],
    "plantel_jugador.csv": ["anio", "seleccion_id", "jugador_id"],
    "plantel_entrenador.csv": ["anio", "seleccion_id", "entrenador_id"],
    "participacion_mundial.csv": ["anio", "seleccion_id"],
    "resolucion_identidad_jugador.csv": ["source_table", "source_event_id"],
}

RESOLUCION_FILE = "resolucion_identidad_jugador.csv"
RESOLUCION_HEADER = [
    "source_table", "source_event_id", "partido_id", "seleccion_id",
    "jugador_nombre_raw", "minuto", "metodo", "confianza", "notas"
]

# Caracteres que no tienen descomposicion NFD util — mapeo manual
EXTRA_MAP = {
    'ð': 'd', 'ø': 'o', 'ł': 'l', 'Ł': 'L', 'ı': 'i', 'İ': 'I',
    'ß': 'ss', 'æ': 'ae', 'œ': 'oe', 'þ': 'th',
}

def normalize_text(value: str) -> str:
    """Quita tildes y normaliza caracteres especiales a ASCII."""
    if not value:
        return value
    # Aplicar mapa manual primero
    for src, dst in EXTRA_MAP.items():
        value = value.replace(src, dst)
    # Descomponer en forma NFD y eliminar marcas diacriticas (Mn = Mark, Nonspacing)
    nfd = unicodedata.normalize('NFD', value)
    return ''.join(ch for ch in nfd if unicodedata.category(ch) != 'Mn')

def fix_int(value: str):
    if value in ("", None):
        return value
    try:
        f = float(value)
        if f == int(f):
            return str(int(f))
    except (ValueError, OverflowError):
        pass
    return value

def fix_bool(value: str):
    if value == "True":
        return "1"
    if value == "False":
        return "0"
    return value

# Garantiza CSV especial requerido por ETL incluso si no hay ambiguedades.
res_file_path = os.path.join(CSV_DIR, RESOLUCION_FILE)
if not os.path.exists(res_file_path):
    with open(res_file_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(RESOLUCION_HEADER)
    print(f"  CREATED: {RESOLUCION_FILE} (solo encabezado)")

for filename, int_cols in INT_COLUMNS.items():
    filepath = os.path.join(CSV_DIR, filename)
    if not os.path.exists(filepath):
        print(f"  SKIP (no existe): {filename}")
        continue

    bool_cols = BOOL_COLUMNS.get(filename, [])
    pk_cols = PRIMARY_KEYS.get(filename, [])

    with open(filepath, "r", encoding="utf-8-sig") as f:
        content = f.read()

    reader = csv.DictReader(content.splitlines())
    fieldnames = reader.fieldnames
    rows = list(reader)

    if not fieldnames:
        print(f"  WARN: {filename} sin encabezados, se omite")
        continue

    for row in rows:
        for col in int_cols:
            if col in row:
                row[col] = fix_int(row[col])
        for col in bool_cols:
            if col in row:
                row[col] = fix_bool(row[col])
        # Normalizar texto en todas las columnas de texto
        for col in row:
            if col not in int_cols and col not in bool_cols:
                if isinstance(row[col], str):
                    row[col] = normalize_text(row[col])

    if pk_cols:
        seen = set()
        unique_rows = []
        dupes = 0
        for row in rows:
            key = tuple((row.get(c, "") or "").strip() for c in pk_cols)
            if key not in seen:
                seen.add(key)
                unique_rows.append(row)
            else:
                dupes += 1
        if dupes:
            print(f"  DEDUP: {filename} - {dupes} duplicado(s) eliminado(s)")
        rows = unique_rows

    with open(filepath, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

    print(f"  OK: {filename} ({len(rows)} filas)")

print(">>> Limpieza completada.")
PYEOF