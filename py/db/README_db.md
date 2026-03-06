# Base de datos normalizada de Mundiales

Este directorio contiene el modelo relacional, el script de creación y el ETL para cargar los CSV generados por el scraper.

## Archivos

- `postgres_schema.sql`: crea tablas, llaves foráneas, vista de apoyo e índices.
- `postgres_etl.sql`: carga cada CSV a staging temporal y luego hace `UPSERT` hacia tablas finales.
- `modelo_wc.dbml`: diagrama lógico del modelo, ya sin prefijos `wc`.

## Idea general del modelo

El diseño separa cuatro tipos de información:

1. Catálogos base: mundiales, selecciones y jugadores.
2. Hechos por partido: partidos, alineaciones, goles, tarjetas, cambios y penales.
3. Hechos por torneo: grupos, posiciones finales, goleadores, premios y planteles.
4. Tablas de apoyo: alias históricos de selecciones, participaciones por mundial y cola de resolución de identidades ambiguas.

La normalización busca que un mismo jugador o selección se reutilice en varias tablas sin duplicar toda su información en cada fila.

## Tablas y columnas

### `mundiales`

Una fila por edición del Mundial.

- `anio`: llave primaria. Año de la edición.
- `sede`: país o sede organizadora.
- `campeon`: selección campeona.
- `subcampeon`: selección subcampeona.
- `tercer_lugar`: selección ubicada en tercer lugar.
- `cuarto_lugar`: selección ubicada en cuarto lugar.
- `equipos`: cantidad de selecciones participantes.
- `partidos_jugados`: total de partidos disputados.
- `goles_total`: total de goles del torneo.
- `promedio_gol`: promedio de gol reportado por la fuente.

### `selecciones`

Una fila por selección nacional.

- `seleccion_id`: llave primaria técnica.
- `slug`: identificador estable derivado del sitio.
- `nombre`: nombre visible de la selección.
- `participaciones`: cantidad total de mundiales jugados.
- `pj`: partidos jugados históricamente.
- `pg`: partidos ganados históricamente.
- `pe`: partidos empatados históricamente.
- `pp`: partidos perdidos históricamente.
- `gf`: goles a favor históricos.
- `gc`: goles en contra históricos.
- `titulos`: cantidad de títulos mundiales.
- `subcampeonatos`: cantidad de subcampeonatos.
- `posicion_historica`: posición histórica reportada por el sitio.

### `selecciones_alias`

Sirve para relacionar nombres históricos con una selección actual o canónica.

- `alias_slug`: llave primaria del alias normalizado.
- `alias_nombre`: nombre histórico visto en la fuente.
- `seleccion_id`: referencia a `selecciones`.
- `notas`: explicación del mapeo histórico.

Ejemplo: `Alemania Occidental` puede apuntar a `alemania`.

El campo `notas` en esta tabla normalmente sí se llena de forma manual o semimanual. Su objetivo es dejar explicado por qué un alias histórico se amarra a una selección canónica.

### `jugadores`

Una fila por jugador identificado en el sitio.

- `jugador_id`: llave primaria técnica.
- `slug`: identificador estable del jugador.
- `nombre`: nombre corto del jugador.
- `nombre_completo`: nombre completo cuando la ficha lo muestra.
- `seleccion_nombre`: nombre textual de la selección asociada.
- `seleccion_id`: referencia a `selecciones`.
- `fecha_nacimiento`: fecha de nacimiento en formato textual de la fuente.
- `lugar_nacimiento`: lugar de nacimiento.
- `posicion`: posición declarada en la ficha del jugador.
- `numeros_camiseta`: dorsales usados en mundiales.
- `altura`: altura del jugador.
- `apodo`: apodo si existe.
- `sitio_web`: sitio oficial si existe.
- `redes_sociales`: texto resumido de redes sociales.
- `mundiales`: cantidad de mundiales disputados.
- `partidos`: cantidad total de partidos mundialistas.
- `goles`: cantidad total de goles mundialistas.
- `promedio_gol`: promedio de gol histórico del jugador.

### `partidos`

Una fila por partido.

- `partido_id`: llave primaria técnica.
- `slug`: identificador estable del partido.
- `anio`: referencia a `mundiales`.
- `fecha`: fecha textual del partido.
- `etapa`: fase o ronda.
- `local_nombre`: nombre del equipo local.
- `visitante_nombre`: nombre del equipo visitante.
- `local_seleccion_id`: referencia a `selecciones` para el local.
- `visitante_seleccion_id`: referencia a `selecciones` para el visitante.
- `resultado`: marcador regular mostrado por la fuente.
- `tiempo_extra`: indica si hubo prórroga.
- `penales`: indica si el partido se definió por penales.
- `resultado_penales`: marcador de la tanda, por ejemplo `4 - 2`.

### `apariciones_partido`

Guarda quién estuvo disponible o participó en cada partido.

- `aparicion_id`: llave primaria técnica.
- `partido_slug`: referencia a `partidos`.
- `anio`: referencia a `mundiales`.
- `equipo_nombre`: equipo al que pertenece la aparición.
- `seleccion_id`: referencia a `selecciones`.
- `jugador_slug`: referencia opcional a `jugadores`.
- `jugador_id`: referencia opcional a `jugadores`.
- `jugador_nombre`: nombre del jugador o entrenador.
- `posicion`: posición reportada en la hoja del partido.
- `camiseta`: dorsal usado en ese partido.
- `seccion`: `titular`, `ingresado`, `suplente_no_jugo` o `entrenador`.
- `es_capitan`: indica si el jugador fue capitán.

### `goles`

Una fila por gol marcado en un partido.

- `gol_id`: llave primaria técnica.
- `partido_slug`: referencia a `partidos`.
- `anio`: referencia a `mundiales`.
- `equipo_nombre`: equipo al que se adjudica el gol.
- `seleccion_id`: referencia a `selecciones`.
- `jugador`: nombre del autor registrado.
- `jugador_slug`: referencia opcional a `jugadores`.
- `jugador_id`: referencia opcional a `jugadores`.
- `minuto`: minuto textual, incluyendo agregado si aplica.
- `es_penal`: indica si el gol fue de penal.
- `es_autogol`: indica si fue gol en contra.

### `tarjetas`

Una fila por tarjeta mostrada.

- `tarjeta_id`: llave primaria técnica.
- `partido_slug`: referencia a `partidos`.
- `anio`: referencia a `mundiales`.
- `jugador`: nombre del amonestado o expulsado.
- `jugador_slug`: referencia opcional a `jugadores`.
- `jugador_id`: referencia opcional a `jugadores`.
- `equipo_nombre`: selección del jugador.
- `seleccion_id`: referencia a `selecciones`.
- `tipo`: `amarilla` o `roja`.
- `minuto`: minuto textual.

### `cambios`

Una fila por sustitución.

- `cambio_id`: llave primaria técnica.
- `partido_slug`: referencia a `partidos`.
- `anio`: referencia a `mundiales`.
- `equipo_nombre`: selección que hizo el cambio.
- `seleccion_id`: referencia a `selecciones`.
- `sale`: jugador que sale.
- `sale_slug`: referencia opcional al jugador que sale.
- `sale_jugador_id`: referencia opcional al jugador que sale.
- `entra`: jugador que entra.
- `entra_slug`: referencia opcional al jugador que entra.
- `entra_jugador_id`: referencia opcional al jugador que entra.
- `minuto`: minuto del cambio.

### `penales`

Una fila por ejecución dentro de una tanda de penales.

- `penal_id`: llave primaria técnica.
- `partido_slug`: referencia a `partidos`.
- `anio`: referencia a `mundiales`.
- `equipo_nombre`: selección que ejecutó el penal.
- `seleccion_id`: referencia a `selecciones`.
- `orden`: orden de ejecución dentro de la tanda para ese equipo.
- `jugador`: ejecutor.
- `jugador_slug`: referencia opcional a `jugadores`.
- `jugador_id`: referencia opcional a `jugadores`.
- `resultado`: resultado del tiro, por ejemplo `gol`, `atajado`, `desviado` o `poste`.

### `grupos`

Tabla de posiciones de fase de grupos.

- `grupo_id`: llave primaria técnica.
- `anio`: referencia a `mundiales`.
- `grupo`: nombre del grupo.
- `posicion`: posición dentro del grupo.
- `seleccion_nombre`: nombre textual de la selección.
- `seleccion_id`: referencia a `selecciones`.
- `pts`: puntos.
- `pj`: partidos jugados.
- `pg`: partidos ganados.
- `pe`: partidos empatados.
- `pp`: partidos perdidos.
- `gf`: goles a favor.
- `gc`: goles en contra.
- `dif`: diferencia de goles.
- `clasificado`: indica si avanzó de fase.

### `posiciones_finales`

Ranking final del torneo.

- `posicion_final_id`: llave primaria técnica.
- `anio`: referencia a `mundiales`.
- `posicion`: posición final.
- `seleccion_nombre`: nombre textual de la selección.
- `seleccion_id`: referencia a `selecciones`.

### `goleadores`

Tabla de goleadores por edición.

- `goleador_id`: llave primaria técnica.
- `anio`: referencia a `mundiales`.
- `jugador`: nombre del jugador.
- `jugador_slug`: referencia opcional a `jugadores`.
- `jugador_id`: referencia opcional a `jugadores`.
- `seleccion_nombre`: selección del jugador.
- `seleccion_id`: referencia a `selecciones`.
- `goles`: total de goles de esa edición.

### `premios`

Premios de una edición. Soporta premios a jugadores y a selecciones.

- `premio_id`: llave primaria técnica.
- `anio`: referencia a `mundiales`.
- `premio`: nombre del premio.
- `tipo_destinatario`: `jugador` o `seleccion`.
- `jugador`: nombre del jugador si el premio fue individual.
- `jugador_slug`: referencia opcional a `jugadores`.
- `jugador_id`: referencia opcional a `jugadores`.
- `seleccion_nombre`: selección premiada o selección del jugador.
- `seleccion_id`: referencia a `selecciones`.
- `destinatario_key`: columna generada para evitar duplicados en premios.

### `planteles`

Planteles oficiales por mundial y selección.

- `plantel_id`: llave primaria técnica.
- `anio`: referencia a `mundiales`.
- `seleccion_nombre`: nombre textual de la selección.
- `seleccion_slug`: slug textual de la selección.
- `seleccion_key`: columna generada para deduplicar planteles.
- `seleccion_id`: referencia a `selecciones`.
- `jugador`: nombre del jugador o entrenador.
- `jugador_slug`: referencia opcional a `jugadores`.
- `jugador_key`: columna generada para deduplicar jugadores del plantel.
- `jugador_id`: referencia opcional a `jugadores`.
- `posicion`: posición dentro del plantel.
- `camiseta`: dorsal en ese torneo.
- `fecha_nacimiento`: fecha de nacimiento mostrada en el plantel.
- `altura`: altura reportada en el plantel.
- `club`: club del jugador en ese momento.
- `rol`: `jugador` o `entrenador`.

### `participaciones_mundial`

Resumen por selección y edición del Mundial.

- `participacion_id`: llave primaria técnica.
- `anio`: referencia a `mundiales`.
- `seleccion_nombre`: selección evaluada.
- `seleccion_slug`: slug textual de la selección.
- `seleccion_key`: columna generada para deduplicar por año y selección.
- `seleccion_id`: referencia a `selecciones`.
- `posicion`: posición final o histórica de esa edición.
- `etapa`: fase alcanzada o texto como `No participó`.
- `pts`: puntos obtenidos.
- `pj`: partidos jugados.
- `pg`: partidos ganados.
- `pe`: partidos empatados.
- `pp`: partidos perdidos.
- `gf`: goles a favor.
- `gc`: goles en contra.
- `dif`: diferencia de goles.
- `participo`: indica si realmente participó.

### `resolucion_identidad_jugador`

Cola para revisar filas en las que el sitio no permite identificar un jugador con slug confiable.

- `resolucion_id`: llave primaria técnica.
- `source_table`: tabla de origen del problema.
- `source_pk`: llave primaria de la fila origen, si existe.
- `partido_slug`: referencia a `partidos`.
- `anio`: referencia a `mundiales`.
- `equipo_nombre`: equipo relacionado.
- `equipo_key`: columna generada para deduplicación.
- `jugador_nombre_raw`: nombre tal como salió del scraping.
- `jugador_slug_raw`: slug capturado, si existía.
- `minuto`: minuto relacionado, si aplica.
- `minuto_key`: columna generada para deduplicación.
- `jugador_id_resuelto`: jugador resuelto manualmente.
- `jugador_slug_resuelto`: slug resuelto manualmente.
- `metodo`: método de resolución.
- `confianza`: confianza asignada a la resolución.
- `notas`: comentarios del analista.
- `resolved_at`: momento en que quedó resuelto.

El campo `notas` aquí también es principalmente manual. Sirve para que, cuando resuelvas un jugador dudoso, quede documentado qué decisión se tomó y por qué.

## Relaciones principales

- `mundiales` se relaciona con `partidos`, `grupos`, `posiciones_finales`, `goleadores`, `premios`, `planteles` y `participaciones_mundial` por `anio`.
- `selecciones` se relaciona con casi todas las tablas de hechos por medio de `seleccion_id`.
- `jugadores` se relaciona con `apariciones_partido`, `goles`, `tarjetas`, `cambios`, `penales`, `goleadores`, `premios` y `planteles`.
- `partidos` es el centro de los hechos por encuentro: alineaciones, goles, tarjetas, cambios y tandas de penales.

## Cómo cargar los datos

### 1. Crear la estructura

```bash
psql -h <host> -U <user> -d <database> -f py/db/postgres_schema.sql
```

### 2. Ajustar rutas de CSV en `postgres_etl.sql`

Debes revisar al inicio del archivo las variables `\set`, por ejemplo:

```sql
\set f_partidos 'C:/Users/Enner/Desktop/bases2_proyecto1/datos_normalizados/partidos.csv'
```

### 3. Ejecutar el ETL

```bash
psql -h <host> -U <user> -d <database> -f py/db/postgres_etl.sql
```

## Validaciones rápidas

```sql
SELECT COUNT(*) AS mundiales FROM mundiales;
SELECT COUNT(*) AS selecciones FROM selecciones;
SELECT COUNT(*) AS jugadores FROM jugadores;
SELECT COUNT(*) AS partidos FROM partidos;
SELECT COUNT(*) AS goles FROM goles;
SELECT COUNT(*) AS penales FROM penales;
SELECT COUNT(*) AS planteles FROM planteles;
SELECT COUNT(*) AS participaciones FROM participaciones_mundial;
SELECT COUNT(*) AS pendientes_resolucion FROM resolucion_identidad_jugador WHERE jugador_id_resuelto IS NULL;
```

## Resolver identidades faltantes

Filas pendientes:

```sql
SELECT *
FROM resolucion_identidad_jugador
WHERE jugador_id_resuelto IS NULL
ORDER BY resolucion_id DESC
LIMIT 100;
```

Asignar manualmente un jugador ya conocido:

```sql
UPDATE resolucion_identidad_jugador r
SET jugador_id_resuelto = j.jugador_id,
    jugador_slug_resuelto = j.slug,
    metodo = 'manual',
    confianza = 1.00,
    notas = 'Resuelto por revision manual',
    resolved_at = now()
FROM jugadores j
WHERE r.resolucion_id = <RESOLUCION_ID>
  AND j.slug = '<JUGADOR_SLUG>';

## Qué significa un slug

`slug` no significa “nombre de jugador más nombre de equipo”.

En español, lo más cercano sería decir que es un `identificador legible`, `etiqueta normalizada` o `clave textual estable`.

La idea es convertir un texto visible a una forma más consistente para usarlo como referencia técnica. Por ejemplo:

- `Argentina` -> `argentina`
- `Lionel Messi` -> `lionel_messi`
- `2022 Argentina vs Francia` -> `2022_argentina_francia`

Sus propiedades importantes son estas:

- Usa solo caracteres simples, normalmente minúsculas, números y guiones o guiones bajos.
- Evita espacios, tildes y símbolos raros.
- Intenta mantenerse estable aunque cambie el formato visual del texto.

En este proyecto el slug sirve para enlazar datos entre archivos y tablas sin depender tanto del nombre visible. Por ejemplo, si `Lionel Messi` aparece en `goles.csv`, `premios.csv` y `jugadores.csv`, el slug ayuda a decir que se trata de la misma persona.

## Qué es un slug confiable

Un `slug confiable` es uno que realmente identifica a la misma entidad de forma consistente en varias fuentes del sitio.

Ejemplo de slug confiable:

- una página de jugador enlaza a `/jugadores/lionel_messi.php`
- el scraper toma `lionel_messi`
- ese mismo valor vuelve a aparecer desde otros links del sitio para el mismo jugador

Eso es confiable porque viene de la URL oficial del propio sitio.

Ejemplo de slug poco confiable o ausente:

- en una tabla solo aparece el texto del nombre, pero no hay link al jugador
- entonces solo ves `Messi` o `Lionel Messi` escrito en HTML plano
- ahí no puedes asegurar al 100% cuál ficha del sitio le corresponde

Por eso existe la tabla `resolucion_identidad_jugador`: guarda casos donde hay nombre, pero no un slug suficientemente confiable para enlazarlo automáticamente.

## Para qué sirve `resolved_at`

`resolved_at` guarda el momento en que una fila pendiente de `resolucion_identidad_jugador` fue resuelta manualmente.

Sirve para saber:

- si ya fue revisada
- cuándo se revisó
- qué pendientes siguen abiertos

No es obligatorio para que la base funcione. A diferencia de `slug`, no es estructural. Si quieres un modelo todavía más minimalista, también se podría eliminar sin romper la carga principal.
```
