# Justificacion y Descripcion de las Tablas de la Base de Datos

Este documento justifica la decision de incluir cada una de las 21 tablas del modelo relacional, describe que almacena cada una con base en los datos reales verificados, y documenta observaciones relevantes encontradas durante la auditoria.

---

## Tablas Catalogo (entidades maestras)

### 1. mundial

**Que almacena:** cada fila representa una edicion de la Copa del Mundo FIFA. Contiene el anio (clave primaria), el pais o paises sede, la cantidad de equipos participantes, el total de partidos jugados y el total de goles del torneo.

**Justificacion:** es la tabla eje del modelo. Toda consulta historica parte de un anio de mundial. Sin esta tabla no se puede contextualizar ningun evento con su torneo.

**Observacion en los datos:** el mundial 2026 existe como registro pero todos sus valores numericos estan en 0, lo cual es correcto porque aun no se ha disputado. Hay 22 registros (1930-2026).

---

### 2. seleccion

**Que almacena:** catalogo de selecciones nacionales con un ID tecnico autoincremental y un nombre canonico unico. Contiene 87 selecciones.

**Justificacion:** es la segunda tabla eje del modelo. Todas las tablas de hechos referencian selecciones por ID. Centralizar los nombres permite evitar duplicados historicos (por ejemplo, "Alemania Federal" y "Alemania" se unifican aqui).

**Observacion en los datos:** los IDs tienen saltos; esto es normal para un catalogo construido por orden de aparicion en el scraping.

---

### 3. seleccion_alias

**Que almacena:** mapeo de nombres historicos o alternativos de selecciones al ID canonico. Ejemplo: "Alemania Occidental" apunta al mismo ID que "Alemania".

**Justificacion:** preservar la trazabilidad historica sin contaminar el catalogo principal. Permite buscar por nombres antiguos y obtener resultados unificados.

**Observacion en los datos:** pocos registros (~9). Cubre los alias definidos en la politica de canonizacion (Alemania Federal/Oriental, URSS, Yugoslavia, Checoslovaquia, Holanda).

---

### 4. jugador

**Que almacena:** catalogo maestro de jugadores. Cada fila contiene un ID, nombre principal, nombre completo, fecha de nacimiento, lugar de nacimiento, altura, apodo, sitio web y redes sociales. Tiene 8,444 registros.

**Justificacion:** es la tabla de referencia para todas las tablas de eventos de partidos (goles, tarjetas, cambios, apariciones). Sin ella no se puede saber quien anoto, quien fue amonestado, ni quien jugo.

**Observacion en los datos:** algunos jugadores de mundiales antiguos (pre-1950) tienen campos vacios en fecha de nacimiento y otros datos personales. Esto es esperado por la falta de registros historicos digitalizados.

---

### 5. entrenador

**Que almacena:** catalogo de directores tecnicos con un ID y su nombre. Tiene 366 registros.

**Justificacion:** la separacion del entrenador como entidad independiente del jugador es necesaria porque un entrenador no participa como jugador en los partidos, pero si dirige selecciones y aparece vinculado a planteles y partidos.

**Observacion en los datos:** sin problemas detectados.

---

## Tablas de Hechos Principales

### 6. partido

**Que almacena:** cada fila representa un partido disputado. Contiene: ID del partido, anio del mundial, fecha, etapa (grupo, octavos, cuartos, semifinal, final, etc.), seleccion local y visitante (por ID), goles de cada equipo, si hubo tiempo extra, si hubo definicion por penales, y el resultado de la tanda de penales. Tiene 965 registros.

**Justificacion:** es la tabla central de hechos del modelo. Los goles, tarjetas, cambios, penales y apariciones de jugadores se vinculan a un partido especifico.

**Observacion en los datos:** cuando no hubo tanda de penales, los campos penales_local y penales_visitante quedan nulos (no en cero). Esto es una decision de diseno para distinguir "no hubo tanda" de "hubo tanda con 0 goles".

---

### 7. gol

**Que almacena:** cada gol individual anotado en un partido. Contiene: ID del gol, ID del partido, ID de la seleccion, ID del jugador que anoto, minuto del gol, si fue de penal y si fue autogol. Tiene 2,721 registros.

**Justificacion:** esta es la tabla de detalle granular de anotaciones. Permite responder preguntas como "en que minuto anoto?", "cuantos goles de penal hubo?", "cuantos autogoles?". Es complementaria a la tabla goleador, que es un resumen.

**Observacion en los datos:** el jugador_id puede ser nulo en casos historicos donde no se pudo resolver la identidad del anotador.

---

### 8. goleador

**Que almacena:** lista de jugadores que aparecen en la tabla oficial de goleadores de cada edicion, con la cantidad real de goles anotados en ese torneo. Cada fila contiene: anio, jugador_id, seleccion_id, y `goles`. Tiene 1,643 registros.

**Fuente web:** https://www.losmundialesdefutbol.com/mundiales/{anio}_goleadores.php
**Archivo HTML local:** html_descargados/mundiales_{anio}_goleadores.php

**Justificacion:** El principal motivo para mantener esta tabla, a pesar de la existencia de la tabla `gol`, es la **fidelidad e integridad con la fuente de datos original**. La página web original tiene una sección estructurada explícita para la tabla oficial de goleadores por cada mundial, independiente del detalle de cada partido.
* Si visitas <https://www.losmundialesdefutbol.com/mundiales/2022_goleadores.php>, verás una tabla llamada "Goleadores" que enumera oficialmente a los jugadores con sus totales. 
* Mantener una tabla `goleador` en nuestro modelo relacional garantiza que estamos preservando la arquitectura de la información original de la web, respetando el ránking *oficialmente publicado* por ellos en lugar de intentar reconstruirlo a mano agrupando (con `JOIN` y `COUNT`) la tabla `gol`. 
* **Ejemplo práctico:** Si la FIFA, y por consiguiente la página, decidiera otorgar la autoría de un gol dudoso a otro jugador días después, esto se vería reflejado inmediatamente en su lista de "Goleadores". Al tener esta tabla, confiamos en la versión oficial publicada por la fuente en lugar de depender únicamente de nuestra suma de eventos en bruto, sirviendo como doble canal de validación.


---

### 9. tarjeta

**Que almacena:** cada tarjeta disciplinaria mostrada en un partido. Contiene: ID de tarjeta, ID de partido, ID de seleccion, ID de jugador, tipo de tarjeta y minuto. Tiene 2,731 registros.

**Justificacion:** el registro de amonestaciones y expulsiones es un hecho fundamental del futbol. Permite analizar patrones disciplinarios por seleccion, jugador, etapa del torneo y epoca historica.

**Observacion en los datos:** los tipos de tarjeta son "amarilla", "roja" y en algunos casos "doble amarilla" (que precede a una roja indirecta). Los mundiales anteriores a 1970 no tenian sistema de tarjetas, por lo que los registros comienzan desde ese anio.

---

### 10. cambio

**Que almacena:** cada sustitucion realizada en un partido. Contiene: ID del cambio, ID de partido, ID de seleccion, ID del jugador que sale, ID del jugador que entra y minuto. Tiene 3,818 registros.

**Justificacion:** las sustituciones son datos oficiales de cada partido. Permiten saber quien reemplazo a quien y en que momento, lo cual es relevante para analisis tactico historico.

**Observacion en los datos:** en mundiales antiguos, las sustituciones no existian (se permitieron oficialmente a partir de 1970). Los registros anteriores a esa fecha son escasos o inexistentes.

---

### 11. penal

**Que almacena:** cada ejecucion individual dentro de una tanda de penales. Contiene: ID, ID de partido, ID de seleccion, orden del tiro, ID del ejecutor y resultado (gol, atajado, desviado, poste). Tiene 321 registros.

**Justificacion:** las tandas de penales se introducieron en 1978. Registrar cada tiro individualmente permite analizar tasas de conversion, orden de ejecucion y rendimiento bajo presion.

**Observacion en los datos:** solo se registran tandas de definicion por penales, no penales durante el tiempo regular (esos estan en la tabla `gol` con es_penal = True).

---

## Tablas de Contexto de Partido

### 12. aparicion_partido

**Que almacena:** cada aparicion de un jugador en un partido. Contiene: ID de partido, ID de seleccion, ID de jugador, posicion, numero de camiseta, seccion (titular, ingresado, suplente_no_jugo) y si fue capitan. Tiene 43,324 registros — la tabla mas grande del modelo.

**Justificacion:** esta tabla es el registro completo de alineaciones. Sin ella no se puede saber quien jugo en cada partido, quien fue titular, quien entro de cambio ni quien fue capitan.

**Observacion en los datos:** las secciones son: `titular` (jugadores que iniciaron el partido), `ingresado` (jugadores que entraron como sustitutos) y `suplente_no_jugo` (jugadores en la banca que no ingresaron).

---

### 13. direccion_tecnica_partido

**Que almacena:** que entrenador dirigio a que seleccion en cada partido. Contiene: ID de partido, ID de seleccion e ID de entrenador. Tiene 1,929 registros (2 por partido, uno por equipo).

**Justificacion:** separar la direccion tecnica por partido permite saber exactamente quien dirigio en cada encuentro, lo cual puede diferir del entrenador registrado en el plantel si hubo cambio de DT durante el torneo.

**Observacion en los datos:** sin problemas detectados. La relacion es consistente.

---

## Tablas de Fase de Grupos y Clasificacion

### 14. grupo

**Que almacena:** la tabla de posiciones de la fase de grupos de cada mundial. Contiene: anio, letra del grupo, posicion en el grupo, seleccion, puntos, partidos jugados/ganados/empatados/perdidos, goles a favor/contra, diferencia de goles y si clasifico. Tiene 533 registros.

**Justificacion:** la fase de grupos es una estructura fundamental de los mundiales. Almacenar las tablas de posiciones permite analizar el rendimiento en esta fase especifica y entender el camino de cada seleccion en el torneo.

**Observacion en los datos:** mundiales anteriores a 1950 no tenian la estructura de grupos actual, por lo que algunos anios tienen formatos diferentes.

---

### 15. posicion_final

**Que almacena:** la clasificacion final oficial de cada seleccion en cada mundial. Contiene: anio, posicion y seleccion_id. Tiene 491 registros.

**Justificacion:** la posicion final es el dato definitivo de resultado del torneo. Es diferente a la participacion porque refleja la clasificacion asignada por FIFA, no apenas si participo o no.

**Observacion en los datos:** existen empates de posicion (por ejemplo, en 1970 dos equipos comparten la posicion 10; en 1934 tres equipos comparten la posicion 9). Esto es correcto y refleja la realidad de mundiales donde los equipos eliminados en la misma ronda reciben la misma posicion. PK compuesta: (anio, posicion, seleccion_id).

---

### 16. participacion_mundial

**Que almacena:** resumen de la campania de cada seleccion en cada edicion del mundial (o su no participacion). Contiene: anio, seleccion_id, posicion final, etapa maxima alcanzada, estadisticas completas (pts, pj, pg, pe, pp, gf, gc, dif) y una marca booleana de si participo o no. Tiene 1,929 registros.

**Justificacion:** esta tabla combina dos funciones: (1) registrar el resumen estadistico de la participacion efectiva, y (2) marcar mundiales donde la seleccion no participo (participo = False). Esto permite consultar tanto "como le fue a Argentina en 1986" como "en cuantos mundiales no participo Argentina".

**Observacion en los datos:** puede haber mas de una fila para la misma combinacion (anio, seleccion_id) debido a la canonizacion historica. Por ejemplo, si "Alemania Federal" y "Alemania" se unifican, ambos registros historicos se preservan. Los registros del mundial 2026 con participo=True pero sin estadisticas representan equipos ya clasificados para un torneo no disputado.

---

## Tablas de Planteles y Convocatorias

### 17. plantel_jugador

**Que almacena:** cada jugador convocado a un mundial por su seleccion. Contiene: anio, seleccion_id, jugador_id, posicion declarada, dorsal y club al momento de la convocatoria. Tiene 10,939 registros.

**Justificacion:** los planteles son la nomina oficial de cada seleccion. Este dato es diferente de las apariciones en partido: un jugador puede estar convocado en el plantel pero no haber jugado ningun partido (suplente todo el torneo).

**Observacion en los datos:** sin problemas detectados. La posicion se registra con codigos (AR = arquero, DF = defensor, MC = mediocampista, DL = delantero).

---

### 18. plantel_entrenador

**Que almacena:** que entrenador estaba a cargo de cada seleccion en cada mundial, a nivel de plantel/convocatoria. Contiene: anio, seleccion_id, entrenador_id. Tiene 490 registros.

**Justificacion:** vincula al entrenador con la seleccion a nivel de torneo (no de partido individual, que es la tabla direccion_tecnica_partido).

**Observacion en los datos:** Alemania en 1974 tiene 2 entrenadores registrados (IDs 237 y 250). Esto corresponde a un caso real de co-direccion tecnica y no es un error.

---

## Tablas de Premios

### 19. premio_jugador

**Que almacena:** premios individuales otorgados a jugadores en cada mundial. Contiene: anio, nombre del premio, jugador_id y seleccion_id. Tiene 91 registros.

**Justificacion:** los premios individuales (Balon de Oro, Botin de Oro, Guante de Oro, Mejor Jugador Joven, etc.) son reconocimientos oficiales que agregan valor analitico al modelo.

**Observacion en los datos:** los premios mas antiguos comienzan en 1930 con el Balon de Oro. Premios como el Guante de Oro y el Mejor Jugador Joven aparecen en ediciones posteriores.

---

### 20. premio_seleccion

**Que almacena:** premios colectivos otorgados a selecciones. Contiene: anio, nombre del premio y seleccion_id. Tiene 18 registros.

**Justificacion:** aunque pocos, estos premios (FIFA Fair Play, Equipo Mas Entretenido) son datos oficiales que complementan la dimension de reconocimientos del modelo.

**Observacion en los datos:** solo existen 2 tipos de premio colectivo en los datos.

---

## Tabla de Contingencia

### 21. resolucion_identidad_jugador

**Que almacena:** registro de trazabilidad para casos donde un jugador mencionado en un evento (gol, tarjeta, cambio, penal) no pudo ser identificado automaticamente durante la normalizacion. Contiene: tabla de origen, ID del evento, ID de partido, ID de seleccion, nombre crudo del jugador, minuto, metodo de resolucion, nivel de confianza y notas.

**Justificacion:** en un dataset historico que abarca casi 100 anios, es inevitable que algunos nombres de jugadores en la fuente no coincidan exactamente con el catalogo maestro. En lugar de perder esos eventos, se registran aqui para resolucion manual posterior.

**Observacion en los datos:** actualmente esta vacio (solo contiene el encabezado). Esto indica que el proceso de normalizacion logro resolver todas las identidades automaticamente, o que los casos pendientes fueron descartados. El archivo existe como mecanismo de contingencia.

---

## Resumen Cuantitativo

| # | Tabla | Registros | Tipo | Funcion principal |
|---|-------|-----------|------|-------------------|
| 1 | mundial | 22 | Catalogo | Eje temporal (ediciones del torneo) |
| 2 | seleccion | 87 | Catalogo | Eje de entidades participantes |
| 3 | seleccion_alias | ~9 | Catalogo | Mapeo de nombres historicos |
| 4 | jugador | 8,444 | Catalogo | Registro maestro de personas |
| 5 | entrenador | 366 | Catalogo | Registro maestro de DT |
| 6 | partido | 965 | Hecho | Evento principal del modelo |
| 7 | gol | 2,721 | Hecho | Detalle granular de cada gol |
| 8 | goleador | 1,644 | Referencia | Lista de goleadores por mundial (de la fuente) |
| 9 | tarjeta | 2,731 | Hecho | Amonestaciones y expulsiones |
| 10 | cambio | 3,818 | Hecho | Sustituciones en partidos |
| 11 | penal | 321 | Hecho | Ejecuciones de tandas de penales |
| 12 | aparicion_partido | 43,324 | Hecho | Alineaciones completas |
| 13 | direccion_tecnica_partido | 1,929 | Hecho | DT por partido |
| 14 | grupo | 533 | Clasificacion | Tablas de posiciones de grupos |
| 15 | posicion_final | 491 | Clasificacion | Ranking final del torneo |
| 16 | participacion_mundial | 1,929 | Resumen | Campania por seleccion por mundial |
| 17 | plantel_jugador | 10,939 | Convocatoria | Nominas oficiales |
| 18 | plantel_entrenador | 490 | Convocatoria | DT por plantel |
| 19 | premio_jugador | 91 | Reconocimiento | Premios individuales |
| 20 | premio_seleccion | 18 | Reconocimiento | Premios colectivos |
| 21 | resolucion_identidad_jugador | 0 | Contingencia | Trazabilidad de identidades |
| | **TOTAL** | **~80,852** | | |

---

## Consideraciones Especiales y Valores Atipicos

Esta seccion documenta los valores extraños, particularidades historicas y casos especiales que se deben tomar en cuenta al trabajar con estas tablas.

---

### 1. Canonizacion de selecciones historicas

**Tablas afectadas:** `seleccion`, `seleccion_alias`, y todas las que referencian `seleccion_id`.

Varias selecciones cambiaron de nombre a lo largo de la historia. El modelo las unifica bajo un nombre canonico, pero las variantes historicas se preservan en `seleccion_alias`:

| Nombre actual (canonico) | Nombres historicos |
|---|---|
| Alemania | Alemania Federal, Alemania Occidental |
| Rusia | Union Sovietica, URSS |
| Serbia | Yugoslavia, Serbia y Montenegro |
| Republica Checa | Checoslovaquia |
| Holanda | Paises Bajos |

**Implicacion practica:** si se busca el historial completo de Alemania, hay que considerar que los mundiales de 1954-1990 figuran como "Alemania Federal". El sistema los unifica bajo el mismo `seleccion_id`, pero la tabla `seleccion_alias` permite rastrear el nombre original.

**Caso especial de Alemania Oriental:** tiene un `seleccion_id` separado porque fue un pais diferente (participo solo en 1974). NO se unifica con Alemania.

---

### 2. Archivo HTML faltante: Mundial 1970

**Tablas afectadas:** `goleador` (143 registros con goles=0).

El archivo `html_descargados/mundiales_1970_goleadores.php` no existe en la carpeta local. Esto causa que los ~55 goleadores del mundial 1970 no pudieran actualizarse con los valores corregidos y mantienen `goles=0`. Para los demas mundiales los datos son correctos.

**Solucion:** descargar manualmente el archivo desde `https://www.losmundialesdefutbol.com/mundiales/1970_goleadores.php` y re-ejecutar el scraper.

---

### 3. Tarjetas y cambios inexistentes antes de 1970

**Tablas afectadas:** `tarjeta`, `cambio`.

El sistema de tarjetas amarillas y rojas fue introducido oficialmente en el Mundial de Mexico 1970. Las sustituciones se permitieron desde el mismo anio. Por lo tanto:

- `tarjeta`: no hay registros para mundiales anteriores a 1970.
- `cambio`: los registros anteriores a 1970 son escasos o inexistentes.

Esto NO es un error de datos — es coherente con las reglas historicas del futbol.

---

### 4. Posiciones finales compartidas

**Tabla afectada:** `posicion_final`.

Existen 4 combinaciones (anio, posicion) donde mas de una seleccion comparte la misma posicion final. Por ejemplo:

- 1970: dos equipos en la posicion 10.
- 1934: tres equipos en la posicion 9.

Esto es correcto y refleja que los equipos eliminados en la misma ronda reciben la misma posicion oficial. La clave primaria compuesta de esta tabla es `(anio, posicion, seleccion_id)`, no solo `(anio, posicion)`.

---

### 5. Mundial 2026: datos placeholder

**Tablas afectadas:** `mundial`, `participacion_mundial`, `plantel_jugador`.

El mundial 2026 existe como registro pero aun no se ha disputado al momento de la extraccion de datos:

- `mundial`: tiene `partidos_jugados=0`, `goles_total=0`, `equipos` con valor.
- `participacion_mundial`: tiene filas con `participo=True` pero sin estadisticas (0 en todos los campos numericos). Representan equipos ya clasificados.
- `plantel_jugador`: puede no tener registros si los planteles no se habian publicado.

---

### 6. Tanda de penales: tipos de resultado

**Tabla afectada:** `penal`.

Los 321 tiros de penales registrados tienen 5 tipos de resultado posibles:

| Resultado | Cantidad | Descripcion |
|---|:---:|---|
| gol | 222 | Penal convertido |
| atajado | 70 | Atajado por el portero |
| desviado | 13 | Tiro fuera del arco |
| poste | 8 | Tiro al poste |
| travesaño | 7 | Tiro al travesaño |

Estos penales son SOLO de tandas de definicion, no de penales durante el tiempo regular (esos estan en la tabla `gol` con `es_penal=True`).

---

### 7. Jugadores sin datos personales completos

**Tabla afectada:** `jugador`.

Jugadores de mundiales antiguos (especialmente pre-1950) pueden tener campos vacios en fecha de nacimiento, lugar de nacimiento, altura, apodo y redes sociales. Esto es esperado por la falta de registros historicos digitalizados en la fuente web.

---

### 8. Co-direccion tecnica

**Tabla afectada:** `plantel_entrenador`.

Alemania en 1974 tiene 2 entrenadores registrados (`entrenador_id` 237 y 250). Esto corresponde a un caso real de co-direccion tecnica y no es un error.

---

### 9. Penales regulares vs tanda de penales

**Tablas afectadas:** `gol`, `penal`.

Existen dos tablas distintas que contienen informacion sobre penales:

- `gol` con `es_penal=True` (210 registros): penales cobrados durante el tiempo regular como parte del marcador.
- `penal` (321 registros): ejecuciones individuales de tandas de penales post-partido.

Estos son conceptos diferentes y NO deben mezclarse en consultas.

---

### 10. Fuente web unica

**Todas las tablas.**

Todos los datos provienen de una unica fuente: `https://www.losmundialesdefutbol.com`. Esto significa que cualquier error, omision o sesgo de la fuente se refleja en los datos. Los archivos HTML descargados en `html_descargados/` sirven como respaldo y evidencia para verificacion.

Patron de nombres de archivos HTML:

| Tipo | Patron | Ejemplo |
|---|---|---|
| Goleadores por mundial | `mundiales_{anio}_goleadores.php` | `mundiales_2022_goleadores.php` |
| Pagina de jugador | `jugadores_{slug}.php` | `jugadores_kylian_mbappe.php` |
| Historial entre selecciones | `historial_{sel1}_vs_{sel2}.php` | `historial_argentina_vs_francia.php` |
| Goleadores por seleccion | `selecciones_{sel}_goleadores.php` | `selecciones_argentina_goleadores.php` |
| Estadisticas generales | `estadisticas_*.php` | `estadisticas_goleadores_por_mundial.php` |
