# Scraper normalizado de Mundiales

El script principal y único flujo de extracción vigente es `py/scraping_normalizado.py`.

Genera CSV listos para cargarse en una base relacional y ahora puede trabajar en dos modos:

- `local`: lee la carpeta `html_descargados`.
- `web`: consulta directamente `https://www.losmundialesdefutbol.com`.

## CSV generados

| CSV | Descripción |
|---|---|
| `mundial.csv` | Resumen general por edición, incluyendo promedio de gol |
| `seleccion.csv` | Ficha histórica resumida por selección |
| `participacion_mundial.csv` | Resumen por selección y mundial |
| `jugador.csv` | Ficha ampliada de jugador |
| `partido.csv` | Resultado, fecha, etapa, prórroga y penales |
| `aparicion_partido.csv` | Titulares, ingresos, suplentes y entrenador por partido |
| `gol.csv` | Goles por partido, incluyendo penal y autogol |
| `tarjeta.csv` | Tarjetas amarillas y rojas |
| `cambio.csv` | Sustituciones |
| `penal.csv` | Ejecuciones detalladas de tandas de penales |
| `grupo.csv` | Tabla de posiciones por grupo |
| `posicion_final.csv` | Ranking final por mundial |
| `goleador.csv` | Goleadores por edición |
| `premio.csv` | Premios a jugadores y selecciones |
| `plantel.csv` | Planteles por mundial, incluyendo altura, club y entrenador |

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

- Los `slug` salen de las URLs y se usan como clave natural.
- `penal.csv` existe solo para las tandas detalladas, no para goles de penal en tiempo regular.
- Los autogoles se marcan en `gol.csv` mediante `es_autogol`.
- Los premios ahora distinguen si el destinatario fue un `jugador` o una `seleccion`.
- Los planteles incluyen filas de `rol = entrenador`.
