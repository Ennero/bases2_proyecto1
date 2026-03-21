SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    INSERT INTO dbo.partido (
        partido_id, anio, fecha, etapa, local_seleccion_id, visitante_seleccion_id,
        goles_local, goles_visitante, tiempo_extra, definicion_penales, penales_local, penales_visitante
    )
    SELECT v.partido_id, 2030, v.fecha, N'Fase de grupos', v.local_id, v.visitante_id,
           v.goles_local, v.goles_visitante, 0, 0, NULL, NULL
    FROM (VALUES
        (6001, N'2030-06-10', 1, 2, 2, 1),
        (6002, N'2030-06-10', 3, 4, 1, 1),
        (6003, N'2030-06-14', 1, 3, 0, 1),
        (6004, N'2030-06-14', 2, 4, 2, 2)
    ) AS v(partido_id, fecha, local_id, visitante_id, goles_local, goles_visitante)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.partido p
        WHERE p.partido_id = v.partido_id
    );

    INSERT INTO dbo.aparicion_partido (
        partido_id, seleccion_id, jugador_id, posicion, camiseta, seccion, es_capitan
    )
    SELECT a.partido_id, a.seleccion_id, a.jugador_id, a.posicion, a.camiseta, N'titular', a.es_capitan
    FROM (VALUES
        (6001, 1, 1,  N'Arquero',       N'1',  1),
        (6001, 1, 2,  N'Defensor',      N'2',  0),
        (6001, 1, 6,  N'Mediocampista', N'6',  0),
        (6001, 1, 9,  N'Delantero',     N'9',  0),
        (6001, 2, 12, N'Arquero',       N'1',  1),
        (6001, 2, 13, N'Defensor',      N'2',  0),
        (6001, 2, 17, N'Mediocampista', N'6',  0),
        (6001, 2, 20, N'Delantero',     N'9',  0),

        (6002, 3, 23, N'Arquero',       N'1',  1),
        (6002, 3, 24, N'Defensor',      N'2',  0),
        (6002, 3, 28, N'Mediocampista', N'6',  0),
        (6002, 3, 31, N'Delantero',     N'9',  0),
        (6002, 4, 34, N'Arquero',       N'1',  1),
        (6002, 4, 35, N'Defensor',      N'2',  0),
        (6002, 4, 39, N'Mediocampista', N'6',  0),
        (6002, 4, 42, N'Delantero',     N'9',  0),

        (6003, 1, 1,  N'Arquero',       N'1',  1),
        (6003, 1, 3,  N'Defensor',      N'3',  0),
        (6003, 1, 7,  N'Mediocampista', N'7',  0),
        (6003, 1, 10, N'Delantero',     N'10', 0),
        (6003, 3, 23, N'Arquero',       N'1',  1),
        (6003, 3, 25, N'Defensor',      N'3',  0),
        (6003, 3, 29, N'Mediocampista', N'7',  0),
        (6003, 3, 32, N'Delantero',     N'10', 0),

        (6004, 2, 12, N'Arquero',       N'1',  1),
        (6004, 2, 14, N'Defensor',      N'3',  0),
        (6004, 2, 18, N'Mediocampista', N'7',  0),
        (6004, 2, 21, N'Delantero',     N'10', 0),
        (6004, 4, 34, N'Arquero',       N'1',  1),
        (6004, 4, 36, N'Defensor',      N'3',  0),
        (6004, 4, 40, N'Mediocampista', N'7',  0),
        (6004, 4, 43, N'Delantero',     N'10', 0)
    ) AS a(partido_id, seleccion_id, jugador_id, posicion, camiseta, es_capitan)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.aparicion_partido ap
        WHERE ap.partido_id = a.partido_id
          AND ap.seleccion_id = a.seleccion_id
          AND ap.jugador_id = a.jugador_id
          AND ap.seccion = N'titular'
    );

    INSERT INTO dbo.gol (gol_id, partido_id, seleccion_id, jugador_id, minuto, es_penal, es_autogol)
    SELECT g.gol_id, g.partido_id, g.seleccion_id, g.jugador_id, g.minuto, g.es_penal, g.es_autogol
    FROM (VALUES
        (8001, 6001, 1,  9,  N'15', 0, 0),
        (8002, 6001, 1, 10,  N'60', 0, 0),
        (8003, 6001, 2, 20,  N'77', 0, 0),
        (8004, 6002, 3, 31,  N'22', 0, 0),
        (8005, 6002, 4, 42,  N'83', 0, 0),
        (8006, 6003, 3, 32,  N'55', 0, 0),
        (8007, 6004, 2, 21,  N'18', 0, 0),
        (8008, 6004, 2, 20,  N'71', 0, 0),
        (8009, 6004, 4, 43,  N'79', 0, 0),
        (8010, 6004, 4, 42,  N'88', 0, 0)
    ) AS g(gol_id, partido_id, seleccion_id, jugador_id, minuto, es_penal, es_autogol)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.gol x
        WHERE x.gol_id = g.gol_id
    );

    INSERT INTO dbo.tarjeta (tarjeta_id, partido_id, seleccion_id, jugador_id, tipo, minuto)
    SELECT t.tarjeta_id, t.partido_id, t.seleccion_id, t.jugador_id, t.tipo, t.minuto
    FROM (VALUES
        (9001, 6001, 1, 2,  N'amarilla', N'35'),
        (9002, 6001, 2, 13, N'amarilla', N'66'),
        (9003, 6002, 3, 24, N'amarilla', N'48'),
        (9004, 6003, 1, 7,  N'roja',     N'73'),
        (9005, 6004, 2, 18, N'amarilla', N'42'),
        (9006, 6004, 4, 40, N'amarilla', N'64')
    ) AS t(tarjeta_id, partido_id, seleccion_id, jugador_id, tipo, minuto)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.tarjeta x
        WHERE x.tarjeta_id = t.tarjeta_id
    );

    INSERT INTO dbo.cambio (cambio_id, partido_id, seleccion_id, jugador_sale_id, jugador_entra_id, minuto)
    SELECT c.cambio_id, c.partido_id, c.seleccion_id, c.jugador_sale_id, c.jugador_entra_id, c.minuto
    FROM (VALUES
        (10001, 6001, 1, 10, 11, N'70'),
        (10002, 6002, 4, 42, 44, N'65'),
        (10003, 6003, 3, 31, 33, N'75'),
        (10004, 6004, 2, 20, 22, N'80')
    ) AS c(cambio_id, partido_id, seleccion_id, jugador_sale_id, jugador_entra_id, minuto)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.cambio x
        WHERE x.cambio_id = c.cambio_id
    );

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;
    THROW;
END CATCH;
GO

EXEC dbo.sp_registrar_logs_diarios @descripcion_carga = N'Carga Masiva Día 1 - Grupos 2030';
GO
