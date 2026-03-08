# Base de datos normalizada de Mundiales

Este directorio contiene el esquema PostgreSQL, el ETL y el modelo lógico del proyecto ya llevados a una normalización estricta.

## Archivos

- `postgres_schema.sql`: crea tablas, llaves foráneas, restricciones, vista e índices.
- `postgres_etl.sql`: hace una carga completa por `TRUNCATE` + `\copy` desde los CSV finales.
- `modelo_wc.dbml`: representación lógica equivalente al esquema SQL.

## Criterios del modelo

- Las tablas están en singular.
- Los `slug` ya no se persisten como parte del modelo final.
- Los hechos referencian entidades mediante llaves técnicas (`seleccion_id`, `jugador_id`, `entrenador_id`, `partido_id`).
- Los premios y planteles se separaron por tipo para evitar tablas polimórficas o con roles mezclados.
- La resolución manual de identidades ambiguas quedó aislada en `resolucion_identidad_jugador`.

## Estructura general

El modelo queda dividido en cuatro áreas:

1. Catálogos: `mundial`, `seleccion`, `seleccion_alias`, `jugador`, `entrenador`.
2. Hechos por partido: `partido`, `aparicion_partido`, `direccion_tecnica_partido`, `gol`, `tarjeta`, `cambio`, `penal`.
3. Hechos por edición: `grupo`, `posicion_final`, `goleador`, `premio_jugador`, `premio_seleccion`, `plantel_jugador`, `plantel_entrenador`, `participacion_mundial`.
4. Apoyo operativo: `resolucion_identidad_jugador` y la vista `v_evento_jugador_pendiente`.

## Tablas principales

### `mundial`

Una fila por edición del torneo.

- `anio` es la llave primaria.
- `sede`, `equipos`, `partidos_jugados` y `goles_total` conservan el resumen agregado de la edición.

### `seleccion` y `seleccion_alias`

- `seleccion` guarda la entidad canónica de cada selección.
- `seleccion_alias` resuelve nombres históricos o alternativos hacia una sola selección canónica.

Esto evita duplicar países por cambios de nombre como `Alemania Occidental`, `URSS` o `Serbia y Montenegro`.

### `jugador` y `entrenador`

- `jugador` almacena datos descriptivos del jugador cuando la fuente los ofrece.
- `entrenador` queda separado para evitar mezclar técnicos con apariciones o planteles de jugadores.

### `partido`

Representa el encuentro en su grano natural de partido.

- Tiene FK a `mundial` por `anio`.
- Vincula al local y visitante mediante `local_seleccion_id` y `visitante_seleccion_id`.
- Conserva resultado numérico y banderas de prórroga o definición por penales.

### `aparicion_partido` y `direccion_tecnica_partido`

- `aparicion_partido` modela solo jugadores, diferenciando `titular`, `ingresado` y `suplente_no_jugo`.
- `direccion_tecnica_partido` modela por separado el cuerpo técnico del partido.

Esta separación elimina la mezcla previa entre jugadores y entrenadores dentro de una misma relación.

### `gol`, `tarjeta`, `cambio`, `penal`

Son hechos transaccionales por partido.

- Todos referencian `partido`.
- Cuando existe conciliación suficiente, enlazan también a `jugador` y `seleccion`.
- Si no es posible resolver al jugador con seguridad, el evento queda con `jugador_id` nulo y se registra en `resolucion_identidad_jugador`.

### `grupo` y `participacion_mundial`

No representan el mismo hecho:

- `grupo` captura el rendimiento dentro de la fase de grupos.
- `participacion_mundial` resume la participación completa de una selección en la edición.

Comparten algunas métricas, pero están a distinto grano analítico.

### `premio_jugador` y `premio_seleccion`

La tabla polimórfica anterior se eliminó.

- `premio_jugador` guarda premios cuyo destinatario es un jugador.
- `premio_seleccion` guarda premios cuyo destinatario es una selección.

### `plantel_jugador` y `plantel_entrenador`

El plantel también quedó separado por tipo de entidad.

- `plantel_jugador` almacena convocados y solo atributos propios de esa convocatoria, como posición, camiseta y club.
- `plantel_entrenador` relaciona selección, edición y técnico.

La fecha de nacimiento y la altura no permanecen en `plantel_jugador` porque dependen del jugador, no de la convocatoria.

### `resolucion_identidad_jugador`

Es una cola de conciliación manual o semiautomática para eventos donde no se pudo asignar `jugador_id` con suficiente confianza.

- `source_table` identifica el origen (`gol`, `tarjeta`, `cambio_entrada`, `cambio_salida`, `penal`).
- `source_event_id` apunta al identificador del hecho fuente.
- `partido_id`, `seleccion_id`, `jugador_nombre_raw`, `minuto`, `metodo`, `confianza` y `notas` documentan la resolución.

La vista `v_evento_jugador_pendiente` ayuda a localizar rápidamente eventos aún no conciliados.

Durante la normalización de CSV, esta tabla se llena automáticamente si el scraper detecta un evento cuyo nombre de jugador no pudo reconciliar con un `jugador_id`. Si no hay ambigüedades, el CSV se genera vacío, con encabezado, listo para una eventual carga manual.

## Carga de datos

### 1. Crear el esquema

```bash
psql -h <host> -U <user> -d <database> -f py/db/postgres_schema.sql
```

### 2. Ajustar rutas en `postgres_etl.sql`

Al inicio del archivo hay variables `\set` para cada CSV. Ejemplo:

```sql
\set f_partidos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/partido.csv'
```

Si la fuente que vas a cargar es la local, cambia esas rutas a `datos_normalizados_local`.

### 3. Ejecutar la carga completa

```bash
psql -h <host> -U <user> -d <database> -f py/db/postgres_etl.sql
```

El ETL asume un snapshot completo y por eso vacía las tablas antes de recargar.

## Validaciones rápidas

```sql
SELECT COUNT(*) AS mundial FROM mundial;
SELECT COUNT(*) AS seleccion FROM seleccion;
SELECT COUNT(*) AS jugador FROM jugador;
SELECT COUNT(*) AS entrenador FROM entrenador;
SELECT COUNT(*) AS partido FROM partido;
SELECT COUNT(*) AS gol FROM gol;
SELECT COUNT(*) AS premio_jugador FROM premio_jugador;
SELECT COUNT(*) AS premio_seleccion FROM premio_seleccion;
SELECT COUNT(*) AS plantel_jugador FROM plantel_jugador;
SELECT COUNT(*) AS plantel_entrenador FROM plantel_entrenador;
SELECT COUNT(*) AS participacion FROM participacion_mundial;
SELECT COUNT(*) AS pendientes_resolucion FROM v_evento_jugador_pendiente;
```