from __future__ import annotations

import os
import re
import unicodedata
from dataclasses import dataclass, field

import pandas as pd


LEGACY_FILES = (
    "mundial.csv",
    "seleccion.csv",
    "jugador.csv",
    "partido.csv",
    "aparicion_partido.csv",
    "gol.csv",
    "tarjeta.csv",
    "cambio.csv",
    "penal.csv",
    "grupo.csv",
    "posicion_final.csv",
    "goleador.csv",
    "premio.csv",
    "plantel.csv",
    "participacion_mundial.csv",
)

FINAL_FILES = (
    "mundial.csv",
    "seleccion.csv",
    "seleccion_alias.csv",
    "jugador.csv",
    "entrenador.csv",
    "partido.csv",
    "aparicion_partido.csv",
    "direccion_tecnica_partido.csv",
    "gol.csv",
    "tarjeta.csv",
    "cambio.csv",
    "penal.csv",
    "grupo.csv",
    "posicion_final.csv",
    "goleador.csv",
    "premio_jugador.csv",
    "premio_seleccion.csv",
    "plantel_jugador.csv",
    "plantel_entrenador.csv",
    "participacion_mundial.csv",
    "resolucion_identidad_jugador.csv",
)

OBSOLETE_OUTPUT_FILES = (
    "premio.csv",
    "plantel.csv",
)

NORMALIZED_ONLY_FILES = (
    "premio_jugador.csv",
    "premio_seleccion.csv",
    "plantel_jugador.csv",
    "plantel_entrenador.csv",
    "direccion_tecnica_partido.csv",
)

SELECCION_ALIAS_MAP = {
    "Alemania Occidental": "Alemania",
    "Alemania Oriental": "Alemania",
    "URSS": "Rusia",
    "RF de Yugoslavia": "Serbia",
    "Serbia y Montenegro": "Serbia",
    "Checoslovaquia": "República Checa",
    "Holanda": "Paises Bajos",
    "Países Bajos": "Paises Bajos",
}

GENERIC_SELECTION_VALUES = {
    "",
    "Selecciones",
    "Seleccion",
}


def _read_optional_csv(raw_dir: str, filename: str) -> pd.DataFrame:
    path = os.path.join(raw_dir, filename)
    if not os.path.exists(path):
        return pd.DataFrame()
    return pd.read_csv(path, dtype=str, keep_default_na=False)


def _write_csv(df: pd.DataFrame, out_dir: str, filename: str) -> None:
    os.makedirs(out_dir, exist_ok=True)
    output = df.fillna("")
    output.to_csv(os.path.join(out_dir, filename), index=False, encoding="utf-8-sig")


def _clean_text(value: object) -> str:
    if value is None:
        return ""
    text = str(value).replace("\ufeff", "")
    return " ".join(text.split()).strip()


def _normalize_key(value: object) -> str:
    text = _clean_text(value).lower()
    normalized = unicodedata.normalize("NFKD", text)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]+", "_", ascii_text).strip("_")


def _clean_player_name(value: object) -> str:
    text = _clean_text(value)
    text = re.sub(r"^(?:\+?\d+(?:\+\d+)?)'\s*", "", text)
    text = re.sub(r"^(?:\+?\d+(?:\+\d+)?)\s+", "", text)
    if text.lower().startswith("minuto "):
        return ""
    if text.lower().startswith("jugadores que participaron"):
        return ""
    return text


def _is_valid_selection_name(value: object) -> bool:
    text = _clean_text(value)
    if text in GENERIC_SELECTION_VALUES:
        return False
    if not text:
        return False
    lowered = text.lower()
    return "comparación de las selecciones" not in lowered and "comparacion de las selecciones" not in lowered


def _canonical_selection_name(value: object) -> str:
    text = _clean_text(value)
    if not _is_valid_selection_name(text):
        return ""
    return SELECCION_ALIAS_MAP.get(text, text)


def _parse_bool(value: object) -> bool:
    text = _clean_text(value).lower()
    return text in {"true", "1", "t", "yes", "si", "sí"}


def _parse_int(value: object) -> int | None:
    text = _clean_text(value)
    if not text:
        return None
    match = re.search(r"-?\d+", text)
    return int(match.group()) if match else None


def _parse_score_pair(value: object) -> tuple[int | None, int | None]:
    text = _clean_text(value)
    match = re.search(r"(\d+)\s*-\s*(\d+)", text)
    if not match:
        return None, None
    return int(match.group(1)), int(match.group(2))


def _empty_frame(columns: list[str]) -> pd.DataFrame:
    return pd.DataFrame(columns=columns)


@dataclass
class PlayerRow:
    jugador_id: int
    nombre: str
    nombre_completo: str = ""
    fecha_nacimiento: str = ""
    lugar_nacimiento: str = ""
    altura: str = ""
    apodo: str = ""
    sitio_web: str = ""
    redes_sociales: str = ""


@dataclass
class PlayerRegistry:
    rows: dict[int, PlayerRow] = field(default_factory=dict)
    by_slug: dict[str, int] = field(default_factory=dict)
    by_name_selection: dict[tuple[str, str], int] = field(default_factory=dict)
    by_name: dict[str, int] = field(default_factory=dict)
    next_id: int = 1

    def _merge(self, player_id: int, attrs: dict[str, str]) -> None:
        row = self.rows[player_id]
        for field_name, value in attrs.items():
            cleaned = _clean_text(value)
            if cleaned and not getattr(row, field_name):
                setattr(row, field_name, cleaned)

    def register(self, name: object, slug: object = "", selection_name: object = "", attrs: dict[str, str] | None = None) -> int | None:
        player_name = _clean_player_name(name)
        if not player_name:
            return None

        slug_key = _normalize_key(slug)
        selection_key = _normalize_key(_canonical_selection_name(selection_name))
        name_key = _normalize_key(player_name)

        player_id: int | None = None
        if slug_key and slug_key != "jugadores":
            player_id = self.by_slug.get(slug_key)

        if player_id is None and selection_key:
            player_id = self.by_name_selection.get((name_key, selection_key))

        if player_id is None:
            player_id = self.by_name.get(name_key)

        if player_id is None:
            player_id = self.next_id
            self.next_id += 1
            self.rows[player_id] = PlayerRow(jugador_id=player_id, nombre=player_name)
            self.by_name[name_key] = player_id

        if slug_key and slug_key != "jugadores":
            self.by_slug[slug_key] = player_id
        if selection_key:
            self.by_name_selection[(name_key, selection_key)] = player_id

        self._merge(player_id, attrs or {})
        return player_id

    def resolve(self, name: object, slug: object = "", selection_name: object = "") -> int | None:
        player_name = _clean_player_name(name)
        if not player_name:
            return None
        slug_key = _normalize_key(slug)
        if slug_key and slug_key in self.by_slug:
            return self.by_slug[slug_key]
        selection_key = _normalize_key(_canonical_selection_name(selection_name))
        name_key = _normalize_key(player_name)
        if selection_key and (name_key, selection_key) in self.by_name_selection:
            return self.by_name_selection[(name_key, selection_key)]
        return self.by_name.get(name_key)

    def to_frame(self) -> pd.DataFrame:
        rows = [vars(self.rows[player_id]) for player_id in sorted(self.rows)]
        return pd.DataFrame(rows, columns=[
            "jugador_id",
            "nombre",
            "nombre_completo",
            "fecha_nacimiento",
            "lugar_nacimiento",
            "altura",
            "apodo",
            "sitio_web",
            "redes_sociales",
        ])


@dataclass
class CoachRegistry:
    rows: dict[int, str] = field(default_factory=dict)
    by_name: dict[str, int] = field(default_factory=dict)
    next_id: int = 1

    def register(self, name: object) -> int | None:
        coach_name = _clean_player_name(name)
        if not coach_name:
            return None
        key = _normalize_key(coach_name)
        if key in self.by_name:
            return self.by_name[key]
        coach_id = self.next_id
        self.next_id += 1
        self.by_name[key] = coach_id
        self.rows[coach_id] = coach_name
        return coach_id

    def to_frame(self) -> pd.DataFrame:
        rows = [
            {"entrenador_id": coach_id, "nombre": self.rows[coach_id]}
            for coach_id in sorted(self.rows)
        ]
        return pd.DataFrame(rows, columns=["entrenador_id", "nombre"])


def _collect_selection_names(frames: dict[str, pd.DataFrame]) -> list[str]:
    observed: set[str] = set()
    source_columns = {
        "seleccion.csv": ["nombre"],
        "partido.csv": ["local", "visitante"],
        "aparicion_partido.csv": ["equipo"],
        "gol.csv": ["equipo"],
        "tarjeta.csv": ["equipo"],
        "cambio.csv": ["equipo"],
        "penal.csv": ["equipo"],
        "grupo.csv": ["seleccion"],
        "posicion_final.csv": ["seleccion"],
        "goleador.csv": ["seleccion"],
        "premio.csv": ["seleccion"],
        "plantel.csv": ["seleccion"],
        "participacion_mundial.csv": ["seleccion"],
    }
    for filename, columns in source_columns.items():
        frame = frames.get(filename)
        if frame is None or frame.empty:
            continue
        for column in columns:
            if column not in frame.columns:
                continue
            for value in frame[column].tolist():
                canonical = _canonical_selection_name(value)
                if canonical:
                    observed.add(canonical)
    return sorted(observed)


def _build_selection_frames(frames: dict[str, pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame, dict[str, int]]:
    canonical_names = _collect_selection_names(frames)
    selection_rows = [
        {"seleccion_id": index, "nombre": name}
        for index, name in enumerate(canonical_names, start=1)
    ]
    selection_frame = pd.DataFrame(selection_rows, columns=["seleccion_id", "nombre"])
    selection_map = {row["nombre"]: row["seleccion_id"] for row in selection_rows}

    observed_aliases: set[tuple[str, int]] = set()
    for alias_name, canonical_name in SELECCION_ALIAS_MAP.items():
        if canonical_name in selection_map:
            observed_aliases.add((alias_name, selection_map[canonical_name]))

    for frame in frames.values():
        if frame.empty:
            continue
        for column in frame.columns:
            for value in frame[column].tolist():
                text = _clean_text(value)
                canonical = _canonical_selection_name(text)
                if text and canonical and text != canonical and canonical in selection_map:
                    observed_aliases.add((text, selection_map[canonical]))

    alias_frame = pd.DataFrame(
        sorted(
            ({"alias_nombre": alias_name, "seleccion_id": selection_id} for alias_name, selection_id in observed_aliases),
            key=lambda row: (_normalize_key(row["alias_nombre"]), row["seleccion_id"]),
        ),
        columns=["alias_nombre", "seleccion_id"],
    )
    return selection_frame, alias_frame, selection_map


def _build_player_registry(frames: dict[str, pd.DataFrame]) -> PlayerRegistry:
    registry = PlayerRegistry()

    players = frames.get("jugador.csv", pd.DataFrame())
    if not players.empty:
        for _, row in players.iterrows():
            selection_name = "" if _clean_text(row.get("seleccion")) in GENERIC_SELECTION_VALUES else row.get("seleccion", "")
            registry.register(
                row.get("nombre", ""),
                slug=row.get("slug", ""),
                selection_name=selection_name,
                attrs={
                    "nombre_completo": row.get("nombre_completo", ""),
                    "fecha_nacimiento": row.get("fecha_nacimiento", ""),
                    "lugar_nacimiento": row.get("lugar_nacimiento", ""),
                    "altura": row.get("altura", ""),
                    "apodo": row.get("apodo", ""),
                    "sitio_web": row.get("sitio_web", ""),
                    "redes_sociales": row.get("redes_sociales", ""),
                },
            )

    def register_simple(frame_name: str, name_col: str, slug_col: str | None, selection_col: str | None) -> None:
        frame = frames.get(frame_name, pd.DataFrame())
        if frame.empty:
            return
        for _, row in frame.iterrows():
            registry.register(
                row.get(name_col, ""),
                slug=row.get(slug_col, "") if slug_col else "",
                selection_name=row.get(selection_col, "") if selection_col else "",
            )

    register_simple("gol.csv", "jugador", "jugador_slug", "equipo")
    register_simple("tarjeta.csv", "jugador", "jugador_slug", "equipo")
    register_simple("penal.csv", "jugador", "jugador_slug", "equipo")
    register_simple("goleador.csv", "jugador", "jugador_slug", "seleccion")

    premios = frames.get("premio.csv", pd.DataFrame())
    if not premios.empty:
        for _, row in premios.iterrows():
            if _clean_text(row.get("tipo_destinatario", "")) == "jugador":
                registry.register(row.get("jugador", ""), slug=row.get("jugador_slug", ""), selection_name=row.get("seleccion", ""))

    apariciones = frames.get("aparicion_partido.csv", pd.DataFrame())
    if not apariciones.empty:
        for _, row in apariciones.iterrows():
            if _clean_text(row.get("seccion", "")) != "entrenador":
                registry.register(row.get("jugador_nombre", ""), slug=row.get("jugador_slug", ""), selection_name=row.get("equipo", ""))

    cambios = frames.get("cambio.csv", pd.DataFrame())
    if not cambios.empty:
        for _, row in cambios.iterrows():
            registry.register(row.get("sale", ""), slug=row.get("sale_slug", ""), selection_name=row.get("equipo", ""))
            registry.register(row.get("entra", ""), slug=row.get("entra_slug", ""), selection_name=row.get("equipo", ""))

    plantel = frames.get("plantel.csv", pd.DataFrame())
    if not plantel.empty:
        for _, row in plantel.iterrows():
            if _clean_text(row.get("rol", "")) == "jugador":
                registry.register(
                    row.get("jugador", ""),
                    slug=row.get("jugador_slug", ""),
                    selection_name=row.get("seleccion", ""),
                    attrs={
                        "fecha_nacimiento": row.get("fecha_nacimiento", ""),
                        "altura": row.get("altura", ""),
                    },
                )
    return registry


def _build_coach_registry(frames: dict[str, pd.DataFrame]) -> CoachRegistry:
    registry = CoachRegistry()
    plantel = frames.get("plantel.csv", pd.DataFrame())
    if not plantel.empty:
        for _, row in plantel.iterrows():
            if _clean_text(row.get("rol", "")) == "entrenador":
                registry.register(row.get("jugador", ""))
    apariciones = frames.get("aparicion_partido.csv", pd.DataFrame())
    if not apariciones.empty:
        for _, row in apariciones.iterrows():
            if _clean_text(row.get("seccion", "")) == "entrenador":
                registry.register(row.get("jugador_nombre", ""))
    return registry


def _build_match_frame(frames: dict[str, pd.DataFrame], selection_map: dict[str, int]) -> tuple[pd.DataFrame, dict[str, int]]:
    partidos = frames.get("partido.csv", pd.DataFrame())
    if partidos.empty:
        return _empty_frame([
            "partido_id",
            "anio",
            "fecha",
            "etapa",
            "local_seleccion_id",
            "visitante_seleccion_id",
            "goles_local",
            "goles_visitante",
            "tiempo_extra",
            "definicion_penales",
            "penales_local",
            "penales_visitante",
        ]), {}

    rows: list[dict[str, object]] = []
    match_map: dict[str, int] = {}
    next_id = 1
    for _, row in partidos.iterrows():
        match_key = _clean_text(row.get("slug", ""))
        if not match_key:
            match_key = "|".join([
                _clean_text(row.get("anio", "")),
                _clean_text(row.get("fecha", "")),
                _clean_text(row.get("local", "")),
                _clean_text(row.get("visitante", "")),
                _clean_text(row.get("etapa", "")),
            ])
        if match_key in match_map:
            continue
        goles_local, goles_visitante = _parse_score_pair(row.get("resultado", ""))
        penales_local, penales_visitante = _parse_score_pair(row.get("resultado_penales", ""))
        match_id = next_id
        next_id += 1
        match_map[match_key] = match_id
        rows.append({
            "partido_id": match_id,
            "anio": _parse_int(row.get("anio", "")),
            "fecha": _clean_text(row.get("fecha", "")),
            "etapa": _clean_text(row.get("etapa", "")),
            "local_seleccion_id": selection_map.get(_canonical_selection_name(row.get("local", ""))),
            "visitante_seleccion_id": selection_map.get(_canonical_selection_name(row.get("visitante", ""))),
            "goles_local": goles_local,
            "goles_visitante": goles_visitante,
            "tiempo_extra": _parse_bool(row.get("tiempo_extra", "")),
            "definicion_penales": _parse_bool(row.get("penales", "")),
            "penales_local": penales_local,
            "penales_visitante": penales_visitante,
        })
    return pd.DataFrame(rows), match_map


def _event_resolution_row(source_table: str, source_event_id: int, partido_id: int | None, seleccion_id: int | None, jugador_nombre: str, minuto: object, notas: str) -> dict[str, object]:
    return {
        "source_table": source_table,
        "source_event_id": source_event_id,
        "partido_id": partido_id,
        "seleccion_id": seleccion_id,
        "jugador_nombre_raw": jugador_nombre,
        "minuto": _clean_text(minuto),
        "metodo": "pendiente",
        "confianza": "",
        "notas": notas,
    }


def normalizar_csv_legados(raw_dir: str, output_dir: str) -> None:
    legacy_present = any(os.path.exists(os.path.join(raw_dir, filename)) for filename in ("premio.csv", "plantel.csv"))
    normalized_present = any(os.path.exists(os.path.join(raw_dir, filename)) for filename in NORMALIZED_ONLY_FILES)
    if not legacy_present and normalized_present:
        raise ValueError(
            "La carpeta indicada ya parece estar en formato normalizado final; usa una carpeta legacy como entrada raw-dir."
        )

    frames = {filename: _read_optional_csv(raw_dir, filename) for filename in LEGACY_FILES}
    for filename in FINAL_FILES + OBSOLETE_OUTPUT_FILES:
        output_path = os.path.join(output_dir, filename)
        if os.path.exists(output_path):
            os.remove(output_path)
    seleccion_frame, alias_frame, selection_map = _build_selection_frames(frames)
    player_registry = _build_player_registry(frames)
    coach_registry = _build_coach_registry(frames)
    partido_frame, match_map = _build_match_frame(frames, selection_map)

    match_lookup = {key: value for key, value in match_map.items()}

    aparicion_rows: list[dict[str, object]] = []
    tecnico_rows: list[dict[str, object]] = []
    gol_rows: list[dict[str, object]] = []
    tarjeta_rows: list[dict[str, object]] = []
    cambio_rows: list[dict[str, object]] = []
    penal_rows: list[dict[str, object]] = []
    grupo_rows: list[dict[str, object]] = []
    posicion_rows: list[dict[str, object]] = []
    goleador_rows: list[dict[str, object]] = []
    premio_jugador_rows: list[dict[str, object]] = []
    premio_seleccion_rows: list[dict[str, object]] = []
    plantel_jugador_rows: list[dict[str, object]] = []
    plantel_entrenador_rows: list[dict[str, object]] = []
    participacion_rows: list[dict[str, object]] = []
    resolucion_rows: list[dict[str, object]] = []

    apariciones = frames.get("aparicion_partido.csv", pd.DataFrame())
    if not apariciones.empty:
        for _, row in apariciones.iterrows():
            match_id = match_lookup.get(_clean_text(row.get("partido_slug", "")))
            selection_id = selection_map.get(_canonical_selection_name(row.get("equipo", "")))
            seccion = _clean_text(row.get("seccion", ""))
            if seccion == "entrenador":
                coach_id = coach_registry.register(row.get("jugador_nombre", ""))
                if match_id and selection_id and coach_id:
                    tecnico_rows.append({
                        "partido_id": match_id,
                        "seleccion_id": selection_id,
                        "entrenador_id": coach_id,
                    })
                continue

            player_id = player_registry.resolve(row.get("jugador_nombre", ""), row.get("jugador_slug", ""), row.get("equipo", ""))
            if not player_id:
                player_id = player_registry.register(row.get("jugador_nombre", ""), row.get("jugador_slug", ""), row.get("equipo", ""))
            if match_id and selection_id and player_id:
                aparicion_rows.append({
                    "partido_id": match_id,
                    "seleccion_id": selection_id,
                    "jugador_id": player_id,
                    "posicion": _clean_text(row.get("posicion", "")),
                    "camiseta": _clean_text(row.get("camiseta", "")),
                    "seccion": seccion,
                    "es_capitan": _parse_bool(row.get("es_capitan", "")),
                })

    goals = frames.get("gol.csv", pd.DataFrame())
    next_gol_id = 1
    if not goals.empty:
        for _, row in goals.iterrows():
            jugador_nombre = _clean_player_name(row.get("jugador", ""))
            selection_id = selection_map.get(_canonical_selection_name(row.get("equipo", "")))
            match_id = match_lookup.get(_clean_text(row.get("partido_slug", "")))
            player_id = player_registry.resolve(jugador_nombre, row.get("jugador_slug", ""), row.get("equipo", "")) if jugador_nombre else None
            if match_id and selection_id:
                gol_rows.append({
                    "gol_id": next_gol_id,
                    "partido_id": match_id,
                    "seleccion_id": selection_id,
                    "jugador_id": player_id,
                    "minuto": _clean_text(row.get("minuto", "")),
                    "es_penal": _parse_bool(row.get("es_penal", "")),
                    "es_autogol": _parse_bool(row.get("es_autogol", "")),
                })
                if jugador_nombre and not player_id:
                    resolucion_rows.append(_event_resolution_row("gol", next_gol_id, match_id, selection_id, jugador_nombre, row.get("minuto", ""), "Jugador sin correspondencia directa"))
                next_gol_id += 1

    cards = frames.get("tarjeta.csv", pd.DataFrame())
    next_card_id = 1
    if not cards.empty:
        for _, row in cards.iterrows():
            jugador_nombre = _clean_player_name(row.get("jugador", ""))
            selection_id = selection_map.get(_canonical_selection_name(row.get("equipo", "")))
            match_id = match_lookup.get(_clean_text(row.get("partido_slug", "")))
            if not match_id:
                continue
            if not selection_id and not jugador_nombre:
                continue
            player_id = player_registry.resolve(jugador_nombre, row.get("jugador_slug", ""), row.get("equipo", "")) if jugador_nombre else None
            tarjeta_rows.append({
                "tarjeta_id": next_card_id,
                "partido_id": match_id,
                "seleccion_id": selection_id,
                "jugador_id": player_id,
                "tipo": _clean_text(row.get("tipo", "")),
                "minuto": _clean_text(row.get("minuto", "")),
            })
            if jugador_nombre and not player_id:
                resolucion_rows.append(_event_resolution_row("tarjeta", next_card_id, match_id, selection_id, jugador_nombre, row.get("minuto", ""), "Jugador sin correspondencia directa"))
            next_card_id += 1

    changes = frames.get("cambio.csv", pd.DataFrame())
    next_change_id = 1
    if not changes.empty:
        for _, row in changes.iterrows():
            selection_id = selection_map.get(_canonical_selection_name(row.get("equipo", "")))
            match_id = match_lookup.get(_clean_text(row.get("partido_slug", "")))
            if not match_id or not selection_id:
                continue
            sale_name = _clean_player_name(row.get("sale", ""))
            entra_name = _clean_player_name(row.get("entra", ""))
            sale_id = player_registry.resolve(sale_name, row.get("sale_slug", ""), row.get("equipo", "")) if sale_name else None
            entra_id = player_registry.resolve(entra_name, row.get("entra_slug", ""), row.get("equipo", "")) if entra_name else None
            cambio_rows.append({
                "cambio_id": next_change_id,
                "partido_id": match_id,
                "seleccion_id": selection_id,
                "jugador_sale_id": sale_id,
                "jugador_entra_id": entra_id,
                "minuto": _clean_text(row.get("minuto", "")),
            })
            if sale_name and not sale_id:
                resolucion_rows.append(_event_resolution_row("cambio_salida", next_change_id, match_id, selection_id, sale_name, row.get("minuto", ""), "Jugador saliente sin correspondencia directa"))
            if entra_name and not entra_id:
                resolucion_rows.append(_event_resolution_row("cambio_entrada", next_change_id, match_id, selection_id, entra_name, row.get("minuto", ""), "Jugador entrante sin correspondencia directa"))
            next_change_id += 1

    penalties = frames.get("penal.csv", pd.DataFrame())
    next_penal_id = 1
    if not penalties.empty:
        for _, row in penalties.iterrows():
            selection_id = selection_map.get(_canonical_selection_name(row.get("equipo", "")))
            match_id = match_lookup.get(_clean_text(row.get("partido_slug", "")))
            if not match_id or not selection_id:
                continue
            jugador_nombre = _clean_player_name(row.get("jugador", ""))
            player_id = player_registry.resolve(jugador_nombre, row.get("jugador_slug", ""), row.get("equipo", "")) if jugador_nombre else None
            penal_rows.append({
                "penal_id": next_penal_id,
                "partido_id": match_id,
                "seleccion_id": selection_id,
                "orden": _parse_int(row.get("orden", "")),
                "jugador_id": player_id,
                "resultado": _clean_text(row.get("resultado", "")),
            })
            if jugador_nombre and not player_id:
                resolucion_rows.append(_event_resolution_row("penal", next_penal_id, match_id, selection_id, jugador_nombre, "", "Ejecutor sin correspondencia directa"))
            next_penal_id += 1

    groups = frames.get("grupo.csv", pd.DataFrame())
    if not groups.empty:
        for _, row in groups.iterrows():
            selection_id = selection_map.get(_canonical_selection_name(row.get("seleccion", "")))
            if not selection_id:
                continue
            grupo_rows.append({
                "anio": _parse_int(row.get("anio", "")),
                "grupo": _clean_text(row.get("grupo", "")),
                "posicion": _parse_int(row.get("posicion", "")),
                "seleccion_id": selection_id,
                "pts": _parse_int(row.get("pts", "")),
                "pj": _parse_int(row.get("pj", "")),
                "pg": _parse_int(row.get("pg", "")),
                "pe": _parse_int(row.get("pe", "")),
                "pp": _parse_int(row.get("pp", "")),
                "gf": _parse_int(row.get("gf", "")),
                "gc": _parse_int(row.get("gc", "")),
                "dif": _parse_int(row.get("dif", "")),
                "clasificado": _parse_bool(row.get("clasificado", "")),
            })

    final_positions = frames.get("posicion_final.csv", pd.DataFrame())
    if not final_positions.empty:
        for _, row in final_positions.iterrows():
            selection_id = selection_map.get(_canonical_selection_name(row.get("seleccion", "")))
            if selection_id:
                posicion_rows.append({
                    "anio": _parse_int(row.get("anio", "")),
                    "posicion": _parse_int(row.get("posicion", "")),
                    "seleccion_id": selection_id,
                })

    scorers = frames.get("goleador.csv", pd.DataFrame())
    if not scorers.empty:
        for _, row in scorers.iterrows():
            selection_id = selection_map.get(_canonical_selection_name(row.get("seleccion", "")))
            player_id = player_registry.resolve(row.get("jugador", ""), row.get("jugador_slug", ""), row.get("seleccion", ""))
            if player_id:
                goleador_rows.append({
                    "anio": _parse_int(row.get("anio", "")),
                    "jugador_id": player_id,
                    "seleccion_id": selection_id,
                    "goles": _parse_int(row.get("goles", "")),
                })

    awards = frames.get("premio.csv", pd.DataFrame())
    if not awards.empty:
        for _, row in awards.iterrows():
            award_name = _clean_text(row.get("premio", ""))
            if not award_name:
                continue
            if _clean_text(row.get("tipo_destinatario", "")) == "jugador":
                player_id = player_registry.resolve(row.get("jugador", ""), row.get("jugador_slug", ""), row.get("seleccion", ""))
                if player_id:
                    premio_jugador_rows.append({
                        "anio": _parse_int(row.get("anio", "")),
                        "premio": award_name,
                        "jugador_id": player_id,
                        "seleccion_id": selection_map.get(_canonical_selection_name(row.get("seleccion", ""))),
                    })
            else:
                selection_id = selection_map.get(_canonical_selection_name(row.get("seleccion", "")))
                if selection_id:
                    premio_seleccion_rows.append({
                        "anio": _parse_int(row.get("anio", "")),
                        "premio": award_name,
                        "seleccion_id": selection_id,
                    })

    roster = frames.get("plantel.csv", pd.DataFrame())
    if not roster.empty:
        for _, row in roster.iterrows():
            selection_id = selection_map.get(_canonical_selection_name(row.get("seleccion", "")))
            if not selection_id:
                continue
            if _clean_text(row.get("rol", "")) == "entrenador":
                coach_id = coach_registry.register(row.get("jugador", ""))
                if coach_id:
                    plantel_entrenador_rows.append({
                        "anio": _parse_int(row.get("anio", "")),
                        "seleccion_id": selection_id,
                        "entrenador_id": coach_id,
                    })
                continue
            player_id = player_registry.resolve(row.get("jugador", ""), row.get("jugador_slug", ""), row.get("seleccion", ""))
            if player_id:
                plantel_jugador_rows.append({
                    "anio": _parse_int(row.get("anio", "")),
                    "seleccion_id": selection_id,
                    "jugador_id": player_id,
                    "posicion": _clean_text(row.get("posicion", "")),
                    "camiseta": _clean_text(row.get("camiseta", "")),
                    "club": _clean_text(row.get("club", "")),
                })

    participations = frames.get("participacion_mundial.csv", pd.DataFrame())
    if not participations.empty:
        for _, row in participations.iterrows():
            selection_id = selection_map.get(_canonical_selection_name(row.get("seleccion", "")))
            if not selection_id:
                continue
            participacion_rows.append({
                "anio": _parse_int(row.get("anio", "")),
                "seleccion_id": selection_id,
                "posicion": _parse_int(row.get("posicion", "")),
                "etapa": _clean_text(row.get("etapa", "")),
                "pts": _parse_int(row.get("pts", "")),
                "pj": _parse_int(row.get("pj", "")),
                "pg": _parse_int(row.get("pg", "")),
                "pe": _parse_int(row.get("pe", "")),
                "pp": _parse_int(row.get("pp", "")),
                "gf": _parse_int(row.get("gf", "")),
                "gc": _parse_int(row.get("gc", "")),
                "dif": _parse_int(row.get("dif", "")),
                "participo": _parse_bool(row.get("participo", "")),
            })

    mundiales = frames.get("mundial.csv", pd.DataFrame())
    mundial_rows: list[dict[str, object]] = []
    if not mundiales.empty:
        for _, row in mundiales.iterrows():
            mundial_rows.append({
                "anio": _parse_int(row.get("anio", "")),
                "sede": _clean_text(row.get("sede", "")),
                "equipos": _parse_int(row.get("equipos", "")),
                "partidos_jugados": _parse_int(row.get("partidos_jugados", "")),
                "goles_total": _parse_int(row.get("goles_total", "")),
            })

    _write_csv(pd.DataFrame(mundial_rows, columns=["anio", "sede", "equipos", "partidos_jugados", "goles_total"]).drop_duplicates(), output_dir, "mundial.csv")
    _write_csv(seleccion_frame.drop_duplicates(subset=["seleccion_id"]), output_dir, "seleccion.csv")
    _write_csv(alias_frame.drop_duplicates(subset=["alias_nombre", "seleccion_id"]), output_dir, "seleccion_alias.csv")
    _write_csv(player_registry.to_frame().drop_duplicates(subset=["jugador_id"]), output_dir, "jugador.csv")
    _write_csv(coach_registry.to_frame().drop_duplicates(subset=["entrenador_id"]), output_dir, "entrenador.csv")
    _write_csv(partido_frame.drop_duplicates(subset=["partido_id"]), output_dir, "partido.csv")
    _write_csv(pd.DataFrame(aparicion_rows, columns=["partido_id", "seleccion_id", "jugador_id", "posicion", "camiseta", "seccion", "es_capitan"]).drop_duplicates(), output_dir, "aparicion_partido.csv")
    _write_csv(pd.DataFrame(tecnico_rows, columns=["partido_id", "seleccion_id", "entrenador_id"]).drop_duplicates(), output_dir, "direccion_tecnica_partido.csv")
    _write_csv(pd.DataFrame(gol_rows, columns=["gol_id", "partido_id", "seleccion_id", "jugador_id", "minuto", "es_penal", "es_autogol"]).drop_duplicates(subset=["gol_id"]), output_dir, "gol.csv")
    _write_csv(pd.DataFrame(tarjeta_rows, columns=["tarjeta_id", "partido_id", "seleccion_id", "jugador_id", "tipo", "minuto"]).drop_duplicates(subset=["tarjeta_id"]), output_dir, "tarjeta.csv")
    _write_csv(pd.DataFrame(cambio_rows, columns=["cambio_id", "partido_id", "seleccion_id", "jugador_sale_id", "jugador_entra_id", "minuto"]).drop_duplicates(subset=["cambio_id"]), output_dir, "cambio.csv")
    _write_csv(pd.DataFrame(penal_rows, columns=["penal_id", "partido_id", "seleccion_id", "orden", "jugador_id", "resultado"]).drop_duplicates(subset=["penal_id"]), output_dir, "penal.csv")
    _write_csv(pd.DataFrame(grupo_rows, columns=["anio", "grupo", "posicion", "seleccion_id", "pts", "pj", "pg", "pe", "pp", "gf", "gc", "dif", "clasificado"]).drop_duplicates(), output_dir, "grupo.csv")
    _write_csv(pd.DataFrame(posicion_rows, columns=["anio", "posicion", "seleccion_id"]).drop_duplicates(), output_dir, "posicion_final.csv")
    _write_csv(pd.DataFrame(goleador_rows, columns=["anio", "jugador_id", "seleccion_id", "goles"]).drop_duplicates(), output_dir, "goleador.csv")
    _write_csv(pd.DataFrame(premio_jugador_rows, columns=["anio", "premio", "jugador_id", "seleccion_id"]).drop_duplicates(), output_dir, "premio_jugador.csv")
    _write_csv(pd.DataFrame(premio_seleccion_rows, columns=["anio", "premio", "seleccion_id"]).drop_duplicates(), output_dir, "premio_seleccion.csv")
    _write_csv(pd.DataFrame(plantel_jugador_rows, columns=["anio", "seleccion_id", "jugador_id", "posicion", "camiseta", "club"]).drop_duplicates(), output_dir, "plantel_jugador.csv")
    _write_csv(pd.DataFrame(plantel_entrenador_rows, columns=["anio", "seleccion_id", "entrenador_id"]).drop_duplicates(), output_dir, "plantel_entrenador.csv")
    _write_csv(pd.DataFrame(participacion_rows, columns=["anio", "seleccion_id", "posicion", "etapa", "pts", "pj", "pg", "pe", "pp", "gf", "gc", "dif", "participo"]).drop_duplicates(), output_dir, "participacion_mundial.csv")
    _write_csv(pd.DataFrame(resolucion_rows, columns=["source_table", "source_event_id", "partido_id", "seleccion_id", "jugador_nombre_raw", "minuto", "metodo", "confianza", "notas"]).drop_duplicates(), output_dir, "resolucion_identidad_jugador.csv")