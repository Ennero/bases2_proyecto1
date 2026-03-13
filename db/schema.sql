CREATE TABLE [mundial] (
  [anio] integer PRIMARY KEY,
  [sede] text,
  [equipos] integer,
  [partidos_jugados] integer,
  [goles_total] integer
)
GO

CREATE TABLE [seleccion] (
  [seleccion_id] bigint PRIMARY KEY,
  [nombre] text UNIQUE NOT NULL
)
GO

CREATE TABLE [seleccion_alias] (
  [alias_nombre] text PRIMARY KEY,
  [seleccion_id] bigint NOT NULL
)
GO

CREATE TABLE [jugador] (
  [jugador_id] bigint PRIMARY KEY,
  [nombre] text NOT NULL,
  [nombre_completo] text,
  [fecha_nacimiento] text,
  [lugar_nacimiento] text,
  [altura] text,
  [apodo] text,
  [sitio_web] text,
  [redes_sociales] text
)
GO

CREATE TABLE [entrenador] (
  [entrenador_id] bigint PRIMARY KEY,
  [nombre] text UNIQUE NOT NULL
)
GO

CREATE TABLE [partido] (
  [partido_id] bigint PRIMARY KEY,
  [anio] integer NOT NULL,
  [fecha] text,
  [etapa] text,
  [local_seleccion_id] bigint NOT NULL,
  [visitante_seleccion_id] bigint NOT NULL,
  [goles_local] integer,
  [goles_visitante] integer,
  [tiempo_extra] boolean NOT NULL DEFAULT (false),
  [definicion_penales] boolean NOT NULL DEFAULT (false),
  [penales_local] integer,
  [penales_visitante] integer
)
GO

CREATE TABLE [aparicion_partido] (
  [partido_id] bigint NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [jugador_id] bigint NOT NULL,
  [posicion] text,
  [camiseta] text,
  [seccion] nvarchar(255) NOT NULL CHECK ([seccion] IN ('titular', 'ingresado', 'suplente_no_jugo')) NOT NULL,
  [es_capitan] boolean NOT NULL DEFAULT (false),
  PRIMARY KEY ([partido_id], [seleccion_id], [jugador_id], [seccion])
)
GO

CREATE TABLE [direccion_tecnica_partido] (
  [partido_id] bigint NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [entrenador_id] bigint NOT NULL,
  PRIMARY KEY ([partido_id], [seleccion_id], [entrenador_id])
)
GO

CREATE TABLE [gol] (
  [gol_id] bigint PRIMARY KEY,
  [partido_id] bigint NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [jugador_id] bigint,
  [minuto] text,
  [es_penal] boolean NOT NULL DEFAULT (false),
  [es_autogol] boolean NOT NULL DEFAULT (false)
)
GO

CREATE TABLE [tarjeta] (
  [tarjeta_id] bigint PRIMARY KEY,
  [partido_id] bigint NOT NULL,
  [seleccion_id] bigint,
  [jugador_id] bigint,
  [tipo] nvarchar(255) NOT NULL CHECK ([tipo] IN ('amarilla', 'roja')) NOT NULL,
  [minuto] text
)
GO

CREATE TABLE [cambio] (
  [cambio_id] bigint PRIMARY KEY,
  [partido_id] bigint NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [jugador_sale_id] bigint,
  [jugador_entra_id] bigint,
  [minuto] text
)
GO

CREATE TABLE [penal] (
  [penal_id] bigint PRIMARY KEY,
  [partido_id] bigint NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [orden] integer NOT NULL,
  [jugador_id] bigint,
  [resultado] text NOT NULL
)
GO

CREATE TABLE [grupo] (
  [anio] integer NOT NULL,
  [grupo] text NOT NULL,
  [posicion] integer,
  [seleccion_id] bigint NOT NULL,
  [pts] integer,
  [pj] integer,
  [pg] integer,
  [pe] integer,
  [pp] integer,
  [gf] integer,
  [gc] integer,
  [dif] integer,
  [clasificado] boolean,
  PRIMARY KEY ([anio], [grupo], [seleccion_id])
)
GO

CREATE TABLE [posicion_final] (
  [anio] integer NOT NULL,
  [posicion] integer NOT NULL,
  [seleccion_id] bigint NOT NULL,
  PRIMARY KEY ([anio], [posicion])
)
GO

CREATE TABLE [goleador] (
  [anio] integer NOT NULL,
  [jugador_id] bigint NOT NULL,
  [seleccion_id] bigint,
  [goles] integer,
  PRIMARY KEY ([anio], [jugador_id])
)
GO

CREATE TABLE [premio_jugador] (
  [anio] integer NOT NULL,
  [premio] text NOT NULL,
  [jugador_id] bigint NOT NULL,
  [seleccion_id] bigint,
  PRIMARY KEY ([anio], [premio], [jugador_id])
)
GO

CREATE TABLE [premio_seleccion] (
  [anio] integer NOT NULL,
  [premio] text NOT NULL,
  [seleccion_id] bigint NOT NULL,
  PRIMARY KEY ([anio], [premio], [seleccion_id])
)
GO

CREATE TABLE [plantel_jugador] (
  [anio] integer NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [jugador_id] bigint NOT NULL,
  [posicion] text,
  [camiseta] text,
  [club] text,
  PRIMARY KEY ([anio], [seleccion_id], [jugador_id])
)
GO

CREATE TABLE [plantel_entrenador] (
  [anio] integer NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [entrenador_id] bigint NOT NULL,
  PRIMARY KEY ([anio], [seleccion_id], [entrenador_id])
)
GO

CREATE TABLE [participacion_mundial] (
  [anio] integer NOT NULL,
  [seleccion_id] bigint NOT NULL,
  [posicion] integer,
  [etapa] text,
  [pts] integer,
  [pj] integer,
  [pg] integer,
  [pe] integer,
  [pp] integer,
  [gf] integer,
  [gc] integer,
  [dif] integer,
  [participo] boolean NOT NULL DEFAULT (true),
  PRIMARY KEY ([anio], [seleccion_id])
)
GO

CREATE TABLE [resolucion_identidad_jugador] (
  [resolucion_id] bigint PRIMARY KEY IDENTITY(1, 1),
  [source_table] nvarchar(255) NOT NULL CHECK ([source_table] IN ('gol', 'tarjeta', 'cambio_entrada', 'cambio_salida', 'penal')) NOT NULL,
  [source_event_id] bigint NOT NULL,
  [partido_id] bigint,
  [seleccion_id] bigint,
  [jugador_nombre_raw] text NOT NULL,
  [minuto] text,
  [metodo] text NOT NULL DEFAULT 'manual',
  [confianza] decimal(5,2),
  [notas] text
)
GO

CREATE UNIQUE INDEX [partido_index_0] ON [partido] ("anio", "fecha", "etapa", "local_seleccion_id", "visitante_seleccion_id")
GO

CREATE UNIQUE INDEX [penal_index_1] ON [penal] ("partido_id", "seleccion_id", "orden")
GO

CREATE UNIQUE INDEX [posicion_final_index_2] ON [posicion_final] ("anio", "seleccion_id")
GO

CREATE UNIQUE INDEX [resolucion_identidad_jugador_index_3] ON [resolucion_identidad_jugador] ("source_table", "source_event_id")
GO

ALTER TABLE [seleccion_alias] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [partido] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [partido] ADD FOREIGN KEY ([local_seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [partido] ADD FOREIGN KEY ([visitante_seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [aparicion_partido] ADD FOREIGN KEY ([partido_id]) REFERENCES [partido] ([partido_id])
GO

ALTER TABLE [aparicion_partido] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [aparicion_partido] ADD FOREIGN KEY ([jugador_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [direccion_tecnica_partido] ADD FOREIGN KEY ([partido_id]) REFERENCES [partido] ([partido_id])
GO

ALTER TABLE [direccion_tecnica_partido] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [direccion_tecnica_partido] ADD FOREIGN KEY ([entrenador_id]) REFERENCES [entrenador] ([entrenador_id])
GO

ALTER TABLE [gol] ADD FOREIGN KEY ([partido_id]) REFERENCES [partido] ([partido_id])
GO

ALTER TABLE [gol] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [gol] ADD FOREIGN KEY ([jugador_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [tarjeta] ADD FOREIGN KEY ([partido_id]) REFERENCES [partido] ([partido_id])
GO

ALTER TABLE [tarjeta] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [tarjeta] ADD FOREIGN KEY ([jugador_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [cambio] ADD FOREIGN KEY ([partido_id]) REFERENCES [partido] ([partido_id])
GO

ALTER TABLE [cambio] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [cambio] ADD FOREIGN KEY ([jugador_sale_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [cambio] ADD FOREIGN KEY ([jugador_entra_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [penal] ADD FOREIGN KEY ([partido_id]) REFERENCES [partido] ([partido_id])
GO

ALTER TABLE [penal] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [penal] ADD FOREIGN KEY ([jugador_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [grupo] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [grupo] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [posicion_final] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [posicion_final] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [goleador] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [goleador] ADD FOREIGN KEY ([jugador_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [goleador] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [premio_jugador] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [premio_jugador] ADD FOREIGN KEY ([jugador_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [premio_jugador] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [premio_seleccion] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [premio_seleccion] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [plantel_jugador] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [plantel_jugador] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [plantel_jugador] ADD FOREIGN KEY ([jugador_id]) REFERENCES [jugador] ([jugador_id])
GO

ALTER TABLE [plantel_entrenador] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [plantel_entrenador] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [plantel_entrenador] ADD FOREIGN KEY ([entrenador_id]) REFERENCES [entrenador] ([entrenador_id])
GO

ALTER TABLE [participacion_mundial] ADD FOREIGN KEY ([anio]) REFERENCES [mundial] ([anio])
GO

ALTER TABLE [participacion_mundial] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO

ALTER TABLE [resolucion_identidad_jugador] ADD FOREIGN KEY ([partido_id]) REFERENCES [partido] ([partido_id])
GO

ALTER TABLE [resolucion_identidad_jugador] ADD FOREIGN KEY ([seleccion_id]) REFERENCES [seleccion] ([seleccion_id])
GO
