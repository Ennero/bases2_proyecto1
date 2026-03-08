-- PostgreSQL schema for a strictly normalized World Cup model
-- Target: PostgreSQL 13+

BEGIN;

CREATE TABLE IF NOT EXISTS mundial (
    anio integer PRIMARY KEY,
    sede text,
    equipos integer,
    partidos_jugados integer,
    goles_total integer
);

CREATE TABLE IF NOT EXISTS seleccion (
    seleccion_id bigint PRIMARY KEY,
    nombre text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS seleccion_alias (
    alias_nombre text PRIMARY KEY,
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id)
);

CREATE TABLE IF NOT EXISTS jugador (
    jugador_id bigint PRIMARY KEY,
    nombre text NOT NULL,
    nombre_completo text,
    fecha_nacimiento text,
    lugar_nacimiento text,
    altura text,
    apodo text,
    sitio_web text,
    redes_sociales text
);

CREATE TABLE IF NOT EXISTS entrenador (
    entrenador_id bigint PRIMARY KEY,
    nombre text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS partido (
    partido_id bigint PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundial(anio),
    fecha text,
    etapa text,
    local_seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    visitante_seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    goles_local integer,
    goles_visitante integer,
    tiempo_extra boolean NOT NULL DEFAULT false,
    definicion_penales boolean NOT NULL DEFAULT false,
    penales_local integer,
    penales_visitante integer,
    UNIQUE (anio, fecha, etapa, local_seleccion_id, visitante_seleccion_id)
);

CREATE TABLE IF NOT EXISTS aparicion_partido (
    partido_id bigint NOT NULL REFERENCES partido(partido_id),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    jugador_id bigint NOT NULL REFERENCES jugador(jugador_id),
    posicion text,
    camiseta text,
    seccion text NOT NULL CHECK (seccion IN ('titular', 'ingresado', 'suplente_no_jugo')),
    es_capitan boolean NOT NULL DEFAULT false,
    PRIMARY KEY (partido_id, seleccion_id, jugador_id, seccion)
);

CREATE TABLE IF NOT EXISTS direccion_tecnica_partido (
    partido_id bigint NOT NULL REFERENCES partido(partido_id),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    entrenador_id bigint NOT NULL REFERENCES entrenador(entrenador_id),
    PRIMARY KEY (partido_id, seleccion_id, entrenador_id)
);

CREATE TABLE IF NOT EXISTS gol (
    gol_id bigint PRIMARY KEY,
    partido_id bigint NOT NULL REFERENCES partido(partido_id),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    jugador_id bigint REFERENCES jugador(jugador_id),
    minuto text,
    es_penal boolean NOT NULL DEFAULT false,
    es_autogol boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS tarjeta (
    tarjeta_id bigint PRIMARY KEY,
    partido_id bigint NOT NULL REFERENCES partido(partido_id),
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    jugador_id bigint REFERENCES jugador(jugador_id),
    tipo text NOT NULL CHECK (tipo IN ('amarilla', 'roja')),
    minuto text
);

CREATE TABLE IF NOT EXISTS cambio (
    cambio_id bigint PRIMARY KEY,
    partido_id bigint NOT NULL REFERENCES partido(partido_id),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    jugador_sale_id bigint REFERENCES jugador(jugador_id),
    jugador_entra_id bigint REFERENCES jugador(jugador_id),
    minuto text
);

CREATE TABLE IF NOT EXISTS penal (
    penal_id bigint PRIMARY KEY,
    partido_id bigint NOT NULL REFERENCES partido(partido_id),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    orden integer NOT NULL,
    jugador_id bigint REFERENCES jugador(jugador_id),
    resultado text NOT NULL,
    UNIQUE (partido_id, seleccion_id, orden)
);

CREATE TABLE IF NOT EXISTS grupo (
    anio integer NOT NULL REFERENCES mundial(anio),
    grupo text NOT NULL,
    posicion integer,
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    pts integer,
    pj integer,
    pg integer,
    pe integer,
    pp integer,
    gf integer,
    gc integer,
    dif integer,
    clasificado boolean,
    PRIMARY KEY (anio, grupo, seleccion_id)
);

CREATE TABLE IF NOT EXISTS posicion_final (
    anio integer NOT NULL REFERENCES mundial(anio),
    posicion integer NOT NULL,
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    PRIMARY KEY (anio, posicion),
    UNIQUE (anio, seleccion_id)
);

CREATE TABLE IF NOT EXISTS goleador (
    anio integer NOT NULL REFERENCES mundial(anio),
    jugador_id bigint NOT NULL REFERENCES jugador(jugador_id),
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    goles integer,
    PRIMARY KEY (anio, jugador_id)
);

CREATE TABLE IF NOT EXISTS premio_jugador (
    anio integer NOT NULL REFERENCES mundial(anio),
    premio text NOT NULL,
    jugador_id bigint NOT NULL REFERENCES jugador(jugador_id),
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    PRIMARY KEY (anio, premio, jugador_id)
);

CREATE TABLE IF NOT EXISTS premio_seleccion (
    anio integer NOT NULL REFERENCES mundial(anio),
    premio text NOT NULL,
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    PRIMARY KEY (anio, premio, seleccion_id)
);

CREATE TABLE IF NOT EXISTS plantel_jugador (
    anio integer NOT NULL REFERENCES mundial(anio),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    jugador_id bigint NOT NULL REFERENCES jugador(jugador_id),
    posicion text,
    camiseta text,
    club text,
    PRIMARY KEY (anio, seleccion_id, jugador_id)
);

CREATE TABLE IF NOT EXISTS plantel_entrenador (
    anio integer NOT NULL REFERENCES mundial(anio),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    entrenador_id bigint NOT NULL REFERENCES entrenador(entrenador_id),
    PRIMARY KEY (anio, seleccion_id, entrenador_id)
);

CREATE TABLE IF NOT EXISTS participacion_mundial (
    anio integer NOT NULL REFERENCES mundial(anio),
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    posicion integer,
    etapa text,
    pts integer,
    pj integer,
    pg integer,
    pe integer,
    pp integer,
    gf integer,
    gc integer,
    dif integer,
    participo boolean NOT NULL DEFAULT true,
    PRIMARY KEY (anio, seleccion_id)
);

CREATE TABLE IF NOT EXISTS resolucion_identidad_jugador (
    resolucion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_table text NOT NULL CHECK (source_table IN ('gol', 'tarjeta', 'cambio_entrada', 'cambio_salida', 'penal')),
    source_event_id bigint NOT NULL,
    partido_id bigint REFERENCES partido(partido_id),
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    jugador_nombre_raw text NOT NULL,
    minuto text,
    metodo text NOT NULL DEFAULT 'manual',
    confianza numeric(5,2),
    notas text,
    UNIQUE (source_table, source_event_id)
);

CREATE OR REPLACE VIEW v_evento_jugador_pendiente AS
SELECT 'gol'::text AS source_table,
       g.gol_id AS source_event_id,
       g.partido_id,
       g.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, g.minuto) AS minuto
FROM gol g
LEFT JOIN resolucion_identidad_jugador r
    ON r.source_table = 'gol'
      AND r.source_event_id = g.gol_id
WHERE g.jugador_id IS NULL
UNION ALL
SELECT 'tarjeta'::text,
       t.tarjeta_id,
       t.partido_id,
       t.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, t.minuto)
FROM tarjeta t
LEFT JOIN resolucion_identidad_jugador r
    ON r.source_table = 'tarjeta'
      AND r.source_event_id = t.tarjeta_id
WHERE t.jugador_id IS NULL
UNION ALL
SELECT 'cambio_entrada'::text,
       c.cambio_id,
       c.partido_id,
       c.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, c.minuto)
FROM cambio c
LEFT JOIN resolucion_identidad_jugador r
    ON r.source_table = 'cambio_entrada'
      AND r.source_event_id = c.cambio_id
WHERE c.jugador_entra_id IS NULL
UNION ALL
SELECT 'cambio_salida'::text,
       c.cambio_id,
       c.partido_id,
       c.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, c.minuto)
FROM cambio c
LEFT JOIN resolucion_identidad_jugador r
    ON r.source_table = 'cambio_salida'
      AND r.source_event_id = c.cambio_id
WHERE c.jugador_sale_id IS NULL
UNION ALL
SELECT 'penal'::text,
       p.penal_id,
       p.partido_id,
       p.seleccion_id,
    r.jugador_nombre_raw,
    r.minuto
FROM penal p
LEFT JOIN resolucion_identidad_jugador r
    ON r.source_table = 'penal'
      AND r.source_event_id = p.penal_id
WHERE p.jugador_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_partido_anio ON partido(anio);
CREATE INDEX IF NOT EXISTS idx_partido_local ON partido(local_seleccion_id);
CREATE INDEX IF NOT EXISTS idx_partido_visitante ON partido(visitante_seleccion_id);
CREATE INDEX IF NOT EXISTS idx_gol_partido ON gol(partido_id);
CREATE INDEX IF NOT EXISTS idx_tarjeta_partido ON tarjeta(partido_id);
CREATE INDEX IF NOT EXISTS idx_cambio_partido ON cambio(partido_id);
CREATE INDEX IF NOT EXISTS idx_penal_partido ON penal(partido_id);
CREATE INDEX IF NOT EXISTS idx_grupo_anio_grupo ON grupo(anio, grupo);
CREATE INDEX IF NOT EXISTS idx_posicion_final_anio ON posicion_final(anio);
CREATE INDEX IF NOT EXISTS idx_participacion_anio ON participacion_mundial(anio);

COMMIT;