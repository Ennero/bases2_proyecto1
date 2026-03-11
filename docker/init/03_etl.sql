-- ETL para Docker - sin variables \set (no soportadas en modo servidor)
-- Los CSV se leen desde /csv/ montado desde ./datos_normalizados_web
SET
    client_encoding = 'UTF8';

COPY mundial (
    anio,
    sede,
    equipos,
    partidos_jugados,
    goles_total
)
FROM
    '/csv/mundial.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY seleccion (seleccion_id, nombre)
FROM
    '/csv/seleccion.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY seleccion_alias (alias_nombre, seleccion_id)
FROM
    '/csv/seleccion_alias.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY jugador (
    jugador_id,
    nombre,
    nombre_completo,
    fecha_nacimiento,
    lugar_nacimiento,
    altura,
    apodo,
    sitio_web,
    redes_sociales
)
FROM
    '/csv/jugador.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY entrenador (entrenador_id, nombre)
FROM
    '/csv/entrenador.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY partido (
    partido_id,
    anio,
    fecha,
    etapa,
    local_seleccion_id,
    visitante_seleccion_id,
    goles_local,
    goles_visitante,
    tiempo_extra,
    definicion_penales,
    penales_local,
    penales_visitante
)
FROM
    '/csv/partido.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY aparicion_partido (
    partido_id,
    seleccion_id,
    jugador_id,
    posicion,
    camiseta,
    seccion,
    es_capitan
)
FROM
    '/csv/aparicion_partido.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY direccion_tecnica_partido (partido_id, seleccion_id, entrenador_id)
FROM
    '/csv/direccion_tecnica_partido.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY gol (
    gol_id,
    partido_id,
    seleccion_id,
    jugador_id,
    minuto,
    es_penal,
    es_autogol
)
FROM
    '/csv/gol.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY tarjeta (
    tarjeta_id,
    partido_id,
    seleccion_id,
    jugador_id,
    tipo,
    minuto
)
FROM
    '/csv/tarjeta.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY cambio (
    cambio_id,
    partido_id,
    seleccion_id,
    jugador_sale_id,
    jugador_entra_id,
    minuto
)
FROM
    '/csv/cambio.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY penal (
    penal_id,
    partido_id,
    seleccion_id,
    orden,
    jugador_id,
    resultado
)
FROM
    '/csv/penal.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY grupo (
    anio,
    grupo,
    posicion,
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
FROM
    '/csv/grupo.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY posicion_final (anio, posicion, seleccion_id)
FROM
    '/csv/posicion_final.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY goleador (anio, jugador_id, seleccion_id, goles)
FROM
    '/csv/goleador.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY premio_jugador (anio, premio, jugador_id, seleccion_id)
FROM
    '/csv/premio_jugador.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY premio_seleccion (anio, premio, seleccion_id)
FROM
    '/csv/premio_seleccion.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY plantel_jugador (
    anio,
    seleccion_id,
    jugador_id,
    posicion,
    camiseta,
    club
)
FROM
    '/csv/plantel_jugador.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY plantel_entrenador (anio, seleccion_id, entrenador_id)
FROM
    '/csv/plantel_entrenador.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY participacion_mundial (
    anio,
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
FROM
    '/csv/participacion_mundial.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );

COPY resolucion_identidad_jugador (
    source_table,
    source_event_id,
    partido_id,
    seleccion_id,
    jugador_nombre_raw,
    minuto,
    metodo,
    confianza,
    notas
)
FROM
    '/csv/resolucion_identidad_jugador.csv' WITH (
        FORMAT csv,
        HEADER true,
        ENCODING 'UTF8',
        NULL ''
    );