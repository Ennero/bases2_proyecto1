SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.log_mundial', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_mundial (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_seleccion', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_seleccion (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_seleccion_alias', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_seleccion_alias (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_jugador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_jugador (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_entrenador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_entrenador (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_partido', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_partido (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_aparicion_partido', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_aparicion_partido (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_direccion_tecnica_partido', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_direccion_tecnica_partido (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_gol', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_gol (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_tarjeta', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_tarjeta (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_cambio', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_cambio (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_penal', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_penal (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_grupo', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_grupo (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_posicion_final', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_posicion_final (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_goleador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_goleador (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_premio_jugador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_premio_jugador (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_premio_seleccion', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_premio_seleccion (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_plantel_jugador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_plantel_jugador (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_plantel_entrenador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_plantel_entrenador (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_participacion_mundial', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_participacion_mundial (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'dbo.log_resolucion_identidad_jugador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.log_resolucion_identidad_jugador (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_registro DATETIME DEFAULT GETDATE(),
        nivel_fragmentacion DECIMAL(5,2),
        filas_totales INT,
        descripcion_carga NVARCHAR(255)
    );
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_registrar_logs_diarios
    @descripcion_carga NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @tablas TABLE (
        schema_name SYSNAME NOT NULL,
        table_name SYSNAME NOT NULL,
        log_table_name SYSNAME NOT NULL
    );

    INSERT INTO @tablas (schema_name, table_name, log_table_name)
    VALUES
        (N'dbo', N'mundial', N'log_mundial'),
        (N'dbo', N'seleccion', N'log_seleccion'),
        (N'dbo', N'seleccion_alias', N'log_seleccion_alias'),
        (N'dbo', N'jugador', N'log_jugador'),
        (N'dbo', N'entrenador', N'log_entrenador'),
        (N'dbo', N'partido', N'log_partido'),
        (N'dbo', N'aparicion_partido', N'log_aparicion_partido'),
        (N'dbo', N'direccion_tecnica_partido', N'log_direccion_tecnica_partido'),
        (N'dbo', N'gol', N'log_gol'),
        (N'dbo', N'tarjeta', N'log_tarjeta'),
        (N'dbo', N'cambio', N'log_cambio'),
        (N'dbo', N'penal', N'log_penal'),
        (N'dbo', N'grupo', N'log_grupo'),
        (N'dbo', N'posicion_final', N'log_posicion_final'),
        (N'dbo', N'goleador', N'log_goleador'),
        (N'dbo', N'premio_jugador', N'log_premio_jugador'),
        (N'dbo', N'premio_seleccion', N'log_premio_seleccion'),
        (N'dbo', N'plantel_jugador', N'log_plantel_jugador'),
        (N'dbo', N'plantel_entrenador', N'log_plantel_entrenador'),
        (N'dbo', N'participacion_mundial', N'log_participacion_mundial'),
        (N'dbo', N'resolucion_identidad_jugador', N'log_resolucion_identidad_jugador');

    DECLARE @schema_name SYSNAME;
    DECLARE @table_name SYSNAME;
    DECLARE @log_table_name SYSNAME;
    DECLARE @table_object_id INT;
    DECLARE @filas_totales BIGINT;
    DECLARE @nivel_fragmentacion DECIMAL(5,2);
    DECLARE @sql NVARCHAR(MAX);

    DECLARE c_tablas CURSOR LOCAL FAST_FORWARD FOR
        SELECT schema_name, table_name, log_table_name
        FROM @tablas;

    OPEN c_tablas;

    FETCH NEXT FROM c_tablas INTO @schema_name, @table_name, @log_table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @table_object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name));

        SELECT @filas_totales = ISNULL(SUM(ps.row_count), 0)
        FROM sys.dm_db_partition_stats AS ps
        WHERE ps.object_id = @table_object_id
          AND ps.index_id IN (0, 1);

        SELECT TOP (1)
            @nivel_fragmentacion = TRY_CONVERT(DECIMAL(5,2), ips.avg_fragmentation_in_percent)
        FROM sys.dm_db_index_physical_stats(DB_ID(), @table_object_id, NULL, NULL, N'LIMITED') AS ips
        INNER JOIN sys.indexes AS i
            ON i.object_id = ips.object_id
           AND i.index_id = ips.index_id
        WHERE ips.index_id > 0
        ORDER BY
            CASE WHEN i.is_primary_key = 1 THEN 0 ELSE 1 END,
            ips.index_id;

        IF @nivel_fragmentacion IS NULL
            SET @nivel_fragmentacion = CAST(0.00 AS DECIMAL(5,2));

        SET @sql = N'
            INSERT INTO ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@log_table_name) + N' (
                nivel_fragmentacion,
                filas_totales,
                descripcion_carga
            )
            VALUES (
                @p_nivel_fragmentacion,
                @p_filas_totales,
                @p_descripcion_carga
            );';

        EXEC sys.sp_executesql
            @sql,
            N'@p_nivel_fragmentacion DECIMAL(5,2), @p_filas_totales INT, @p_descripcion_carga NVARCHAR(255)',
            @p_nivel_fragmentacion = @nivel_fragmentacion,
            @p_filas_totales = TRY_CONVERT(INT, @filas_totales),
            @p_descripcion_carga = @descripcion_carga;

        FETCH NEXT FROM c_tablas INTO @schema_name, @table_name, @log_table_name;
    END

    CLOSE c_tablas;
    DEALLOCATE c_tablas;
END;
GO
