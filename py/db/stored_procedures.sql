-- ============================================================
-- STORED PROCEDURES - Mundiales de Futbol
-- Base de datos: mundiales (SQL Server 2022)
-- Nota: los nombres de paises y jugadores se almacenan sin
--       tildes ni diacriticos (normalizacion al cargar datos).
--       Ejemplo: 'Espana', 'Mexico', 'Belgica'
-- ============================================================
-- ============================================================
-- SP 1: sp_mundial_por_anio
-- Muestra toda la informacion de una edicion del Mundial.
-- Parametros obligatorios:
--   @anio         INT   -- año del mundial (ej: 2022)
-- Parametros opcionales de filtro:
--   @grupo        CHAR(1)       -- filtra por grupo (ej: 'A')
--   @pais         NVARCHAR(191) -- filtra partidos de un pais
--   @fecha        NVARCHAR(64)  -- filtra por fecha (ej: '20-Nov-2022')
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_mundial_por_anio
    @anio INT,
    @grupo CHAR(1) = NULL,
    @pais NVARCHAR(191) = NULL,
    @fecha NVARCHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el mundial exista
    IF NOT EXISTS (SELECT 1 FROM dbo.mundial WHERE anio = @anio)
    BEGIN
        RAISERROR('No existe un Mundial registrado para el año %d.', 16, 1, @anio);
        RETURN;
    END

    -- 1. Resumen General del mundial
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║         RESUMEN GENERAL DEL MUNDIAL          ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT 
        m.anio AS [Anio],
        m.sede AS [Sede],
        m.equipos AS [Equipos Participantes],
        m.partidos_jugados AS [Partidos Jugados],
        m.goles_total AS [Goles Totales],
        CASE
            WHEN m.partidos_jugados > 0
            THEN CAST(CAST(m.goles_total AS DECIMAL(6,2)) / m.partidos_jugados AS DECIMAL(4,2))
            ELSE NULL
        END AS [Promedio Goles por Partido]
    FROM dbo.mundial m
    WHERE m.anio = @anio;

    -- 2. Posición Final (podio + todos)
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           POSICIONES FINALES                 ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT 
        pf.posicion AS [Posicion],
        s.nombre AS [Seleccion],
        CASE pf.posicion
            WHEN 1 THEN 'Campeon'
            WHEN 2 THEN 'SubCampeon'
            WHEN 3 THEN 'Tercer Lugar'
            WHEN 4 THEN 'Cuarto Lugar'
            ELSE 'Participante'
        END AS [Distinción]
    FROM dbo.posicion_final pf
    JOIN dbo.seleccion s ON s.seleccion_id = pf.seleccion_id
    WHERE pf.anio = @anio
    ORDER BY pf.posicion;

    -- 3. Tabla de grupos
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           TABLA DE GRUPOS                    ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        g.grupo                 AS [Grupo],
        g.posicion              AS [Pos],
        s.nombre                AS [Seleccion],
        g.pj                    AS [PJ],
        g.pg                    AS [PG],
        g.pe                    AS [PE],
        g.pp                    AS [PP],
        g.gf                    AS [GF],
        g.gc                    AS [GC],
        g.dif                   AS [DIF],
        g.pts                   AS [PTS],
        CASE g.clasificado WHEN 1 THEN 'Si' ELSE 'No' END AS [Clasifico]
    FROM dbo.grupo g
    JOIN dbo.seleccion s ON s.seleccion_id = g.seleccion_id
    WHERE g.anio = @anio
        AND (@grupo IS NULL OR g.grupo = UPPER(@grupo))
    ORDER BY g.grupo, g.posicion;

    -- 4. Partidos y resultados
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           PARTIDOS Y RESULTADOS              ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT 
        p.partido_id AS [ID],
        p.fecha AS [Fecha],
        p.etapa AS [Etapa],
        s1.nombre AS [Seleccion Local],
        p.goles_local AS [Goles Local],
        sv.nombre AS [Seleccion Visitante],
        CASE 
            WHEN p.definicion_penales = 1
            THEN CONCAT('(Penales: ', p.penales_local, '-', p.penales_visitante, ')')
            ELSE ''
        END AS [Definicion Penales],
        CASE
            WHEN p.goles_local > p.goles_visitante THEN s1.nombre
            WHEN p.goles_visitante > p.goles_local THEN sv.nombre
            WHEN p.definicion_penales = 1 AND p.penales_local > p.penales_visitante THEN s1.nombre
            WHEN p.definicion_penales = 1 AND p.penales_visitante > p.penales_local THEN sv.nombre
            ELSE 'Empate'
        END AS [Ganador]
    FROM dbo.partido p
    JOIN dbo.seleccion s1 ON s1.seleccion_id = p.local_seleccion_id
    JOIN dbo.seleccion sv ON sv.seleccion_id = p.visitante_seleccion_id
    WHERE p.anio = @anio
        AND (@pais IS NULL OR s1.nombre = @pais OR sv.nombre = @pais)
        AND (@fecha IS NULL OR p.fecha = @fecha)
    ORDER BY p.partido_id;

    -- 5. Goles por partido (detalle)
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           DETALLE DE GOLES                   ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        p.fecha AS [Fecha],
        p.etapa AS [Etapa],
        s1.nombre AS [Local],
        sv.nombre AS [Visitante],
        s.nombre AS [Seleccion Gol],
        ISNULL(j.nombre, 'Desconocido') AS [Goleador],
        g.minuto AS [Minuto],
        CASE 
            WHEN g.es_autogol = 1 THEN 'Autogol'
            WHEN g.es_penal = 1 THEN 'Penal'
            ELSE 'Gol'
        END AS [Tipo]
    FROM dbo.gol g
    JOIN dbo.partido p ON p.partido_id = g.partido_id
    JOIN dbo.seleccion s ON s.seleccion_id = g.seleccion_id
    JOIN dbo.seleccion s1 ON s1.seleccion_id = p.local_seleccion_id
    JOIN dbo.seleccion sv ON sv.seleccion_id = p.visitante_seleccion_id
    LEFT JOIN dbo.jugador j ON j.jugador_id = g.jugador_id
    WHERE p.anio = @anio
        AND (@pais IS NULL OR s1.nombre = @pais OR sv.nombre = @pais)
        AND (@fecha IS NULL OR p.fecha = @fecha)
    ORDER BY p.partido_id, g.minuto

    -- 6. Tabla de goleadores del torneo 
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           GOLEADORES DEL TORNEO              ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        ROW_NUMBER() OVER (ORDER BY gl.goles DESC) AS [Ranking],
        j.nombre AS [Jugador],
        s.nombre AS [Seleccion],
        gl.goles AS [Goles]
    FROM dbo.goleador gl
    JOIN dbo.jugador j ON j.jugador_id = gl.jugador_id
    JOIN dbo.seleccion s ON s.seleccion_id = gl.seleccion_id
    WHERE gl.anio = @anio
        AND (@pais IS NULL OR s.nombre = @pais)
    ORDER BY gl.goles DESC, j.nombre;

    -- 7. Premios del torneo 
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           PREMIOS DEL TORNEO                 ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT 
        pj.premio AS [Premio],
        j.nombre AS [Jugador],
        s.nombre AS [Seleccion]
    FROM dbo.premio_jugador pj
    JOIN dbo.jugador j ON j.jugador_id = pj.jugador_id
    JOIN dbo.seleccion s ON s.seleccion_id = pj.seleccion_id
    WHERE pj.anio = @anio
    UNION ALL
    SELECT 
        ps.premio AS [Premio],
        NULL AS [Jugador],
        s.nombre AS [Seleccion]
    FROM dbo.premio_seleccion ps
    JOIN dbo.seleccion s ON s.seleccion_id = ps.seleccion_id
    WHERE ps.anio = @anio
    ORDER BY [Premio];

    -- 8. Tarjetas del torneo 
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           TARJETAS DEL TORNEO                ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT 
        s.nombre AS [Seleccion],
        SUM(CASE WHEN t.tipo = 'amarilla' THEN 1 ELSE 0 END) AS [Amarillas],
        SUM(CASE WHEN t.tipo = 'roja' THEN 1 ELSE 0 END) AS [Rojas],
        COUNT(*) AS [Total]
    FROM dbo.tarjeta t
    JOIN dbo.partido p ON p.partido_id = t.partido_id
    JOIN dbo.seleccion s ON s.seleccion_id = t.seleccion_id
    WHERE p.anio = @anio
        AND (@pais IS NULL OR s.nombre = @pais)
    GROUP BY s.nombre
    ORDER BY [Total] DESC, [Rojas] DESC;

    -- 9. Planteles convocados 
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           PLANTELES CONVOCADOS               ║';
    PRINT '╚══════════════════════════════════════════════╝';

    Select
        s.nombre                AS [Seleccion],
        j.nombre                AS [Jugador],
        pj.posicion             AS [Posicion],
        pj.camiseta             AS [Camiseta],
        pj.club                 AS [Club]
    FROM dbo.plantel_jugador pj
    JOIN dbo.seleccion s ON s.seleccion_id = pj.seleccion_id
    JOIN dbo.jugador j ON j.jugador_id = pj.jugador_id
    WHERE pj.anio = @anio
        AND (@pais IS NULL OR s.nombre = @pais)
        AND (@grupo IS NULL OR s.seleccion_id IN (
            SELECT seleccion_id FROM dbo.grupo
            WHERE anio = @anio AND grupo = UPPER(@grupo)
        ))
    ORDER BY s.nombre, pj.posicion, pj.camiseta;

    -- 10. Entrenadores
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           ENTRENADORES                       ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT DISTINCT 
        s.nombre AS [Seleccion],
        e.nombre AS [Entrenador]
    FROM dbo.plantel_entrenador pe
    JOIN dbo.seleccion s ON s.seleccion_id = pe.seleccion_id
    JOIN dbo.entrenador e ON e.entrenador_id = pe.entrenador_id
    WHERE pe.anio = @anio
        AND (@pais IS NULL OR s.nombre = @pais)
    ORDER BY s.nombre;

END;
GO

-- ============================================================
-- SP 2: sp_historial_pais
-- Muestra toda la informacion historica de una seleccion.
-- Parametros obligatorios:
--   @pais         NVARCHAR(191) -- nombre del pais (sin tildes)
-- Parametros opcionales de filtro:
--   @anio         INT           -- filtra por una edicion especifica
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_historial_pais
    @pais  NVARCHAR(191),
    @anio  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Resolver seleccion_id (puede venir por nombre canónico o alias)
    DECLARE @seleccion_id BIGINT;

    SELECT @seleccion_id = seleccion_id
    FROM dbo.seleccion
    WHERE nombre = @pais;

    -- Si no se encontró por nombre canónico, buscar en alias
    IF @seleccion_id IS NULL
    BEGIN
        SELECT @seleccion_id = seleccion_id
        FROM dbo.seleccion_alias
        WHERE alias_nombre = @pais;
    END

    IF @seleccion_id IS NULL
    BEGIN
        RAISERROR('No se encontró ninguna selección con el nombre "%s". Verifique que el nombre esté sin tildes.', 16, 1, @pais);
        RETURN;
    END

    DECLARE @nombre_canonico NVARCHAR(191);
    SELECT @nombre_canonico = nombre FROM dbo.seleccion WHERE seleccion_id = @seleccion_id;

    -- ── 1. Resumen general de la seleccion ────────────────────────────────────
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║         RESUMEN HISTORICO DE LA SELECCION    ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        @nombre_canonico            AS [Seleccion],
        COUNT(CASE WHEN pm.participo = 1 THEN 1 END) AS [Mundiales Jugados],
        MIN(CASE WHEN pm.participo = 1 THEN pm.anio END) AS [Primer Mundial],
        MAX(CASE WHEN pm.participo = 1 THEN pm.anio END) AS [Ultimo Mundial],
        SUM(CASE WHEN pm.participo = 1 THEN pm.pj  ELSE 0 END) AS [Partidos Jugados],
        SUM(CASE WHEN pm.participo = 1 THEN pm.pg  ELSE 0 END) AS [Partidos Ganados],
        SUM(CASE WHEN pm.participo = 1 THEN pm.pe  ELSE 0 END) AS [Partidos Empatados],
        SUM(CASE WHEN pm.participo = 1 THEN pm.pp  ELSE 0 END) AS [Partidos Perdidos],
        SUM(CASE WHEN pm.participo = 1 THEN pm.gf  ELSE 0 END) AS [Goles a Favor],
        SUM(CASE WHEN pm.participo = 1 THEN pm.gc  ELSE 0 END) AS [Goles en Contra],
        SUM(CASE WHEN pm.participo = 1 THEN pm.dif ELSE 0 END) AS [Diferencia de Gol],
        MIN(CASE WHEN pm.posicion = 1 THEN pm.anio END)        AS [Primer Titulo],
        COUNT(CASE WHEN pm.posicion = 1 THEN 1 END)            AS [Titulos]
    FROM dbo.participacion_mundial pm
    WHERE pm.seleccion_id = @seleccion_id;

    -- ── 2. Participaciones por edicion ────────────────────────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           PARTICIPACIONES POR EDICION        ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        pm.anio                 AS [Anio],
        m.sede                  AS [Sede],
        CASE pm.participo WHEN 1 THEN 'Si' ELSE 'No clasifico' END AS [Participo],
        ISNULL(pm.etapa, '-')   AS [Mejor Etapa],
        pm.posicion             AS [Posicion Final],
        pm.pj                   AS [PJ],
        pm.pg                   AS [PG],
        pm.pe                   AS [PE],
        pm.pp                   AS [PP],
        pm.gf                   AS [GF],
        pm.gc                   AS [GC],
        pm.dif                  AS [DIF],
        pm.pts                  AS [PTS],
        CASE
            WHEN m.sede LIKE CONCAT('%', @nombre_canonico, '%') THEN 'Si'
            ELSE 'No'
        END                     AS [Fue Sede]
    FROM dbo.participacion_mundial pm
    JOIN dbo.mundial m ON m.anio = pm.anio
    WHERE pm.seleccion_id = @seleccion_id
        AND (@anio IS NULL OR pm.anio = @anio)
    ORDER BY pm.anio;

    -- ── 3. Mundiales como sede ────────────────────────────────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           MUNDIALES COMO SEDE                ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        m.anio                  AS [Anio],
        m.sede                  AS [Sede Completa],
        m.equipos               AS [Equipos],
        m.partidos_jugados      AS [Partidos],
        m.goles_total           AS [Goles]
    FROM dbo.mundial m
    WHERE m.sede LIKE CONCAT('%', @nombre_canonico, '%');

    IF @@ROWCOUNT = 0
        SELECT 'Esta seleccion no ha sido sede de ningun Mundial.' AS [Informacion];

    -- ── 4. Informacion de grupos por edicion ──────────────────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           DESEMPENO EN FASE DE GRUPOS        ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        g.anio                  AS [Anio],
        g.grupo                 AS [Grupo],
        g.posicion              AS [Posicion Grupo],
        g.pj                    AS [PJ],
        g.pg                    AS [PG],
        g.pe                    AS [PE],
        g.pp                    AS [PP],
        g.gf                    AS [GF],
        g.gc                    AS [GC],
        g.dif                   AS [DIF],
        g.pts                   AS [PTS],
        CASE g.clasificado WHEN 1 THEN 'Si' ELSE 'No' END AS [Clasifico]
    FROM dbo.grupo g
    WHERE g.seleccion_id = @seleccion_id
        AND (@anio IS NULL OR g.anio = @anio)
    ORDER BY g.anio;

    -- ── 5. Todos los partidos ─────────────────────────────────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           PARTIDOS JUGADOS                   ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        p.anio                  AS [Anio],
        p.fecha                 AS [Fecha],
        p.etapa                 AS [Etapa],
        sl.nombre               AS [Local],
        p.goles_local           AS [GL],
        p.goles_visitante       AS [GV],
        sv.nombre               AS [Visitante],
        CASE
            WHEN p.definicion_penales = 1
            THEN CONCAT('(Penales: ', p.penales_local, '-', p.penales_visitante, ')')
            WHEN p.tiempo_extra = 1 THEN '(Tiempo Extra)'
            ELSE ''
        END                     AS [Extra],
        CASE
            WHEN p.local_seleccion_id = @seleccion_id AND p.goles_local > p.goles_visitante  THEN 'Ganado'
            WHEN p.visitante_seleccion_id = @seleccion_id AND p.goles_visitante > p.goles_local THEN 'Ganado'
            WHEN p.definicion_penales = 1 AND p.local_seleccion_id = @seleccion_id
                    AND p.penales_local > p.penales_visitante THEN 'Ganado'
            WHEN p.definicion_penales = 1 AND p.visitante_seleccion_id = @seleccion_id
                    AND p.penales_visitante > p.penales_local THEN 'Ganado'
            WHEN p.goles_local = p.goles_visitante AND p.definicion_penales = 0 THEN 'Empate'
            ELSE 'Perdido'
        END                     AS [Resultado]
    FROM dbo.partido p
    JOIN dbo.seleccion sl ON sl.seleccion_id = p.local_seleccion_id
    JOIN dbo.seleccion sv ON sv.seleccion_id = p.visitante_seleccion_id
    WHERE (p.local_seleccion_id = @seleccion_id OR p.visitante_seleccion_id = @seleccion_id)
        AND (@anio IS NULL OR p.anio = @anio)
    ORDER BY p.anio, p.partido_id;

    -- ── 6. Goles anotados por jugadores de la seleccion ───────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           GOLES ANOTADOS                     ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        p.anio                  AS [Anio],
        ISNULL(j.nombre, 'Desconocido') AS [Jugador],
        COUNT(*)                AS [Goles],
        SUM(CASE WHEN g.es_penal   = 1 THEN 1 ELSE 0 END) AS [De Penal],
        SUM(CASE WHEN g.es_autogol = 1 THEN 1 ELSE 0 END) AS [Autogoles]
    FROM dbo.gol g
    JOIN dbo.partido p ON p.partido_id = g.partido_id
    LEFT JOIN dbo.jugador j ON j.jugador_id = g.jugador_id
    WHERE g.seleccion_id = @seleccion_id
        AND (@anio IS NULL OR p.anio = @anio)
    GROUP BY p.anio, j.nombre
    ORDER BY p.anio, [Goles] DESC;

    -- ── 7. Maximos goleadores historicos de la seleccion ─────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           TOP GOLEADORES HISTORICOS          ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT TOP 10
        j.nombre                AS [Jugador],
        COUNT(*)                AS [Goles Totales],
        COUNT(DISTINCT p.anio)  AS [Mundiales],
        MIN(p.anio)             AS [Primer Mundial],
        MAX(p.anio)             AS [Ultimo Mundial]
    FROM dbo.gol g
    JOIN dbo.partido p ON p.partido_id = g.partido_id
    JOIN dbo.jugador j ON j.jugador_id = g.jugador_id
    WHERE g.seleccion_id = @seleccion_id
        AND g.es_autogol = 0
    GROUP BY j.nombre
    ORDER BY [Goles Totales] DESC;

    -- ── 8. Premios obtenidos ──────────────────────────────────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           PREMIOS OBTENIDOS                  ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT
        pj.anio                 AS [Anio],
        pj.premio               AS [Premio],
        j.nombre                AS [Jugador],
        'Individual'            AS [Tipo]
    FROM dbo.premio_jugador pj
    JOIN dbo.jugador j ON j.jugador_id = pj.jugador_id
    WHERE pj.seleccion_id = @seleccion_id
        AND (@anio IS NULL OR pj.anio = @anio)
    UNION ALL
    SELECT
        ps.anio                 AS [Anio],
        ps.premio               AS [Premio],
        NULL                    AS [Jugador],
        'Colectivo'             AS [Tipo]
    FROM dbo.premio_seleccion ps
    WHERE ps.seleccion_id = @seleccion_id
        AND (@anio IS NULL OR ps.anio = @anio)
    ORDER BY [Anio], [Premio];

    -- ── 9. Entrenadores historicos ────────────────────────────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           ENTRENADORES HISTORICOS            ║';
    PRINT '╚══════════════════════════════════════════════╝';

    SELECT DISTINCT
        pe.anio                 AS [Anio],
        e.nombre                AS [Entrenador]
    FROM dbo.plantel_entrenador pe
    JOIN dbo.entrenador e ON e.entrenador_id = pe.entrenador_id
    WHERE pe.seleccion_id = @seleccion_id
        AND (@anio IS NULL OR pe.anio = @anio)
    ORDER BY pe.anio;

    -- ── 10. Jugadores mas convocados historicamente ───────────────────────────
    PRINT '';
    PRINT '╔══════════════════════════════════════════════╗';
    PRINT '║           JUGADORES MAS CONVOCADOS           ║';
    PRINT '╚══════════════════════════════════════════════╝';
 
    SELECT TOP 15
        j.nombre                AS [Jugador],
        COUNT(*)                AS [Mundiales Convocado],
        MIN(pj.anio)            AS [Primera Convocatoria],
        MAX(pj.anio)            AS [Ultima Convocatoria]
    FROM dbo.plantel_jugador pj
    JOIN dbo.jugador j ON j.jugador_id = pj.jugador_id
    WHERE pj.seleccion_id = @seleccion_id
    GROUP BY j.nombre
    ORDER BY [Mundiales Convocado] DESC, j.nombre;

END;
GO