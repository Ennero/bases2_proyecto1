SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    IF (
        SELECT COUNT(*)
        FROM dbo.seleccion s
        WHERE s.seleccion_id IN (1, 2, 3, 4)
    ) < 4
    BEGIN
        THROW 50001, 'Faltan selecciones requeridas (IDs 1,2,3,4) en dbo.seleccion.', 1;
    END;

    IF EXISTS (
        SELECT TOP (44) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS jugador_id
        FROM sys.all_objects
        EXCEPT
        SELECT jugador_id FROM dbo.jugador WHERE jugador_id BETWEEN 1 AND 44
    )
    BEGIN
        THROW 50002, 'Faltan jugadores requeridos (IDs del 1 al 44) en dbo.jugador.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.mundial WHERE anio = 2030)
    BEGIN
        INSERT INTO dbo.mundial (anio, sede, equipos, partidos_jugados, goles_total)
        VALUES (2030, N'Ficticio', 4, 7, 0);
    END;

    DECLARE @selecciones_2030 TABLE (
        seleccion_id BIGINT NOT NULL,
        posicion INT NOT NULL,
        etapa NVARCHAR(191) NOT NULL,
        grupo NVARCHAR(16) NOT NULL,
        pts INT NOT NULL,
        pj INT NOT NULL,
        pg INT NOT NULL,
        pe INT NOT NULL,
        pp INT NOT NULL,
        gf INT NOT NULL,
        gc INT NOT NULL,
        dif INT NOT NULL,
        clasificado BIT NOT NULL,
        participo BIT NOT NULL
    );

    INSERT INTO @selecciones_2030 (
        seleccion_id, posicion, etapa, grupo, pts, pj, pg, pe, pp, gf, gc, dif, clasificado, participo
    )
    VALUES
        (1, 1, N'Final',       N'A', 0, 0, 0, 0, 0, 0, 0, 0, 1, 1),
        (2, 2, N'Semifinal',   N'A', 0, 0, 0, 0, 0, 0, 0, 0, 1, 1),
        (3, 3, N'Final',       N'A', 0, 0, 0, 0, 0, 0, 0, 0, 1, 1),
        (4, 4, N'Semifinal',   N'A', 0, 0, 0, 0, 0, 0, 0, 0, 1, 1);

    INSERT INTO dbo.participacion_mundial (
        anio, seleccion_id, posicion, etapa, pts, pj, pg, pe, pp, gf, gc, dif, participo
    )
    SELECT
        2030,
        s.seleccion_id,
        s.posicion,
        s.etapa,
        s.pts,
        s.pj,
        s.pg,
        s.pe,
        s.pp,
        s.gf,
        s.gc,
        s.dif,
        s.participo
    FROM @selecciones_2030 AS s
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.participacion_mundial pm
        WHERE pm.anio = 2030
          AND pm.seleccion_id = s.seleccion_id
    );

    INSERT INTO dbo.grupo (
        anio, grupo, posicion, seleccion_id, pts, pj, pg, pe, pp, gf, gc, dif, clasificado
    )
    SELECT
        2030,
        s.grupo,
        s.posicion,
        s.seleccion_id,
        s.pts,
        s.pj,
        s.pg,
        s.pe,
        s.pp,
        s.gf,
        s.gc,
        s.dif,
        s.clasificado
    FROM @selecciones_2030 AS s
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.grupo g
        WHERE g.anio = 2030
          AND g.grupo = s.grupo
          AND g.seleccion_id = s.seleccion_id
    );

    DECLARE @plantel_2030 TABLE (
        anio INT NOT NULL,
        seleccion_id BIGINT NOT NULL,
        jugador_id BIGINT NOT NULL,
        posicion NVARCHAR(64) NULL,
        camiseta NVARCHAR(16) NULL,
        club NVARCHAR(191) NULL
    );

    INSERT INTO @plantel_2030 (anio, seleccion_id, jugador_id, posicion, camiseta, club)
    VALUES
        (2030, 1,  1, N'Arquero',      N'1',  N'Club A1'),
        (2030, 1,  2, N'Defensor',     N'2',  N'Club A2'),
        (2030, 1,  3, N'Defensor',     N'3',  N'Club A3'),
        (2030, 1,  4, N'Defensor',     N'4',  N'Club A4'),
        (2030, 1,  5, N'Defensor',     N'5',  N'Club A5'),
        (2030, 1,  6, N'Mediocampista',N'6',  N'Club A6'),
        (2030, 1,  7, N'Mediocampista',N'7',  N'Club A7'),
        (2030, 1,  8, N'Mediocampista',N'8',  N'Club A8'),
        (2030, 1,  9, N'Delantero',    N'9',  N'Club A9'),
        (2030, 1, 10, N'Delantero',    N'10', N'Club A10'),
        (2030, 1, 11, N'Delantero',    N'11', N'Club A11'),

        (2030, 2, 12, N'Arquero',      N'1',  N'Club B1'),
        (2030, 2, 13, N'Defensor',     N'2',  N'Club B2'),
        (2030, 2, 14, N'Defensor',     N'3',  N'Club B3'),
        (2030, 2, 15, N'Defensor',     N'4',  N'Club B4'),
        (2030, 2, 16, N'Defensor',     N'5',  N'Club B5'),
        (2030, 2, 17, N'Mediocampista',N'6',  N'Club B6'),
        (2030, 2, 18, N'Mediocampista',N'7',  N'Club B7'),
        (2030, 2, 19, N'Mediocampista',N'8',  N'Club B8'),
        (2030, 2, 20, N'Delantero',    N'9',  N'Club B9'),
        (2030, 2, 21, N'Delantero',    N'10', N'Club B10'),
        (2030, 2, 22, N'Delantero',    N'11', N'Club B11'),

        (2030, 3, 23, N'Arquero',      N'1',  N'Club C1'),
        (2030, 3, 24, N'Defensor',     N'2',  N'Club C2'),
        (2030, 3, 25, N'Defensor',     N'3',  N'Club C3'),
        (2030, 3, 26, N'Defensor',     N'4',  N'Club C4'),
        (2030, 3, 27, N'Defensor',     N'5',  N'Club C5'),
        (2030, 3, 28, N'Mediocampista',N'6',  N'Club C6'),
        (2030, 3, 29, N'Mediocampista',N'7',  N'Club C7'),
        (2030, 3, 30, N'Mediocampista',N'8',  N'Club C8'),
        (2030, 3, 31, N'Delantero',    N'9',  N'Club C9'),
        (2030, 3, 32, N'Delantero',    N'10', N'Club C10'),
        (2030, 3, 33, N'Delantero',    N'11', N'Club C11'),

        (2030, 4, 34, N'Arquero',      N'1',  N'Club D1'),
        (2030, 4, 35, N'Defensor',     N'2',  N'Club D2'),
        (2030, 4, 36, N'Defensor',     N'3',  N'Club D3'),
        (2030, 4, 37, N'Defensor',     N'4',  N'Club D4'),
        (2030, 4, 38, N'Defensor',     N'5',  N'Club D5'),
        (2030, 4, 39, N'Mediocampista',N'6',  N'Club D6'),
        (2030, 4, 40, N'Mediocampista',N'7',  N'Club D7'),
        (2030, 4, 41, N'Mediocampista',N'8',  N'Club D8'),
        (2030, 4, 42, N'Delantero',    N'9',  N'Club D9'),
        (2030, 4, 43, N'Delantero',    N'10', N'Club D10'),
        (2030, 4, 44, N'Delantero',    N'11', N'Club D11');

    INSERT INTO dbo.plantel_jugador (anio, seleccion_id, jugador_id, posicion, camiseta, club)
    SELECT
        p.anio,
        p.seleccion_id,
        p.jugador_id,
        p.posicion,
        p.camiseta,
        p.club
    FROM @plantel_2030 p
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.plantel_jugador pj
        WHERE pj.anio = p.anio
          AND pj.seleccion_id = p.seleccion_id
          AND pj.jugador_id = p.jugador_id
    );

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;
    THROW;
END CATCH;
GO