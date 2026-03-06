# Scraper normalizado de Mundiales

El script principal es `py/scraping_normalizado.py`.

Genera CSV listos para cargarse en una base relacional y ahora puede trabajar en dos modos:

- `local`: lee la carpeta `html_descargados`.
- `web`: consulta directamente `https://www.losmundialesdefutbol.com`.

## CSV generados

| CSV | Descripción |
|---|---|
| `mundiales.csv` | Resumen general por edición, incluyendo promedio de gol |
| `selecciones.csv` | Ficha histórica resumida por selección |
| `participaciones_mundial.csv` | Resumen por selección y mundial |
| `jugadores.csv` | Ficha ampliada de jugador |
| `partidos.csv` | Resultado, fecha, etapa, prórroga y penales |
| `apariciones_partido.csv` | Titulares, ingresos, suplentes y entrenador por partido |
| `goles.csv` | Goles por partido, incluyendo penal y autogol |
| `tarjetas.csv` | Tarjetas amarillas y rojas |
| `cambios.csv` | Sustituciones |
| `penales.csv` | Ejecuciones detalladas de tandas de penales |
| `grupos.csv` | Tabla de posiciones por grupo |
| `posiciones_finales.csv` | Ranking final por mundial |
| `goleadores.csv` | Goleadores por edición |
| `premios.csv` | Premios a jugadores y selecciones |
| `planteles.csv` | Planteles por mundial, incluyendo altura, club y entrenador |

## Dependencias

```bash
pip install pandas beautifulsoup4
```

No depende de Selenium.

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
- `penales.csv` existe solo para las tandas detalladas, no para goles de penal en tiempo regular.
- Los autogoles se marcan en `goles.csv` mediante `es_autogol`.
- Los premios ahora distinguen si el destinatario fue un `jugador` o una `seleccion`.
- Los planteles incluyen filas de `rol = entrenador`.
