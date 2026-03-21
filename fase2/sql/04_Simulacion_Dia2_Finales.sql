SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    INSERT INTO dbo.partido (
        partido_id, anio, fecha, etapa, local_seleccion_id, visitante_seleccion_id,
        goles_local, goles_visitante, tiempo_extra, definicion_penales, penales_local, penales_visitante
    )
    SELECT v.partido_id, 2030, v.fecha, v.etapa, v.local_id, v.visitante_id,
           v.goles_local, v.goles_visitante, v.tiempo_extra, v.definicion_penales, v.penales_local, v.penales_visitante
    FROM (VALUES
        (6005, N'2030-06-20', N'Semifinal', 1, 4, 2, 0, 0, 0, NULL, NULL),
        (6006, N'2030-06-21', N'Semifinal', 3, 2, 1, 1, 1, 1, 4, 3),
        (6007, N'2030-06-25', N'Final',     1, 3, 2, 2, 1, 1, 5, 4)
    ) AS v(partido_id, fecha, etapa, local_id, visitante_id, goles_local, goles_visitante, tiempo_extra, definicion_penales, penales_local, penales_visitante)
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
        (6005, 1, 1,  N'Arquero',       N'1',  1),
        (6005, 1, 2,  N'Defensor',      N'2',  0),
        (6005, 1, 6,  N'Mediocampista', N'6',  0),
        (6005, 1, 9,  N'Delantero',     N'9',  0),
        (6005, 4, 34, N'Arquero',       N'1',  1),
        (6005, 4, 35, N'Defensor',      N'2',  0),
        (6005, 4, 39, N'Mediocampista', N'6',  0),
        (6005, 4, 42, N'Delantero',     N'9',  0),

        (6006, 3, 23, N'Arquero',       N'1',  1),
        (6006, 3, 24, N'Defensor',      N'2',  0),
        (6006, 3, 28, N'Mediocampista', N'6',  0),
        (6006, 3, 31, N'Delantero',     N'9',  0),
        (6006, 2, 12, N'Arquero',       N'1',  1),
        (6006, 2, 13, N'Defensor',      N'2',  0),
        (6006, 2, 17, N'Mediocampista', N'6',  0),
        (6006, 2, 20, N'Delantero',     N'9',  0),

        (6007, 1, 1,  N'Arquero',       N'1',  1),
        (6007, 1, 3,  N'Defensor',      N'3',  0),
        (6007, 1, 7,  N'Mediocampista', N'7',  0),
        (6007, 1, 10, N'Delantero',     N'10', 0),
        (6007, 3, 23, N'Arquero',       N'1',  1),
        (6007, 3, 25, N'Defensor',      N'3',  0),
        (6007, 3, 29, N'Mediocampista', N'7',  0),
        (6007, 3, 32, N'Delantero',     N'10', 0)
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
        (8011, 6005, 1,  9,  N'34', 0, 0),
        (8012, 6005, 1, 10,  N'81', 0, 0),
        (8013, 6006, 3, 31,  N'50', 0, 0),
        (8014, 6006, 2, 20,  N'88', 0, 0),
        (8015, 6007, 1,  9,  N'12', 0, 0),
        (8016, 6007, 3, 31,  N'27', 0, 0),
        (8017, 6007, 1, 10,  N'95', 0, 0),
        (8018, 6007, 3, 32,  N'111',0, 0)
    ) AS g(gol_id, partido_id, seleccion_id, jugador_id, minuto, es_penal, es_autogol)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.gol x
        WHERE x.gol_id = g.gol_id
    );

    INSERT INTO dbo.tarjeta (tarjeta_id, partido_id, seleccion_id, jugador_id, tipo, minuto)
    SELECT t.tarjeta_id, t.partido_id, t.seleccion_id, t.jugador_id, t.tipo, t.minuto
    FROM (VALUES
        (9007, 6005, 1, 2,  N'amarilla', N'41'),
        (9008, 6006, 2, 17, N'amarilla', N'58'),
        (9009, 6007, 1, 7,  N'amarilla', N'67'),
        (9010, 6007, 3, 29, N'amarilla', N'74')
    ) AS t(tarjeta_id, partido_id, seleccion_id, jugador_id, tipo, minuto)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.tarjeta x
        WHERE x.tarjeta_id = t.tarjeta_id
    );

    INSERT INTO dbo.cambio (cambio_id, partido_id, seleccion_id, jugador_sale_id, jugador_entra_id, minuto)
    SELECT c.cambio_id, c.partido_id, c.seleccion_id, c.jugador_sale_id, c.jugador_entra_id, c.minuto
    FROM (VALUES
        (10005, 6005, 1, 10, 11, N'72'),
        (10006, 6006, 3, 31, 33, N'78'),
        (10007, 6007, 1, 9,  11, N'105'),
        (10008, 6007, 3, 32, 33, N'109')
    ) AS c(cambio_id, partido_id, seleccion_id, jugador_sale_id, jugador_entra_id, minuto)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.cambio x
        WHERE x.cambio_id = c.cambio_id
    );

    INSERT INTO dbo.penal (penal_id, partido_id, seleccion_id, orden, jugador_id, resultado)
    SELECT p.penal_id, p.partido_id, p.seleccion_id, p.orden, p.jugador_id, p.resultado
    FROM (VALUES
        (11001, 6006, 3, 1, 31, N'Gol'),
        (11002, 6006, 2, 1, 20, N'Gol'),
        (11003, 6006, 3, 2, 32, N'Gol'),
        (11004, 6006, 2, 2, 21, N'Atajado'),
        (11005, 6007, 1, 1, 9,  N'Gol'),
        (11006, 6007, 3, 1, 31, N'Gol'),
        (11007, 6007, 1, 2, 10, N'Gol'),
        (11008, 6007, 3, 2, 32, N'Fuera')
    ) AS p(penal_id, partido_id, seleccion_id, orden, jugador_id, resultado)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.penal x
        WHERE x.penal_id = p.penal_id
    );

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;
    THROW;
END CATCH;
GO

EXEC dbo.sp_registrar_logs_diarios @descripcion_carga = N'Carga Masiva Día 2 - Finales 2030';
GO
