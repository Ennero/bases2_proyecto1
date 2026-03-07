-- PostgreSQL ETL for CSV outputs from scraping_normalizado.py
-- Run with psql after executing postgres_schema.sql

\set ON_ERROR_STOP on

-- Update these file paths before running.
\set f_mundiales 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/mundial.csv'
\set f_selecciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/seleccion.csv'
\set f_jugadores 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/jugador.csv'
\set f_partidos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/partido.csv'
\set f_apariciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/aparicion_partido.csv'
\set f_goles 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/gol.csv'
\set f_tarjetas 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/tarjeta.csv'
\set f_cambios 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/cambio.csv'
\set f_penales 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/penal.csv'
\set f_grupos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/grupo.csv'
\set f_posiciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/posicion_final.csv'
\set f_goleadores 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/goleador.csv'
\set f_premios 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/premio.csv'
\set f_planteles 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/plantel.csv'
\set f_participaciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/participacion_mundial.csv'

BEGIN;

CREATE TEMP TABLE stg_mundiales (
    anio integer,
    sede text,
    campeon text,
    subcampeon text,
    tercer_lugar text,
    cuarto_lugar text,
    equipos text,
    partidos_jugados text,
    goles_total text,
    promedio_gol text
);

CREATE TEMP TABLE stg_selecciones (
    slug text,
    nombre text,
    participaciones text,
    pj text,
    pg text,
    pe text,
    pp text,
    gf text,
    gc text,
    titulos text,
    subcampeonatos text,
    posicion_historica text
);

CREATE TEMP TABLE stg_jugadores (
    slug text,
    nombre text,
    nombre_completo text,
    seleccion text,
    fecha_nacimiento text,
    lugar_nacimiento text,
    posicion text,
    numeros_camiseta text,
    altura text,
    apodo text,
    sitio_web text,
    redes_sociales text,
    mundiales text,
    partidos text,
    goles text,
    promedio_gol text
);

CREATE TEMP TABLE stg_partidos (
    anio integer,
    fecha text,
    etapa text,
    local text,
    visitante text,
    resultado text,
    slug text,
    tiempo_extra text,
    penales text,
    resultado_penales text
);

CREATE TEMP TABLE stg_apariciones (
    partido_slug text,
    anio integer,
    equipo text,
    jugador_slug text,
    jugador_nombre text,
    posicion text,
    camiseta text,
    seccion text,
    es_capitan text
);

CREATE TEMP TABLE stg_goles (
    partido_slug text,
    anio integer,
    equipo text,
    jugador text,
    jugador_slug text,
    minuto text,
    es_penal text,
    es_autogol text
);

CREATE TEMP TABLE stg_tarjetas (
    partido_slug text,
    anio integer,
    jugador text,
    jugador_slug text,
    equipo text,
    tipo text,
    minuto text
);

CREATE TEMP TABLE stg_cambios (
    partido_slug text,
    anio integer,
    equipo text,
    sale text,
    sale_slug text,
    entra text,
    entra_slug text,
    minuto text
);

CREATE TEMP TABLE stg_penales (
    partido_slug text,
    anio integer,
    equipo text,
    orden text,
    jugador text,
    jugador_slug text,
    resultado text
);

CREATE TEMP TABLE stg_grupos (
    anio integer,
    grupo text,
    posicion text,
    seleccion text,
    pts text,
    pj text,
    pg text,
    pe text,
    pp text,
    gf text,
    gc text,
    dif text,
    clasificado text
);

CREATE TEMP TABLE stg_posiciones (
    anio integer,
    posicion text,
    seleccion text
);

CREATE TEMP TABLE stg_goleadores (
    anio integer,
    jugador text,
    jugador_slug text,
    seleccion text,
    goles text
);

CREATE TEMP TABLE stg_premios (
    anio integer,
    premio text,
    tipo_destinatario text,
    jugador text,
    jugador_slug text,
    seleccion text
);

CREATE TEMP TABLE stg_planteles (
    anio integer,
    seleccion text,
    seleccion_slug text,
    jugador text,
    jugador_slug text,
    posicion text,
    camiseta text,
    fecha_nacimiento text,
    altura text,
    club text,
    rol text
);

CREATE TEMP TABLE stg_participaciones (
    anio integer,
    seleccion text,
    seleccion_slug text,
    posicion text,
    etapa text,
    pts text,
    pj text,
    pg text,
    pe text,
    pp text,
    gf text,
    gc text,
    dif text,
    participo text
);

\copy stg_mundiales FROM :'f_mundiales' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_selecciones FROM :'f_selecciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_jugadores FROM :'f_jugadores' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_partidos FROM :'f_partidos' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_apariciones FROM :'f_apariciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_goles FROM :'f_goles' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_tarjetas FROM :'f_tarjetas' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_cambios FROM :'f_cambios' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_penales FROM :'f_penales' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_grupos FROM :'f_grupos' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_posiciones FROM :'f_posiciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_goleadores FROM :'f_goleadores' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_premios FROM :'f_premios' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_planteles FROM :'f_planteles' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_participaciones FROM :'f_participaciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

INSERT INTO mundial (
    anio,
    sede,
    campeon,
    subcampeon,
    tercer_lugar,
    cuarto_lugar,
    equipos,
    partidos_jugados,
    goles_total,
    promedio_gol
)
SELECT
    sm.anio,
    NULLIF(sm.sede, ''),
    NULLIF(sm.campeon, ''),
    NULLIF(sm.subcampeon, ''),
    NULLIF(sm.tercer_lugar, ''),
    NULLIF(sm.cuarto_lugar, ''),
    NULLIF(sm.equipos, '')::integer,
    NULLIF(sm.partidos_jugados, '')::integer,
    NULLIF(sm.goles_total, '')::integer,
    NULLIF(sm.promedio_gol, '')::numeric(6,2)
FROM stg_mundiales sm
ON CONFLICT (anio) DO UPDATE
SET sede = EXCLUDED.sede,
    campeon = EXCLUDED.campeon,
    subcampeon = EXCLUDED.subcampeon,
    tercer_lugar = EXCLUDED.tercer_lugar,
    cuarto_lugar = EXCLUDED.cuarto_lugar,
    equipos = EXCLUDED.equipos,
    partidos_jugados = EXCLUDED.partidos_jugados,
    goles_total = EXCLUDED.goles_total,
    promedio_gol = EXCLUDED.promedio_gol;

INSERT INTO mundial (anio)
SELECT DISTINCT anio FROM stg_partidos
UNION
SELECT DISTINCT anio FROM stg_grupos
UNION
SELECT DISTINCT anio FROM stg_posiciones
UNION
SELECT DISTINCT anio FROM stg_goleadores
UNION
SELECT DISTINCT anio FROM stg_premios
UNION
SELECT DISTINCT anio FROM stg_planteles
UNION
SELECT DISTINCT anio FROM stg_participaciones
ON CONFLICT (anio) DO NOTHING;

INSERT INTO seleccion (
    slug,
    nombre,
    participaciones,
    pj,
    pg,
    pe,
    pp,
    gf,
    gc,
    titulos,
    subcampeonatos,
    posicion_historica
)
SELECT
    ss.slug,
    ss.nombre,
    NULLIF(ss.participaciones, '')::integer,
    NULLIF(ss.pj, '')::integer,
    NULLIF(ss.pg, '')::integer,
    NULLIF(ss.pe, '')::integer,
    NULLIF(ss.pp, '')::integer,
    NULLIF(ss.gf, '')::integer,
    NULLIF(ss.gc, '')::integer,
    NULLIF(ss.titulos, '')::integer,
    NULLIF(ss.subcampeonatos, '')::integer,
    NULLIF(ss.posicion_historica, '')
FROM stg_selecciones ss
ON CONFLICT (slug) DO UPDATE
SET nombre = EXCLUDED.nombre,
    participaciones = EXCLUDED.participaciones,
    pj = EXCLUDED.pj,
    pg = EXCLUDED.pg,
    pe = EXCLUDED.pe,
    pp = EXCLUDED.pp,
    gf = EXCLUDED.gf,
    gc = EXCLUDED.gc,
    titulos = EXCLUDED.titulos,
    subcampeonatos = EXCLUDED.subcampeonatos,
    posicion_historica = EXCLUDED.posicion_historica;

INSERT INTO seleccion (slug, nombre)
SELECT DISTINCT slugify_name(x.nombre) AS slug, x.nombre
FROM (
    SELECT local AS nombre FROM stg_partidos
    UNION SELECT visitante FROM stg_partidos
    UNION SELECT equipo FROM stg_apariciones
    UNION SELECT equipo FROM stg_goles
    UNION SELECT equipo FROM stg_tarjetas
    UNION SELECT equipo FROM stg_cambios
    UNION SELECT equipo FROM stg_penales
    UNION SELECT seleccion FROM stg_grupos
    UNION SELECT seleccion FROM stg_posiciones
    UNION SELECT seleccion FROM stg_goleadores
    UNION SELECT seleccion FROM stg_premios
    UNION SELECT seleccion FROM stg_planteles
    UNION SELECT seleccion FROM stg_participaciones
) x
WHERE x.nombre IS NOT NULL
  AND btrim(x.nombre) <> ''
  AND slugify_name(x.nombre) IS NOT NULL
ON CONFLICT (slug) DO NOTHING;

WITH alias_map(alias_nombre, destino_slug, notas) AS (
    VALUES
        ('URSS', 'rusia', 'Cambio historico de nombre o estado'),
        ('Alemania Occidental', 'alemania', 'Alemania unificada'),
        ('Alemania Oriental', 'alemania', 'Alemania unificada'),
        ('Checoslovaquia', 'republica_checa', 'Division historica'),
        ('RF de Yugoslavia', 'serbia', 'Continuidad deportiva parcial'),
        ('Serbia y Montenegro', 'serbia', 'Separacion de estados')
)
INSERT INTO seleccion_alias (alias_slug, alias_nombre, seleccion_id, notas)
SELECT slugify_name(am.alias_nombre), am.alias_nombre, s.seleccion_id, am.notas
FROM alias_map am
JOIN seleccion s ON s.slug = am.destino_slug
ON CONFLICT (alias_slug) DO UPDATE
SET seleccion_id = EXCLUDED.seleccion_id,
    notas = EXCLUDED.notas;

INSERT INTO jugador (
    slug,
    nombre,
    nombre_completo,
    seleccion_nombre,
    seleccion_id,
    fecha_nacimiento,
    lugar_nacimiento,
    posicion,
    numeros_camiseta,
    altura,
    apodo,
    sitio_web,
    redes_sociales,
    mundiales,
    partidos,
    goles,
    promedio_gol
)
SELECT
    NULLIF(sj.slug, ''),
    sj.nombre,
    NULLIF(sj.nombre_completo, ''),
    NULLIF(sj.seleccion, ''),
    COALESCE(s.seleccion_id, sa.seleccion_id),
    NULLIF(sj.fecha_nacimiento, ''),
    NULLIF(sj.lugar_nacimiento, ''),
    NULLIF(sj.posicion, ''),
    NULLIF(sj.numeros_camiseta, ''),
    NULLIF(sj.altura, ''),
    NULLIF(sj.apodo, ''),
    NULLIF(sj.sitio_web, ''),
    NULLIF(sj.redes_sociales, ''),
    NULLIF(sj.mundiales, '')::integer,
    NULLIF(sj.partidos, '')::integer,
    NULLIF(sj.goles, '')::integer,
    NULLIF(sj.promedio_gol, '')::numeric(6,2)
FROM stg_jugadores sj
LEFT JOIN seleccion s ON s.slug = slugify_name(sj.seleccion)
LEFT JOIN seleccion_alias sa ON sa.alias_slug = slugify_name(sj.seleccion)
WHERE sj.nombre IS NOT NULL
  AND btrim(sj.nombre) <> ''
ON CONFLICT (slug) DO UPDATE
SET nombre = EXCLUDED.nombre,
    nombre_completo = COALESCE(EXCLUDED.nombre_completo, jugador.nombre_completo),
    seleccion_nombre = COALESCE(EXCLUDED.seleccion_nombre, jugador.seleccion_nombre),
    seleccion_id = COALESCE(EXCLUDED.seleccion_id, jugador.seleccion_id),
    fecha_nacimiento = COALESCE(EXCLUDED.fecha_nacimiento, jugador.fecha_nacimiento),
    lugar_nacimiento = COALESCE(EXCLUDED.lugar_nacimiento, jugador.lugar_nacimiento),
    posicion = COALESCE(EXCLUDED.posicion, jugador.posicion),
    numeros_camiseta = COALESCE(EXCLUDED.numeros_camiseta, jugador.numeros_camiseta),
    altura = COALESCE(EXCLUDED.altura, jugador.altura),
    apodo = COALESCE(EXCLUDED.apodo, jugador.apodo),
    sitio_web = COALESCE(EXCLUDED.sitio_web, jugador.sitio_web),
    redes_sociales = COALESCE(EXCLUDED.redes_sociales, jugador.redes_sociales),
    mundiales = COALESCE(EXCLUDED.mundiales, jugador.mundiales),
    partidos = COALESCE(EXCLUDED.partidos, jugador.partidos),
    goles = COALESCE(EXCLUDED.goles, jugador.goles),
    promedio_gol = COALESCE(EXCLUDED.promedio_gol, jugador.promedio_gol);

INSERT INTO jugador (slug, nombre, seleccion_nombre, seleccion_id)
SELECT DISTINCT
    z.jugador_slug,
    z.jugador_nombre,
    z.seleccion_nombre,
    COALESCE(s.seleccion_id, sa.seleccion_id)
FROM (
    SELECT NULLIF(jugador_slug, '') AS jugador_slug, jugador_nombre, equipo AS seleccion_nombre FROM stg_apariciones
    UNION ALL
    SELECT NULLIF(jugador_slug, ''), jugador, equipo FROM stg_goles
    UNION ALL
    SELECT NULLIF(jugador_slug, ''), jugador, equipo FROM stg_tarjetas
    UNION ALL
    SELECT NULLIF(entra_slug, ''), entra, equipo FROM stg_cambios
    UNION ALL
    SELECT NULLIF(sale_slug, ''), sale, equipo FROM stg_cambios
    UNION ALL
    SELECT NULLIF(jugador_slug, ''), jugador, equipo FROM stg_penales
    UNION ALL
    SELECT NULLIF(jugador_slug, ''), jugador, seleccion FROM stg_planteles
    UNION ALL
    SELECT NULLIF(jugador_slug, ''), jugador, seleccion FROM stg_goleadores
    UNION ALL
    SELECT NULLIF(jugador_slug, ''), jugador, seleccion FROM stg_premios
) z
LEFT JOIN seleccion s ON s.slug = slugify_name(z.seleccion_nombre)
LEFT JOIN seleccion_alias sa ON sa.alias_slug = slugify_name(z.seleccion_nombre)
WHERE z.jugador_slug IS NOT NULL
  AND z.jugador_nombre IS NOT NULL
  AND btrim(z.jugador_nombre) <> ''
ON CONFLICT (slug) DO UPDATE
SET nombre = COALESCE(EXCLUDED.nombre, jugador.nombre),
    seleccion_nombre = COALESCE(EXCLUDED.seleccion_nombre, jugador.seleccion_nombre),
    seleccion_id = COALESCE(EXCLUDED.seleccion_id, jugador.seleccion_id);

INSERT INTO partido (
    slug,
    anio,
    fecha,
    etapa,
    local_nombre,
    visitante_nombre,
    local_seleccion_id,
    visitante_seleccion_id,
    resultado,
    tiempo_extra,
    penales,
    resultado_penales
)
SELECT
    sp.slug,
    sp.anio,
    NULLIF(sp.fecha, ''),
    NULLIF(sp.etapa, ''),
    sp.local,
    sp.visitante,
    COALESCE(sl.seleccion_id, sal.seleccion_id),
    COALESCE(sv.seleccion_id, sav.seleccion_id),
    NULLIF(sp.resultado, ''),
    NULLIF(sp.tiempo_extra, '')::boolean,
    NULLIF(sp.penales, '')::boolean,
    NULLIF(sp.resultado_penales, '')
FROM stg_partidos sp
LEFT JOIN seleccion sl ON sl.slug = slugify_name(sp.local)
LEFT JOIN seleccion sv ON sv.slug = slugify_name(sp.visitante)
LEFT JOIN seleccion_alias sal ON sal.alias_slug = slugify_name(sp.local)
LEFT JOIN seleccion_alias sav ON sav.alias_slug = slugify_name(sp.visitante)
WHERE sp.slug IS NOT NULL
  AND btrim(sp.slug) <> ''
ON CONFLICT (slug) DO UPDATE
SET anio = EXCLUDED.anio,
    fecha = EXCLUDED.fecha,
    etapa = EXCLUDED.etapa,
    local_nombre = EXCLUDED.local_nombre,
    visitante_nombre = EXCLUDED.visitante_nombre,
    local_seleccion_id = COALESCE(EXCLUDED.local_seleccion_id, partido.local_seleccion_id),
    visitante_seleccion_id = COALESCE(EXCLUDED.visitante_seleccion_id, partido.visitante_seleccion_id),
    resultado = EXCLUDED.resultado,
    tiempo_extra = EXCLUDED.tiempo_extra,
    penales = EXCLUDED.penales,
    resultado_penales = EXCLUDED.resultado_penales;

INSERT INTO aparicion_partido (
    partido_slug,
    anio,
    equipo_nombre,
    seleccion_id,
    jugador_slug,
    jugador_id,
    jugador_nombre,
    posicion,
    camiseta,
    seccion,
    es_capitan
)
SELECT
    sa.partido_slug,
    sa.anio,
    sa.equipo,
    COALESCE(s.seleccion_id, sx.seleccion_id),
    NULLIF(sa.jugador_slug, ''),
    j.jugador_id,
    sa.jugador_nombre,
    NULLIF(sa.posicion, ''),
    NULLIF(sa.camiseta, ''),
    sa.seccion,
    COALESCE(NULLIF(sa.es_capitan, '')::boolean, false)
FROM stg_apariciones sa
LEFT JOIN seleccion s ON s.slug = slugify_name(sa.equipo)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sa.equipo)
LEFT JOIN jugador j ON j.slug = NULLIF(sa.jugador_slug, '')
WHERE sa.partido_slug IS NOT NULL
  AND btrim(sa.partido_slug) <> ''
  AND sa.jugador_nombre IS NOT NULL
  AND btrim(sa.jugador_nombre) <> ''
ON CONFLICT (partido_slug, equipo_nombre, jugador_nombre, seccion) DO UPDATE
SET seleccion_id = COALESCE(EXCLUDED.seleccion_id, aparicion_partido.seleccion_id),
    jugador_slug = COALESCE(EXCLUDED.jugador_slug, aparicion_partido.jugador_slug),
    jugador_id = COALESCE(EXCLUDED.jugador_id, aparicion_partido.jugador_id),
    posicion = COALESCE(EXCLUDED.posicion, aparicion_partido.posicion),
    camiseta = COALESCE(EXCLUDED.camiseta, aparicion_partido.camiseta),
    es_capitan = EXCLUDED.es_capitan;

INSERT INTO gol (
    partido_slug,
    anio,
    equipo_nombre,
    seleccion_id,
    jugador,
    jugador_slug,
    jugador_id,
    minuto,
    es_penal,
    es_autogol
)
SELECT
    sg.partido_slug,
    sg.anio,
    sg.equipo,
    COALESCE(s.seleccion_id, sx.seleccion_id),
    sg.jugador,
    NULLIF(sg.jugador_slug, ''),
    j.jugador_id,
    NULLIF(sg.minuto, ''),
    COALESCE(NULLIF(sg.es_penal, '')::boolean, false),
    COALESCE(NULLIF(sg.es_autogol, '')::boolean, false)
FROM stg_goles sg
LEFT JOIN seleccion s ON s.slug = slugify_name(sg.equipo)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sg.equipo)
LEFT JOIN jugador j ON j.slug = NULLIF(sg.jugador_slug, '')
WHERE sg.partido_slug IS NOT NULL
  AND btrim(sg.partido_slug) <> ''
  AND sg.jugador IS NOT NULL
  AND btrim(sg.jugador) <> '';

INSERT INTO tarjeta (
    partido_slug,
    anio,
    jugador,
    jugador_slug,
    jugador_id,
    equipo_nombre,
    seleccion_id,
    tipo,
    minuto
)
SELECT
    st.partido_slug,
    st.anio,
    st.jugador,
    NULLIF(st.jugador_slug, ''),
    j.jugador_id,
    st.equipo,
    COALESCE(s.seleccion_id, sx.seleccion_id),
    st.tipo,
    NULLIF(st.minuto, '')
FROM stg_tarjetas st
LEFT JOIN seleccion s ON s.slug = slugify_name(st.equipo)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(st.equipo)
LEFT JOIN jugador j ON j.slug = NULLIF(st.jugador_slug, '')
WHERE st.partido_slug IS NOT NULL
  AND btrim(st.partido_slug) <> ''
  AND st.jugador IS NOT NULL
  AND btrim(st.jugador) <> '';

INSERT INTO cambio (
    partido_slug,
    anio,
    equipo_nombre,
    seleccion_id,
    sale,
    sale_slug,
    sale_jugador_id,
    entra,
    entra_slug,
    entra_jugador_id,
    minuto
)
SELECT
    sc.partido_slug,
    sc.anio,
    sc.equipo,
    COALESCE(s.seleccion_id, sx.seleccion_id),
    NULLIF(sc.sale, ''),
    NULLIF(sc.sale_slug, ''),
    js.jugador_id,
    NULLIF(sc.entra, ''),
    NULLIF(sc.entra_slug, ''),
    je.jugador_id,
    NULLIF(sc.minuto, '')
FROM stg_cambios sc
LEFT JOIN seleccion s ON s.slug = slugify_name(sc.equipo)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sc.equipo)
LEFT JOIN jugador js ON js.slug = NULLIF(sc.sale_slug, '')
LEFT JOIN jugador je ON je.slug = NULLIF(sc.entra_slug, '')
WHERE sc.partido_slug IS NOT NULL
  AND btrim(sc.partido_slug) <> '';

INSERT INTO penal (
    partido_slug,
    anio,
    equipo_nombre,
    seleccion_id,
    orden,
    jugador,
    jugador_slug,
    jugador_id,
    resultado
)
SELECT
    sp.partido_slug,
    sp.anio,
    sp.equipo,
    COALESCE(s.seleccion_id, sx.seleccion_id),
    NULLIF(sp.orden, '')::integer,
    sp.jugador,
    NULLIF(sp.jugador_slug, ''),
    j.jugador_id,
    sp.resultado
FROM stg_penales sp
LEFT JOIN seleccion s ON s.slug = slugify_name(sp.equipo)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sp.equipo)
LEFT JOIN jugador j ON j.slug = NULLIF(sp.jugador_slug, '')
WHERE sp.partido_slug IS NOT NULL
  AND btrim(sp.partido_slug) <> ''
  AND sp.jugador IS NOT NULL
  AND btrim(sp.jugador) <> ''
ON CONFLICT (partido_slug, equipo_nombre, orden) DO UPDATE
SET seleccion_id = COALESCE(EXCLUDED.seleccion_id, penal.seleccion_id),
    jugador = EXCLUDED.jugador,
    jugador_slug = COALESCE(EXCLUDED.jugador_slug, penal.jugador_slug),
    jugador_id = COALESCE(EXCLUDED.jugador_id, penal.jugador_id),
    resultado = EXCLUDED.resultado;

INSERT INTO grupo (
    anio,
    grupo,
    posicion,
    seleccion_nombre,
    seleccion_id,
    pts,
    pj,
    pg,
    pe,
    pp,
    gf,
    gc,
    dif,
    clasificado
)
SELECT
    sg.anio,
    sg.grupo,
    NULLIF(sg.posicion, '')::integer,
    sg.seleccion,
    COALESCE(s.seleccion_id, sx.seleccion_id),
    NULLIF(sg.pts, '')::integer,
    NULLIF(sg.pj, '')::integer,
    NULLIF(sg.pg, '')::integer,
    NULLIF(sg.pe, '')::integer,
    NULLIF(sg.pp, '')::integer,
    NULLIF(sg.gf, '')::integer,
    NULLIF(sg.gc, '')::integer,
    NULLIF(sg.dif, '')::integer,
    COALESCE(NULLIF(sg.clasificado, '')::boolean, false)
FROM stg_grupos sg
LEFT JOIN seleccion s ON s.slug = slugify_name(sg.seleccion)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sg.seleccion)
WHERE sg.seleccion IS NOT NULL
  AND btrim(sg.seleccion) <> ''
ON CONFLICT (anio, grupo, seleccion_nombre) DO UPDATE
SET posicion = EXCLUDED.posicion,
    seleccion_id = COALESCE(EXCLUDED.seleccion_id, grupo.seleccion_id),
    pts = EXCLUDED.pts,
    pj = EXCLUDED.pj,
    pg = EXCLUDED.pg,
    pe = EXCLUDED.pe,
    pp = EXCLUDED.pp,
    gf = EXCLUDED.gf,
    gc = EXCLUDED.gc,
    dif = EXCLUDED.dif,
    clasificado = EXCLUDED.clasificado;

INSERT INTO posicion_final (
    anio,
    posicion,
    seleccion_nombre,
    seleccion_id
)
SELECT
    sp.anio,
    NULLIF(sp.posicion, '')::integer,
    sp.seleccion,
    COALESCE(s.seleccion_id, sx.seleccion_id)
FROM stg_posiciones sp
LEFT JOIN seleccion s ON s.slug = slugify_name(sp.seleccion)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sp.seleccion)
WHERE sp.seleccion IS NOT NULL
  AND btrim(sp.seleccion) <> ''
ON CONFLICT (anio, posicion, seleccion_nombre) DO UPDATE
SET seleccion_id = COALESCE(EXCLUDED.seleccion_id, posicion_final.seleccion_id);

INSERT INTO goleador (
    anio,
    jugador,
    jugador_slug,
    jugador_id,
    seleccion_nombre,
    seleccion_id,
    goles
)
SELECT
    sg.anio,
    sg.jugador,
    NULLIF(sg.jugador_slug, ''),
    j.jugador_id,
    NULLIF(sg.seleccion, ''),
    COALESCE(s.seleccion_id, sx.seleccion_id),
    NULLIF(sg.goles, '')::integer
FROM stg_goleadores sg
LEFT JOIN jugador j ON j.slug = NULLIF(sg.jugador_slug, '')
LEFT JOIN seleccion s ON s.slug = slugify_name(sg.seleccion)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sg.seleccion)
WHERE sg.jugador IS NOT NULL
  AND btrim(sg.jugador) <> ''
ON CONFLICT (anio, jugador, seleccion_nombre) DO UPDATE
SET jugador_slug = COALESCE(EXCLUDED.jugador_slug, goleador.jugador_slug),
    jugador_id = COALESCE(EXCLUDED.jugador_id, goleador.jugador_id),
    seleccion_id = COALESCE(EXCLUDED.seleccion_id, goleador.seleccion_id),
    goles = EXCLUDED.goles;

INSERT INTO premio (
    anio,
    premio,
    tipo_destinatario,
    jugador,
    jugador_slug,
    jugador_id,
    seleccion_nombre,
    seleccion_id
)
SELECT
    sp.anio,
    sp.premio,
    sp.tipo_destinatario,
    NULLIF(sp.jugador, ''),
    NULLIF(sp.jugador_slug, ''),
    j.jugador_id,
    NULLIF(sp.seleccion, ''),
    COALESCE(s.seleccion_id, sx.seleccion_id)
FROM stg_premios sp
LEFT JOIN jugador j ON j.slug = NULLIF(sp.jugador_slug, '')
LEFT JOIN seleccion s ON s.slug = slugify_name(sp.seleccion)
LEFT JOIN seleccion_alias sx ON sx.alias_slug = slugify_name(sp.seleccion)
WHERE sp.premio IS NOT NULL
  AND btrim(sp.premio) <> ''
ON CONFLICT (anio, premio, tipo_destinatario, destinatario_key) DO UPDATE
SET jugador = COALESCE(EXCLUDED.jugador, premio.jugador),
    jugador_slug = COALESCE(EXCLUDED.jugador_slug, premio.jugador_slug),
    jugador_id = COALESCE(EXCLUDED.jugador_id, premio.jugador_id),
    seleccion_nombre = COALESCE(EXCLUDED.seleccion_nombre, premio.seleccion_nombre),
    seleccion_id = COALESCE(EXCLUDED.seleccion_id, premio.seleccion_id);

INSERT INTO plantel (
    anio,
    seleccion_nombre,
    seleccion_slug,
    seleccion_id,
    jugador,
    jugador_slug,
    jugador_id,
    posicion,
    camiseta,
    fecha_nacimiento,
    altura,
    club,
    rol
)
SELECT
    sp.anio,
    NULLIF(sp.seleccion, ''),
    NULLIF(sp.seleccion_slug, ''),
    COALESCE(s.seleccion_id, sx.seleccion_id),
    sp.jugador,
    NULLIF(sp.jugador_slug, ''),
    j.jugador_id,
    NULLIF(sp.posicion, ''),
    NULLIF(sp.camiseta, ''),
    NULLIF(sp.fecha_nacimiento, ''),
    NULLIF(sp.altura, ''),
    NULLIF(sp.club, ''),
    sp.rol
FROM stg_planteles sp
LEFT JOIN seleccion s ON s.slug = COALESCE(NULLIF(sp.seleccion_slug, ''), slugify_name(sp.seleccion))
LEFT JOIN seleccion_alias sx ON sx.alias_slug = COALESCE(NULLIF(sp.seleccion_slug, ''), slugify_name(sp.seleccion))
LEFT JOIN jugador j ON j.slug = NULLIF(sp.jugador_slug, '')
WHERE sp.jugador IS NOT NULL
  AND btrim(sp.jugador) <> ''
ON CONFLICT (anio, jugador_key, seleccion_key, rol) DO UPDATE
SET seleccion_id = COALESCE(EXCLUDED.seleccion_id, plantel.seleccion_id),
    jugador_id = COALESCE(EXCLUDED.jugador_id, plantel.jugador_id),
    posicion = COALESCE(EXCLUDED.posicion, plantel.posicion),
    camiseta = COALESCE(EXCLUDED.camiseta, plantel.camiseta),
    fecha_nacimiento = COALESCE(EXCLUDED.fecha_nacimiento, plantel.fecha_nacimiento),
    altura = COALESCE(EXCLUDED.altura, plantel.altura),
    club = COALESCE(EXCLUDED.club, plantel.club);

INSERT INTO participacion_mundial (
    anio,
    seleccion_nombre,
    seleccion_slug,
    seleccion_id,
    posicion,
    etapa,
    pts,
    pj,
    pg,
    pe,
    pp,
    gf,
    gc,
    dif,
    participo
)
SELECT
    sp.anio,
    sp.seleccion,
    NULLIF(sp.seleccion_slug, ''),
    COALESCE(s.seleccion_id, sx.seleccion_id),
    NULLIF(sp.posicion, '')::integer,
    NULLIF(sp.etapa, ''),
    NULLIF(sp.pts, '')::integer,
    NULLIF(sp.pj, '')::integer,
    NULLIF(sp.pg, '')::integer,
    NULLIF(sp.pe, '')::integer,
    NULLIF(sp.pp, '')::integer,
    NULLIF(sp.gf, '')::integer,
    NULLIF(sp.gc, '')::integer,
    NULLIF(sp.dif, '')::integer,
    COALESCE(NULLIF(sp.participo, '')::boolean, true)
FROM stg_participaciones sp
LEFT JOIN seleccion s ON s.slug = COALESCE(NULLIF(sp.seleccion_slug, ''), slugify_name(sp.seleccion))
LEFT JOIN seleccion_alias sx ON sx.alias_slug = COALESCE(NULLIF(sp.seleccion_slug, ''), slugify_name(sp.seleccion))
WHERE sp.seleccion IS NOT NULL
  AND btrim(sp.seleccion) <> ''
ON CONFLICT (anio, seleccion_key) DO UPDATE
SET seleccion_id = COALESCE(EXCLUDED.seleccion_id, participacion_mundial.seleccion_id),
    posicion = EXCLUDED.posicion,
    etapa = EXCLUDED.etapa,
    pts = EXCLUDED.pts,
    pj = EXCLUDED.pj,
    pg = EXCLUDED.pg,
    pe = EXCLUDED.pe,
    pp = EXCLUDED.pp,
    gf = EXCLUDED.gf,
    gc = EXCLUDED.gc,
    dif = EXCLUDED.dif,
    participo = EXCLUDED.participo;

INSERT INTO resolucion_identidad_jugador (
    source_table,
    source_pk,
    partido_slug,
    anio,
    equipo_nombre,
    jugador_nombre_raw,
    jugador_slug_raw,
    minuto
)
SELECT
    v.source_table,
    v.source_pk,
    v.partido_slug,
    v.anio,
    v.equipo_nombre,
    v.jugador_nombre,
    v.jugador_slug,
    v.minuto
FROM v_jugador_sin_slug v
ON CONFLICT (source_table, partido_slug, equipo_key, jugador_nombre_raw, minuto_key) DO NOTHING;

COMMIT;
