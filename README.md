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
- ETL SQL: `py/db/sqlserver_etl.sql` (T-SQL con BULK INSERT),
- Docker con SQL Server 2022 y scripts de init en `docker/init/`.

### 4) Normalización de caracteres especiales

`BULK INSERT` en SQL Server sobre Linux no soporta UTF-8 directamente. La solución
adoptada fue normalizar todos los caracteres acentuados y especiales a su equivalente
ASCII en el script de limpieza (`02_fix_csvs.sh`) antes de la carga, usando
`unicodedata.normalize('NFD')` de Python. Esto garantiza que `Bélgica` se almacene
como `Belgica`, `España` como `Espana`, etc., de forma consistente en toda la base.

### 5) Decisiones de modelado

- Tablas en singular y llaves técnicas (`*_id`) para estabilidad relacional.
- `seleccion_alias` colapsa variantes históricas de nombre hacia una selección canónica.
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
- `py/db/sqlserver_etl.sql`: carga de CSV en SQL Server con BULK INSERT.
- `py/db/modelo_wc.dbml`: modelo lógico.
- `docker/init/`: scripts de inicialización del entorno Docker.- `py/db/stored_procedures.sql`: stored procedures para consultas por año y por país.

## Estructura del repositorio

```
bases2_proyecto1/
├── Dockerfile                          # Imagen SQL Server 2022 + Python3 + dos2unix
├── docker-compose.yml                  # Orquestacion del contenedor
├── .gitattributes                      # Fuerza LF en .sh para compatibilidad Linux
├── docker/
│   └── init/
│       ├── run_init.sh                 # Arranque: espera SQL Server y ejecuta init
│       ├── 01_schema.sql               # Crea la base de datos y llama al schema
│       ├── 02_fix_csvs.sh              # Limpia, normaliza y deduplica los CSV
│       └── 03_etl.sql                  # Llama al ETL principal con BULK INSERT
├── py/
│   ├── scraping_normalizado.py         # Scraper principal
│   ├── normalizacion_csv.py            # Conversor de formato legacy a normalizado
│   ├── README_scraper.md               # Guia del scraper
│   └── db/
│       ├── sqlserver_schema.sql        # Esquema T-SQL (SQL Server 2019+)
│       ├── sqlserver_etl.sql           # ETL T-SQL con BULK INSERT y tablas staging
│       ├── modelo_wc.dbml              # Modelo logico en DBML
│       |── README_db.md               # Documentacion del modelo y ETL
│       ├── stored_procedures.sql       # SPs: sp_mundial_por_anio y sp_historial_pais
│       └── README_stored_procedures.md # Documentacion de los stored procedures
├── datos_normalizados_web/             # CSV generados desde la web (fuente principal)
├── datos_normalizados_local/           # CSV generados desde el espejo HTML local
├── html_descargados/                   # Espejo local del sitio
└── db/
    ├── ER-G3.png                       # Diagrama entidad-relacion
    └── ER-G3.pdf                       # Diagrama entidad-relacion (PDF)
```

## Docker — inicio rápido

### Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo.
- CSV generados en `datos_normalizados_web/` (ya incluidos en el repo).

### Levantar la base de datos

```powershell
docker compose up -d --build
```

La primera vez tarda aproximadamente 60-90 segundos. El proceso hace:

1. Construye la imagen (SQL Server 2022 + Python3 + dos2unix).
2. Convierte los scripts `.sh` de CRLF a LF con `dos2unix` (compatibilidad Windows/Linux).
3. Levanta SQL Server y espera a que esté listo (`run_init.sh`).
4. Limpia y normaliza los CSV (`02_fix_csvs.sh`).
5. Crea la base de datos y todas las tablas (`01_schema.sql`).
6. Carga todos los datos con BULK INSERT (`03_etl.sql`).

### Verificar que los datos cargaron

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "Mundiales2026!" -d mundiales -Q "SELECT COUNT(*) AS partidos FROM dbo.partido; SELECT COUNT(*) AS jugadores FROM dbo.jugador;"
```

### Conectarse con un cliente externo

Usar DBeaver, Azure Data Studio, SSMS o cualquier cliente SQL:

| Parámetro     | Valor            |
| ------------- | ---------------- |
| Host          | `localhost`      |
| Puerto        | `1433`           |
| Usuario       | `sa`             |
| Contraseña    | `Mundiales2026!` |
| Base de datos | `mundiales`      |

> En DBeaver: Driver Properties → `trustServerCertificate = true`

### Reiniciar desde cero

```powershell
docker compose down -v
docker compose up -d --build
```

El flag `-v` destruye el volumen y fuerza la reinicialización completa.

### Detener sin borrar datos

```powershell
docker compose down
```

## Detalle de los scripts Docker

### `Dockerfile`

Extiende `mcr.microsoft.com/mssql/server:2022-latest` instalando Python3, pip,
dos2unix y mssql-tools18. Copia los scripts de init y ejecuta `dos2unix` sobre
los `.sh` para convertir CRLF a LF, lo que es necesario porque los archivos se
editan en Windows pero se ejecutan en Linux.

### `docker-compose.yml`

Define el servicio `db`. Puntos clave:

- Monta `datos_normalizados_web/` como `/csv` dentro del contenedor.
- Monta `py/db/` como `/db_scripts` (los scripts SQL referencian esta ruta con `:r`).
- El volumen `mssql_data` persiste los datos entre reinicios.
- El `command` llama directamente a `run_init.sh` en lugar del entrypoint por defecto.

### `docker/init/run_init.sh`

Script principal de arranque. Levanta `sqlservr` en segundo plano, espera hasta
180 segundos a que acepte conexiones, y si el marcador `/var/opt/mssql/.init_done`
no existe ejecuta los tres pasos de inicialización en orden. El marcador evita
que la inicialización se repita en reinicios posteriores.

### `docker/init/02_fix_csvs.sh`

Script bash que invoca Python3 para preparar los CSV antes de la carga. Realiza
tres operaciones sobre cada archivo:

1. **Corrección de tipos**: convierte columnas numéricas que pandas exporta como
   float (`1454.0` → `1454`) y booleanos de Python (`True`/`False` → `1`/`0`).
2. **Normalización de caracteres**: elimina tildes y diacríticos usando
   `unicodedata.normalize('NFD')`. Necesario porque `BULK INSERT` en SQL Server
   Linux no soporta UTF-8 y leería `é` como caracteres corruptos. Caracteres sin
   descomposición NFD (`ł`, `ø`, `ð`, etc.) se manejan con un mapa explícito.
3. **Deduplicación**: elimina filas duplicadas usando las llaves primarias exactas
   del schema, previniendo errores de constraint al cargar.

### `docker/init/01_schema.sql`

Crea la base de datos `mundiales` si no existe y luego incluye
`/db_scripts/sqlserver_schema.sql` con `:r`. Requiere que `py/db/` esté montado
como `/db_scripts` en el contenedor.

### `docker/init/03_etl.sql`

Define la variable `CSV_DIR="/csv"` e incluye `/db_scripts/sqlserver_etl.sql`
con `:r`. El ETL principal usa tablas staging temporales (`#stg_*`) para cada
CSV, hace la conversión de tipos con `TRY_CONVERT`, y luego inserta en las tablas
definitivas. Todo corre dentro de una transacción con `XACT_ABORT ON`.

## Inicio rápido sin Docker

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
- `nombre`: nombre canónico único (sin tildes).

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
- `pts`, `pj`, `pg`, `pe`, `pp`, `gf`, `gc`, `dif`: estadísticas del grupo.
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
- `pts`, `pj`, `pg`, `pe`, `pp`, `gf`, `gc`, `dif`: estadísticas de la campaña.
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

## Archivos de salida del scraper

- `mundial.csv`, `seleccion.csv`, `seleccion_alias.csv`
- `participacion_mundial.csv`, `jugador.csv`, `entrenador.csv`
- `partido.csv`, `aparicion_partido.csv`, `direccion_tecnica_partido.csv`
- `gol.csv`, `tarjeta.csv`, `cambio.csv`, `penal.csv`
- `grupo.csv`, `posicion_final.csv`, `goleador.csv`
- `premio_jugador.csv`, `premio_seleccion.csv`
- `plantel_jugador.csv`, `plantel_entrenador.csv`
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

### Partidos jugados por Argentina

```sql
SELECT p.anio, p.fecha, p.etapa,
       sl.nombre AS local, p.goles_local,
       p.goles_visitante, sv.nombre AS visitante
FROM partido p
JOIN seleccion sl ON sl.seleccion_id = p.local_seleccion_id
JOIN seleccion sv ON sv.seleccion_id = p.visitante_seleccion_id
WHERE sl.nombre = 'Argentina' OR sv.nombre = 'Argentina'
ORDER BY p.anio, p.partido_id;
```

## Validaciones rápidas

```sql
SELECT COUNT(*) AS mundial            FROM dbo.mundial;
SELECT COUNT(*) AS seleccion          FROM dbo.seleccion;
SELECT COUNT(*) AS jugador            FROM dbo.jugador;
SELECT COUNT(*) AS entrenador         FROM dbo.entrenador;
SELECT COUNT(*) AS partido            FROM dbo.partido;
SELECT COUNT(*) AS gol                FROM dbo.gol;
SELECT COUNT(*) AS tarjeta            FROM dbo.tarjeta;
SELECT COUNT(*) AS cambio             FROM dbo.cambio;
SELECT COUNT(*) AS penal              FROM dbo.penal;
SELECT COUNT(*) AS grupo              FROM dbo.grupo;
SELECT COUNT(*) AS posicion_final     FROM dbo.posicion_final;
SELECT COUNT(*) AS goleador           FROM dbo.goleador;
SELECT COUNT(*) AS premio_jugador     FROM dbo.premio_jugador;
SELECT COUNT(*) AS premio_seleccion   FROM dbo.premio_seleccion;
SELECT COUNT(*) AS plantel_jugador    FROM dbo.plantel_jugador;
SELECT COUNT(*) AS plantel_entrenador FROM dbo.plantel_entrenador;
SELECT COUNT(*) AS participacion      FROM dbo.participacion_mundial;
SELECT COUNT(*) AS pendientes         FROM dbo.v_evento_jugador_pendiente;
```

## Documentación adicional

- `py/README_scraper.md`: opciones de scraping y modos de extracción.
- `py/db/README_db.md`: guía del esquema, ETL y decisiones de modelado.
- `py/db/README_stored_procedures.md`: construcción, uso y ejemplos de los stored procedures.
