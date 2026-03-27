SET
    NOCOUNT ON;

GO
    IF OBJECT_ID(N'dbo.log_mundial', N'U') IS NULL BEGIN CREATE TABLE dbo.log_mundial (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_seleccion', N'U') IS NULL BEGIN CREATE TABLE dbo.log_seleccion (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_seleccion_alias', N'U') IS NULL BEGIN CREATE TABLE dbo.log_seleccion_alias (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_jugador', N'U') IS NULL BEGIN CREATE TABLE dbo.log_jugador (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_entrenador', N'U') IS NULL BEGIN CREATE TABLE dbo.log_entrenador (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_partido', N'U') IS NULL BEGIN CREATE TABLE dbo.log_partido (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_aparicion_partido', N'U') IS NULL BEGIN CREATE TABLE dbo.log_aparicion_partido (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_direccion_tecnica_partido', N'U') IS NULL BEGIN CREATE TABLE dbo.log_direccion_tecnica_partido (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_gol', N'U') IS NULL BEGIN CREATE TABLE dbo.log_gol (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_tarjeta', N'U') IS NULL BEGIN CREATE TABLE dbo.log_tarjeta (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_cambio', N'U') IS NULL BEGIN CREATE TABLE dbo.log_cambio (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_penal', N'U') IS NULL BEGIN CREATE TABLE dbo.log_penal (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_grupo', N'U') IS NULL BEGIN CREATE TABLE dbo.log_grupo (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_posicion_final', N'U') IS NULL BEGIN CREATE TABLE dbo.log_posicion_final (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_goleador', N'U') IS NULL BEGIN CREATE TABLE dbo.log_goleador (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_premio_jugador', N'U') IS NULL BEGIN CREATE TABLE dbo.log_premio_jugador (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_premio_seleccion', N'U') IS NULL BEGIN CREATE TABLE dbo.log_premio_seleccion (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_plantel_jugador', N'U') IS NULL BEGIN CREATE TABLE dbo.log_plantel_jugador (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_plantel_entrenador', N'U') IS NULL BEGIN CREATE TABLE dbo.log_plantel_entrenador (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_participacion_mundial', N'U') IS NULL BEGIN CREATE TABLE dbo.log_participacion_mundial (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    IF OBJECT_ID(N'dbo.log_resolucion_identidad_jugador', N'U') IS NULL BEGIN CREATE TABLE dbo.log_resolucion_identidad_jugador (
        log_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5, 2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );

END
GO
    CREATE
    OR ALTER PROCEDURE dbo.sp_registrar_logs_diarios @descripcion_carga NVARCHAR(255) AS BEGIN
SET
    NOCOUNT ON;

DECLARE @frag DECIMAL(5, 2);

DECLARE @filas INT;

DECLARE @oid INT;

-- ── mundial ──────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.mundial');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_mundial(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── seleccion ─────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.seleccion');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_seleccion(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── seleccion_alias ───────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.seleccion_alias');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_seleccion_alias(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── jugador ───────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.jugador');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_jugador(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── entrenador ────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.entrenador');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_entrenador(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── partido ───────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.partido');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_partido(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── aparicion_partido ─────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.aparicion_partido');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_aparicion_partido(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── direccion_tecnica_partido ─────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.direccion_tecnica_partido');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_direccion_tecnica_partido(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── gol ───────────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.gol');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_gol(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── tarjeta ───────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.tarjeta');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_tarjeta(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── cambio ────────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.cambio');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_cambio(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── penal ─────────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.penal');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_penal(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── grupo ─────────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.grupo');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_grupo(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── posicion_final ────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.posicion_final');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_posicion_final(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── goleador ──────────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.goleador');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_goleador(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── premio_jugador ────────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.premio_jugador');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_premio_jugador(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── premio_seleccion ──────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.premio_seleccion');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_premio_seleccion(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── plantel_jugador ───────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.plantel_jugador');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_plantel_jugador(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── plantel_entrenador ────────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.plantel_entrenador');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_plantel_entrenador(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── participacion_mundial ─────────────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.participacion_mundial');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_participacion_mundial(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

-- ── resolucion_identidad_jugador ──────────────────────────────────────────
SET
    @oid = OBJECT_ID(N'dbo.resolucion_identidad_jugador');

SELECT
    @filas = ISNULL(SUM(row_count), 0)
FROM
    sys.dm_db_partition_stats
WHERE
    object_id = @oid
    AND index_id IN (0, 1);

SELECT
    TOP(1) @frag = CAST(avg_fragmentation_in_percent AS DECIMAL(5, 2))
FROM
    sys.dm_db_index_physical_stats(DB_ID(), @oid, NULL, NULL, N'LIMITED')
WHERE
    index_id > 0;

IF @frag IS NULL
SET
    @frag = 0.00;

INSERT INTO
    dbo.log_resolucion_identidad_jugador(
        nivel_fragmentacion,
        filas_totales,
        descripcion_carga
    )
VALUES
(@frag, @filas, @descripcion_carga);

END;

GO