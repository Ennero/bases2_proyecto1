# Base de datos normalizada de Mundiales

Este directorio contiene el modelo relacional, el script de creación y el ETL para cargar los CSV generados por el scraper.

## Archivos

- `postgres_schema.sql`: crea tablas, llaves foráneas, vista de apoyo e índices.
- `postgres_etl.sql`: carga los CSV a staging temporal y luego hace `UPSERT` hacia las tablas finales.
- `modelo_wc.dbml`: diagrama lógico del modelo.

## Decisiones actuales del modelo

- Los nombres de tabla quedaron en singular.
- Se conservaron `slug` porque siguen siendo la mejor llave textual estable para enlazar datos entre páginas y CSV.
- Se eliminaron columnas de auditoría que no aportaban al objetivo del proyecto.
- Solo se mantienen campos que sí aparecen en la fuente o en el espejo local.

## Validación contra el HTML fuente

Se revisó HTML local real antes de ajustar el esquema:

- En [html_descargados/jugadores_lionel_messi.php](/c:/Users/Enner/Desktop/bases2_proyecto1/html_descargados/jugadores_lionel_messi.php) sí aparecen `Nombre completo`, `Apodo`, `Sitio Web Oficial` y `Redes Sociales`.
- En [html_descargados/planteles_2022_argentina_jugadores.php](/c:/Users/Enner/Desktop/bases2_proyecto1/html_descargados/planteles_2022_argentina_jugadores.php) sí aparece `Club` dentro del plantel.

Eso significa que esos campos no eran inventados por el modelo. Sí son opcionales porque no todas las páginas muestran la misma riqueza de detalle, pero forman parte de la fuente.

## Idea general del modelo

El diseño separa cuatro grupos de información:

1. Catálogos base: `mundial`, `seleccion` y `jugador`.
2. Hechos por partido: `partido`, `aparicion_partido`, `gol`, `tarjeta`, `cambio` y `penal`.
3. Hechos por torneo: `grupo`, `posicion_final`, `goleador`, `premio`, `plantel` y `participacion_mundial`.
4. Tablas de apoyo: `seleccion_alias` y `resolucion_identidad_jugador`.

La normalización busca reutilizar la misma selección o el mismo jugador en varias tablas sin repetir toda su información descriptiva.

## Tablas principales

### `mundial`

Una fila por edición del Mundial.

- `anio`: llave primaria.
- `sede`: sede organizadora.
- `campeon`, `subcampeon`, `tercer_lugar`, `cuarto_lugar`: posiciones finales principales.
- `equipos`, `partidos_jugados`, `goles_total`, `promedio_gol`: métricas globales de la edición.

### `seleccion`

Una fila por selección nacional canónica.

- `seleccion_id`: llave primaria técnica.
- `slug`: identificador textual estable.
- `nombre`: nombre visible.
- `participaciones`, `pj`, `pg`, `pe`, `pp`, `gf`, `gc`, `titulos`, `subcampeonatos`, `posicion_historica`: resumen histórico del sitio.

### `seleccion_alias`

Relaciona nombres históricos o alternativos con una selección canónica.

- `alias_slug`: llave primaria del alias normalizado.
- `alias_nombre`: nombre histórico observado.
- `seleccion_id`: referencia a `seleccion`.
- `notas`: explicación del mapeo.

Ejemplos típicos: `Alemania Occidental`, `URSS`, `Serbia y Montenegro`.

### `jugador`

Una fila por jugador identificado en la fuente.

- `jugador_id`: llave primaria técnica.
- `slug`: identificador estable del jugador.
- `nombre`: nombre corto.
- `nombre_completo`, `fecha_nacimiento`, `lugar_nacimiento`, `posicion`, `numeros_camiseta`, `altura`, `apodo`, `sitio_web`, `redes_sociales`: datos tomados de la ficha del jugador cuando existen.
- `seleccion_nombre`, `seleccion_id`: selección asociada.
- `mundiales`, `partidos`, `goles`, `promedio_gol`: resumen histórico publicado por el sitio.

### `partido`

Una fila por partido.

- `partido_id`: llave primaria técnica.
- `slug`: identificador estable del partido.
- `anio`: referencia a `mundial`.
- `fecha`, `etapa`, `resultado`, `tiempo_extra`, `penales`, `resultado_penales`: metadatos del encuentro.
- `local_nombre`, `visitante_nombre`, `local_seleccion_id`, `visitante_seleccion_id`: participantes del partido.

### `aparicion_partido`

Disponibilidad y presencia por encuentro.

- `jugador_nombre`: nombre del jugador o entrenador tal como sale en la hoja del partido.
- `seccion`: `titular`, `ingresado`, `suplente_no_jugo` o `entrenador`.
- `camiseta`, `posicion`, `es_capitan`: detalle de la aparición.

### `gol`

Una fila por gol.

- `jugador`, `jugador_slug`, `jugador_id`: autor del gol.
- `equipo_nombre`, `seleccion_id`: equipo al que se adjudica.
- `minuto`, `es_penal`, `es_autogol`: contexto del gol.

### `tarjeta`

Una fila por tarjeta mostrada.

- `tipo`: `amarilla` o `roja`.
- `jugador`, `jugador_slug`, `jugador_id`: jugador sancionado.
- `equipo_nombre`, `seleccion_id`, `minuto`: contexto de la sanción.

### `cambio`

Una fila por sustitución.

- `sale`, `sale_slug`, `sale_jugador_id`: jugador que sale.
- `entra`, `entra_slug`, `entra_jugador_id`: jugador que entra.
- `equipo_nombre`, `seleccion_id`, `minuto`: contexto del cambio.

### `penal`

Una fila por ejecución dentro de una tanda.

- `orden`: orden del tiro para ese equipo.
- `jugador`, `jugador_slug`, `jugador_id`: ejecutor.
- `resultado`: resultado textual del tiro.

### `grupo`

Tabla de posiciones de la fase de grupos.

- `anio`, `grupo`, `seleccion_nombre`: identifican una fila.
- `posicion`, `pts`, `pj`, `pg`, `pe`, `pp`, `gf`, `gc`, `dif`, `clasificado`: resumen exclusivo de la fase de grupos.

### `posicion_final`

Posición final por edición.

- `anio`, `posicion`, `seleccion_nombre`: combinación única.

### `goleador`

Tabla de goleadores por edición.

- `anio`, `jugador`, `seleccion_nombre`, `goles`: resumen del ranking de goleadores.

### `premio`

Premios de una edición.

- `tipo_destinatario`: `jugador` o `seleccion`.
- `destinatario_key`: columna generada para deduplicar premios individuales y colectivos.

### `plantel`

Planteles oficiales por mundial y selección.

- `seleccion_nombre`, `seleccion_slug`, `seleccion_id`: selección del plantel.
- `jugador`, `jugador_slug`, `jugador_id`: integrante del plantel.
- `posicion`, `camiseta`, `fecha_nacimiento`, `altura`, `club`: detalle mostrado en la página de plantel.
- `rol`: `jugador` o `entrenador`.

### `participacion_mundial`

Resumen de una selección en una edición completa.

- `anio`, `seleccion_nombre`, `seleccion_slug`, `seleccion_id`: selección y edición.
- `posicion`, `etapa`, `pts`, `pj`, `pg`, `pe`, `pp`, `gf`, `gc`, `dif`, `participo`: resumen global del torneo.

## `grupo` vs `participacion_mundial`

Estas dos tablas no modelan lo mismo.

- `grupo` guarda el rendimiento en la fase de grupos.
- `participacion_mundial` guarda el resumen completo de la edición para una selección, incluso cuando no participó.

Ejemplo claro:

- En [datos_normalizados_local/grupo.csv](/c:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_local/grupo.csv) hay filas por grupo, por ejemplo `2026, A, ...`.
- En [datos_normalizados_local/participacion_mundial.csv](/c:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_local/participacion_mundial.csv) hay una sola fila por selección y año, con la etapa final alcanzada o `no participó`.

Comparten columnas como `pj`, `pg`, `gf` y `gc`, pero no están duplicando el mismo hecho; están representando dos granos distintos.

### `resolucion_identidad_jugador`

Cola de trabajo para revisar filas donde el sitio no permite enlazar con seguridad a un `slug` de jugador.

- `source_table`: origen del problema (`gol`, `tarjeta`, `cambio_entrada`, `cambio_salida`, `aparicion_partido`, `penal`).
- `source_pk`: llave primaria de la fila origen.
- `partido_slug`, `anio`, `equipo_nombre`, `jugador_nombre_raw`, `minuto`: contexto del caso ambiguo.
- `jugador_id_resuelto`, `jugador_slug_resuelto`, `metodo`, `confianza`, `notas`: resolución manual o semimanual.

## Relaciones principales

- `mundial` se relaciona con `partido`, `grupo`, `posicion_final`, `goleador`, `premio`, `plantel` y `participacion_mundial` por `anio`.
- `seleccion` se relaciona con la mayoría de tablas de hechos por `seleccion_id`.
- `jugador` se relaciona con `aparicion_partido`, `gol`, `tarjeta`, `cambio`, `penal`, `goleador`, `premio` y `plantel`.
- `partido` es el centro de los hechos por encuentro.

## Cómo cargar los datos

### 1. Crear la estructura

```bash
psql -h <host> -U <user> -d <database> -f py/db/postgres_schema.sql
```

### 2. Ajustar rutas de CSV en `postgres_etl.sql`

Revisa las variables `\set` del inicio, por ejemplo:

```sql
\set f_partidos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados_web/partido.csv'
```

Si prefieres cargar la salida obtenida desde el espejo local, cambia esas rutas a `datos_normalizados_local`.

### 3. Ejecutar el ETL

```bash
psql -h <host> -U <user> -d <database> -f py/db/postgres_etl.sql
```

## Validaciones rápidas

```sql
SELECT COUNT(*) AS mundial FROM mundial;
SELECT COUNT(*) AS seleccion FROM seleccion;
SELECT COUNT(*) AS jugador FROM jugador;
SELECT COUNT(*) AS partido FROM partido;
SELECT COUNT(*) AS gol FROM gol;
SELECT COUNT(*) AS penal FROM penal;
SELECT COUNT(*) AS plantel FROM plantel;
SELECT COUNT(*) AS participacion FROM participacion_mundial;
SELECT COUNT(*) AS pendientes_resolucion FROM resolucion_identidad_jugador WHERE jugador_id_resuelto IS NULL;
```

## Qué significa un slug

Un `slug` es una clave textual estable y legible.

Ejemplos:

- `Argentina` -> `argentina`
- `Lionel Messi` -> `lionel_messi`
- `2022 Argentina vs Francia` -> `2022_argentina_francia`

En este proyecto sirve para enlazar filas entre CSV, páginas HTML y tablas sin depender solamente del nombre visible.