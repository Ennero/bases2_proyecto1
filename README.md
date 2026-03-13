# bases2_proyecto1

Proyecto de extracción y carga de datos históricos de los Mundiales de fútbol a un modelo relacional en SQL Server.

## Objetivo del proyecto

Construir un dataset limpio y normalizado para consultas históricas de Mundiales, con dos etapas claras:

1. Extracción (scraping).
2. Carga transaccional en una base relacional.

## Decisiones tomadas y por qué

### 1) Primero scraping local (HTML descargados)

Se usó `--origen local` al inicio para:

- poder depurar el parser sin depender de red,
- tener ejecuciones repetibles durante desarrollo,
- aislar errores de scraping versus errores de modelado.

Esto fue útil para estabilizar el pipeline, pero el espejo local no siempre contiene todo el sitio.

### 2) Luego scraping web (sitio en vivo)

Se pasó a `--origen web` para:

- completar faltantes del espejo local,
- obtener la versión más actualizada del contenido,
- generar un snapshot final más completo para carga.

Por eso la salida recomendada es `datos_normalizados_web/`.

### 3) Migración a SQL Server

El flujo final quedó en SQL Server para tener un solo stack de ejecución local y Docker:

- esquema SQL: `py/db/sqlserver_schema.sql` (T-SQL),
- ETL SQL: `py/db/sqlserver_etl.sql` (T-SQL),
- Docker con SQL Server 2022 y scripts de init en `docker/init/`.

### 4) Decisiones de modelado

- Tablas en singular y llaves técnicas (`*_id`) para estabilidad relacional.
- Separación de premios por tipo (`premio_jugador`, `premio_seleccion`).
- Separación de plantel por tipo (`plantel_jugador`, `plantel_entrenador`).
- Separación por grano analítico:
  - `grupo` = desempeño en fase de grupos.
  - `participacion_mundial` = campaña completa en la edición.
- `slug` se usa durante extracción, pero no como clave persistida final.

## Tabla que se llena "automáticamente"

Sí: `resolucion_identidad_jugador`.

- Se llena al cargar `resolucion_identidad_jugador.csv`.
- Ese CSV se genera automáticamente al normalizar datos.
- Si no hay ambigüedades, queda vacío con encabezado (archivo válido).
- En Docker, `docker/init/02_fix_csvs.sh` asegura que exista ese CSV (lo crea con encabezado si falta).

## Flujo activo del repositorio

- `py/scraping_normalizado.py`: scraper y normalizador principal.
- `py/db/sqlserver_schema.sql`: esquema SQL Server (T-SQL).
- `py/db/sqlserver_etl.sql`: carga de CSV en SQL Server.
- `py/db/modelo_wc.dbml`: modelo lógico.

## Inicio rápido

### 1. Preparar entorno Python

```powershell
.venv\Scripts\activate
pip install pandas beautifulsoup4
```

### 2. Generar CSV normalizados

#### Opción recomendada (web)

```powershell
.venv\Scripts\python.exe py\scraping_normalizado.py --origen web --salida .\datos_normalizados_web
```

#### Opción local (espejo HTML)

```powershell
.venv\Scripts\python.exe py\scraping_normalizado.py --origen local --html-dir .\html_descargados --salida .\datos_normalizados_local
```

### 3. Crear esquema en SQL Server

```bash
sqlcmd -S <host>,1433 -U sa -P <password> -C -d <basedatos> -i py/db/sqlserver_schema.sql
```

### 4. Cargar CSV en SQL Server

```bash
sqlcmd -S <host>,1433 -U sa -P <password> -C -d <basedatos> -i py/db/sqlserver_etl.sql -v CSV_DIR="./datos_normalizados_web"
```

## Docker (SQL Server)

```bash
docker compose up -d --build
```

El init hace:

1. `01_schema.sql`: crea base, tablas y vista.
2. `02_fix_csvs.sh`: limpia tipos, deduplica y garantiza `resolucion_identidad_jugador.csv`.
3. `03_etl.sql`: carga todos los CSV.

## Por qué existen estas tablas

### Catálogos

- `mundial`: una fila por edición.
- `seleccion`: selección canónica.
- `seleccion_alias`: equivalencias históricas de nombre.
- `jugador`: catálogo maestro de jugadores.
- `entrenador`: catálogo maestro de entrenadores.

### Hechos por partido

- `partido`: partido como unidad principal.
- `aparicion_partido`: participación individual por partido.
- `direccion_tecnica_partido`: técnicos que dirigieron el partido.
- `gol`: goles con metadatos.
- `tarjeta`: tarjetas por partido.
- `cambio`: sustituciones.
- `penal`: ejecuciones de tanda de penales.

### Hechos por edición

- `grupo`: tabla de posiciones por grupo.
- `posicion_final`: ranking final de la edición.
- `goleador`: goleadores por Mundial.
- `premio_jugador`: premios a jugadores.
- `premio_seleccion`: premios a selecciones.
- `plantel_jugador`: convocados por selección y edición.
- `plantel_entrenador`: técnicos de plantel por edición.
- `participacion_mundial`: resumen global de campaña por selección.

### Apoyo operativo

- `resolucion_identidad_jugador`: cola de conciliación de identidad cuando no se pudo mapear jugador con certeza.
- `v_evento_jugador_pendiente`: vista de eventos con jugador no resuelto.

## Diccionario corto de campos (tabla por tabla)

### mundial

- `anio`: edición del Mundial (PK).
- `sede`: país sede.
- `equipos`: cantidad de selecciones participantes.
- `partidos_jugados`: total de partidos disputados.
- `goles_total`: total de goles del torneo.

### seleccion

- `seleccion_id`: identificador técnico (PK).
- `nombre`: nombre canónico único.

### seleccion_alias

- `alias_nombre`: nombre alternativo o histórico (PK).
- `seleccion_id`: referencia a selección canónica.

### jugador

- `jugador_id`: identificador técnico (PK).
- `nombre`: nombre común.
- `nombre_completo`: nombre extendido.
- `fecha_nacimiento`: fecha de nacimiento reportada por fuente.
- `lugar_nacimiento`: lugar de nacimiento.
- `altura`: altura textual.
- `apodo`: alias deportivo.
- `sitio_web`: URL principal.
- `redes_sociales`: perfiles sociales.

### entrenador

- `entrenador_id`: identificador técnico (PK).
- `nombre`: nombre del entrenador.

### partido

- `partido_id`: identificador técnico (PK).
- `anio`: edición del Mundial (FK a `mundial`).
- `fecha`: fecha textual del partido.
- `etapa`: fase del torneo.
- `local_seleccion_id`: selección local.
- `visitante_seleccion_id`: selección visitante.
- `goles_local`: goles del local.
- `goles_visitante`: goles del visitante.
- `tiempo_extra`: indicador de prórroga.
- `definicion_penales`: indicador de tanda de penales.
- `penales_local`: penales convertidos por local.
- `penales_visitante`: penales convertidos por visitante.

### aparicion_partido

- `partido_id`: partido asociado.
- `seleccion_id`: selección del jugador en ese partido.
- `jugador_id`: jugador participante.
- `posicion`: posición en cancha.
- `camiseta`: dorsal.
- `seccion`: `titular`, `ingresado` o `suplente_no_jugo`.
- `es_capitan`: marca de capitanía.

### direccion_tecnica_partido

- `partido_id`: partido asociado.
- `seleccion_id`: selección dirigida.
- `entrenador_id`: entrenador de ese partido.

### gol

- `gol_id`: identificador técnico del evento.
- `partido_id`: partido donde ocurrió.
- `seleccion_id`: selección que registra el gol.
- `jugador_id`: autor (puede ser nulo si no se resolvió).
- `minuto`: minuto textual del gol.
- `es_penal`: si fue de penal.
- `es_autogol`: si fue autogol.

### tarjeta

- `tarjeta_id`: identificador técnico del evento.
- `partido_id`: partido donde ocurrió.
- `seleccion_id`: selección del amonestado/expulsado (nullable).
- `jugador_id`: jugador sancionado (nullable).
- `tipo`: `amarilla` o `roja`.
- `minuto`: minuto textual.

### cambio

- `cambio_id`: identificador técnico del evento.
- `partido_id`: partido donde ocurrió.
- `seleccion_id`: selección del cambio.
- `jugador_sale_id`: jugador que sale (nullable).
- `jugador_entra_id`: jugador que entra (nullable).
- `minuto`: minuto textual.

### penal

- `penal_id`: identificador técnico del evento.
- `partido_id`: partido de la tanda.
- `seleccion_id`: selección ejecutora.
- `orden`: orden del tiro dentro de la tanda.
- `jugador_id`: ejecutor (nullable).
- `resultado`: resultado textual del tiro.

### grupo

- `anio`: edición del Mundial.
- `grupo`: identificador de grupo (A, B, 1, 2, etc.).
- `posicion`: posición final en el grupo.
- `seleccion_id`: selección en ese grupo.
- `pts`: puntos.
- `pj`: partidos jugados.
- `pg`: partidos ganados.
- `pe`: partidos empatados.
- `pp`: partidos perdidos.
- `gf`: goles a favor.
- `gc`: goles en contra.
- `dif`: diferencia de gol.
- `clasificado`: si avanzó de fase.

### posicion_final

- `anio`: edición del Mundial.
- `posicion`: posición final absoluta en esa edición.
- `seleccion_id`: selección ubicada en esa posición.

### goleador

- `anio`: edición del Mundial.
- `jugador_id`: jugador goleador.
- `seleccion_id`: selección del goleador.
- `goles`: cantidad de goles.

### premio_jugador

- `anio`: edición del Mundial.
- `premio`: nombre del premio.
- `jugador_id`: destinatario jugador.
- `seleccion_id`: selección del jugador (nullable).

### premio_seleccion

- `anio`: edición del Mundial.
- `premio`: nombre del premio.
- `seleccion_id`: destinatario selección.

### plantel_jugador

- `anio`: edición del Mundial.
- `seleccion_id`: selección convocante.
- `jugador_id`: jugador convocado.
- `posicion`: rol/posición de convocatoria.
- `camiseta`: dorsal en la convocatoria.
- `club`: club reportado en esa convocatoria.

### plantel_entrenador

- `anio`: edición del Mundial.
- `seleccion_id`: selección convocante.
- `entrenador_id`: entrenador del plantel.

### participacion_mundial

- `anio`: edición del Mundial.
- `seleccion_id`: selección participante.
- `posicion`: posición final de campaña.
- `etapa`: última etapa alcanzada.
- `pts`: puntos totales en la edición.
- `pj`: partidos jugados.
- `pg`: partidos ganados.
- `pe`: partidos empatados.
- `pp`: partidos perdidos.
- `gf`: goles a favor.
- `gc`: goles en contra.
- `dif`: diferencia de gol.
- `participo`: marca booleana de participación efectiva.

### resolucion_identidad_jugador

- `resolucion_id`: identificador autonumérico de resolución.
- `source_table`: tabla origen del evento ambiguo.
- `source_event_id`: id del evento en su tabla origen.
- `partido_id`: partido asociado (nullable).
- `seleccion_id`: selección asociada (nullable).
- `jugador_nombre_raw`: nombre textual no conciliado.
- `minuto`: minuto del evento (nullable).
- `metodo`: método de resolución (`manual` por defecto).
- `confianza`: score de confianza opcional.
- `notas`: observaciones de conciliación.

## Archivos de salida esperados

El scraper genera:

- `mundial.csv`
- `seleccion.csv`
- `seleccion_alias.csv`
- `participacion_mundial.csv`
- `jugador.csv`
- `entrenador.csv`
- `partido.csv`
- `aparicion_partido.csv`
- `direccion_tecnica_partido.csv`
- `gol.csv`
- `tarjeta.csv`
- `cambio.csv`
- `penal.csv`
- `grupo.csv`
- `posicion_final.csv`
- `goleador.csv`
- `premio_jugador.csv`
- `premio_seleccion.csv`
- `plantel_jugador.csv`
- `plantel_entrenador.csv`
- `resolucion_identidad_jugador.csv`

## Consultas ejemplo

### Mundiales en los que participaron ciertos países

```sql
SELECT s.nombre AS seleccion, pm.anio
FROM participacion_mundial pm
JOIN seleccion s ON s.seleccion_id = pm.seleccion_id
WHERE s.nombre IN ('Argentina', 'Brasil', 'Alemania')
  AND pm.participo = 1
ORDER BY s.nombre, pm.anio;
```

### Goles anotados por Lionel Messi

```sql
SELECT j.nombre, COUNT(*) AS goles
FROM gol g
JOIN jugador j ON j.jugador_id = g.jugador_id
WHERE j.nombre = 'Lionel Messi'
  AND g.es_autogol = 0
GROUP BY j.nombre;
```

## Documentación adicional

- `py/README_scraper.md`: opciones de scraping.
- `py/db/README_db.md`: guía de esquema y ETL SQL Server.
