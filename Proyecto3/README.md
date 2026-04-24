# 🏆 Sistema de Consultas — Mundiales de Fútbol (MongoDB)

Fase 3 del proyecto de Bases de Datos 2 (USAC). Este módulo implementa una
interfaz en Python para consultar la base de datos NoSQL de Mundiales de
Fútbol (1930–2026) almacenada en MongoDB Atlas.

Es la continuación de la Fase 1 (base relacional en SQL Server) y la
Fase 2 (simulación de backups y restauraciones). Aquí los mismos datos
históricos fueron migrados a un modelo de documentos en MongoDB.

---

## 🚀 Requisitos previos

**Python:** 3.8 o superior.

**Dependencias:**

```bash
pip install -r requirements.txt
```

El archivo `requirements.txt` incluye:

```
pymongo
certifi
```

- `pymongo` — cliente oficial de MongoDB para Python.
- `certifi` — gestiona los certificados SSL requeridos por MongoDB Atlas.

**Conexión:** los scripts se conectan automáticamente al cluster en MongoDB
Atlas. No se requiere instalar MongoDB localmente. La cadena de conexión está
centralizada en `conexion.py`.

---

## 📂 Estructura del proyecto

```
fase3/
├── main.py          # Menú interactivo — punto de entrada principal
├── conexion.py      # Conexión centralizada a MongoDB Atlas
├── metodo_c.py      # Método C: reporte completo por año de mundial
├── metodo_d.py      # Método D: expediente completo por selección
├── consultas.py     # Consultas rápidas y resúmenes generales
└── requirements.txt # Dependencias del proyecto
```

---

## 🗄️ Modelo de datos en MongoDB

La base de datos se llama `mundiales` y contiene 4 colecciones principales.
A diferencia del modelo relacional de la Fase 1, MongoDB embebe los datos
relacionados dentro del mismo documento para evitar JOINs costosos.

### Colección `mundial`

Un documento por cada edición del Mundial. Embebe grupos, posiciones finales,
goleadores del torneo, premios, planteles y participaciones de todas las
selecciones en esa edición.

| Campo                   | Tipo   | Descripcion                                 |
| :---------------------- | :----- | :------------------------------------------ |
| `anio`                  | int    | Año del mundial (identificador)             |
| `sede`                  | string | País o países sede                          |
| `equipos`               | int    | Cantidad de selecciones participantes       |
| `partidosJugados`       | int    | Total de partidos disputados                |
| `golesTotal`            | int    | Total de goles del torneo                   |
| `grupos`                | array  | Tabla de posiciones por grupo               |
| `posicionFinals`        | array  | Ranking final del torneo                    |
| `goleadors`             | array  | Goleadores del torneo con cantidad de goles |
| `premioJugadors`        | array  | Premios individuales (Balón de Oro, etc.)   |
| `premioSeleccions`      | array  | Premios colectivos (Fair Play, etc.)        |
| `participacionMundials` | array  | Campaña de cada selección en esa edición    |
| `plantelJugadors`       | array  | Convocados por selección                    |
| `plantelEntrenadors`    | array  | Técnicos por selección                      |

### Colección `partido`

Un documento por cada partido disputado. Embebe goles, tarjetas, cambios,
apariciones de jugadores y dirección técnica de ese partido.

| Campo                      | Tipo     | Descripcion                                    |
| :------------------------- | :------- | :--------------------------------------------- |
| `partidoId`                | int      | Identificador del partido                      |
| `anio`                     | int      | Edición del mundial                            |
| `fecha`                    | string   | Fecha del partido                              |
| `etapa`                    | string   | Fase del torneo (Grupos, Octavos, Final, etc.) |
| `localSeleccionId`         | int      | ID de la selección local                       |
| `visitanteSeleccionId`     | int      | ID de la selección visitante                   |
| `golesLocal`               | int      | Goles del equipo local                         |
| `golesVisitante`           | int      | Goles del equipo visitante                     |
| `tiempoExtra`              | bool     | Si hubo prórroga                               |
| `definicionPenales`        | bool     | Si se definió por penales                      |
| `penalesLocal`             | int/null | Penales convertidos por el local               |
| `penalesVisitante`         | int/null | Penales convertidos por el visitante           |
| `gols`                     | array    | Detalle de cada gol con jugador y minuto       |
| `tarjetas`                 | array    | Tarjetas amarillas y rojas                     |
| `cambios`                  | array    | Sustituciones realizadas                       |
| `aparicionPartidos`        | array    | Jugadores titulares, ingresados y suplentes    |
| `direccionTecnicaPartidos` | array    | Entrenadores que dirigieron el partido         |

### Colección `seleccion`

Un documento por cada selección. Embebe toda su historia en mundiales:
participaciones, grupos, goles, tarjetas, planteles y entrenadores.

| Campo                   | Tipo   | Descripcion                                    |
| :---------------------- | :----- | :--------------------------------------------- |
| `seleccionId`           | int    | Identificador de la selección                  |
| `nombre`                | string | Nombre de la selección                         |
| `participacionMundials` | array  | Campaña por edición con estadísticas completas |
| `grupos`                | array  | Desempeño en fase de grupos por edición        |
| `posicionFinals`        | array  | Posición final por edición                     |
| `gols`                  | array  | Todos los goles anotados históricamente        |
| `tarjetas`              | array  | Todas las tarjetas recibidas                   |
| `goleadors`             | array  | Goleadores de la selección por edición         |
| `plantelJugadors`       | array  | Jugadores convocados por edición               |
| `plantelEntrenadors`    | array  | Técnicos por edición                           |

### Colección `jugador`

Un documento por cada jugador. Embebe sus apariciones en partidos, goles
anotados y convocatorias.

| Campo               | Tipo        | Descripcion                   |
| :------------------ | :---------- | :---------------------------- |
| `jugadorId`         | int         | Identificador del jugador     |
| `nombre`            | string      | Nombre del jugador            |
| `nombreCompleto`    | string/null | Nombre completo               |
| `fechaNacimiento`   | string      | Fecha de nacimiento           |
| `altura`            | string/null | Altura                        |
| `aparicionPartidos` | array       | Partidos en los que participó |
| `gols`              | array       | Goles que anotó               |
| `plantelJugadors`   | array       | Convocatorias recibidas       |

---

## 🛠️ Guía de uso

### Opción 1 — Menú interactivo (recomendado)

```bash
python main.py
```

Presenta un menú con dos opciones y acepta filtros opcionales paso a paso:

```
========================================
   MENÚ DE CONSULTAS - FASE 3
========================================
1. Buscar Mundial por Año (Método C)
2. Buscar Selección por País (Método D)
0. Salir
```

### Opción 2 — Importar los métodos directamente

```python
from metodo_c import info_mundial_por_anio
from metodo_d import info_por_pais

info_mundial_por_anio(2022)
info_por_pais("Argentina")
```

### Opción 3 - Ejecutar desde la terminal

```python
python -c "from metodo_c import info_mundial_por_anio; info_mundial_por_anio(2022)"

python -c "from metodo_d import info_por_pais; info_por_pais('Argentina')"
```

### Opción 4 — Consultas rápidas

```bash
python consultas.py
```

Ejecuta las 6 consultas de resumen general en secuencia.

---

## 📘 Método C — `info_mundial_por_anio`

Muestra el reporte completo de una edición del Mundial.

### Parámetros

| Parametro      | Tipo | Requerido | Descripcion                         | Ejemplo         |
| :------------- | :--- | :-------- | :---------------------------------- | :-------------- |
| `anio_buscado` | int  | Si        | Año del mundial a consultar         | `2022`          |
| `filtro_grupo` | str  | No        | Muestra solo el grupo indicado      | `"A"`           |
| `filtro_pais`  | str  | No        | Filtra partidos del pais indicado   | `"Brasil"`      |
| `filtro_fecha` | str  | No        | Filtra partidos de una fecha exacta | `"18-Dic-2022"` |

### Secciones que despliega

1. Informacion general: sede, equipos, partidos jugados, goles totales y promedio.
2. Podio: campeon, subcampeon, tercer y cuarto lugar.
3. Premios: individuales (Balon de Oro, Bota de Oro) y colectivos (Fair Play).
4. Fase de grupos: tabla completa con PJ, PG, PE, PP, GF, GC, Dif, Pts y clasificacion.
5. Partidos jugados: con resultado calculado e indicador de definicion por penales.

### Ejemplos de uso

```python
from metodo_c import info_mundial_por_anio

# Mundial 2022 completo
info_mundial_por_anio(2022)

# Solo el grupo B del Mundial 1998
info_mundial_por_anio(1998, filtro_grupo="B")

# Partidos de Argentina en el 2022
info_mundial_por_anio(2022, filtro_pais="Argentina")

# Partidos del 18 de diciembre de 2022 (la final)
info_mundial_por_anio(2022, filtro_fecha="18-Dic-2022")

# Partidos de Brasil en el grupo G del 2022
info_mundial_por_anio(2022, filtro_grupo="G", filtro_pais="Brasil")
```

Desde el menú interactivo:

```
▶ Ingresa el año del mundial: 2022
Filtro - Grupo (ej. A, B): G
Filtro - País participante (ej. Brasil): Brasil
Filtro - Fecha exacta (ej. 12-Jul-1998): [Enter para omitir]
```

---

## 📗 Método D — `info_por_pais`

Muestra el expediente historico completo de una seleccion.

### Parámetros

| Parametro      | Tipo | Requerido | Descripcion                                    | Ejemplo       |
| :------------- | :--- | :-------- | :--------------------------------------------- | :------------ |
| `nombre_pais`  | str  | Si        | Nombre de la seleccion                         | `"Argentina"` |
| `filtro_anio`  | int  | No        | Filtra todas las secciones a un año especifico | `2022`        |
| `filtro_etapa` | str  | No        | Filtra partidos por etapa del torneo           | `"Final"`     |

### Secciones que despliega

1. Historial como sede: años en que el pais organizo el mundial.
2. Resumen historico acumulado: mundiales jugados, partidos, goles y mejor resultado.
3. Rendimiento por edicion: tabla con estadisticas de cada mundial jugado.
4. Desempeno en fase de grupos: grupo, posicion y estadisticas por edicion.
5. Top 5 goleadores historicos del pais con los mundiales en que anotaron.
6. Historial de partidos: resultado desde perspectiva del pais, indicando si fue local o visitante y si hubo penales.

### Ejemplos de uso

```python
from metodo_d import info_por_pais

# Expediente completo de Argentina
info_por_pais("Argentina")

# Solo el Mundial 2022 de Argentina
info_por_pais("Argentina", filtro_anio=2022)

# Solo las finales de Brasil en toda su historia
info_por_pais("Brasil", filtro_etapa="Final")

# Alemania en el Mundial 1974
info_por_pais("Alemania", filtro_anio=1974)

# La busqueda es insensible a mayusculas
info_por_pais("argentina")
info_por_pais("BRASIL")
```

---

## 📙 Consultas rápidas — `consultas.py`

Ejecuta 6 funciones de resumen general sobre toda la base de datos.

| Funcion                       | Descripcion                                                             |
| :---------------------------- | :---------------------------------------------------------------------- |
| `resumen_mundiales()`         | Lista todos los mundiales con sede, equipos, partidos, goles y promedio |
| `campeones()`                 | Muestra el campeon de cada edicion                                      |
| `goles_hechos_mundiales(top)` | Top N goleadores historicos de todos los mundiales                      |
| `tabla_grupos(anio)`          | Tabla de grupos completa de un mundial especifico                       |
| `rendimiento_seleccion(pais)` | Estadisticas acumuladas de una seleccion                                |
| `podios()`                    | Veces que cada seleccion quedo en 1ro, 2do o 3er lugar                  |

```bash
# Ejecutar todas las consultas en secuencia
python consultas.py
```

```python
# Importar funciones individuales
from consultas import campeones, podios, goles_hechos_mundiales

campeones()
podios()
goles_hechos_mundiales(top=5)
```

---

## ⚙️ Detalles de implementacion

### Conexion a MongoDB Atlas

La conexion esta centralizada en `conexion.py` para evitar duplicar codigo.
Todos los scripts importan `db` desde este modulo:

```python
from conexion import db
```

### Busqueda insensible a mayusculas

Los nombres de paises y filtros de etapa usan expresiones regulares con la
opcion `$options: "i"` para que `"brasil"`, `"Brasil"` y `"BRASIL"` devuelvan
el mismo resultado.

### Agregaciones con `$lookup`

El Metodo C usa un pipeline de agregacion para unir la coleccion `mundial`
con la coleccion `partido` usando el campo `anio` como clave de union, ya que
los partidos no estan embebidos dentro del documento del mundial sino en su
propia coleccion.

### Goleadores historicos

El Metodo D calcula los goleadores historicos de una seleccion usando
`$unwind` sobre la coleccion `partido` para descomponer el array de goles
y luego agrupar por jugador. Los autogoles se excluyen del conteo.

---
