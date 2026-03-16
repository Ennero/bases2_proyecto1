# Stored Procedures — Mundiales de Fútbol

Este documento explica los dos stored procedures implementados para el proyecto,
su propósito, cómo están construidos internamente y cómo ejecutarlos.

Los SPs cubren los requerimientos d) y e) del enunciado:

- `sp_mundial_por_anio`: despliega toda la información de una edición del Mundial.
- `sp_historial_pais`: despliega el historial completo de una selección.

---

## Consideración importante sobre nombres

Los datos en la base están normalizados sin tildes ni diacríticos. Esto es consecuencia
de una decisión técnica: `BULK INSERT` en SQL Server sobre Linux no soporta UTF-8,
por lo que el script `02_fix_csvs.sh` convierte todos los caracteres acentuados a su
equivalente ASCII antes de cargar los datos.

Esto significa que al llamar a los SPs se deben usar nombres sin tildes:

| Lo que se busca | Cómo escribirlo |
| --------------- | --------------- |
| España          | `Espana`        |
| México          | `Mexico`        |
| Bélgica         | `Belgica`       |
| Japón           | `Japon`         |
| Irán            | `Iran`          |
| Túnez           | `Tunez`         |

---

## Archivo

El archivo se encuentra en `py/db/stored_procedures.sql`. Para cargarlo en la base:

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -d mundiales `
  -i /db_scripts/stored_procedures.sql
```

---

## SP 1: `sp_mundial_por_anio`

### Introducción

Recibe el año de un Mundial y despliega toda la información relacionada con esa
edición: resumen del torneo, posiciones finales, tablas de grupos, partidos con
sus resultados, detalle de goles, ranking de goleadores, premios, tarjetas y
planteles convocados. Acepta parámetros opcionales para filtrar la salida por
grupo, país o fecha.

### Firma

```sql
EXEC dbo.sp_mundial_por_anio
    @anio  INT,               -- obligatorio: año del mundial (ej: 2022)
    @grupo CHAR(1)   = NULL,  -- opcional: letra del grupo (ej: 'A')
    @pais  NVARCHAR(191) = NULL,  -- opcional: nombre del país sin tildes
    @fecha NVARCHAR(64)  = NULL   -- opcional: fecha exacta (ej: '20-Nov-2022')
```

### Construcción interna

El SP valida primero que el año exista en la tabla `mundial`. Si no existe, lanza
un error con `RAISERROR` y detiene la ejecución. Luego ejecuta diez consultas
en secuencia, cada una mostrando una sección distinta:

**Sección 1 — Resumen general**
Consulta directa a `mundial`. Calcula el promedio de goles por partido con
`CAST(goles_total AS DECIMAL) / partidos_jugados`.

**Sección 2 — Posiciones finales**
JOIN entre `posicion_final` y `seleccion`. Usa un `CASE` sobre `posicion`
para etiquetar las primeras cuatro posiciones (Campeón, Subcampeón, etc.).

**Sección 3 — Tabla de grupos**
JOIN entre `grupo` y `seleccion`. El filtro `@grupo` se aplica con
`UPPER(@grupo)` para aceptar tanto mayúsculas como minúsculas. Muestra
todas las métricas estadísticas del grupo.

**Sección 4 — Partidos y resultados**
Triple JOIN: `partido` con `seleccion` dos veces (local y visitante). Calcula
el ganador con un `CASE` que evalúa goles normales y, si hubo penales, el
marcador de penales. El filtro `@pais` aplica sobre ambos equipos con `OR`.

**Sección 5 — Detalle de goles**
JOIN entre `gol`, `partido`, `seleccion` (×3) y `jugador` con `LEFT JOIN`
para los casos donde el goleador no fue identificado. Clasifica cada gol
como Gol, Penal o Autogol.

**Sección 6 — Goleadores del torneo**
JOIN entre `goleador`, `jugador` y `seleccion`. Usa `ROW_NUMBER() OVER
(ORDER BY goles DESC)` para generar el ranking dinámicamente.

**Sección 7 — Premios**
`UNION ALL` entre `premio_jugador` y `premio_seleccion` para mostrar todos
los premios en una sola tabla. Los premios colectivos muestran `NULL` en la
columna Jugador.

**Sección 8 — Tarjetas**
Agrega tarjetas por selección usando `SUM(CASE WHEN tipo = 'amarilla' THEN 1
ELSE 0 END)`. Ordena por total de tarjetas descendente.

**Sección 9 — Planteles**
JOIN entre `plantel_jugador`, `seleccion` y `jugador`. Si se filtra por
grupo, hace un subquery a `grupo` para obtener las selecciones del grupo
y filtrar el plantel con `IN`.

**Sección 10 — Entrenadores**
`SELECT DISTINCT` sobre `plantel_entrenador` y `entrenador` para evitar
duplicados por edición.

### Ejemplos de uso

```sql
-- Mundial 2022 completo
EXEC dbo.sp_mundial_por_anio @anio = 2022;

-- Solo el grupo A del Mundial 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @grupo = 'A';

-- Partidos de Argentina en el Mundial 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @pais = 'Argentina';

-- Partidos del 20 de noviembre de 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @fecha = '20-Nov-2022';

-- Partidos de Espana en el grupo A del Mundial 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @grupo = 'A', @pais = 'Espana';
```

### Salida esperada (resumen de secciones)

| #   | Sección               | Tablas involucradas                                          |
| --- | --------------------- | ------------------------------------------------------------ |
| 1   | Resumen general       | `mundial`                                                    |
| 2   | Posiciones finales    | `posicion_final`, `seleccion`                                |
| 3   | Tabla de grupos       | `grupo`, `seleccion`                                         |
| 4   | Partidos y resultados | `partido`, `seleccion` ×2                                    |
| 5   | Detalle de goles      | `gol`, `partido`, `seleccion` ×3, `jugador`                  |
| 6   | Goleadores del torneo | `goleador`, `jugador`, `seleccion`                           |
| 7   | Premios               | `premio_jugador`, `premio_seleccion`, `jugador`, `seleccion` |
| 8   | Tarjetas              | `tarjeta`, `partido`, `seleccion`                            |
| 9   | Planteles             | `plantel_jugador`, `seleccion`, `jugador`                    |
| 10  | Entrenadores          | `plantel_entrenador`, `seleccion`, `entrenador`              |

---

## SP 2: `sp_historial_pais`

### Introducción

Recibe el nombre de una selección y despliega toda su historia en los Mundiales:
resumen estadístico acumulado, participaciones edición por edición indicando si
fue sede, desempeño en fase de grupos, todos los partidos con resultado desde la
perspectiva del país, goles anotados, top de goleadores históricos, premios
obtenidos, entrenadores y jugadores más convocados a lo largo del tiempo.

### Firma

```sql
EXEC dbo.sp_historial_pais
    @pais  NVARCHAR(191),     -- obligatorio: nombre sin tildes (ej: 'Argentina')
    @anio  INT = NULL         -- opcional: filtra a una edición específica
```

### Construcción interna

El SP comienza resolviendo el `seleccion_id` a partir del nombre recibido. Busca
primero en `seleccion` (nombre canónico) y si no lo encuentra busca en
`seleccion_alias` (nombres históricos como "Alemania Occidental", "URSS", etc.).
Si tampoco se encuentra, lanza un `RAISERROR` informativo y detiene la ejecución.

Con el `seleccion_id` resuelto ejecuta diez consultas en secuencia:

**Sección 1 — Resumen histórico**
Agrega toda la tabla `participacion_mundial` filtrando por `seleccion_id`. Usa
`CASE WHEN pm.participo = 1` para excluir las ediciones donde no clasificó de
los conteos estadísticos. Identifica el primer título con `MIN(CASE WHEN
posicion = 1 THEN anio END)`.

**Sección 2 — Participaciones por edición**
JOIN entre `participacion_mundial` y `mundial`. Determina si la selección fue
sede comparando `m.sede LIKE CONCAT('%', @nombre_canonico, '%')`, ya que
la columna `sede` puede contener múltiples países (ejemplo: "Corea del Sur /
Japón" en 2002).

**Sección 3 — Mundiales como sede**
Consulta directa a `mundial` con el mismo `LIKE` sobre `sede`. Si no hay
resultados, muestra un mensaje informativo con `SELECT 'Esta seleccion no ha
sido sede...'`.

**Sección 4 — Desempeño en fase de grupos**
Consulta directa a `grupo` filtrando por `seleccion_id`. Muestra las métricas
estadísticas del grupo y si clasificó a la siguiente fase.

**Sección 5 — Partidos jugados**
JOIN entre `partido` y `seleccion` (×2). El filtro aplica con `OR` sobre
`local_seleccion_id` y `visitante_seleccion_id`. El resultado (Ganado/Empate/
Perdido) evalúa el marcador desde la perspectiva de la selección, considerando
también los penales cuando `definicion_penales = 1`.

**Sección 6 — Goles anotados por edición y jugador**
JOIN entre `gol`, `partido` y `jugador` filtrando por `seleccion_id` del gol.
Agrupa por `anio` y `jugador` para mostrar cuánto aportó cada jugador en cada
edición.

**Sección 7 — Top goleadores históricos**
Misma lógica pero sin agrupar por año, con `COUNT(DISTINCT p.anio)` para
saber en cuántos mundiales anotó cada jugador. Limitado a `TOP 10` y excluye
autogoles con `es_autogol = 0`.

**Sección 8 — Premios obtenidos**
`UNION ALL` entre `premio_jugador` y `premio_seleccion`, ambos filtrados por
`seleccion_id`. Clasifica cada premio como Individual o Colectivo.

**Sección 9 — Entrenadores históricos**
`SELECT DISTINCT` sobre `plantel_entrenador` y `entrenador` para listar los
técnicos por edición sin duplicados.

**Sección 10 — Jugadores más convocados**
Agrega `plantel_jugador` por jugador contando ediciones con `COUNT(*)`.
Limitado a `TOP 15` ordenado por cantidad de mundiales convocado.

### Ejemplos de uso

```sql
-- Historial completo de Argentina
EXEC dbo.sp_historial_pais @pais = 'Argentina';

-- Historial de Argentina solo en el Mundial 2022
EXEC dbo.sp_historial_pais @pais = 'Argentina', @anio = 2022;

-- Historial de Espana (sin tilde)
EXEC dbo.sp_historial_pais @pais = 'Espana';

-- Historial de Mexico (sin tilde)
EXEC dbo.sp_historial_pais @pais = 'Mexico';

-- Historial de Brasil
EXEC dbo.sp_historial_pais @pais = 'Brasil';

-- Historial de Alemania en el Mundial 1974
EXEC dbo.sp_historial_pais @pais = 'Alemania', @anio = 1974;
```

### Salida esperada (resumen de secciones)

| #   | Sección                     | Tablas involucradas                             |
| --- | --------------------------- | ----------------------------------------------- |
| 1   | Resumen histórico acumulado | `participacion_mundial`                         |
| 2   | Participaciones por edición | `participacion_mundial`, `mundial`              |
| 3   | Mundiales como sede         | `mundial`                                       |
| 4   | Desempeño en fase de grupos | `grupo`                                         |
| 5   | Partidos jugados            | `partido`, `seleccion` ×2                       |
| 6   | Goles por edición y jugador | `gol`, `partido`, `jugador`                     |
| 7   | Top goleadores históricos   | `gol`, `partido`, `jugador`                     |
| 8   | Premios obtenidos           | `premio_jugador`, `premio_seleccion`, `jugador` |
| 9   | Entrenadores históricos     | `plantel_entrenador`, `entrenador`              |
| 10  | Jugadores más convocados    | `plantel_jugador`, `jugador`                    |

---

## Cómo ejecutar los SPs desde Docker

### Desde la terminal con sqlcmd

```powershell
# Mundial 2022
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -Q "EXEC dbo.sp_mundial_por_anio @anio = 2022"

# Historial de Argentina
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -Q "EXEC dbo.sp_historial_pais @pais = 'Argentina'"
```

### Desde DBeaver o Azure Data Studio

Abrir una nueva consulta conectado a la base `mundiales` y ejecutar directamente:

```sql
EXEC dbo.sp_mundial_por_anio @anio = 2022;
EXEC dbo.sp_historial_pais @pais = 'Argentina';
```

---

## Validaciones de error

Ambos SPs validan su parámetro principal antes de ejecutar. Si el año o país
no existe en la base, lanzan un mensaje descriptivo y se detienen:

```sql
-- Año inexistente
EXEC dbo.sp_mundial_por_anio @anio = 2000;
-- Msg: No existe un Mundial registrado para el año 2000.

-- País inexistente o con tilde
EXEC dbo.sp_historial_pais @pais = 'España';
-- Msg: No se encontró ninguna selección con el nombre "España".
--      Verifique que el nombre esté sin tildes.
```
