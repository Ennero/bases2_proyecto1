-- PostgreSQL ETL for the fully normalized CSV outputs
-- Run with psql after executing postgres_schema.sql

\set ON_ERROR_STOP on

-- Update these file paths before running.
\set f_mundiales 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/mundial.csv'
\set f_selecciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/seleccion.csv'
\set f_aliases 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/seleccion_alias.csv'
\set f_jugadores 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/jugador.csv'
\set f_entrenadores 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/entrenador.csv'
\set f_partidos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/partido.csv'
\set f_apariciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/aparicion_partido.csv'
\set f_tecnicos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/direccion_tecnica_partido.csv'
\set f_goles 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/gol.csv'
\set f_tarjetas 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/tarjeta.csv'
\set f_cambios 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/cambio.csv'
\set f_penales 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/penal.csv'
\set f_grupos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/grupo.csv'
\set f_posiciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/posicion_final.csv'
\set f_goleadores 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/goleador.csv'
\set f_premios_jugador 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/premio_jugador.csv'
\set f_premios_seleccion 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/premio_seleccion.csv'
\set f_plantel_jugador 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/plantel_jugador.csv'
\set f_plantel_entrenador 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/plantel_entrenador.csv'
\set f_participaciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/participacion_mundial.csv'
\set f_resoluciones 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/resolucion_identidad_jugador.csv'

BEGIN;

TRUNCATE TABLE
    resolucion_identidad_jugador,
    participacion_mundial,
    plantel_entrenador,
    plantel_jugador,
    premio_seleccion,
    premio_jugador,
    goleador,
    posicion_final,
    grupo,
    penal,
    cambio,
    tarjeta,
    gol,
    direccion_tecnica_partido,
    aparicion_partido,
    partido,
    entrenador,
    jugador,
    seleccion_alias,
    seleccion,
    mundial;

COMMIT;

\copy mundial (anio, sede, equipos, partidos_jugados, goles_total) FROM :'f_mundiales' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy seleccion (seleccion_id, nombre) FROM :'f_selecciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy seleccion_alias (alias_nombre, seleccion_id) FROM :'f_aliases' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy jugador (jugador_id, nombre, nombre_completo, fecha_nacimiento, lugar_nacimiento, altura, apodo, sitio_web, redes_sociales) FROM :'f_jugadores' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy entrenador (entrenador_id, nombre) FROM :'f_entrenadores' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy partido (partido_id, anio, fecha, etapa, local_seleccion_id, visitante_seleccion_id, goles_local, goles_visitante, tiempo_extra, definicion_penales, penales_local, penales_visitante) FROM :'f_partidos' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy aparicion_partido (partido_id, seleccion_id, jugador_id, posicion, camiseta, seccion, es_capitan) FROM :'f_apariciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy direccion_tecnica_partido (partido_id, seleccion_id, entrenador_id) FROM :'f_tecnicos' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy gol (gol_id, partido_id, seleccion_id, jugador_id, minuto, es_penal, es_autogol) FROM :'f_goles' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy tarjeta (tarjeta_id, partido_id, seleccion_id, jugador_id, tipo, minuto) FROM :'f_tarjetas' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy cambio (cambio_id, partido_id, seleccion_id, jugador_sale_id, jugador_entra_id, minuto) FROM :'f_cambios' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy penal (penal_id, partido_id, seleccion_id, orden, jugador_id, resultado) FROM :'f_penales' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy grupo (anio, grupo, posicion, seleccion_id, pts, pj, pg, pe, pp, gf, gc, dif, clasificado) FROM :'f_grupos' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy posicion_final (anio, posicion, seleccion_id) FROM :'f_posiciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy goleador (anio, jugador_id, seleccion_id, goles) FROM :'f_goleadores' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy premio_jugador (anio, premio, jugador_id, seleccion_id) FROM :'f_premios_jugador' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy premio_seleccion (anio, premio, seleccion_id) FROM :'f_premios_seleccion' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy plantel_jugador (anio, seleccion_id, jugador_id, posicion, camiseta, club) FROM :'f_plantel_jugador' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy plantel_entrenador (anio, seleccion_id, entrenador_id) FROM :'f_plantel_entrenador' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy participacion_mundial (anio, seleccion_id, posicion, etapa, pts, pj, pg, pe, pp, gf, gc, dif, participo) FROM :'f_participaciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
\copy resolucion_identidad_jugador (source_table, source_event_id, partido_id, seleccion_id, jugador_nombre_raw, minuto, metodo, confianza, notas) FROM :'f_resoluciones' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')