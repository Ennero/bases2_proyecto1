-- SQL Server ETL for normalized CSV outputs
-- Run with sqlcmd (example):
-- sqlcmd -S localhost,1433 -U sa -P <password> -d mundiales -C -i py/db/sqlserver_etl.sql -v CSV_DIR="./datos_normalizados_web"
-- The SQLCMD variable CSV_DIR is required and must point to the CSV folder.

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    DELETE FROM dbo.resolucion_identidad_jugador;
    DELETE FROM dbo.participacion_mundial;
    DELETE FROM dbo.plantel_entrenador;
    DELETE FROM dbo.plantel_jugador;
    DELETE FROM dbo.premio_seleccion;
    DELETE FROM dbo.premio_jugador;
    DELETE FROM dbo.goleador;
    DELETE FROM dbo.posicion_final;
    DELETE FROM dbo.grupo;
    DELETE FROM dbo.penal;
    DELETE FROM dbo.cambio;
    DELETE FROM dbo.tarjeta;
    DELETE FROM dbo.gol;
    DELETE FROM dbo.direccion_tecnica_partido;
    DELETE FROM dbo.aparicion_partido;
    DELETE FROM dbo.partido;
    DELETE FROM dbo.entrenador;
    DELETE FROM dbo.jugador;
    DELETE FROM dbo.seleccion_alias;
    DELETE FROM dbo.seleccion;
    DELETE FROM dbo.mundial;

    CREATE TABLE #stg_mundial (
        anio NVARCHAR(64) NULL,
        sede NVARCHAR(191) NULL,
        equipos NVARCHAR(64) NULL,
        partidos_jugados NVARCHAR(64) NULL,
        goles_total NVARCHAR(64) NULL
    );

    BULK INSERT #stg_mundial
    FROM '$(CSV_DIR)/mundial.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.mundial (anio, sede, equipos, partidos_jugados, goles_total)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        NULLIF(LTRIM(RTRIM(sede)), ''),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(equipos)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(partidos_jugados)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(goles_total)), ''))
    FROM #stg_mundial;

    DROP TABLE #stg_mundial;

    CREATE TABLE #stg_seleccion (
        seleccion_id NVARCHAR(64) NULL,
        nombre NVARCHAR(191) NULL
    );

    BULK INSERT #stg_seleccion
    FROM '$(CSV_DIR)/seleccion.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.seleccion (seleccion_id, nombre)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        LTRIM(RTRIM(nombre))
    FROM #stg_seleccion;

    DROP TABLE #stg_seleccion;

    CREATE TABLE #stg_seleccion_alias (
        alias_nombre NVARCHAR(191) NULL,
        seleccion_id NVARCHAR(64) NULL
    );

    BULK INSERT #stg_seleccion_alias
    FROM '$(CSV_DIR)/seleccion_alias.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.seleccion_alias (alias_nombre, seleccion_id)
    SELECT
        LTRIM(RTRIM(alias_nombre)),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), ''))
    FROM #stg_seleccion_alias;

    DROP TABLE #stg_seleccion_alias;

    CREATE TABLE #stg_jugador (
        jugador_id NVARCHAR(64) NULL,
        nombre NVARCHAR(191) NULL,
        nombre_completo NVARCHAR(191) NULL,
        fecha_nacimiento NVARCHAR(64) NULL,
        lugar_nacimiento NVARCHAR(191) NULL,
        altura NVARCHAR(64) NULL,
        apodo NVARCHAR(191) NULL,
        sitio_web NVARCHAR(255) NULL,
        redes_sociales NVARCHAR(255) NULL
    );

    BULK INSERT #stg_jugador
    FROM '$(CSV_DIR)/jugador.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.jugador (
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
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        LTRIM(RTRIM(nombre)),
        NULLIF(LTRIM(RTRIM(nombre_completo)), ''),
        NULLIF(LTRIM(RTRIM(fecha_nacimiento)), ''),
        NULLIF(LTRIM(RTRIM(lugar_nacimiento)), ''),
        NULLIF(LTRIM(RTRIM(altura)), ''),
        NULLIF(LTRIM(RTRIM(apodo)), ''),
        NULLIF(LTRIM(RTRIM(sitio_web)), ''),
        NULLIF(LTRIM(RTRIM(redes_sociales)), '')
    FROM #stg_jugador;

    DROP TABLE #stg_jugador;

    CREATE TABLE #stg_entrenador (
        entrenador_id NVARCHAR(64) NULL,
        nombre NVARCHAR(191) NULL
    );

    BULK INSERT #stg_entrenador
    FROM '$(CSV_DIR)/entrenador.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.entrenador (entrenador_id, nombre)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(entrenador_id)), '')),
        LTRIM(RTRIM(nombre))
    FROM #stg_entrenador;

    DROP TABLE #stg_entrenador;

    CREATE TABLE #stg_partido (
        partido_id NVARCHAR(64) NULL,
        anio NVARCHAR(64) NULL,
        fecha NVARCHAR(64) NULL,
        etapa NVARCHAR(191) NULL,
        local_seleccion_id NVARCHAR(64) NULL,
        visitante_seleccion_id NVARCHAR(64) NULL,
        goles_local NVARCHAR(64) NULL,
        goles_visitante NVARCHAR(64) NULL,
        tiempo_extra NVARCHAR(16) NULL,
        definicion_penales NVARCHAR(16) NULL,
        penales_local NVARCHAR(64) NULL,
        penales_visitante NVARCHAR(64) NULL
    );

    BULK INSERT #stg_partido
    FROM '$(CSV_DIR)/partido.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.partido (
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
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        NULLIF(LTRIM(RTRIM(fecha)), ''),
        NULLIF(LTRIM(RTRIM(etapa)), ''),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(local_seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(visitante_seleccion_id)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(goles_local)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(goles_visitante)), '')),
        CASE WHEN LOWER(LTRIM(RTRIM(tiempo_extra))) IN ('1', 'true', 't', 'yes', 'si') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
        CASE WHEN LOWER(LTRIM(RTRIM(definicion_penales))) IN ('1', 'true', 't', 'yes', 'si') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(penales_local)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(penales_visitante)), ''))
    FROM #stg_partido;

    DROP TABLE #stg_partido;

    CREATE TABLE #stg_aparicion_partido (
        partido_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        jugador_id NVARCHAR(64) NULL,
        posicion NVARCHAR(64) NULL,
        camiseta NVARCHAR(16) NULL,
        seccion NVARCHAR(32) NULL,
        es_capitan NVARCHAR(16) NULL
    );

    BULK INSERT #stg_aparicion_partido
    FROM '$(CSV_DIR)/aparicion_partido.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.aparicion_partido (partido_id, seleccion_id, jugador_id, posicion, camiseta, seccion, es_capitan)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        NULLIF(LTRIM(RTRIM(posicion)), ''),
        NULLIF(LTRIM(RTRIM(camiseta)), ''),
        LOWER(LTRIM(RTRIM(seccion))),
        CASE WHEN LOWER(LTRIM(RTRIM(es_capitan))) IN ('1', 'true', 't', 'yes', 'si') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
    FROM #stg_aparicion_partido;

    DROP TABLE #stg_aparicion_partido;

    CREATE TABLE #stg_direccion_tecnica_partido (
        partido_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        entrenador_id NVARCHAR(64) NULL
    );

    BULK INSERT #stg_direccion_tecnica_partido
    FROM '$(CSV_DIR)/direccion_tecnica_partido.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.direccion_tecnica_partido (partido_id, seleccion_id, entrenador_id)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(entrenador_id)), ''))
    FROM #stg_direccion_tecnica_partido;

    DROP TABLE #stg_direccion_tecnica_partido;

    CREATE TABLE #stg_gol (
        gol_id NVARCHAR(64) NULL,
        partido_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        jugador_id NVARCHAR(64) NULL,
        minuto NVARCHAR(32) NULL,
        es_penal NVARCHAR(16) NULL,
        es_autogol NVARCHAR(16) NULL
    );

    BULK INSERT #stg_gol
    FROM '$(CSV_DIR)/gol.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.gol (gol_id, partido_id, seleccion_id, jugador_id, minuto, es_penal, es_autogol)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(gol_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        NULLIF(LTRIM(RTRIM(minuto)), ''),
        CASE WHEN LOWER(LTRIM(RTRIM(es_penal))) IN ('1', 'true', 't', 'yes', 'si') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
        CASE WHEN LOWER(LTRIM(RTRIM(es_autogol))) IN ('1', 'true', 't', 'yes', 'si') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
    FROM #stg_gol;

    DROP TABLE #stg_gol;

    CREATE TABLE #stg_tarjeta (
        tarjeta_id NVARCHAR(64) NULL,
        partido_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        jugador_id NVARCHAR(64) NULL,
        tipo NVARCHAR(16) NULL,
        minuto NVARCHAR(32) NULL
    );

    BULK INSERT #stg_tarjeta
    FROM '$(CSV_DIR)/tarjeta.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.tarjeta (tarjeta_id, partido_id, seleccion_id, jugador_id, tipo, minuto)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(tarjeta_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        LOWER(LTRIM(RTRIM(tipo))),
        NULLIF(LTRIM(RTRIM(minuto)), '')
    FROM #stg_tarjeta;

    DROP TABLE #stg_tarjeta;

    CREATE TABLE #stg_cambio (
        cambio_id NVARCHAR(64) NULL,
        partido_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        jugador_sale_id NVARCHAR(64) NULL,
        jugador_entra_id NVARCHAR(64) NULL,
        minuto NVARCHAR(32) NULL
    );

    BULK INSERT #stg_cambio
    FROM '$(CSV_DIR)/cambio.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.cambio (cambio_id, partido_id, seleccion_id, jugador_sale_id, jugador_entra_id, minuto)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(cambio_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_sale_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_entra_id)), '')),
        NULLIF(LTRIM(RTRIM(minuto)), '')
    FROM #stg_cambio;

    DROP TABLE #stg_cambio;

    CREATE TABLE #stg_penal (
        penal_id NVARCHAR(64) NULL,
        partido_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        orden NVARCHAR(64) NULL,
        jugador_id NVARCHAR(64) NULL,
        resultado NVARCHAR(32) NULL
    );

    BULK INSERT #stg_penal
    FROM '$(CSV_DIR)/penal.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.penal (penal_id, partido_id, seleccion_id, orden, jugador_id, resultado)
    SELECT
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(penal_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(orden)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        LTRIM(RTRIM(resultado))
    FROM #stg_penal;

    DROP TABLE #stg_penal;

    CREATE TABLE #stg_grupo (
        anio NVARCHAR(64) NULL,
        grupo NVARCHAR(16) NULL,
        posicion NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        pts NVARCHAR(64) NULL,
        pj NVARCHAR(64) NULL,
        pg NVARCHAR(64) NULL,
        pe NVARCHAR(64) NULL,
        pp NVARCHAR(64) NULL,
        gf NVARCHAR(64) NULL,
        gc NVARCHAR(64) NULL,
        dif NVARCHAR(64) NULL,
        clasificado NVARCHAR(16) NULL
    );

    BULK INSERT #stg_grupo
    FROM '$(CSV_DIR)/grupo.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.grupo (anio, grupo, posicion, seleccion_id, pts, pj, pg, pe, pp, gf, gc, dif, clasificado)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        LTRIM(RTRIM(grupo)),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(posicion)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pts)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pj)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pg)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pe)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pp)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(gf)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(gc)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(dif)), '')),
        CASE
            WHEN NULLIF(LTRIM(RTRIM(clasificado)), '') IS NULL THEN NULL
            WHEN LOWER(LTRIM(RTRIM(clasificado))) IN ('1', 'true', 't', 'yes', 'si') THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END
    FROM #stg_grupo;

    DROP TABLE #stg_grupo;

    CREATE TABLE #stg_posicion_final (
        anio NVARCHAR(64) NULL,
        posicion NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL
    );

    BULK INSERT #stg_posicion_final
    FROM '$(CSV_DIR)/posicion_final.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.posicion_final (anio, posicion, seleccion_id)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(posicion)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), ''))
    FROM #stg_posicion_final;

    DROP TABLE #stg_posicion_final;

    CREATE TABLE #stg_goleador (
        anio NVARCHAR(64) NULL,
        jugador_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        goles NVARCHAR(64) NULL
    );

    BULK INSERT #stg_goleador
    FROM '$(CSV_DIR)/goleador.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.goleador (anio, jugador_id, seleccion_id, goles)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(goles)), ''))
    FROM #stg_goleador;

    DROP TABLE #stg_goleador;

    CREATE TABLE #stg_premio_jugador (
        anio NVARCHAR(64) NULL,
        premio NVARCHAR(191) NULL,
        jugador_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL
    );

    BULK INSERT #stg_premio_jugador
    FROM '$(CSV_DIR)/premio_jugador.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.premio_jugador (anio, premio, jugador_id, seleccion_id)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        LTRIM(RTRIM(premio)),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), ''))
    FROM #stg_premio_jugador;

    DROP TABLE #stg_premio_jugador;

    CREATE TABLE #stg_premio_seleccion (
        anio NVARCHAR(64) NULL,
        premio NVARCHAR(191) NULL,
        seleccion_id NVARCHAR(64) NULL
    );

    BULK INSERT #stg_premio_seleccion
    FROM '$(CSV_DIR)/premio_seleccion.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.premio_seleccion (anio, premio, seleccion_id)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        LTRIM(RTRIM(premio)),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), ''))
    FROM #stg_premio_seleccion;

    DROP TABLE #stg_premio_seleccion;

    CREATE TABLE #stg_plantel_jugador (
        anio NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        jugador_id NVARCHAR(64) NULL,
        posicion NVARCHAR(64) NULL,
        camiseta NVARCHAR(16) NULL,
        club NVARCHAR(191) NULL
    );

    BULK INSERT #stg_plantel_jugador
    FROM '$(CSV_DIR)/plantel_jugador.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.plantel_jugador (anio, seleccion_id, jugador_id, posicion, camiseta, club)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(jugador_id)), '')),
        NULLIF(LTRIM(RTRIM(posicion)), ''),
        NULLIF(LTRIM(RTRIM(camiseta)), ''),
        NULLIF(LTRIM(RTRIM(club)), '')
    FROM #stg_plantel_jugador;

    DROP TABLE #stg_plantel_jugador;

    CREATE TABLE #stg_plantel_entrenador (
        anio NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        entrenador_id NVARCHAR(64) NULL
    );

    BULK INSERT #stg_plantel_entrenador
    FROM '$(CSV_DIR)/plantel_entrenador.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.plantel_entrenador (anio, seleccion_id, entrenador_id)
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(entrenador_id)), ''))
    FROM #stg_plantel_entrenador;

    DROP TABLE #stg_plantel_entrenador;

    CREATE TABLE #stg_participacion_mundial (
        anio NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        posicion NVARCHAR(64) NULL,
        etapa NVARCHAR(191) NULL,
        pts NVARCHAR(64) NULL,
        pj NVARCHAR(64) NULL,
        pg NVARCHAR(64) NULL,
        pe NVARCHAR(64) NULL,
        pp NVARCHAR(64) NULL,
        gf NVARCHAR(64) NULL,
        gc NVARCHAR(64) NULL,
        dif NVARCHAR(64) NULL,
        participo NVARCHAR(16) NULL
    );

    BULK INSERT #stg_participacion_mundial
    FROM '$(CSV_DIR)/participacion_mundial.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.participacion_mundial (
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
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(posicion)), '')),
        NULLIF(LTRIM(RTRIM(etapa)), ''),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pts)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pj)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pg)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pe)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pp)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(gf)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(gc)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(dif)), '')),
        CASE WHEN LOWER(LTRIM(RTRIM(participo))) IN ('1', 'true', 't', 'yes', 'si') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
    FROM #stg_participacion_mundial;

    DROP TABLE #stg_participacion_mundial;

    CREATE TABLE #stg_resolucion_identidad_jugador (
        source_table NVARCHAR(32) NULL,
        source_event_id NVARCHAR(64) NULL,
        partido_id NVARCHAR(64) NULL,
        seleccion_id NVARCHAR(64) NULL,
        jugador_nombre_raw NVARCHAR(191) NULL,
        minuto NVARCHAR(32) NULL,
        metodo NVARCHAR(64) NULL,
        confianza NVARCHAR(64) NULL,
        notas NVARCHAR(MAX) NULL
    );

    BULK INSERT #stg_resolucion_identidad_jugador
    FROM '$(CSV_DIR)/resolucion_identidad_jugador.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    INSERT INTO dbo.resolucion_identidad_jugador (
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
    SELECT
        LOWER(LTRIM(RTRIM(source_table))),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(source_event_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(partido_id)), '')),
        TRY_CONVERT(BIGINT, NULLIF(LTRIM(RTRIM(seleccion_id)), '')),
        LTRIM(RTRIM(jugador_nombre_raw)),
        NULLIF(LTRIM(RTRIM(minuto)), ''),
        CASE WHEN NULLIF(LTRIM(RTRIM(metodo)), '') IS NULL THEN N'manual' ELSE LTRIM(RTRIM(metodo)) END,
        TRY_CONVERT(DECIMAL(5,2), NULLIF(LTRIM(RTRIM(confianza)), '')),
        NULLIF(LTRIM(RTRIM(notas)), '')
    FROM #stg_resolucion_identidad_jugador;

    DROP TABLE #stg_resolucion_identidad_jugador;

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    THROW;
END CATCH;
