SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
Validacion de Fase 2:
1) Existencia de catalogos requeridos para 2030.
2) Conteos por tabla impactada.
3) Resumen deportivo del torneo 2030.
4) Evidencia de logs por cada dia de carga.
*/

PRINT '============================================================';
PRINT 'VALIDACION FASE 2 - TORNEO FICTICIO 2030';
PRINT '============================================================';

/* 1) Precondiciones de catalogo */
PRINT '';
PRINT '1) PRECONDICIONES DE CATALOGO';

SELECT
    CASE WHEN COUNT(*) = 4 THEN 'OK' ELSE 'ERROR' END AS estado_selecciones_1_4,
    COUNT(*) AS total_encontradas
FROM dbo.seleccion
WHERE seleccion_id IN (1, 2, 3, 4);

;WITH numeros AS (
    SELECT TOP (44)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS jugador_id
    FROM sys.all_objects
)
SELECT
    CASE WHEN SUM(CASE WHEN j.jugador_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'ERROR' END AS estado_jugadores_1_44,
    SUM(CASE WHEN j.jugador_id IS NULL THEN 1 ELSE 0 END) AS faltantes
FROM numeros n
LEFT JOIN dbo.jugador j
    ON j.jugador_id = n.jugador_id;

/* 2) Conteos de filas generadas para 2030 */
PRINT '';
PRINT '2) CONTEOS POR TABLA (ANIO 2030)';

SELECT 'mundial' AS tabla, COUNT(*) AS filas
FROM dbo.mundial
WHERE anio = 2030
UNION ALL
SELECT 'participacion_mundial', COUNT(*)
FROM dbo.participacion_mundial
WHERE anio = 2030
UNION ALL
SELECT 'grupo', COUNT(*)
FROM dbo.grupo
WHERE anio = 2030
UNION ALL
SELECT 'plantel_jugador', COUNT(*)
FROM dbo.plantel_jugador
WHERE anio = 2030
UNION ALL
SELECT 'partido', COUNT(*)
FROM dbo.partido
WHERE anio = 2030
UNION ALL
SELECT 'aparicion_partido', COUNT(*)
FROM dbo.aparicion_partido ap
INNER JOIN dbo.partido p
    ON p.partido_id = ap.partido_id
WHERE p.anio = 2030
UNION ALL
SELECT 'gol', COUNT(*)
FROM dbo.gol g
INNER JOIN dbo.partido p
    ON p.partido_id = g.partido_id
WHERE p.anio = 2030
UNION ALL
SELECT 'tarjeta', COUNT(*)
FROM dbo.tarjeta t
INNER JOIN dbo.partido p
    ON p.partido_id = t.partido_id
WHERE p.anio = 2030
UNION ALL
SELECT 'cambio', COUNT(*)
FROM dbo.cambio c
INNER JOIN dbo.partido p
    ON p.partido_id = c.partido_id
WHERE p.anio = 2030
UNION ALL
SELECT 'penal', COUNT(*)
FROM dbo.penal pe
INNER JOIN dbo.partido p
    ON p.partido_id = pe.partido_id
WHERE p.anio = 2030
ORDER BY tabla;

/* 3) Resumen deportivo rapido */
PRINT '';
PRINT '3) RESUMEN DE RESULTADOS (ANIO 2030)';

SELECT
    p.partido_id,
    p.fecha,
    p.etapa,
    s_local.nombre AS seleccion_local,
    p.goles_local,
    p.goles_visitante,
    s_visita.nombre AS seleccion_visitante,
    p.tiempo_extra,
    p.definicion_penales,
    p.penales_local,
    p.penales_visitante
FROM dbo.partido p
INNER JOIN dbo.seleccion s_local
    ON s_local.seleccion_id = p.local_seleccion_id
INNER JOIN dbo.seleccion s_visita
    ON s_visita.seleccion_id = p.visitante_seleccion_id
WHERE p.anio = 2030
ORDER BY p.partido_id;

/* 4) Evidencia de logs de auditoria */
PRINT '';
PRINT '4) EVIDENCIA DE LOGS (ULTIMOS REGISTROS POR DIA)';

SELECT
    l.partido_log_id,
    l.partido_fecha,
    l.partido_fragmentacion,
    l.partido_filas,
    l.partido_descripcion
FROM (
    SELECT TOP (5)
        lp.log_id AS partido_log_id,
        lp.fecha_registro AS partido_fecha,
        lp.nivel_fragmentacion AS partido_fragmentacion,
        lp.filas_totales AS partido_filas,
        lp.descripcion_carga AS partido_descripcion
    FROM dbo.log_partido lp
    WHERE lp.descripcion_carga IN (
        N'Carga Masiva Día 1 - Grupos 2030',
        N'Carga Masiva Día 2 - Finales 2030',
        N'Update Mayusculas Día 3'
    )
    ORDER BY lp.log_id DESC
) l
ORDER BY l.partido_log_id DESC;

SELECT
    ls.log_id,
    ls.fecha_registro,
    ls.nivel_fragmentacion,
    ls.filas_totales,
    ls.descripcion_carga
FROM dbo.log_seleccion ls
WHERE ls.descripcion_carga IN (
    N'Carga Masiva Día 1 - Grupos 2030',
    N'Carga Masiva Día 2 - Finales 2030',
    N'Update Mayusculas Día 3'
)
ORDER BY ls.log_id DESC;

/* 5) Semaforo de estado final */
PRINT '';
PRINT '5) SEMAFORO FINAL';

;WITH esperados AS (
    SELECT 'mundial' AS tabla, 1 AS esperado
    UNION ALL SELECT 'participacion_mundial', 4
    UNION ALL SELECT 'grupo', 4
    UNION ALL SELECT 'plantel_jugador', 44
    UNION ALL SELECT 'partido', 7
),
obtenidos AS (
    SELECT 'mundial' AS tabla, COUNT(*) AS obtenido FROM dbo.mundial WHERE anio = 2030
    UNION ALL SELECT 'participacion_mundial', COUNT(*) FROM dbo.participacion_mundial WHERE anio = 2030
    UNION ALL SELECT 'grupo', COUNT(*) FROM dbo.grupo WHERE anio = 2030
    UNION ALL SELECT 'plantel_jugador', COUNT(*) FROM dbo.plantel_jugador WHERE anio = 2030
    UNION ALL SELECT 'partido', COUNT(*) FROM dbo.partido WHERE anio = 2030
)
SELECT
    e.tabla,
    e.esperado,
    o.obtenido,
    CASE WHEN o.obtenido = e.esperado THEN 'OK' ELSE 'REVISAR' END AS estado
FROM esperados e
INNER JOIN obtenidos o
    ON o.tabla = e.tabla
ORDER BY e.tabla;
GO
