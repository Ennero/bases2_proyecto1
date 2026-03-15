-- SQL Server schema for a strictly normalized World Cup model
-- Target: SQL Server 2019+

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.v_evento_jugador_pendiente', N'V') IS NOT NULL
    DROP VIEW dbo.v_evento_jugador_pendiente;
GO

IF OBJECT_ID(N'dbo.resolucion_identidad_jugador', N'U') IS NOT NULL DROP TABLE dbo.resolucion_identidad_jugador;
IF OBJECT_ID(N'dbo.participacion_mundial', N'U') IS NOT NULL DROP TABLE dbo.participacion_mundial;
IF OBJECT_ID(N'dbo.plantel_entrenador', N'U') IS NOT NULL DROP TABLE dbo.plantel_entrenador;
IF OBJECT_ID(N'dbo.plantel_jugador', N'U') IS NOT NULL DROP TABLE dbo.plantel_jugador;
IF OBJECT_ID(N'dbo.premio_seleccion', N'U') IS NOT NULL DROP TABLE dbo.premio_seleccion;
IF OBJECT_ID(N'dbo.premio_jugador', N'U') IS NOT NULL DROP TABLE dbo.premio_jugador;
IF OBJECT_ID(N'dbo.goleador', N'U') IS NOT NULL DROP TABLE dbo.goleador;
IF OBJECT_ID(N'dbo.posicion_final', N'U') IS NOT NULL DROP TABLE dbo.posicion_final;
IF OBJECT_ID(N'dbo.grupo', N'U') IS NOT NULL DROP TABLE dbo.grupo;
IF OBJECT_ID(N'dbo.penal', N'U') IS NOT NULL DROP TABLE dbo.penal;
IF OBJECT_ID(N'dbo.cambio', N'U') IS NOT NULL DROP TABLE dbo.cambio;
IF OBJECT_ID(N'dbo.tarjeta', N'U') IS NOT NULL DROP TABLE dbo.tarjeta;
IF OBJECT_ID(N'dbo.gol', N'U') IS NOT NULL DROP TABLE dbo.gol;
IF OBJECT_ID(N'dbo.direccion_tecnica_partido', N'U') IS NOT NULL DROP TABLE dbo.direccion_tecnica_partido;
IF OBJECT_ID(N'dbo.aparicion_partido', N'U') IS NOT NULL DROP TABLE dbo.aparicion_partido;
IF OBJECT_ID(N'dbo.partido', N'U') IS NOT NULL DROP TABLE dbo.partido;
IF OBJECT_ID(N'dbo.entrenador', N'U') IS NOT NULL DROP TABLE dbo.entrenador;
IF OBJECT_ID(N'dbo.jugador', N'U') IS NOT NULL DROP TABLE dbo.jugador;
IF OBJECT_ID(N'dbo.seleccion_alias', N'U') IS NOT NULL DROP TABLE dbo.seleccion_alias;
IF OBJECT_ID(N'dbo.seleccion', N'U') IS NOT NULL DROP TABLE dbo.seleccion;
IF OBJECT_ID(N'dbo.mundial', N'U') IS NOT NULL DROP TABLE dbo.mundial;
GO

CREATE TABLE dbo.mundial (
    anio INT NOT NULL PRIMARY KEY,
    sede NVARCHAR(191) NULL,
    equipos INT NULL,
    partidos_jugados INT NULL,
    goles_total INT NULL
);
GO

CREATE TABLE dbo.seleccion (
    seleccion_id BIGINT NOT NULL PRIMARY KEY,
    nombre NVARCHAR(191) NOT NULL,
    CONSTRAINT uq_seleccion_nombre UNIQUE (nombre)
);
GO

CREATE TABLE dbo.seleccion_alias (
    alias_nombre NVARCHAR(191) NOT NULL PRIMARY KEY,
    seleccion_id BIGINT NOT NULL,
    CONSTRAINT fk_seleccion_alias_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE TABLE dbo.jugador (
    jugador_id BIGINT NOT NULL PRIMARY KEY,
    nombre NVARCHAR(191) NOT NULL,
    nombre_completo NVARCHAR(191) NULL,
    fecha_nacimiento NVARCHAR(64) NULL,
    lugar_nacimiento NVARCHAR(191) NULL,
    altura NVARCHAR(64) NULL,
    apodo NVARCHAR(191) NULL,
    sitio_web NVARCHAR(255) NULL,
    redes_sociales NVARCHAR(255) NULL
);
GO

CREATE TABLE dbo.entrenador (
    entrenador_id BIGINT NOT NULL PRIMARY KEY,
    nombre NVARCHAR(191) NOT NULL,
    CONSTRAINT uq_entrenador_nombre UNIQUE (nombre)
);
GO

CREATE TABLE dbo.partido (
    partido_id BIGINT NOT NULL PRIMARY KEY,
    anio INT NOT NULL,
    fecha NVARCHAR(64) NULL,
    etapa NVARCHAR(191) NULL,
    local_seleccion_id BIGINT NOT NULL,
    visitante_seleccion_id BIGINT NOT NULL,
    goles_local INT NULL,
    goles_visitante INT NULL,
    tiempo_extra BIT NOT NULL CONSTRAINT df_partido_tiempo_extra DEFAULT (0),
    definicion_penales BIT NOT NULL CONSTRAINT df_partido_definicion_penales DEFAULT (0),
    penales_local INT NULL,
    penales_visitante INT NULL,
    CONSTRAINT uq_partido_natural UNIQUE (anio, fecha, etapa, local_seleccion_id, visitante_seleccion_id),
    CONSTRAINT fk_partido_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_partido_local
        FOREIGN KEY (local_seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_partido_visitante
        FOREIGN KEY (visitante_seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE INDEX idx_partido_anio ON dbo.partido(anio);
CREATE INDEX idx_partido_local ON dbo.partido(local_seleccion_id);
CREATE INDEX idx_partido_visitante ON dbo.partido(visitante_seleccion_id);
GO

CREATE TABLE dbo.aparicion_partido (
    partido_id BIGINT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    jugador_id BIGINT NOT NULL,
    posicion NVARCHAR(64) NULL,
    camiseta NVARCHAR(16) NULL,
    seccion NVARCHAR(32) NOT NULL,
    es_capitan BIT NOT NULL CONSTRAINT df_aparicion_es_capitan DEFAULT (0),
    CONSTRAINT pk_aparicion_partido PRIMARY KEY (partido_id, seleccion_id, jugador_id, seccion),
    CONSTRAINT ck_aparicion_seccion CHECK (seccion IN (N'titular', N'ingresado', N'suplente_no_jugo')),
    CONSTRAINT fk_aparicion_partido
        FOREIGN KEY (partido_id) REFERENCES dbo.partido(partido_id),
    CONSTRAINT fk_aparicion_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_aparicion_jugador
        FOREIGN KEY (jugador_id) REFERENCES dbo.jugador(jugador_id)
);
GO

CREATE TABLE dbo.direccion_tecnica_partido (
    partido_id BIGINT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    entrenador_id BIGINT NOT NULL,
    CONSTRAINT pk_direccion_tecnica_partido PRIMARY KEY (partido_id, seleccion_id, entrenador_id),
    CONSTRAINT fk_dtp_partido
        FOREIGN KEY (partido_id) REFERENCES dbo.partido(partido_id),
    CONSTRAINT fk_dtp_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_dtp_entrenador
        FOREIGN KEY (entrenador_id) REFERENCES dbo.entrenador(entrenador_id)
);
GO

CREATE TABLE dbo.gol (
    gol_id BIGINT NOT NULL PRIMARY KEY,
    partido_id BIGINT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    jugador_id BIGINT NULL,
    minuto NVARCHAR(32) NULL,
    es_penal BIT NOT NULL CONSTRAINT df_gol_es_penal DEFAULT (0),
    es_autogol BIT NOT NULL CONSTRAINT df_gol_es_autogol DEFAULT (0),
    CONSTRAINT fk_gol_partido
        FOREIGN KEY (partido_id) REFERENCES dbo.partido(partido_id),
    CONSTRAINT fk_gol_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_gol_jugador
        FOREIGN KEY (jugador_id) REFERENCES dbo.jugador(jugador_id)
);
GO

CREATE INDEX idx_gol_partido ON dbo.gol(partido_id);
GO

CREATE TABLE dbo.tarjeta (
    tarjeta_id BIGINT NOT NULL PRIMARY KEY,
    partido_id BIGINT NOT NULL,
    seleccion_id BIGINT NULL,
    jugador_id BIGINT NULL,
    tipo NVARCHAR(16) NOT NULL,
    minuto NVARCHAR(32) NULL,
    CONSTRAINT ck_tarjeta_tipo CHECK (tipo IN (N'amarilla', N'roja')),
    CONSTRAINT fk_tarjeta_partido
        FOREIGN KEY (partido_id) REFERENCES dbo.partido(partido_id),
    CONSTRAINT fk_tarjeta_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_tarjeta_jugador
        FOREIGN KEY (jugador_id) REFERENCES dbo.jugador(jugador_id)
);
GO

CREATE INDEX idx_tarjeta_partido ON dbo.tarjeta(partido_id);
GO

CREATE TABLE dbo.cambio (
    cambio_id BIGINT NOT NULL PRIMARY KEY,
    partido_id BIGINT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    jugador_sale_id BIGINT NULL,
    jugador_entra_id BIGINT NULL,
    minuto NVARCHAR(32) NULL,
    CONSTRAINT fk_cambio_partido
        FOREIGN KEY (partido_id) REFERENCES dbo.partido(partido_id),
    CONSTRAINT fk_cambio_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_cambio_jugador_sale
        FOREIGN KEY (jugador_sale_id) REFERENCES dbo.jugador(jugador_id),
    CONSTRAINT fk_cambio_jugador_entra
        FOREIGN KEY (jugador_entra_id) REFERENCES dbo.jugador(jugador_id)
);
GO

CREATE INDEX idx_cambio_partido ON dbo.cambio(partido_id);
GO

CREATE TABLE dbo.penal (
    penal_id BIGINT NOT NULL PRIMARY KEY,
    partido_id BIGINT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    orden INT NOT NULL,
    jugador_id BIGINT NULL,
    resultado NVARCHAR(32) NOT NULL,
    CONSTRAINT uq_penal_orden UNIQUE (partido_id, seleccion_id, orden),
    CONSTRAINT fk_penal_partido
        FOREIGN KEY (partido_id) REFERENCES dbo.partido(partido_id),
    CONSTRAINT fk_penal_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_penal_jugador
        FOREIGN KEY (jugador_id) REFERENCES dbo.jugador(jugador_id)
);
GO

CREATE INDEX idx_penal_partido ON dbo.penal(partido_id);
GO

CREATE TABLE dbo.grupo (
    anio INT NOT NULL,
    grupo NVARCHAR(16) NOT NULL,
    posicion INT NULL,
    seleccion_id BIGINT NOT NULL,
    pts INT NULL,
    pj INT NULL,
    pg INT NULL,
    pe INT NULL,
    pp INT NULL,
    gf INT NULL,
    gc INT NULL,
    dif INT NULL,
    clasificado BIT NULL,
    CONSTRAINT pk_grupo PRIMARY KEY (anio, grupo, seleccion_id),
    CONSTRAINT fk_grupo_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_grupo_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE INDEX idx_grupo_anio_grupo ON dbo.grupo(anio, grupo);
GO

CREATE TABLE dbo.posicion_final (
    anio INT NOT NULL,
    posicion INT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    CONSTRAINT pk_posicion_final PRIMARY KEY (anio, posicion),
    CONSTRAINT fk_posicion_final_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_posicion_final_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE INDEX idx_posicion_final_anio ON dbo.posicion_final(anio);
GO

CREATE TABLE dbo.goleador (
    anio INT NOT NULL,
    jugador_id BIGINT NOT NULL,
    seleccion_id BIGINT NULL,
    goles INT NULL,
    CONSTRAINT pk_goleador PRIMARY KEY (anio, jugador_id),
    CONSTRAINT fk_goleador_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_goleador_jugador
        FOREIGN KEY (jugador_id) REFERENCES dbo.jugador(jugador_id),
    CONSTRAINT fk_goleador_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE TABLE dbo.premio_jugador (
    anio INT NOT NULL,
    premio NVARCHAR(191) NOT NULL,
    jugador_id BIGINT NOT NULL,
    seleccion_id BIGINT NULL,
    CONSTRAINT pk_premio_jugador PRIMARY KEY (anio, premio, jugador_id),
    CONSTRAINT fk_premio_jugador_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_premio_jugador_jugador
        FOREIGN KEY (jugador_id) REFERENCES dbo.jugador(jugador_id),
    CONSTRAINT fk_premio_jugador_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE TABLE dbo.premio_seleccion (
    anio INT NOT NULL,
    premio NVARCHAR(191) NOT NULL,
    seleccion_id BIGINT NOT NULL,
    CONSTRAINT pk_premio_seleccion PRIMARY KEY (anio, premio, seleccion_id),
    CONSTRAINT fk_premio_seleccion_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_premio_seleccion_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE TABLE dbo.plantel_jugador (
    anio INT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    jugador_id BIGINT NOT NULL,
    posicion NVARCHAR(64) NULL,
    camiseta NVARCHAR(16) NULL,
    club NVARCHAR(191) NULL,
    CONSTRAINT pk_plantel_jugador PRIMARY KEY (anio, seleccion_id, jugador_id),
    CONSTRAINT fk_plantel_jugador_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_plantel_jugador_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_plantel_jugador_jugador
        FOREIGN KEY (jugador_id) REFERENCES dbo.jugador(jugador_id)
);
GO

CREATE TABLE dbo.plantel_entrenador (
    anio INT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    entrenador_id BIGINT NOT NULL,
    CONSTRAINT pk_plantel_entrenador PRIMARY KEY (anio, seleccion_id, entrenador_id),
    CONSTRAINT fk_plantel_entrenador_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_plantel_entrenador_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id),
    CONSTRAINT fk_plantel_entrenador_entrenador
        FOREIGN KEY (entrenador_id) REFERENCES dbo.entrenador(entrenador_id)
);
GO

CREATE TABLE dbo.participacion_mundial (
    anio INT NOT NULL,
    seleccion_id BIGINT NOT NULL,
    posicion INT NULL,
    etapa NVARCHAR(191) NULL,
    pts INT NULL,
    pj INT NULL,
    pg INT NULL,
    pe INT NULL,
    pp INT NULL,
    gf INT NULL,
    gc INT NULL,
    dif INT NULL,
    participo BIT NOT NULL CONSTRAINT df_participacion_participo DEFAULT (1),
    CONSTRAINT pk_participacion_mundial PRIMARY KEY (anio, seleccion_id),
    CONSTRAINT fk_participacion_mundial
        FOREIGN KEY (anio) REFERENCES dbo.mundial(anio),
    CONSTRAINT fk_participacion_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE INDEX idx_participacion_anio ON dbo.participacion_mundial(anio);
GO

CREATE TABLE dbo.resolucion_identidad_jugador (
    resolucion_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    source_table NVARCHAR(32) NOT NULL,
    source_event_id BIGINT NOT NULL,
    partido_id BIGINT NULL,
    seleccion_id BIGINT NULL,
    jugador_nombre_raw NVARCHAR(191) NOT NULL,
    minuto NVARCHAR(32) NULL,
    metodo NVARCHAR(64) NOT NULL CONSTRAINT df_resolucion_metodo DEFAULT (N'manual'),
    confianza DECIMAL(5, 2) NULL,
    notas NVARCHAR(MAX) NULL,
    CONSTRAINT ck_resolucion_source_table
        CHECK (source_table IN (N'gol', N'tarjeta', N'cambio_entrada', N'cambio_salida', N'penal')),
    CONSTRAINT uq_resolucion_source UNIQUE (source_table, source_event_id),
    CONSTRAINT fk_resolucion_partido
        FOREIGN KEY (partido_id) REFERENCES dbo.partido(partido_id),
    CONSTRAINT fk_resolucion_seleccion
        FOREIGN KEY (seleccion_id) REFERENCES dbo.seleccion(seleccion_id)
);
GO

CREATE VIEW dbo.v_evento_jugador_pendiente AS
SELECT
    N'gol' AS source_table,
    g.gol_id AS source_event_id,
    g.partido_id,
    g.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, g.minuto) AS minuto
FROM dbo.gol AS g
LEFT JOIN dbo.resolucion_identidad_jugador AS r
    ON r.source_table = N'gol'
   AND r.source_event_id = g.gol_id
WHERE g.jugador_id IS NULL
UNION ALL
SELECT
    N'tarjeta' AS source_table,
    t.tarjeta_id AS source_event_id,
    t.partido_id,
    t.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, t.minuto) AS minuto
FROM dbo.tarjeta AS t
LEFT JOIN dbo.resolucion_identidad_jugador AS r
    ON r.source_table = N'tarjeta'
   AND r.source_event_id = t.tarjeta_id
WHERE t.jugador_id IS NULL
UNION ALL
SELECT
    N'cambio_entrada' AS source_table,
    c.cambio_id AS source_event_id,
    c.partido_id,
    c.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, c.minuto) AS minuto
FROM dbo.cambio AS c
LEFT JOIN dbo.resolucion_identidad_jugador AS r
    ON r.source_table = N'cambio_entrada'
   AND r.source_event_id = c.cambio_id
WHERE c.jugador_entra_id IS NULL
UNION ALL
SELECT
    N'cambio_salida' AS source_table,
    c.cambio_id AS source_event_id,
    c.partido_id,
    c.seleccion_id,
    r.jugador_nombre_raw,
    COALESCE(r.minuto, c.minuto) AS minuto
FROM dbo.cambio AS c
LEFT JOIN dbo.resolucion_identidad_jugador AS r
    ON r.source_table = N'cambio_salida'
   AND r.source_event_id = c.cambio_id
WHERE c.jugador_sale_id IS NULL
UNION ALL
SELECT
    N'penal' AS source_table,
    p.penal_id AS source_event_id,
    p.partido_id,
    p.seleccion_id,
    r.jugador_nombre_raw,
    r.minuto
FROM dbo.penal AS p
LEFT JOIN dbo.resolucion_identidad_jugador AS r
    ON r.source_table = N'penal'
   AND r.source_event_id = p.penal_id
WHERE p.jugador_id IS NULL;
GO
