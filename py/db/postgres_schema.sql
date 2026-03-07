-- PostgreSQL schema for normalized World Cup data
-- Target: PostgreSQL 13+

BEGIN;

CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION slugify_name(input_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT NULLIF(
        regexp_replace(
            regexp_replace(lower(unaccent(coalesce(input_text, ''))), '[^a-z0-9]+', '_', 'g'),
            '(^_+|_+$)',
            '',
            'g'
        ),
        ''
    );
$$;

CREATE TABLE IF NOT EXISTS mundial (
    anio integer PRIMARY KEY,
    sede text,
    campeon text,
    subcampeon text,
    tercer_lugar text,
    cuarto_lugar text,
    equipos integer,
    partidos_jugados integer,
    goles_total integer,
    promedio_gol numeric(6,2)
);

CREATE TABLE IF NOT EXISTS seleccion (
    seleccion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    nombre text NOT NULL,
    participaciones integer,
    pj integer,
    pg integer,
    pe integer,
    pp integer,
    gf integer,
    gc integer,
    titulos integer,
    subcampeonatos integer,
    posicion_historica text
);

CREATE TABLE IF NOT EXISTS seleccion_alias (
    alias_slug text PRIMARY KEY,
    alias_nombre text NOT NULL,
    seleccion_id bigint NOT NULL REFERENCES seleccion(seleccion_id),
    notas text
);

CREATE TABLE IF NOT EXISTS jugador (
    jugador_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text UNIQUE,
    nombre text NOT NULL,
    nombre_completo text,
    seleccion_nombre text,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    fecha_nacimiento text,
    lugar_nacimiento text,
    posicion text,
    numeros_camiseta text,
    altura text,
    apodo text,
    sitio_web text,
    redes_sociales text,
    mundiales integer,
    partidos integer,
    goles integer,
    promedio_gol numeric(6,2)
);

CREATE TABLE IF NOT EXISTS partido (
    partido_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    anio integer NOT NULL REFERENCES mundial(anio),
    fecha text,
    etapa text,
    local_nombre text NOT NULL,
    visitante_nombre text NOT NULL,
    local_seleccion_id bigint REFERENCES seleccion(seleccion_id),
    visitante_seleccion_id bigint REFERENCES seleccion(seleccion_id),
    resultado text,
    tiempo_extra boolean,
    penales boolean,
    resultado_penales text
);

CREATE TABLE IF NOT EXISTS aparicion_partido (
    aparicion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partido(slug),
    anio integer NOT NULL REFERENCES mundial(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    jugador_slug text REFERENCES jugador(slug),
    jugador_id bigint REFERENCES jugador(jugador_id),
    jugador_nombre text NOT NULL,
    posicion text,
    camiseta text,
    seccion text NOT NULL CHECK (seccion IN ('titular', 'ingresado', 'suplente_no_jugo', 'entrenador')),
    es_capitan boolean NOT NULL DEFAULT false,
    UNIQUE (partido_slug, equipo_nombre, jugador_nombre, seccion)
);

CREATE TABLE IF NOT EXISTS gol (
    gol_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partido(slug),
    anio integer NOT NULL REFERENCES mundial(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugador(slug),
    jugador_id bigint REFERENCES jugador(jugador_id),
    minuto text,
    es_penal boolean NOT NULL DEFAULT false,
    es_autogol boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS tarjeta (
    tarjeta_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partido(slug),
    anio integer NOT NULL REFERENCES mundial(anio),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugador(slug),
    jugador_id bigint REFERENCES jugador(jugador_id),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    tipo text NOT NULL CHECK (tipo IN ('amarilla', 'roja')),
    minuto text
);

CREATE TABLE IF NOT EXISTS cambio (
    cambio_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partido(slug),
    anio integer NOT NULL REFERENCES mundial(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    sale text,
    sale_slug text REFERENCES jugador(slug),
    sale_jugador_id bigint REFERENCES jugador(jugador_id),
    entra text,
    entra_slug text REFERENCES jugador(slug),
    entra_jugador_id bigint REFERENCES jugador(jugador_id),
    minuto text
);

CREATE TABLE IF NOT EXISTS penal (
    penal_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partido(slug),
    anio integer NOT NULL REFERENCES mundial(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    orden integer NOT NULL,
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugador(slug),
    jugador_id bigint REFERENCES jugador(jugador_id),
    resultado text NOT NULL,
    UNIQUE (partido_slug, equipo_nombre, orden)
);

CREATE TABLE IF NOT EXISTS grupo (
    grupo_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundial(anio),
    grupo text NOT NULL,
    posicion integer,
    seleccion_nombre text NOT NULL,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    pts integer,
    pj integer,
    pg integer,
    pe integer,
    pp integer,
    gf integer,
    gc integer,
    dif integer,
    clasificado boolean,
    UNIQUE (anio, grupo, seleccion_nombre)
);

CREATE TABLE IF NOT EXISTS posicion_final (
    posicion_final_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundial(anio),
    posicion integer NOT NULL,
    seleccion_nombre text NOT NULL,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    UNIQUE (anio, posicion, seleccion_nombre)
);

CREATE TABLE IF NOT EXISTS goleador (
    goleador_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundial(anio),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugador(slug),
    jugador_id bigint REFERENCES jugador(jugador_id),
    seleccion_nombre text,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    goles integer,
    UNIQUE (anio, jugador, seleccion_nombre)
);

CREATE TABLE IF NOT EXISTS premio (
    premio_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundial(anio),
    premio text NOT NULL,
    tipo_destinatario text NOT NULL CHECK (tipo_destinatario IN ('jugador', 'seleccion')),
    jugador text,
    jugador_slug text REFERENCES jugador(slug),
    jugador_id bigint REFERENCES jugador(jugador_id),
    seleccion_nombre text,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    destinatario_key text GENERATED ALWAYS AS (
        coalesce(nullif(jugador_slug, ''), nullif(jugador, ''), slugify_name(nullif(seleccion_nombre, '')), '')
    ) STORED,
    UNIQUE (anio, premio, tipo_destinatario, destinatario_key)
);

CREATE TABLE IF NOT EXISTS plantel (
    plantel_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundial(anio),
    seleccion_nombre text,
    seleccion_slug text,
    seleccion_key text GENERATED ALWAYS AS (coalesce(nullif(seleccion_slug, ''), nullif(seleccion_nombre, ''), '')) STORED,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugador(slug),
    jugador_key text GENERATED ALWAYS AS (coalesce(nullif(jugador_slug, ''), nullif(jugador, ''), '')) STORED,
    jugador_id bigint REFERENCES jugador(jugador_id),
    posicion text,
    camiseta text,
    fecha_nacimiento text,
    altura text,
    club text,
    rol text NOT NULL CHECK (rol IN ('jugador', 'entrenador')),
    UNIQUE (anio, jugador_key, seleccion_key, rol)
);

CREATE TABLE IF NOT EXISTS participacion_mundial (
    participacion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundial(anio),
    seleccion_nombre text NOT NULL,
    seleccion_slug text,
    seleccion_key text GENERATED ALWAYS AS (coalesce(nullif(seleccion_slug, ''), slugify_name(nullif(seleccion_nombre, '')), '')) STORED,
    seleccion_id bigint REFERENCES seleccion(seleccion_id),
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
    UNIQUE (anio, seleccion_key)
);

CREATE TABLE IF NOT EXISTS resolucion_identidad_jugador (
    resolucion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_table text NOT NULL CHECK (source_table IN ('gol', 'tarjeta', 'cambio_entrada', 'cambio_salida', 'aparicion_partido', 'penal')),
    source_pk bigint,
    partido_slug text NOT NULL REFERENCES partido(slug),
    anio integer NOT NULL REFERENCES mundial(anio),
    equipo_nombre text,
    equipo_key text GENERATED ALWAYS AS (coalesce(equipo_nombre, '')) STORED,
    jugador_nombre_raw text NOT NULL,
    jugador_slug_raw text,
    minuto text,
    minuto_key text GENERATED ALWAYS AS (coalesce(minuto, '')) STORED,
    jugador_id_resuelto bigint REFERENCES jugador(jugador_id),
    jugador_slug_resuelto text REFERENCES jugador(slug),
    metodo text NOT NULL DEFAULT 'manual',
    confianza numeric(5,2),
    notas text,
    UNIQUE (source_table, partido_slug, equipo_key, jugador_nombre_raw, minuto_key)
);

CREATE OR REPLACE VIEW v_jugador_sin_slug AS
SELECT 'gol'::text AS source_table,
       g.gol_id::bigint AS source_pk,
       g.partido_slug,
       g.anio,
       g.equipo_nombre,
       g.jugador AS jugador_nombre,
       g.jugador_slug,
       g.minuto
FROM gol g
WHERE g.jugador_slug IS NULL OR btrim(g.jugador_slug) = ''
UNION ALL
SELECT 'tarjeta'::text,
       t.tarjeta_id::bigint,
       t.partido_slug,
       t.anio,
       t.equipo_nombre,
       t.jugador,
       t.jugador_slug,
       t.minuto
FROM tarjeta t
WHERE t.jugador_slug IS NULL OR btrim(t.jugador_slug) = ''
UNION ALL
SELECT 'cambio_entrada'::text,
       c.cambio_id::bigint,
       c.partido_slug,
       c.anio,
       c.equipo_nombre,
       c.entra,
       c.entra_slug,
       c.minuto
FROM cambio c
WHERE c.entra IS NOT NULL
  AND btrim(c.entra) <> ''
  AND (c.entra_slug IS NULL OR btrim(c.entra_slug) = '')
UNION ALL
SELECT 'cambio_salida'::text,
       c.cambio_id::bigint,
       c.partido_slug,
       c.anio,
       c.equipo_nombre,
       c.sale,
       c.sale_slug,
       c.minuto
FROM cambio c
WHERE c.sale IS NOT NULL
  AND btrim(c.sale) <> ''
  AND (c.sale_slug IS NULL OR btrim(c.sale_slug) = '')
UNION ALL
SELECT 'aparicion_partido'::text,
       a.aparicion_id::bigint,
       a.partido_slug,
       a.anio,
       a.equipo_nombre,
       a.jugador_nombre,
       a.jugador_slug,
       NULL::text AS minuto
FROM aparicion_partido a
WHERE a.seccion <> 'entrenador'
  AND (a.jugador_slug IS NULL OR btrim(a.jugador_slug) = '')
UNION ALL
SELECT 'penal'::text,
       p.penal_id::bigint,
       p.partido_slug,
       p.anio,
       p.equipo_nombre,
       p.jugador,
       p.jugador_slug,
       NULL::text AS minuto
FROM penal p
WHERE p.jugador_slug IS NULL OR btrim(p.jugador_slug) = '';

CREATE INDEX IF NOT EXISTS idx_partido_anio ON partido(anio);
CREATE INDEX IF NOT EXISTS idx_partido_local_sel ON partido(local_seleccion_id);
CREATE INDEX IF NOT EXISTS idx_partido_visitante_sel ON partido(visitante_seleccion_id);

CREATE INDEX IF NOT EXISTS idx_aparicion_partido_slug ON aparicion_partido(partido_slug);
CREATE INDEX IF NOT EXISTS idx_aparicion_jugador_slug ON aparicion_partido(jugador_slug);
CREATE INDEX IF NOT EXISTS idx_aparicion_jugador_id ON aparicion_partido(jugador_id);

CREATE INDEX IF NOT EXISTS idx_gol_partido_slug ON gol(partido_slug);
CREATE INDEX IF NOT EXISTS idx_gol_jugador_slug ON gol(jugador_slug);
CREATE INDEX IF NOT EXISTS idx_gol_jugador_id ON gol(jugador_id);

CREATE INDEX IF NOT EXISTS idx_tarjeta_partido_slug ON tarjeta(partido_slug);
CREATE INDEX IF NOT EXISTS idx_tarjeta_jugador_slug ON tarjeta(jugador_slug);
CREATE INDEX IF NOT EXISTS idx_tarjeta_jugador_id ON tarjeta(jugador_id);

CREATE INDEX IF NOT EXISTS idx_cambio_partido_slug ON cambio(partido_slug);
CREATE INDEX IF NOT EXISTS idx_cambio_entra_slug ON cambio(entra_slug);
CREATE INDEX IF NOT EXISTS idx_cambio_sale_slug ON cambio(sale_slug);

CREATE INDEX IF NOT EXISTS idx_penal_partido_slug ON penal(partido_slug);
CREATE INDEX IF NOT EXISTS idx_penal_jugador_slug ON penal(jugador_slug);

CREATE INDEX IF NOT EXISTS idx_grupo_anio_grupo ON grupo(anio, grupo);
CREATE INDEX IF NOT EXISTS idx_posicion_final_anio ON posicion_final(anio);
CREATE INDEX IF NOT EXISTS idx_goleador_anio ON goleador(anio);
CREATE INDEX IF NOT EXISTS idx_premio_anio ON premio(anio);
CREATE INDEX IF NOT EXISTS idx_plantel_anio ON plantel(anio);
CREATE INDEX IF NOT EXISTS idx_participacion_anio ON participacion_mundial(anio);

COMMIT;