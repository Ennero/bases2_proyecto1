"""
migracion.py
Migración completa de SQL Server → MongoDB
Mundiales de Fútbol (1930–2026)

Orden de ejecución:
  1. Crear colecciones + índices
  2. cargar_selecciones()   ← sin lookups externos
  3. cargar_jugadores()     ← sin lookups externos
  4. cargar_mundiales()     ← enriquece con nombres de seleccion/jugador
  5. cargar_partidos()      ← enriquece con nombres de seleccion/jugador

El enriquecimiento (agregar *Nombre junto a cada *Id) se hace con
diccionarios en memoria para no hacer miles de find_one() a MongoDB.
"""

import os
import pyodbc
from pymongo import MongoClient
from pymongo.errors import BulkWriteError
from dotenv import load_dotenv

load_dotenv()

# ──────────────────────────────────────────────
# CONEXIONES
# ──────────────────────────────────────────────
sql_server = os.getenv("SQL_SERVER", "localhost,1433")
sql_db = os.getenv("SQL_DB", "mundiales")
sql_user = os.getenv("SQL_USER", "sa")
sql_pwd = os.getenv("SQL_PASSWORD", "Mundiales2026!")

sql = pyodbc.connect(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={sql_server};"
    f"DATABASE={sql_db};"
    f"UID={sql_user};"
    f"PWD={sql_pwd};"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/mundiales")
mongo = MongoClient(mongo_uri)
db = mongo["mundiales"]

# ──────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────
def to_int(val):
    return None if val is None else int(val)

def to_bool(val):
    return None if val is None else bool(val)

def safe_str(val):
    return None if val is None else str(val)

def fetchall(query, *params):
    """Abre un cursor nuevo, ejecuta y devuelve todas las filas."""
    c = sql.cursor()
    c.execute(query, *params)
    rows = c.fetchall()
    c.close()
    return rows

# ──────────────────────────────────────────────
# PASO 1 — COLECCIONES E ÍNDICES
# ──────────────────────────────────────────────
def crear_colecciones():
    print("── Creando colecciones ──")
    for nombre in ["mundial", "partido", "seleccion", "jugador"]:
        if nombre in db.list_collection_names():
            db.drop_collection(nombre)
            print(f"  {nombre}: eliminada")
        db.create_collection(nombre)
        print(f"  {nombre}: creada")

def crear_indices():
    print("── Creando índices ──")
    db.mundial.create_index([("anio", 1)], unique=True)
    db.partido.create_index([("anio", 1)])
    db.partido.create_index([("localSeleccionId", 1)])
    db.partido.create_index([("visitanteSeleccionId", 1)])
    db.seleccion.create_index([("seleccionId", 1)], unique=True)
    db.seleccion.create_index([("nombre", 1)])
    db.jugador.create_index([("jugadorId", 1)], unique=True)
    db.jugador.create_index([("nombre", 1)])
    print("  índices creados")

# ──────────────────────────────────────────────
# PASO 2 — SELECCIONES
# ──────────────────────────────────────────────
def cargar_selecciones():
    print("── Cargando selecciones ──")
    selecciones = []

    for row in fetchall("SELECT seleccion_id, nombre FROM seleccion"):
        sid = to_int(row[0])

        aliases = [
            {"aliasNombre": safe_str(r[0]), "seleccionId": to_int(r[1])}
            for r in fetchall(
                "SELECT alias_nombre, seleccion_id FROM seleccion_alias WHERE seleccion_id = ?", sid
            )
        ]

        participaciones = [
            {
                "participacionId": to_int(r[0]), "anio": to_int(r[1]),
                "seleccionId": to_int(r[2]), "posicion": to_int(r[3]),
                "etapa": safe_str(r[4]), "pts": to_int(r[5]),
                "pj": to_int(r[6]), "pg": to_int(r[7]), "pe": to_int(r[8]),
                "pp": to_int(r[9]), "gf": to_int(r[10]), "gc": to_int(r[11]),
                "dif": to_int(r[12]), "participo": to_bool(r[13]),
            }
            for r in fetchall(
                """SELECT participacion_id, anio, seleccion_id, posicion, etapa,
                          pts, pj, pg, pe, pp, gf, gc, dif, participo
                   FROM participacion_mundial WHERE seleccion_id = ?""", sid
            )
        ]

        posiciones = [
            {"anio": to_int(r[0]), "posicion": to_int(r[1]), "seleccionId": to_int(r[2])}
            for r in fetchall(
                "SELECT anio, posicion, seleccion_id FROM posicion_final WHERE seleccion_id = ?", sid
            )
        ]

        grupos = [
            {
                "anio": to_int(r[0]), "grupo": safe_str(r[1]), "posicion": to_int(r[2]),
                "seleccionId": to_int(r[3]), "pts": to_int(r[4]), "pj": to_int(r[5]),
                "pg": to_int(r[6]), "pe": to_int(r[7]), "pp": to_int(r[8]),
                "gf": to_int(r[9]), "gc": to_int(r[10]), "dif": to_int(r[11]),
                "clasificado": to_bool(r[12]),
            }
            for r in fetchall(
                """SELECT anio, grupo, posicion, seleccion_id, pts, pj, pg, pe, pp, gf, gc, dif, clasificado
                   FROM grupo WHERE seleccion_id = ?""", sid
            )
        ]

        selecciones.append({
            "seleccionId": sid,
            "nombre": safe_str(row[1]),
            "seleccionAliases": aliases,
            "participacionMundials": participaciones,
            "posicionFinals": posiciones,
            "grupos": grupos,
        })

    if selecciones:
        try:
            db.seleccion.insert_many(selecciones, ordered=False)
            print(f"  {len(selecciones)} selecciones insertadas")
        except BulkWriteError as e:
            print("  ⚠ BulkWriteError selecciones:", e.details)

# ──────────────────────────────────────────────
# PASO 3 — JUGADORES
# ──────────────────────────────────────────────
def cargar_jugadores():
    print("── Cargando jugadores ──")
    jugadores = []

    for row in fetchall(
        """SELECT jugador_id, nombre, nombre_completo, fecha_nacimiento,
                  lugar_nacimiento, altura, apodo, sitio_web, redes_sociales
           FROM jugador"""
    ):
        jid = to_int(row[0])

        goleadors = [
            {
                "anio": to_int(r[0]), "jugadorId": to_int(r[1]),
                "seleccionId": to_int(r[2]), "goles": to_int(r[3]),
            }
            for r in fetchall(
                "SELECT anio, jugador_id, seleccion_id, goles FROM goleador WHERE jugador_id = ?", jid
            )
        ]

        premios = [
            {
                "anio": to_int(r[0]), "premio": safe_str(r[1]),
                "jugadorId": to_int(r[2]), "seleccionId": to_int(r[3]),
            }
            for r in fetchall(
                "SELECT anio, premio, jugador_id, seleccion_id FROM premio_jugador WHERE jugador_id = ?", jid
            )
        ]

        plantel = [
            {
                "anio": to_int(r[0]), "seleccionId": to_int(r[1]),
                "jugadorId": to_int(r[2]), "posicion": safe_str(r[3]),
                "camiseta": safe_str(r[4]), "club": safe_str(r[5]),
            }
            for r in fetchall(
                """SELECT anio, seleccion_id, jugador_id, posicion, camiseta, club
                   FROM plantel_jugador WHERE jugador_id = ?""", jid
            )
        ]

        jugadores.append({
            "jugadorId": jid,
            "nombre": safe_str(row[1]),
            "nombreCompleto": safe_str(row[2]),
            "fechaNacimiento": safe_str(row[3]),
            "lugarNacimiento": safe_str(row[4]),
            "altura": safe_str(row[5]),
            "apodo": safe_str(row[6]),
            "sitioWeb": safe_str(row[7]),
            "redesSociales": safe_str(row[8]),
            "goleadors": goleadors,
            "premioJugadors": premios,
            "plantelJugadors": plantel,
        })

    if jugadores:
        try:
            db.jugador.insert_many(jugadores, ordered=False)
            print(f"  {len(jugadores)} jugadores insertados")
        except BulkWriteError as e:
            print("  ⚠ BulkWriteError jugadores:", e.details)

# ──────────────────────────────────────────────
# CACHÉ EN MEMORIA  (se construye tras cargar
# selecciones y jugadores en Mongo)
# ──────────────────────────────────────────────
def construir_cache():
    """Devuelve dos dicts id→nombre para no hacer find_one en bucles."""
    print("── Construyendo caché de nombres ──")
    sel_map = {
        doc["seleccionId"]: doc["nombre"]
        for doc in db.seleccion.find({}, {"seleccionId": 1, "nombre": 1, "_id": 0})
    }
    jug_map = {
        doc["jugadorId"]: doc["nombre"]
        for doc in db.jugador.find({}, {"jugadorId": 1, "nombre": 1, "_id": 0})
    }
    print(f"  {len(sel_map)} selecciones, {len(jug_map)} jugadores en caché")
    return sel_map, jug_map

# ──────────────────────────────────────────────
# PASO 4 — MUNDIALES
# ──────────────────────────────────────────────
def cargar_mundiales(sel_map, jug_map):
    print("── Cargando mundiales ──")
    mundiales = []

    for row in fetchall(
        "SELECT anio, sede, equipos, partidos_jugados, goles_total FROM mundial"
    ):
        anio = row[0]

        grupos = [
            {
                "anio": to_int(r[0]), "grupo": safe_str(r[1]), "posicion": to_int(r[2]),
                "seleccionId": to_int(r[3]),
                "seleccionNombre": sel_map.get(to_int(r[3])),
                "pts": to_int(r[4]), "pj": to_int(r[5]), "pg": to_int(r[6]),
                "pe": to_int(r[7]), "pp": to_int(r[8]),
                "gf": to_int(r[9]), "gc": to_int(r[10]), "dif": to_int(r[11]),
                "clasificado": to_bool(r[12]),
            }
            for r in fetchall(
                """SELECT anio, grupo, posicion, seleccion_id, pts, pj, pg, pe, pp, gf, gc, dif, clasificado
                   FROM grupo WHERE anio = ?""", anio
            )
        ]

        posiciones = [
            {
                "anio": to_int(r[0]), "posicion": to_int(r[1]),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])),
            }
            for r in fetchall(
                "SELECT anio, posicion, seleccion_id FROM posicion_final WHERE anio = ?", anio
            )
        ]

        goleadores = [
            {
                "anio": to_int(r[0]),
                "jugadorId": to_int(r[1]),
                "jugadorNombre": jug_map.get(to_int(r[1])),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])),
                "goles": to_int(r[3]),
            }
            for r in fetchall(
                "SELECT anio, jugador_id, seleccion_id, goles FROM goleador WHERE anio = ?", anio
            )
        ]

        premios_sel = [
            {
                "anio": to_int(r[0]), "premio": safe_str(r[1]),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])),
            }
            for r in fetchall(
                "SELECT anio, premio, seleccion_id FROM premio_seleccion WHERE anio = ?", anio
            )
        ]

        premios_jug = [
            {
                "anio": to_int(r[0]), "premio": safe_str(r[1]),
                "jugadorId": to_int(r[2]),
                "jugadorNombre": jug_map.get(to_int(r[2])),
                "seleccionId": to_int(r[3]),
                "seleccionNombre": sel_map.get(to_int(r[3])),
            }
            for r in fetchall(
                "SELECT anio, premio, jugador_id, seleccion_id FROM premio_jugador WHERE anio = ?", anio
            )
        ]

        participaciones = [
            {
                "participacionId": to_int(r[0]), "anio": to_int(r[1]),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])),
                "posicion": to_int(r[3]), "etapa": safe_str(r[4]),
                "pts": to_int(r[5]), "pj": to_int(r[6]), "pg": to_int(r[7]),
                "pe": to_int(r[8]), "pp": to_int(r[9]),
                "gf": to_int(r[10]), "gc": to_int(r[11]),
                "dif": to_int(r[12]), "participo": to_bool(r[13]),
            }
            for r in fetchall(
                """SELECT participacion_id, anio, seleccion_id, posicion, etapa,
                          pts, pj, pg, pe, pp, gf, gc, dif, participo
                   FROM participacion_mundial WHERE anio = ?""", anio
            )
        ]

        plantel_j = [
            {
                "anio": to_int(r[0]),
                "seleccionId": to_int(r[1]),
                "seleccionNombre": sel_map.get(to_int(r[1])),
                "jugadorId": to_int(r[2]),
                "jugadorNombre": jug_map.get(to_int(r[2])),
                "posicion": safe_str(r[3]),
                "camiseta": safe_str(r[4]),
                "club": safe_str(r[5]),
            }
            for r in fetchall(
                """SELECT anio, seleccion_id, jugador_id, posicion, camiseta, club
                   FROM plantel_jugador WHERE anio = ?""", anio
            )
        ]

        plantel_e = [
            {
                "anio": to_int(r[0]),
                "seleccionId": to_int(r[1]),
                "seleccionNombre": sel_map.get(to_int(r[1])),
                "entrenadorId": to_int(r[2]),
                "entrenador": {"entrenadorId": to_int(r[2]), "nombre": safe_str(r[3])},
            }
            for r in fetchall(
                """SELECT pe.anio, pe.seleccion_id, pe.entrenador_id, e.nombre
                   FROM plantel_entrenador pe
                   JOIN entrenador e ON pe.entrenador_id = e.entrenador_id
                   WHERE pe.anio = ?""", anio
            )
        ]

        mundiales.append({
            "anio": to_int(row[0]),
            "sede": safe_str(row[1]),
            "equipos": to_int(row[2]),
            "partidosJugados": to_int(row[3]),
            "golesTotal": to_int(row[4]),
            "grupos": grupos,
            "posicionFinals": posiciones,
            "goleadors": goleadores,
            "premioSeleccions": premios_sel,
            "premioJugadors": premios_jug,
            "participacionMundials": participaciones,
            "plantelJugadors": plantel_j,
            "plantelEntrenadors": plantel_e,
        })

    if mundiales:
        try:
            db.mundial.insert_many(mundiales, ordered=False)
            print(f"  {len(mundiales)} mundiales insertados")
        except BulkWriteError as e:
            print("  ⚠ BulkWriteError mundiales:", e.details)

# ──────────────────────────────────────────────
# PASO 5 — PARTIDOS
# ──────────────────────────────────────────────
def cargar_partidos(sel_map, jug_map):
    print("── Cargando partidos ──")
    partidos = []

    for row in fetchall(
        """SELECT partido_id, anio, fecha, etapa,
                  local_seleccion_id, visitante_seleccion_id,
                  goles_local, goles_visitante,
                  tiempo_extra, definicion_penales,
                  penales_local, penales_visitante
           FROM partido"""
    ):
        pid = row[0]

        gols = [
            {
                "golId": to_int(r[0]), "partidoId": to_int(r[1]),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])),
                "jugadorId": to_int(r[3]),
                "jugadorNombre": jug_map.get(to_int(r[3])) if r[3] is not None else None,
                "minuto": safe_str(r[4]),
                "esPenal": to_bool(r[5]),
                "esAutogol": to_bool(r[6]),
            }
            for r in fetchall(
                """SELECT gol_id, partido_id, seleccion_id, jugador_id,
                          minuto, es_penal, es_autogol
                   FROM gol WHERE partido_id = ?""", pid
            )
        ]

        tarjetas = [
            {
                "tarjetaId": to_int(r[0]), "partidoId": to_int(r[1]),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])) if r[2] is not None else None,
                "jugadorId": to_int(r[3]),
                "jugadorNombre": jug_map.get(to_int(r[3])) if r[3] is not None else None,
                "tipo": safe_str(r[4]),
                "minuto": safe_str(r[5]),
            }
            for r in fetchall(
                """SELECT tarjeta_id, partido_id, seleccion_id, jugador_id, tipo, minuto
                   FROM tarjeta WHERE partido_id = ?""", pid
            )
        ]

        cambios = [
            {
                "cambioId": to_int(r[0]), "partidoId": to_int(r[1]),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])),
                "jugadorSaleId": to_int(r[3]),
                "jugadorSaleNombre": jug_map.get(to_int(r[3])) if r[3] is not None else None,
                "jugadorEntraId": to_int(r[4]),
                "jugadorEntraNombre": jug_map.get(to_int(r[4])) if r[4] is not None else None,
                "minuto": safe_str(r[5]),
            }
            for r in fetchall(
                """SELECT cambio_id, partido_id, seleccion_id,
                          jugador_sale_id, jugador_entra_id, minuto
                   FROM cambio WHERE partido_id = ?""", pid
            )
        ]

        penals = [
            {
                "penalId": to_int(r[0]), "partidoId": to_int(r[1]),
                "seleccionId": to_int(r[2]),
                "seleccionNombre": sel_map.get(to_int(r[2])),
                "orden": to_int(r[3]),
                "jugadorId": to_int(r[4]),
                "jugadorNombre": jug_map.get(to_int(r[4])) if r[4] is not None else None,
                "resultado": safe_str(r[5]),
            }
            for r in fetchall(
                """SELECT penal_id, partido_id, seleccion_id, orden, jugador_id, resultado
                   FROM penal WHERE partido_id = ?""", pid
            )
        ]

        apariciones = [
            {
                "partidoId": to_int(r[0]),
                "seleccionId": to_int(r[1]),
                "seleccionNombre": sel_map.get(to_int(r[1])),
                "jugadorId": to_int(r[2]),
                "jugadorNombre": jug_map.get(to_int(r[2])),
                "posicion": safe_str(r[3]),
                "camiseta": safe_str(r[4]),
                "seccion": safe_str(r[5]),
                "esCapitan": to_bool(r[6]),
            }
            for r in fetchall(
                """SELECT partido_id, seleccion_id, jugador_id,
                          posicion, camiseta, seccion, es_capitan
                   FROM aparicion_partido WHERE partido_id = ?""", pid
            )
        ]

        direccion = [
            {
                "partidoId": to_int(r[0]),
                "seleccionId": to_int(r[1]),
                "seleccionNombre": sel_map.get(to_int(r[1])),
                "entrenadorId": to_int(r[2]),
                "entrenador": {"entrenadorId": to_int(r[2]), "nombre": safe_str(r[3])},
            }
            for r in fetchall(
                """SELECT dt.partido_id, dt.seleccion_id, dt.entrenador_id, e.nombre
                   FROM direccion_tecnica_partido dt
                   JOIN entrenador e ON dt.entrenador_id = e.entrenador_id
                   WHERE dt.partido_id = ?""", pid
            )
        ]

        partidos.append({
            "partidoId": to_int(row[0]),
            "anio": to_int(row[1]),
            "fecha": safe_str(row[2]),
            "etapa": safe_str(row[3]),
            "localSeleccionId": to_int(row[4]),
            "localSeleccionNombre": sel_map.get(to_int(row[4])),
            "visitanteSeleccionId": to_int(row[5]),
            "visitanteSeleccionNombre": sel_map.get(to_int(row[5])),
            "golesLocal": to_int(row[6]),
            "golesVisitante": to_int(row[7]),
            "tiempoExtra": to_bool(row[8]),
            "definicionPenales": to_bool(row[9]),
            "penalesLocal": to_int(row[10]),
            "penalesVisitante": to_int(row[11]),
            "gols": gols,
            "tarjetas": tarjetas,
            "cambios": cambios,
            "penals": penals,
            "aparicionPartidos": apariciones,
            "direccionTecnicaPartidos": direccion,
        })

    if partidos:
        try:
            db.partido.insert_many(partidos, ordered=False)
            print(f"  {len(partidos)} partidos insertados")
        except BulkWriteError as e:
            print("  ⚠ BulkWriteError partidos:", e.details)

# ──────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("  MIGRACIÓN SQL Server → MongoDB")
    print("=" * 50)

    crear_colecciones()
    crear_indices()

    # Carga independiente (sin lookups cruzados)
    cargar_selecciones()
    cargar_jugadores()

    # Construir caché en memoria una sola vez
    sel_map, jug_map = construir_cache()

    # Carga enriquecida
    cargar_mundiales(sel_map, jug_map)
    cargar_partidos(sel_map, jug_map)

    sql.close()
    mongo.close()
    print("=" * 50)
    print("  Migración completada ✓")
    print("=" * 50)