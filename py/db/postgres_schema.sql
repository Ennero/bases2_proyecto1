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

CREATE TABLE IF NOT EXISTS mundiales (
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

CREATE TABLE IF NOT EXISTS selecciones (
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

CREATE TABLE IF NOT EXISTS selecciones_alias (
    alias_slug text PRIMARY KEY,
    alias_nombre text NOT NULL,
    seleccion_id bigint NOT NULL REFERENCES selecciones(seleccion_id),
    notas text
);

CREATE TABLE IF NOT EXISTS jugadores (
    jugador_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text UNIQUE,
    nombre text NOT NULL,
    nombre_completo text,
    seleccion_nombre text,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
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

CREATE TABLE IF NOT EXISTS partidos (
    partido_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    anio integer NOT NULL REFERENCES mundiales(anio),
    fecha text,
    etapa text,
    local_nombre text NOT NULL,
    visitante_nombre text NOT NULL,
    local_seleccion_id bigint REFERENCES selecciones(seleccion_id),
    visitante_seleccion_id bigint REFERENCES selecciones(seleccion_id),
    resultado text,
    tiempo_extra boolean,
    penales boolean,
    resultado_penales text
);

CREATE TABLE IF NOT EXISTS apariciones_partido (
    aparicion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partidos(slug),
    anio integer NOT NULL REFERENCES mundiales(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    jugador_slug text REFERENCES jugadores(slug),
    jugador_id bigint REFERENCES jugadores(jugador_id),
    jugador_nombre text NOT NULL,
    posicion text,
    camiseta text,
    seccion text NOT NULL CHECK (seccion IN ('titular', 'ingresado', 'suplente_no_jugo', 'entrenador')),
    es_capitan boolean NOT NULL DEFAULT false,
    UNIQUE (partido_slug, equipo_nombre, jugador_nombre, seccion)
);

CREATE TABLE IF NOT EXISTS goles (
    gol_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partidos(slug),
    anio integer NOT NULL REFERENCES mundiales(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugadores(slug),
    jugador_id bigint REFERENCES jugadores(jugador_id),
    minuto text,
    es_penal boolean NOT NULL DEFAULT false,
    es_autogol boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS tarjetas (
    tarjeta_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partidos(slug),
    anio integer NOT NULL REFERENCES mundiales(anio),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugadores(slug),
    jugador_id bigint REFERENCES jugadores(jugador_id),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    tipo text NOT NULL CHECK (tipo IN ('amarilla', 'roja')),
    minuto text
);

CREATE TABLE IF NOT EXISTS cambios (
    cambio_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partidos(slug),
    anio integer NOT NULL REFERENCES mundiales(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    sale text,
    sale_slug text REFERENCES jugadores(slug),
    sale_jugador_id bigint REFERENCES jugadores(jugador_id),
    entra text,
    entra_slug text REFERENCES jugadores(slug),
    entra_jugador_id bigint REFERENCES jugadores(jugador_id),
    minuto text
);

CREATE TABLE IF NOT EXISTS penales (
    penal_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_slug text NOT NULL REFERENCES partidos(slug),
    anio integer NOT NULL REFERENCES mundiales(anio),
    equipo_nombre text NOT NULL,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    orden integer NOT NULL,
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugadores(slug),
    jugador_id bigint REFERENCES jugadores(jugador_id),
    resultado text NOT NULL,
    UNIQUE (partido_slug, equipo_nombre, orden)
);

CREATE TABLE IF NOT EXISTS grupos (
    grupo_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundiales(anio),
    grupo text NOT NULL,
    posicion integer,
    seleccion_nombre text NOT NULL,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
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

CREATE TABLE IF NOT EXISTS posiciones_finales (
    posicion_final_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundiales(anio),
    posicion integer NOT NULL,
    seleccion_nombre text NOT NULL,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    UNIQUE (anio, posicion, seleccion_nombre)
);

CREATE TABLE IF NOT EXISTS goleadores (
    goleador_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundiales(anio),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugadores(slug),
    jugador_id bigint REFERENCES jugadores(jugador_id),
    seleccion_nombre text,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    goles integer,
    UNIQUE (anio, jugador, seleccion_nombre)
);

CREATE TABLE IF NOT EXISTS premios (
    premio_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundiales(anio),
    premio text NOT NULL,
    tipo_destinatario text NOT NULL CHECK (tipo_destinatario IN ('jugador', 'seleccion')),
    jugador text,
    jugador_slug text REFERENCES jugadores(slug),
    jugador_id bigint REFERENCES jugadores(jugador_id),
    seleccion_nombre text,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    destinatario_key text GENERATED ALWAYS AS (
        coalesce(nullif(jugador_slug, ''), nullif(jugador, ''), slugify_name(nullif(seleccion_nombre, '')), '')
    ) STORED,
    UNIQUE (anio, premio, tipo_destinatario, destinatario_key)
);

CREATE TABLE IF NOT EXISTS planteles (
    plantel_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundiales(anio),
    seleccion_nombre text,
    seleccion_slug text,
    seleccion_key text GENERATED ALWAYS AS (coalesce(nullif(seleccion_slug, ''), nullif(seleccion_nombre, ''), '')) STORED,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
    jugador text NOT NULL,
    jugador_slug text REFERENCES jugadores(slug),
    jugador_key text GENERATED ALWAYS AS (coalesce(nullif(jugador_slug, ''), nullif(jugador, ''), '')) STORED,
    jugador_id bigint REFERENCES jugadores(jugador_id),
    posicion text,
    camiseta text,
    fecha_nacimiento text,
    altura text,
    club text,
    rol text NOT NULL CHECK (rol IN ('jugador', 'entrenador')),
    UNIQUE (anio, jugador_key, seleccion_key, rol)
);

CREATE TABLE IF NOT EXISTS participaciones_mundial (
    participacion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio integer NOT NULL REFERENCES mundiales(anio),
    seleccion_nombre text NOT NULL,
    seleccion_slug text,
    seleccion_key text GENERATED ALWAYS AS (coalesce(nullif(seleccion_slug, ''), slugify_name(nullif(seleccion_nombre, '')), '')) STORED,
    seleccion_id bigint REFERENCES selecciones(seleccion_id),
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
    source_table text NOT NULL CHECK (source_table IN ('goles', 'tarjetas', 'cambios_entrada', 'cambios_salida', 'apariciones_partido', 'penales')),
    source_pk bigint,
    partido_slug text NOT NULL REFERENCES partidos(slug),
    anio integer NOT NULL REFERENCES mundiales(anio),
    equipo_nombre text,
    equipo_key text GENERATED ALWAYS AS (coalesce(equipo_nombre, '')) STORED,
    jugador_nombre_raw text NOT NULL,
    jugador_slug_raw text,
    minuto text,
    minuto_key text GENERATED ALWAYS AS (coalesce(minuto, '')) STORED,
    jugador_id_resuelto bigint REFERENCES jugadores(jugador_id),
    jugador_slug_resuelto text REFERENCES jugadores(slug),
    metodo text NOT NULL DEFAULT 'manual',
    confianza numeric(5,2),
    notas text,
    resolved_at timestamptz,
    UNIQUE (source_table, partido_slug, equipo_key, jugador_nombre_raw, minuto_key)
);

CREATE OR REPLACE VIEW v_jugadores_sin_slug AS
SELECT 'goles'::text AS source_table,
       g.gol_id::bigint AS source_pk,
       g.partido_slug,
       g.anio,
       g.equipo_nombre,
       g.jugador AS jugador_nombre,
       g.jugador_slug,
       g.minuto
FROM goles g
WHERE g.jugador_slug IS NULL OR btrim(g.jugador_slug) = ''
UNION ALL
SELECT 'tarjetas'::text,
       t.tarjeta_id::bigint,
       t.partido_slug,
       t.anio,
       t.equipo_nombre,
       t.jugador,
       t.jugador_slug,
       t.minuto
FROM tarjetas t
WHERE t.jugador_slug IS NULL OR btrim(t.jugador_slug) = ''
UNION ALL
SELECT 'cambios_entrada'::text,
       c.cambio_id::bigint,
       c.partido_slug,
       c.anio,
       c.equipo_nombre,
       c.entra,
       c.entra_slug,
       c.minuto
FROM cambios c
WHERE c.entra IS NOT NULL
  AND btrim(c.entra) <> ''
  AND (c.entra_slug IS NULL OR btrim(c.entra_slug) = '')
UNION ALL
SELECT 'cambios_salida'::text,
       c.cambio_id::bigint,
       c.partido_slug,
       c.anio,
       c.equipo_nombre,
       c.sale,
       c.sale_slug,
       c.minuto
FROM cambios c
WHERE c.sale IS NOT NULL
  AND btrim(c.sale) <> ''
  AND (c.sale_slug IS NULL OR btrim(c.sale_slug) = '')
UNION ALL
SELECT 'apariciones_partido'::text,
       a.aparicion_id::bigint,
       a.partido_slug,
       a.anio,
       a.equipo_nombre,
       a.jugador_nombre,
       a.jugador_slug,
       NULL::text AS minuto
FROM apariciones_partido a
WHERE a.seccion <> 'entrenador'
  AND (a.jugador_slug IS NULL OR btrim(a.jugador_slug) = '')
UNION ALL
SELECT 'penales'::text,
       p.penal_id::bigint,
       p.partido_slug,
       p.anio,
       p.equipo_nombre,
       p.jugador,
       p.jugador_slug,
       NULL::text AS minuto
FROM penales p
WHERE p.jugador_slug IS NULL OR btrim(p.jugador_slug) = '';

CREATE INDEX IF NOT EXISTS idx_partidos_anio ON partidos(anio);
CREATE INDEX IF NOT EXISTS idx_partidos_local_sel ON partidos(local_seleccion_id);
CREATE INDEX IF NOT EXISTS idx_partidos_visitante_sel ON partidos(visitante_seleccion_id);

CREATE INDEX IF NOT EXISTS idx_apariciones_partido_slug ON apariciones_partido(partido_slug);
CREATE INDEX IF NOT EXISTS idx_apariciones_jugador_slug ON apariciones_partido(jugador_slug);
CREATE INDEX IF NOT EXISTS idx_apariciones_jugador_id ON apariciones_partido(jugador_id);

CREATE INDEX IF NOT EXISTS idx_goles_partido_slug ON goles(partido_slug);
CREATE INDEX IF NOT EXISTS idx_goles_jugador_slug ON goles(jugador_slug);
CREATE INDEX IF NOT EXISTS idx_goles_jugador_id ON goles(jugador_id);

CREATE INDEX IF NOT EXISTS idx_tarjetas_partido_slug ON tarjetas(partido_slug);
CREATE INDEX IF NOT EXISTS idx_tarjetas_jugador_slug ON tarjetas(jugador_slug);
CREATE INDEX IF NOT EXISTS idx_tarjetas_jugador_id ON tarjetas(jugador_id);

CREATE INDEX IF NOT EXISTS idx_cambios_partido_slug ON cambios(partido_slug);
CREATE INDEX IF NOT EXISTS idx_cambios_entra_slug ON cambios(entra_slug);
CREATE INDEX IF NOT EXISTS idx_cambios_sale_slug ON cambios(sale_slug);

CREATE INDEX IF NOT EXISTS idx_penales_partido_slug ON penales(partido_slug);
CREATE INDEX IF NOT EXISTS idx_penales_jugador_slug ON penales(jugador_slug);

CREATE INDEX IF NOT EXISTS idx_grupos_anio_grupo ON grupos(anio, grupo);
CREATE INDEX IF NOT EXISTS idx_posiciones_finales_anio ON posiciones_finales(anio);
CREATE INDEX IF NOT EXISTS idx_goleadores_anio ON goleadores(anio);
CREATE INDEX IF NOT EXISTS idx_premios_anio ON premios(anio);
CREATE INDEX IF NOT EXISTS idx_planteles_anio ON planteles(anio);
CREATE INDEX IF NOT EXISTS idx_participaciones_anio ON participaciones_mundial(anio);

COMMIT;
