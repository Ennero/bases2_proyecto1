# Scraper normalizado de Mundiales

El script principal y único flujo de extracción vigente es `py/scraping_normalizado.py`.

Genera CSV estrictamente normalizados listos para cargarse en una base relacional y puede trabajar en tres formas:

- `local`: lee la carpeta `html_descargados`.
- `web`: consulta directamente `https://www.losmundialesdefutbol.com`.
- `--raw-dir`: transforma una carpeta de CSV legacy al nuevo formato final.

## CSV generados

| CSV | Descripción |
|---|---|
| `mundial.csv` | Resumen general por edición |
| `seleccion.csv` | Selecciones canónicas |
| `seleccion_alias.csv` | Alias históricos y equivalencias de selección |
| `participacion_mundial.csv` | Resumen por selección y mundial |
| `jugador.csv` | Catálogo de jugadores |
| `entrenador.csv` | Catálogo de entrenadores |
| `partido.csv` | Hecho principal del partido con FK de selecciones |
| `aparicion_partido.csv` | Titulares, ingresos y suplentes por partido |
| `direccion_tecnica_partido.csv` | Entrenadores vinculados a cada partido |
| `gol.csv` | Goles por partido, incluyendo penal y autogol |
| `tarjeta.csv` | Tarjetas amarillas y rojas |
| `cambio.csv` | Sustituciones |
| `penal.csv` | Ejecuciones detalladas de tandas de penales |
| `grupo.csv` | Tabla de posiciones por grupo |
| `posicion_final.csv` | Ranking final por mundial |
| `goleador.csv` | Goleadores por edición |
| `premio_jugador.csv` | Premios cuyo destinatario es un jugador |
| `premio_seleccion.csv` | Premios cuyo destinatario es una selección |
| `plantel_jugador.csv` | Jugadores convocados por mundial |
| `plantel_entrenador.csv` | Entrenadores del plantel por mundial |
| `resolucion_identidad_jugador.csv` | Casos ambiguos que requieren conciliación posterior |

## Dependencias

```bash
pip install pandas beautifulsoup4
```

En modo `local` solo necesitas leer los HTML descargados.

En modo `web`, el scraper usa Microsoft Edge en modo headless para evitar el bloqueo `403` del sitio. No depende de Selenium ni de drivers externos, pero sí necesita que Edge esté instalado en Windows.

## Uso con HTML descargado

Desde la raíz del proyecto:

```bash
C:/Users/Enner/Desktop/bases2_proyecto1/.venv/Scripts/python.exe py/scraping_normalizado.py --origen local --html-dir ./html_descargados --salida ./datos_normalizados_local
```

## Conversión de una carpeta legacy

```bash
C:/Users/Enner/Desktop/bases2_proyecto1/.venv/Scripts/python.exe py/scraping_normalizado.py --raw-dir ./datos_normalizados_web --salida ./datos_normalizados_web
```

Ese modo lee los CSV existentes, elimina archivos obsoletos como `premio.csv` y `plantel.csv`, y deja la carpeta en el nuevo formato final.

`resolucion_identidad_jugador.csv` se escribe siempre. Si no hubo ambigüedades, queda como un CSV vacío con encabezados para que el ETL no falle.

Para probar solo una parte:

```bash
C:/Users/Enner/Desktop/bases2_proyecto1/.venv/Scripts/python.exe py/scraping_normalizado.py --origen local --html-dir ./html_descargados --salida ./datos_prueba --anio 2022 --seccion mundiales partidos premios planteles
```

## Uso contra el sitio en vivo

```bash
C:/Users/Enner/Desktop/bases2_proyecto1/.venv/Scripts/python.exe py/scraping_normalizado.py --origen web --salida ./datos_normalizados_web
```

Si quieres bajar la presión sobre el sitio, sube la pausa entre requests:

```bash
C:/Users/Enner/Desktop/bases2_proyecto1/.venv/Scripts/python.exe py/scraping_normalizado.py --origen web --pausa 0.5 --salida ./datos_normalizados_web
```

## Opciones útiles

- `--anio 2022`: limita a una o varias ediciones.
- `--seccion partidos grupos`: ejecuta solo ciertas secciones.
- `--salida ./mi_carpeta`: cambia la carpeta de salida.
- `--limite-jugadores 50`: útil para pruebas rápidas en la sección de jugadores.
- `--html-dir ./html_descargados`: ubicación del mirror local.
- `--pausa 0.2`: espera entre requests en modo web.

## Secciones disponibles

`partidos` `grupos` `posiciones` `goleadores` `premios` `planteles` `selecciones` `jugadores` `mundiales`

## Notas del modelo de extracción

- Los `slug` pueden seguir existiendo internamente durante la extracción o en el formato legacy, pero ya no forman parte del modelo persistido final.
- `penal.csv` existe solo para las tandas detalladas, no para goles de penal en tiempo regular.
- Los autogoles se marcan en `gol.csv` mediante `es_autogol`.
- Los premios quedaron separados en `premio_jugador.csv` y `premio_seleccion.csv`.
- Los planteles quedaron separados en `plantel_jugador.csv` y `plantel_entrenador.csv`.
- `plantel_jugador.csv` conserva solo atributos dependientes del plantel o de esa convocatoria, como posición, camiseta y club; la fecha de nacimiento y la altura quedan en `jugador.csv`.
