# bases2_proyecto1

Proyecto de extracción y carga de datos históricos de los Mundiales de fútbol a un modelo relacional en PostgreSQL.

El flujo activo del repositorio quedó concentrado en dos piezas:

- `py/scraping_normalizado.py`: genera los CSV normalizados.
- `py/db/`: contiene el esquema, el ETL y el modelo lógico.

## Inicio rápido

### 1. Preparar el entorno

En Windows, desde la raíz del proyecto:

```powershell
.venv\Scripts\activate
pip install pandas beautifulsoup4
```

Si no quieres activar el entorno, puedes ejecutar directamente:

```powershell
.venv\Scripts\python.exe --version
```

### 2. Generar los CSV normalizados

Hay dos modos de trabajo:

- `web`: extrae directamente del sitio en vivo. Es la opción recomendada porque produce datos más completos.
- `local`: lee los HTML ya descargados en `html_descargados`.

#### Opción recomendada: extraer desde la web

```powershell
.venv\Scripts\python.exe py\scraping_normalizado.py --origen web --salida .\datos_normalizados_web
```

#### Opción alternativa: extraer desde el espejo local

```powershell
.venv\Scripts\python.exe py\scraping_normalizado.py --origen local --html-dir .\html_descargados --salida .\datos_normalizados_local
```

### 3. Crear la base en PostgreSQL

```powershell
psql -h <host> -U <usuario> -d <basedatos> -f py/db/postgres_schema.sql
```

### 4. Cargar los CSV con el ETL

Antes de ejecutar el ETL, ajusta al inicio de `py/db/postgres_etl.sql` las variables `\set` para que apunten a la carpeta de datos que vas a usar.

Si quieres cargar la salida más completa, apunta a `datos_normalizados_web`.

Luego ejecuta:

```powershell
psql -h <host> -U <usuario> -d <basedatos> -f py/db/postgres_etl.sql
```

## Estructura actual

- `py/scraping_normalizado.py`: scraper principal y único flujo de extracción vigente.
- `py/README_scraper.md`: guía específica del scraper y sus opciones.
- `py/db/postgres_schema.sql`: creación del esquema relacional.
- `py/db/postgres_etl.sql`: carga de CSV a PostgreSQL.
- `py/db/modelo_wc.dbml`: modelo lógico del proyecto.
- `py/db/README_db.md`: explicación de la estructura de datos.
- `html_descargados/`: espejo local del sitio, usado en modo `local`.
- `datos_normalizados_web/`: salida recomendada del scraper.
- `datos_normalizados_local/`: salida generada desde el espejo local.

## Archivos de salida

El scraper genera estos CSV:

- `mundial.csv`
- `seleccion.csv`
- `participacion_mundial.csv`
- `jugador.csv`
- `partido.csv`
- `aparicion_partido.csv`
- `gol.csv`
- `tarjeta.csv`
- `cambio.csv`
- `penal.csv`
- `grupo.csv`
- `posicion_final.csv`
- `goleador.csv`
- `premio.csv`
- `plantel.csv`

## Recomendación práctica

Si el objetivo es poblar la base con la versión más completa posible, usa `datos_normalizados_web` como fuente de carga. La estructura de la base no cambia entre `web` y `local`; lo único que cambia es la completitud de los datos.

## Documentación adicional

- Ver `py/README_scraper.md` para opciones del scraper.
- Ver `py/db/README_db.md` para entender el modelo relacional y el ETL.