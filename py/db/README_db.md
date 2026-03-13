# Base de datos normalizada de Mundiales (SQL Server)

Este directorio contiene el esquema y el ETL de SQL Server para cargar los CSV normalizados del proyecto.

## Archivos

- `sqlserver_schema.sql`: esquema en T-SQL para SQL Server.
- `sqlserver_etl.sql`: ETL en T-SQL con `BULK INSERT`.
- `modelo_wc.dbml`: modelo lógico alineado al esquema.

## Criterios del modelo

- Tablas en singular.
- Llaves tecnicas (`*_id`) para estabilidad relacional.
- Separacion de tablas por grano y rol:
  - `premio_jugador` y `premio_seleccion`.
  - `plantel_jugador` y `plantel_entrenador`.
  - `grupo` (fase de grupos) y `participacion_mundial` (campana total).
- `slug` no se persiste como clave final.

## Tabla que se llena automaticamente al subir datos

Si: `resolucion_identidad_jugador`.

Se carga desde `resolucion_identidad_jugador.csv`, el cual se garantiza de dos maneras:

- El normalizador `py/scraping_normalizado.py` lo genera automaticamente.
- En Docker, `docker/init/02_fix_csvs.sh` lo crea con encabezado si no existe.

Con eso, el ETL no falla aunque no haya ambiguedades (archivo vacio con header).

## Flujo recomendado local

1. Generar CSV normalizados en `datos_normalizados_web/`.
2. Crear esquema:

```bash
sqlcmd -S <host>,1433 -U sa -P <password> -C -i py/db/sqlserver_schema.sql -d <database>
```

3. Cargar datos:

```bash
sqlcmd -S <host>,1433 -U sa -P <password> -C -d <database> -i py/db/sqlserver_etl.sql -v CSV_DIR="./datos_normalizados_web"
```

## Carga con Docker

Desde la raiz del proyecto:

```bash
docker compose up -d --build
```

Esto:

1. Levanta SQL Server 2022.
2. Ejecuta limpieza/deduplicacion de CSV.
3. Crea la base y el esquema.
4. Carga el dataset con ETL.

## Validaciones rapidas

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
