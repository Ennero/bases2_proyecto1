"""
Scraper normalizado para losmundialesdefutbol.com.

Genera CSV relacionales listos para carga a base de datos.
Puede leer directamente desde la web o desde la carpeta local html_descargados.
"""

from __future__ import annotations

import argparse
import os
import random
import re
import shutil
import subprocess
import tempfile
import time
from dataclasses import dataclass
from typing import Any, Iterable
from urllib.parse import urlparse

import pandas as pd
from bs4 import BeautifulSoup, Tag

try:
    from selenium.webdriver import Edge as SeleniumEdgeDriver
    from selenium.webdriver.edge.options import Options as SeleniumEdgeOptions
except Exception:  # pragma: no cover - fallback para entornos sin selenium
    SeleniumEdgeDriver = None  # type: ignore[assignment]
    SeleniumEdgeOptions = None  # type: ignore[assignment]

from normalizacion_csv import normalizar_csv_intermedio


BASE = "https://www.losmundialesdefutbol.com"
ANIOS = [
    2026, 2022, 2018, 2014, 2010, 2006, 2002, 1998, 1994, 1990,
    1986, 1982, 1978, 1974, 1970, 1966, 1962, 1958, 1954, 1950,
    1938, 1934, 1930,
]
LETRAS_GRUPO = list("abcdefghijkl")
NUMEROS_GRUPO = ["1", "2", "3", "4"]
POSICION_MAP = {
    "AR": "Arquero",
    "DF": "Defensor",
    "MC": "Mediocampista",
    "DL": "Delantero",
    "DT": "Entrenador",
}
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/131.0.0.0 Safari/537.36"
)
USER_AGENT_FIREFOX = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) "
    "Gecko/20100101 Firefox/128.0"
)


@dataclass
class FuenteDatos:
    origen: str
    html_dir: str
    pausa: float
    web_estricto: bool = False
    reintentos_web: int = 4
    jitter_web: float = 0.6
    simular_firefox: bool = True
    forzar_ipv4: bool = True
    usar_selenium: bool = True
    selenium_headless: bool = False
    selenium_timeout: int = 90
    edge_profile_dir: str = ""
    driver_selenium: Any = None
    aviso_fallback_local_emitido: bool = False

    def _leer_html_local(self, ruta_sitio: str) -> str:
        archivo_local = ruta_local_desde_sitio(ruta_sitio, self.html_dir)
        with open(archivo_local, "r", encoding="utf-8", errors="ignore") as descriptor:
            return descriptor.read()

    def _asegurar_edge_profile(self) -> str:
        if not self.edge_profile_dir:
            self.edge_profile_dir = tempfile.mkdtemp(prefix="_edge_profile_")
        return self.edge_profile_dir

    def _asegurar_driver_selenium(self) -> Any:
        if self.driver_selenium is not None:
            return self.driver_selenium
        if SeleniumEdgeDriver is None or SeleniumEdgeOptions is None:
            raise RuntimeError("Selenium no está disponible en el entorno para estrategia web.")

        opciones = SeleniumEdgeOptions()
        opciones.binary_location = resolver_ruta_edge()
        opciones.add_argument("--disable-blink-features=AutomationControlled")
        opciones.add_argument("--lang=es-ES")
        if self.selenium_headless:
            opciones.add_argument("--headless=new")

        driver = SeleniumEdgeDriver(options=opciones)
        driver.set_page_load_timeout(max(int(self.selenium_timeout), 30))
        self.driver_selenium = driver
        return driver

    def _obtener_html_con_selenium(self, url: str) -> str:
        driver = self._asegurar_driver_selenium()
        driver.get(url)
        html = getattr(driver, "page_source", "")
        return str(html or "")

    def _pausa_reintento_web(self) -> None:
        base = max(self.pausa, 0.0)
        jitter = random.uniform(0.0, max(self.jitter_web, 0.0))
        espera = base + jitter
        if espera > 0:
            time.sleep(espera)

    def _obtener_html_web(self, url: str) -> tuple[str, Exception | None]:
        html_ultimo = ""
        error_ultimo: Exception | None = None
        total_intentos = max(int(self.reintentos_web), 1)
        user_agents = [USER_AGENT_FIREFOX, USER_AGENT] if self.simular_firefox else [USER_AGENT]
        edge_profile_dir = self._asegurar_edge_profile()
        estrategias = ["edge", "curl"]
        if self.usar_selenium:
            estrategias.insert(0, "selenium")

        for intento in range(1, total_intentos + 1):
            for estrategia in estrategias:
                if estrategia == "selenium":
                    try:
                        html_intento = self._obtener_html_con_selenium(url)
                    except Exception as error:
                        error_ultimo = error
                        continue

                    if html_intento:
                        html_ultimo = html_intento
                    if html_intento and not respuesta_web_bloqueada(html_intento):
                        return html_intento, None
                    continue

                for user_agent in user_agents:
                    try:
                        if estrategia == "edge":
                            html_intento = obtener_html_con_edge(
                                url,
                                user_agent=user_agent,
                                profile_dir=edge_profile_dir,
                            )
                        else:
                            html_intento = obtener_html_con_curl(
                                url,
                                user_agent=user_agent,
                                forzar_ipv4=self.forzar_ipv4,
                            )
                    except Exception as error:
                        error_ultimo = error
                        continue

                    if html_intento:
                        html_ultimo = html_intento
                    if html_intento and not respuesta_web_bloqueada(html_intento):
                        return html_intento, None

            if intento < total_intentos:
                self._pausa_reintento_web()

        return html_ultimo, error_ultimo

    def obtener_soup(self, ruta: str) -> BeautifulSoup:
        ruta_sitio = normalizar_ruta_sitio(ruta)
        if self.origen == "local":
            html = self._leer_html_local(ruta_sitio)
        else:
            url = normalizar_url(ruta_sitio)
            html, error_web = self._obtener_html_web(url)

            if not html or respuesta_web_bloqueada(html):
                if self.web_estricto:
                    if error_web is not None:
                        raise RuntimeError(
                            f"Modo web estricto: no se pudo obtener HTML válido para {url}"
                        ) from error_web
                    raise RuntimeError(
                        f"Modo web estricto: respuesta web bloqueada o vacía para {url}"
                    )
                try:
                    html = self._leer_html_local(ruta_sitio)
                    if not self.aviso_fallback_local_emitido:
                        print("  Aviso: respuesta web bloqueada o vacía; usando html_descargados como respaldo cuando exista.")
                        self.aviso_fallback_local_emitido = True
                except FileNotFoundError:
                    if not html and error_web is not None:
                        raise error_web

            if self.pausa > 0:
                time.sleep(self.pausa)
        return BeautifulSoup(html, "html.parser")

    def cerrar(self) -> None:
        if self.driver_selenium is not None:
            try:
                self.driver_selenium.quit()
            except Exception:
                pass
            self.driver_selenium = None
        if self.edge_profile_dir and os.path.isdir(self.edge_profile_dir):
            shutil.rmtree(self.edge_profile_dir, ignore_errors=True)
        return None


def resolver_ruta_edge() -> str:
    candidatos = [
        shutil.which("msedge.exe"),
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    ]
    for candidato in candidatos:
        if candidato and os.path.exists(candidato):
            return candidato
    raise FileNotFoundError("No se encontró Microsoft Edge instalado para el modo web.")


def resolver_ruta_curl() -> str:
    candidato = shutil.which("curl")
    if candidato:
        return candidato
    raise FileNotFoundError("No se encontró curl instalado para el modo web.")


def obtener_html_con_edge(url: str, user_agent: str = USER_AGENT, profile_dir: str = "") -> str:
    comando = [
        resolver_ruta_edge(),
        "--headless=new",
        "--disable-gpu",
        "--disable-blink-features=AutomationControlled",
        "--lang=es-ES",
        "--window-size=1366,900",
        "--virtual-time-budget=12000",
        "--no-first-run",
        "--no-default-browser-check",
        "--dump-dom",
        f"--user-agent={user_agent}",
        url,
    ]
    if profile_dir:
        comando.insert(1, f"--user-data-dir={profile_dir}")
    resultado = subprocess.run(
        comando,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
        timeout=90,
        check=True,
    )
    return resultado.stdout


def obtener_html_con_curl(url: str, user_agent: str = USER_AGENT, forzar_ipv4: bool = True) -> str:
    comando = [
        resolver_ruta_curl(),
        "--silent",
        "--show-error",
        "--location",
        "--compressed",
        "--connect-timeout",
        "20",
        "--max-time",
        "90",
        "-A",
        user_agent,
        "-H",
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "-H",
        "Accept-Language: es-ES,es;q=0.9,en;q=0.8",
        "-H",
        "Upgrade-Insecure-Requests: 1",
        "-H",
        f"Referer: {BASE}/",
        url,
    ]
    if forzar_ipv4:
        comando.insert(1, "-4")

    resultado = subprocess.run(
        comando,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
        timeout=95,
        check=False,
    )
    if resultado.returncode not in (0,):
        raise RuntimeError(f"curl devolvió código {resultado.returncode} para {url}")
    return resultado.stdout


def normalizar_ruta_sitio(ruta: str) -> str:
    if not ruta:
        return "/"
    valor = ruta.strip()
    if valor.startswith("http"):
        valor = urlparse(valor).path
    while valor.startswith("../"):
        valor = valor[3:]
    if not valor.startswith("/"):
        valor = f"/{valor}"
    return valor


def ruta_local_desde_sitio(ruta_sitio: str, html_dir: str) -> str:
    partes = [parte for parte in ruta_sitio.strip("/").split("/") if parte]
    if not partes:
        raise FileNotFoundError(f"No se pudo mapear la ruta local para {ruta_sitio}")
    nombre_archivo = partes[0] if len(partes) == 1 else "_".join(partes)
    ruta_archivo = os.path.join(html_dir, nombre_archivo)
    if not os.path.exists(ruta_archivo):
        raise FileNotFoundError(f"Archivo local no encontrado: {ruta_archivo}")
    return ruta_archivo


def normalizar_url(ruta: str) -> str:
    if ruta.startswith("http"):
        return ruta
    ruta_sitio = normalizar_ruta_sitio(ruta)
    return f"{BASE}{ruta_sitio}"


def slug_de_href(href: str) -> str:
    if not href:
        return ""
    nombre = href.rsplit("/", 1)[-1]
    return nombre.replace(".php", "")


def limpiar_texto(texto: str | None) -> str:
    if not texto:
        return ""
    return " ".join(texto.split()).strip()


def extraer_entero(texto: str) -> int | None:
    coincidencia = re.search(r"-?\d+", texto or "")
    return int(coincidencia.group()) if coincidencia else None


def extraer_decimal(texto: str) -> str:
    coincidencia = re.search(r"\d+(?:\.\d+)?", texto or "")
    return coincidencia.group() if coincidencia else ""


def atributo_texto(tag: Tag, atributo: str) -> str:
    valor = tag.get(atributo)
    if isinstance(valor, list):
        return " ".join(str(item) for item in valor if item)
    if valor is None:
        return ""
    return str(valor)


def clase_contiene(tag: Tag, fragmento: str) -> bool:
    clases = atributo_texto(tag, "class").split()
    return any(fragmento in clase for clase in clases)


def href_contiene(href: str | None, *fragmentos: str) -> bool:
    if not href:
        return False
    href_normalizado = href.lower()
    return all(fragmento.lower() in href_normalizado for fragmento in fragmentos)


def primer_link(soup: Tag | BeautifulSoup, *fragmentos: str) -> Tag | None:
    for link in soup.find_all("a", href=True):
        href = atributo_texto(link, "href")
        if href_contiene(href, *fragmentos):
            return link
    return None


def todos_los_links(soup: Tag | BeautifulSoup, *fragmentos: str) -> list[Tag]:
    encontrados: list[Tag] = []
    for link in soup.find_all("a", href=True):
        href = atributo_texto(link, "href")
        if href_contiene(href, *fragmentos):
            encontrados.append(link)
    return encontrados


def tabla_tiene_encabezado(tabla: Tag, encabezado: str) -> bool:
    return encabezado.lower() in limpiar_texto(tabla.get_text(" ")).lower()


def obtener_nombre_seleccion_desde_imagen(tag: Tag | None) -> str:
    if not tag:
        return ""
    imagen = tag.find("img", alt=True)
    if not imagen:
        return ""
    valor = limpiar_texto(atributo_texto(imagen, "alt"))
    return valor.replace("Bandera de ", "").strip()


def es_equipo_probable(texto: str) -> bool:
    valor = limpiar_texto(texto)
    if not valor:
        return False
    valor_lower = valor.lower()
    if valor_lower.startswith("minuto "):
        return False
    if valor_lower.startswith("selecc"):
        return False
    if re.fullmatch(r"\d+(?:\+\d+)?", valor):
        return False
    return True


def respuesta_web_bloqueada(html: str) -> bool:
    if not html:
        return True

    html_lower = html.lower()
    texto = limpiar_texto(html).lower()
    if not texto:
        return True

    indicadores_html = (
        "<title>403 forbidden</title>",
        "<title>forbidden</title>",
        "<h1>403 forbidden</h1>",
        "<h1>forbidden</h1>",
        "<h1>access denied</h1>",
        "<title>access denied</title>",
    )
    if any(indicador in html_lower for indicador in indicadores_html):
        return True

    indicadores = (
        "forbidden access",
        "access denied",
        "error 403",
        "403 forbidden",
        "status code 403",
        "captcha",
        "cloudflare",
        "just a moment",
        "request blocked",
    )
    if any(indicador in texto for indicador in indicadores):
        return True
    if "403" in texto and ("forbidden" in texto or "denied" in texto):
        return True
    if len(texto) < 120 and "los mundiales" not in texto:
        return True
    return False


def tabla_bajo_subtitulo(subtitulo: Tag) -> Tag | None:
    for sibling in subtitulo.next_siblings:
        if not isinstance(sibling, Tag):
            continue
        if sibling.name == "h3":
            break
        if sibling.name == "table":
            return sibling
        tabla = sibling.find("table")
        if isinstance(tabla, Tag):
            return tabla
    return None


def guardar_csv(datos: list[dict], nombre: str, carpeta: str) -> None:
    if not datos:
        print(f"  Sin datos para {nombre}")
        return
    os.makedirs(carpeta, exist_ok=True)
    ruta = os.path.join(carpeta, nombre)
    df = pd.DataFrame(datos)
    df = df.fillna("")
    df.to_csv(ruta, index=False, encoding="utf-8-sig")
    print(f"  {nombre}: {len(df)} registros")


def deduplicar(datos: Iterable[dict], llaves: tuple[str, ...]) -> list[dict]:
    resultado: list[dict] = []
    vistos: set[tuple] = set()
    for fila in datos:
        llave = tuple(fila.get(columna, "") for columna in llaves)
        if llave in vistos:
            continue
        vistos.add(llave)
        resultado.append(fila)
    return resultado


def extraer_minuto(texto: str) -> str:
    coincidencia = re.search(r"(\d+)(?:'|’)?(?:\+(\d+))?", texto)
    if not coincidencia:
        return ""
    base = coincidencia.group(1)
    agregado = coincidencia.group(2)
    return f"{base}+{agregado}" if agregado else base


def parsear_resultado_penal(texto: str) -> str:
    texto_limpio = limpiar_texto(texto).lower()
    if not texto_limpio:
        return ""

    # Solo aceptamos marcadores chicos (1-2 digitos) junto al contexto de penales.
    # Evita capturar anios del menu como 2026/2022.
    patrones = (
        r"\((\d{1,2})\s*-\s*(\d{1,2})\)\s*por\s+penales",
        r"(\d{1,2})\s*-\s*(\d{1,2})\s*por\s+penales",
        r"por\s+penales\s*\(?\s*(\d{1,2})\s*-\s*(\d{1,2})\s*\)?",
        r"definici[oó]n\s+por\s+penales\s*:?\s*(\d{1,2})\s*-\s*(\d{1,2})",
    )

    for patron in patrones:
        coincidencia = re.search(patron, texto_limpio)
        if coincidencia:
            return f"{int(coincidencia.group(1))} - {int(coincidencia.group(2))}"
    return ""


def extraer_partidos_basicos(fuente: FuenteDatos, anio: int) -> list[dict]:
    try:
        soup = fuente.obtener_soup(f"/mundiales/{anio}_resultados.php")
    except FileNotFoundError:
        return []
    partidos: list[dict] = []
    for div in soup.find_all("div"):
        if not clase_contiene(div, "game"):
            continue

        fecha = ""
        encabezado_fecha = div.find_previous("h3")
        if encabezado_fecha:
            fecha = limpiar_texto(encabezado_fecha.get_text(" ")).replace("Fecha:", "").strip()

        etapa = ""
        for enlace_etapa in div.find_all_previous("a", href=True):
            href_etapa = atributo_texto(enlace_etapa, "href")
            texto_etapa = limpiar_texto(enlace_etapa.get_text())
            if href_contiene(href_etapa, f"{anio}_") and not href_contiene(href_etapa, "resultados") and texto_etapa:
                etapa = texto_etapa
                break

        imagenes = div.find_all("img", alt=True)
        local = limpiar_texto(atributo_texto(imagenes[0], "alt")) if len(imagenes) >= 1 else ""
        visitante = limpiar_texto(atributo_texto(imagenes[1], "alt")) if len(imagenes) >= 2 else ""

        enlace_resultado = primer_link(div, "partidos")
        if not enlace_resultado:
            continue
        resultado = limpiar_texto(enlace_resultado.get_text())
        detalle_href = atributo_texto(enlace_resultado, "href")

        if local and visitante and resultado:
            partidos.append({
                "anio": anio,
                "fecha": fecha,
                "etapa": etapa,
                "local": local,
                "visitante": visitante,
                "resultado": resultado,
                "slug": slug_de_href(detalle_href),
                "detalle": detalle_href,
            })
    return partidos


def parsear_penales(partido_slug: str, anio: int, local: str, visitante: str, soup: BeautifulSoup) -> list[dict]:
    penales: list[dict] = []
    texto_etiqueta = soup.find(string=lambda texto: isinstance(texto, str) and "Definición por Penales" in texto)
    if not texto_etiqueta:
        return penales

    etiqueta = texto_etiqueta.find_parent("strong")
    if not isinstance(etiqueta, Tag):
        return penales

    contenedor = etiqueta.find_parent("div")
    if not isinstance(contenedor, Tag):
        return penales

    bloque = contenedor
    while True:
        bloque = bloque.find_next_sibling("div")
        if not isinstance(bloque, Tag):
            return penales
        if "patea primero" in limpiar_texto(bloque.get_text(" ")).lower():
            break

    if not isinstance(bloque, Tag):
        return penales

    orden_local = 0
    orden_visitante = 0
    hijos = [hijo for hijo in bloque.find_all("div", recursive=False)]
    indice = 0
    while indice < len(hijos) - 1:
        mitad_local = hijos[indice]
        mitad_visitante = hijos[indice + 1]
        if not (clase_contiene(mitad_local, "w-50") and clase_contiene(mitad_visitante, "w-50")):
            indice += 1
            continue

        for indice_equipo, mitad in enumerate((mitad_local, mitad_visitante)):
            texto = limpiar_texto(mitad.get_text(" "))
            if not texto:
                continue
            equipo = local if indice_equipo == 0 else visitante
            enlace = primer_link(mitad, "jugadores")
            jugador = limpiar_texto(enlace.get_text()) if enlace else re.sub(r"\(.*?\)", "", texto).strip()
            jugador_slug = slug_de_href(atributo_texto(enlace, "href")) if enlace else ""
            detalle = ""
            detalle_match = re.search(r"\((.*?)\)", texto)
            if detalle_match:
                detalle = detalle_match.group(1).strip().lower()
            resultado = "gol"
            if "ataj" in detalle:
                resultado = "atajado"
            elif "desvi" in detalle:
                resultado = "desviado"
            elif "poste" in detalle or "palo" in detalle:
                resultado = "poste"
            elif detalle:
                resultado = detalle

            if equipo == local:
                orden_local += 1
                orden = orden_local
            else:
                orden_visitante += 1
                orden = orden_visitante

            penales.append({
                "partido_slug": partido_slug,
                "anio": anio,
                "equipo": equipo,
                "orden": orden,
                "jugador": jugador,
                "jugador_slug": jugador_slug,
                "resultado": resultado,
            })
        indice += 2
    return penales


def parsear_detalle_partido(fuente: FuenteDatos, partido: dict) -> dict:
    soup = fuente.obtener_soup(partido["detalle"])
    anio = partido["anio"]
    partido_slug = partido["slug"]
    texto_pagina = limpiar_texto(soup.get_text(" "))

    tiempo_extra = "tiempo extra" in texto_pagina.lower() or "prórroga" in texto_pagina.lower()
    penales = False
    resultado_penales = ""
    for texto in soup.stripped_strings:
        texto_limpio = limpiar_texto(texto)
        if "por penales" in texto_limpio.lower():
            penales = True
            resultado = parsear_resultado_penal(texto_limpio)
            if resultado:
                resultado_penales = resultado
                break

    if penales and not resultado_penales:
        for nodo in soup.find_all(string=lambda t: isinstance(t, str) and "penales" in t.lower()):
            if not isinstance(nodo, str):
                continue
            padre = nodo.parent if isinstance(nodo.parent, Tag) else None
            contexto = limpiar_texto(padre.get_text(" ")) if padre else limpiar_texto(nodo)
            resultado = parsear_resultado_penal(contexto)
            if resultado:
                resultado_penales = resultado
                break

    goles: list[dict] = []
    marcador_goles = soup.find(string=lambda texto: isinstance(texto, str) and "Goles:" in texto)
    if marcador_goles:
        cabecera_goles = marcador_goles.find_parent("div")
        if isinstance(cabecera_goles, Tag):
            bloque_goles = cabecera_goles.find_next_sibling("div")
            if isinstance(bloque_goles, Tag):
                for mitad in bloque_goles.find_all("div"):
                    if not clase_contiene(mitad, "w-50"):
                        continue
                    imagen_gol = mitad.find("img", alt=re.compile(r"Gol min", re.IGNORECASE))
                    if not imagen_gol:
                        continue
                    equipo = partido["local"] if clase_contiene(mitad, "a-right") else partido["visitante"]
                    texto = limpiar_texto(mitad.get_text(" "))
                    enlace = primer_link(mitad, "jugadores")
                    jugador = limpiar_texto(enlace.get_text()) if enlace else re.sub(r"^\d+(?:\+\d+)?'?", "", texto).strip()
                    jugador = re.sub(r"\(de penal\)", "", jugador, flags=re.IGNORECASE).strip()
                    jugador_slug = slug_de_href(atributo_texto(enlace, "href")) if enlace else ""
                    es_penal = "de penal" in texto.lower()
                    es_autogol = "en contra" in texto.lower()
                    goles.append({
                        "partido_slug": partido_slug,
                        "anio": anio,
                        "equipo": equipo,
                        "jugador": jugador,
                        "jugador_slug": jugador_slug,
                        "minuto": extraer_minuto(texto),
                        "es_penal": es_penal,
                        "es_autogol": es_autogol,
                    })

    apariciones: list[dict] = []
    for tabla in soup.find_all("table"):
        if not tabla_tiene_encabezado(tabla, "Jugador") or not tabla_tiene_encabezado(tabla, "Cam"):
            continue
        fila_encabezado = tabla.find("tr")
        equipo = obtener_nombre_seleccion_desde_imagen(fila_encabezado)
        if not equipo:
            continue
        seccion = "titular"
        for fila in tabla.find_all("tr"):
            texto_fila = limpiar_texto(fila.get_text(" "))
            fuerte = fila.find("strong")
            if fuerte:
                titulo = limpiar_texto(fuerte.get_text()).lower()
                if "titulares" in titulo:
                    seccion = "titular"
                    continue
                if "ingresaron" in titulo:
                    seccion = "ingresado"
                    continue
                if "no jugaron" in titulo or "suplentes" in titulo or "otros" in titulo:
                    seccion = "suplente_no_jugo"
                    continue
                if "entrenador" in titulo:
                    nombre_entrenador = texto_fila.replace("Entrenador:", "").strip()
                    if nombre_entrenador:
                        apariciones.append({
                            "partido_slug": partido_slug,
                            "anio": anio,
                            "equipo": equipo,
                            "jugador_slug": "",
                            "jugador_nombre": nombre_entrenador,
                            "posicion": "DT",
                            "camiseta": "",
                            "seccion": "entrenador",
                            "es_capitan": False,
                        })
                    continue

            celdas = fila.find_all("td")
            if len(celdas) < 3:
                continue
            posicion = limpiar_texto(celdas[0].get_text())
            if posicion not in POSICION_MAP:
                continue
            camiseta = limpiar_texto(celdas[1].get_text()).rstrip(".")
            celda_jugador = celdas[2]
            enlace = primer_link(celda_jugador, "jugadores")
            jugador_nombre = limpiar_texto(enlace.get_text()) if enlace else limpiar_texto(celda_jugador.get_text(" "))
            jugador_slug = slug_de_href(atributo_texto(enlace, "href")) if enlace else ""
            apariciones.append({
                "partido_slug": partido_slug,
                "anio": anio,
                "equipo": equipo,
                "jugador_slug": jugador_slug,
                "jugador_nombre": jugador_nombre.replace("(C)", "").strip(),
                "posicion": posicion,
                "camiseta": camiseta,
                "seccion": seccion,
                "es_capitan": "(C)" in limpiar_texto(celda_jugador.get_text(" ")),
            })

    tarjetas: list[dict] = []
    for subtitulo in soup.find_all("h3"):
        if "tarjetas" not in limpiar_texto(subtitulo.get_text()).lower():
            continue
        tabla = tabla_bajo_subtitulo(subtitulo)
        if not isinstance(tabla, Tag):
            continue
        equipo_actual = ""
        for fila in tabla.find_all("tr"):
            celdas = fila.find_all("td")
            if len(celdas) == 1:
                equipo_header = obtener_nombre_seleccion_desde_imagen(fila) or limpiar_texto(celdas[0].get_text(" "))
                if es_equipo_probable(equipo_header):
                    equipo_actual = equipo_header
                continue
            if len(celdas) < 3:
                continue

            minuto = extraer_minuto(limpiar_texto(celdas[0].get_text(" ")))
            if minuto:
                equipo = equipo_actual
                celda_jugador = celdas[1]
                celda_tarjeta = celdas[2]
            else:
                equipo_celda = limpiar_texto(celdas[0].get_text(" "))
                if es_equipo_probable(equipo_celda):
                    equipo_actual = equipo_celda
                equipo = equipo_actual
                celda_jugador = celdas[1]
                celda_tarjeta = celdas[2]

            if not es_equipo_probable(equipo):
                continue

            texto_jugador = limpiar_texto(celda_jugador.get_text(" "))
            texto_tarjeta = limpiar_texto(celda_tarjeta.get_text(" "))
            if not texto_jugador and not texto_tarjeta:
                continue

            enlace = primer_link(celda_jugador, "jugadores")
            jugador = limpiar_texto(enlace.get_text()) if enlace else texto_jugador
            jugador_slug = slug_de_href(atributo_texto(enlace, "href")) if enlace else ""

            minuto_tarjeta = minuto or extraer_minuto(texto_tarjeta)
            tipo = "amarilla" if "amarilla" in texto_tarjeta.lower() or fila.find("div", class_="am") else "roja"
            tarjetas.append({
                "partido_slug": partido_slug,
                "anio": anio,
                "jugador": jugador,
                "jugador_slug": jugador_slug,
                "equipo": equipo,
                "tipo": tipo,
                "minuto": minuto_tarjeta,
            })
        break

    cambios: list[dict] = []
    for subtitulo in soup.find_all("h3"):
        if "cambios" not in limpiar_texto(subtitulo.get_text()).lower():
            continue
        tabla = tabla_bajo_subtitulo(subtitulo)
        if not isinstance(tabla, Tag):
            continue
        equipo_actual = ""
        for fila in tabla.find_all("tr"):
            celdas = fila.find_all("td")
            if len(celdas) == 1:
                equipo_header = obtener_nombre_seleccion_desde_imagen(fila) or limpiar_texto(celdas[0].get_text(" "))
                if es_equipo_probable(equipo_header):
                    equipo_actual = equipo_header
                continue
            if len(celdas) < 5:
                continue
            minuto = extraer_minuto(limpiar_texto(celdas[0].get_text(" ")))
            if not minuto:
                continue
            if not es_equipo_probable(equipo_actual):
                continue
            entra_link = primer_link(celdas[2], "jugadores")
            sale_link = primer_link(celdas[4], "jugadores")
            entra = limpiar_texto(entra_link.get_text()) if entra_link else limpiar_texto(celdas[2].get_text(" "))
            sale = limpiar_texto(sale_link.get_text()) if sale_link else limpiar_texto(celdas[4].get_text(" "))
            cambios.append({
                "partido_slug": partido_slug,
                "anio": anio,
                "equipo": equipo_actual,
                "sale": sale,
                "sale_slug": slug_de_href(atributo_texto(sale_link, "href")) if sale_link else "",
                "entra": entra,
                "entra_slug": slug_de_href(atributo_texto(entra_link, "href")) if entra_link else "",
                "minuto": minuto,
            })
        break

    return {
        "partido_extra": {
            "tiempo_extra": tiempo_extra,
            "penales": penales,
            "resultado_penales": resultado_penales,
        },
        "goles": goles,
        "apariciones": apariciones,
        "tarjetas": tarjetas,
        "cambios": cambios,
        "penales_detalle": parsear_penales(partido_slug, anio, partido["local"], partido["visitante"], soup),
    }


def extraer_partidos(fuente: FuenteDatos, anios: list[int], carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO PARTIDOS Y EVENTOS")
    print("=" * 50)

    partidos: list[dict] = []
    goles: list[dict] = []
    apariciones: list[dict] = []
    tarjetas: list[dict] = []
    cambios: list[dict] = []
    penales: list[dict] = []

    for anio in anios:
        partidos_anio = extraer_partidos_basicos(fuente, anio)
        print(f"  {anio}: {len(partidos_anio)} partidos")
        for partido in partidos_anio:
            fila_partido: dict[str, object] = {
                "anio": partido["anio"],
                "fecha": partido["fecha"],
                "etapa": partido["etapa"],
                "local": partido["local"],
                "visitante": partido["visitante"],
                "resultado": partido["resultado"],
                "slug": partido["slug"],
                "tiempo_extra": False,
                "penales": False,
                "resultado_penales": "",
            }
            try:
                detalle = parsear_detalle_partido(fuente, partido)
                fila_partido.update(detalle["partido_extra"])
                goles.extend(detalle["goles"])
                apariciones.extend(detalle["apariciones"])
                tarjetas.extend(detalle["tarjetas"])
                cambios.extend(detalle["cambios"])
                penales.extend(detalle["penales_detalle"])
            except Exception as error:
                print(f"    Error detalle {partido['slug']}: {error}")
            partidos.append(fila_partido)

    guardar_csv(deduplicar(partidos, ("slug",)), "partido.csv", carpeta)
    guardar_csv(deduplicar(goles, ("partido_slug", "equipo", "jugador", "minuto", "es_penal", "es_autogol")), "gol.csv", carpeta)
    guardar_csv(deduplicar(apariciones, ("partido_slug", "equipo", "jugador_nombre", "seccion")), "aparicion_partido.csv", carpeta)
    guardar_csv(deduplicar(tarjetas, ("partido_slug", "equipo", "jugador", "tipo", "minuto")), "tarjeta.csv", carpeta)
    guardar_csv(deduplicar(cambios, ("partido_slug", "equipo", "sale", "entra", "minuto")), "cambio.csv", carpeta)
    guardar_csv(deduplicar(penales, ("partido_slug", "equipo", "orden")), "penal.csv", carpeta)


def extraer_grupos(fuente: FuenteDatos, anios: list[int], carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO GRUPOS")
    print("=" * 50)

    filas: list[dict] = []
    for anio in anios:
        for grupo in LETRAS_GRUPO + NUMEROS_GRUPO:
            try:
                soup = fuente.obtener_soup(f"/mundiales/{anio}_grupo_{grupo}.php")
            except FileNotFoundError:
                continue
            titulo = soup.find("h1")
            if not isinstance(titulo, Tag):
                continue
            texto_titulo = limpiar_texto(titulo.get_text())
            if "404" in texto_titulo or "error" in texto_titulo.lower():
                continue
            for tabla in soup.find_all("table"):
                for fila in tabla.find_all("tr"):
                    celdas = fila.find_all("td")
                    if len(celdas) < 5:
                        continue
                    seleccion = obtener_nombre_seleccion_desde_imagen(fila)
                    if not seleccion:
                        continue
                    valores = [limpiar_texto(celda.get_text()) for celda in celdas]
                    numeros = [valor for valor in valores if re.fullmatch(r"-?\d+", valor or "")]
                    posicion = extraer_entero(valores[0] if valores else "") or 0
                    clasificado = "clasificado" in limpiar_texto(celdas[-1].get_text()).lower() or "sí" in limpiar_texto(celdas[-1].get_text()).lower() or "si" in limpiar_texto(celdas[-1].get_text()).lower()
                    if len(numeros) >= 8:
                        filas.append({
                            "anio": anio,
                            "grupo": grupo.upper(),
                            "posicion": posicion,
                            "seleccion": seleccion,
                            "pts": numeros[0],
                            "pj": numeros[1],
                            "pg": numeros[2],
                            "pe": numeros[3],
                            "pp": numeros[4],
                            "gf": numeros[5],
                            "gc": numeros[6],
                            "dif": numeros[7],
                            "clasificado": clasificado,
                        })
        print(f"  {anio}: grupos procesados")

    guardar_csv(deduplicar(filas, ("anio", "grupo", "seleccion")), "grupo.csv", carpeta)


def extraer_posiciones_finales(fuente: FuenteDatos, anios: list[int], carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO POSICIONES FINALES")
    print("=" * 50)

    filas: list[dict] = []
    for anio in anios:
        try:
            soup = fuente.obtener_soup(f"/mundiales/{anio}_posiciones_finales.php")
        except FileNotFoundError:
            continue
        for fila in soup.find_all("tr"):
            celdas = fila.find_all("td")
            if len(celdas) < 2:
                continue
            seleccion = obtener_nombre_seleccion_desde_imagen(fila)
            posicion = extraer_entero(limpiar_texto(celdas[0].get_text()))
            if seleccion and posicion is not None:
                filas.append({
                    "anio": anio,
                    "posicion": posicion,
                    "seleccion": seleccion,
                })
    guardar_csv(deduplicar(filas, ("anio", "posicion", "seleccion")), "posicion_final.csv", carpeta)


def extraer_goleadores(fuente: FuenteDatos, anios: list[int], carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO GOLEADORES")
    print("=" * 50)

    filas: list[dict] = []
    for anio in anios:
        try:
            soup = fuente.obtener_soup(f"/mundiales/{anio}_goleadores.php")
        except FileNotFoundError:
            continue
        for fila in soup.find_all("tr"):
            celdas = fila.find_all("td")
            if len(celdas) < 3:
                continue
            enlace = primer_link(fila, "jugadores")
            if not enlace:
                continue
            goles = 0
            for celda in reversed(celdas):
                numero = extraer_entero(limpiar_texto(celda.get_text()))
                if numero is not None:
                    goles = numero
                    break
            filas.append({
                "anio": anio,
                "jugador": limpiar_texto(enlace.get_text()),
                "jugador_slug": slug_de_href(atributo_texto(enlace, "href")),
                "seleccion": obtener_nombre_seleccion_desde_imagen(fila),
                "goles": goles,
            })
    guardar_csv(deduplicar(filas, ("anio", "jugador_slug", "seleccion")), "goleador.csv", carpeta)


def extraer_premios(fuente: FuenteDatos, anios: list[int], carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO PREMIOS")
    print("=" * 50)

    filas: list[dict] = []
    for anio in anios:
        try:
            soup = fuente.obtener_soup(f"/mundiales/{anio}_premios.php")
        except FileNotFoundError:
            continue
        for premio_tag in soup.find_all("p", class_="negri"):
            premio = limpiar_texto(premio_tag.get_text())
            if not premio or premio.lower() == "equipo ideal":
                continue
            contenedor = premio_tag.find_parent("div")
            if not isinstance(contenedor, Tag):
                continue
            link_jugador = primer_link(contenedor, "jugadores")
            link_seleccion = primer_link(contenedor, "selecciones")
            if link_jugador:
                filas.append({
                    "anio": anio,
                    "premio": premio,
                    "tipo_destinatario": "jugador",
                    "jugador": limpiar_texto(link_jugador.get_text()),
                    "jugador_slug": slug_de_href(atributo_texto(link_jugador, "href")),
                    "seleccion": obtener_nombre_seleccion_desde_imagen(contenedor),
                })
            elif link_seleccion:
                filas.append({
                    "anio": anio,
                    "premio": premio,
                    "tipo_destinatario": "seleccion",
                    "jugador": "",
                    "jugador_slug": "",
                    "seleccion": limpiar_texto(link_seleccion.get_text()),
                })
    guardar_csv(deduplicar(filas, ("anio", "premio", "tipo_destinatario", "jugador_slug", "seleccion")), "premio.csv", carpeta)


def extraer_planteles(fuente: FuenteDatos, anios: list[int], carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO PLANTELES")
    print("=" * 50)

    filas: list[dict] = []
    for anio in anios:
        try:
            soup = fuente.obtener_soup(f"/mundiales/{anio}_planteles.php")
        except FileNotFoundError:
            continue
        links = todos_los_links(soup, "planteles", "jugadores")
        procesados: set[str] = set()
        for link in links:
            href = atributo_texto(link, "href")
            if href in procesados:
                continue
            procesados.add(href)
            try:
                soup_plantel = fuente.obtener_soup(href)
            except FileNotFoundError:
                continue
            titulo = soup_plantel.find("h1")
            nombre_seleccion = ""
            if isinstance(titulo, Tag):
                nombre_seleccion = limpiar_texto(titulo.get_text())
                nombre_seleccion = re.sub(r"^Jugadores de\s+", "", nombre_seleccion, flags=re.IGNORECASE)
                nombre_seleccion = re.sub(r"\s+en el Mundial\s+\d+\.?$", "", nombre_seleccion, flags=re.IGNORECASE)
            seleccion_slug = re.sub(r"^\d+_", "", slug_de_href(href)).replace("_jugadores", "")
            rol_actual = "jugador"
            posicion_actual = ""
            for tabla in soup_plantel.find_all("table"):
                encabezado = tabla.find("h3")
                if isinstance(encabezado, Tag):
                    texto_encabezado = limpiar_texto(encabezado.get_text()).lower()
                    if "arquero" in texto_encabezado:
                        posicion_actual = "AR"
                        rol_actual = "jugador"
                    elif "defensor" in texto_encabezado:
                        posicion_actual = "DF"
                        rol_actual = "jugador"
                    elif "mediocampista" in texto_encabezado or "medio" in texto_encabezado:
                        posicion_actual = "MC"
                        rol_actual = "jugador"
                    elif "delantero" in texto_encabezado:
                        posicion_actual = "DL"
                        rol_actual = "jugador"
                    elif "entrenador" in texto_encabezado:
                        posicion_actual = "DT"
                        rol_actual = "entrenador"
                for fila in tabla.find_all("tr"):
                    celdas = fila.find_all("td")
                    if rol_actual == "entrenador":
                        if len(celdas) == 1:
                            nombre_entrenador = limpiar_texto(celdas[0].get_text(" "))
                            if nombre_entrenador and nombre_entrenador.lower() != "entrenador":
                                filas.append({
                                    "anio": anio,
                                    "seleccion": nombre_seleccion,
                                    "seleccion_slug": seleccion_slug,
                                    "jugador": nombre_entrenador,
                                    "jugador_slug": "",
                                    "posicion": "DT",
                                    "camiseta": "",
                                    "fecha_nacimiento": "",
                                    "altura": "",
                                    "club": "",
                                    "rol": rol_actual,
                                })
                        continue
                    if len(celdas) < 3:
                        continue
                    link_jugador = primer_link(fila, "jugadores")
                    if not link_jugador:
                        continue
                    nombre = limpiar_texto(link_jugador.get_text()) if link_jugador else limpiar_texto(celdas[1].get_text(" "))
                    if not nombre or nombre.lower() == "jugador":
                        continue
                    camiseta = limpiar_texto(celdas[0].get_text())
                    info_texto = limpiar_texto(celdas[-1].get_text(" "))
                    contenedor_info = celdas[-1].find("div")
                    partes_info: list[str] = []
                    if isinstance(contenedor_info, Tag):
                        partes_info = [
                            limpiar_texto(parte.get_text(" "))
                            for parte in contenedor_info.find_all("div", recursive=False)
                        ]
                    fecha_nacimiento = partes_info[0] if len(partes_info) >= 1 else ""
                    altura = partes_info[1] if len(partes_info) >= 2 else ""
                    club = partes_info[2] if len(partes_info) >= 3 else info_texto
                    filas.append({
                        "anio": anio,
                        "seleccion": nombre_seleccion,
                        "seleccion_slug": seleccion_slug,
                        "jugador": nombre,
                        "jugador_slug": slug_de_href(atributo_texto(link_jugador, "href")) if link_jugador else "",
                        "posicion": posicion_actual,
                        "camiseta": camiseta,
                        "fecha_nacimiento": fecha_nacimiento,
                        "altura": altura,
                        "club": club,
                        "rol": rol_actual,
                    })
        print(f"  {anio}: {len(procesados)} planteles")
    guardar_csv(deduplicar(filas, ("anio", "seleccion_slug", "jugador_slug", "jugador", "rol")), "plantel.csv", carpeta)


def extraer_selecciones(fuente: FuenteDatos, carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO SELECCIONES Y PARTICIPACIONES")
    print("=" * 50)

    soup = fuente.obtener_soup("/selecciones.php")
    links = todos_los_links(soup, "selecciones", "_seleccion")
    selecciones: list[dict] = []
    participaciones: list[dict] = []

    hrefs_unicos = sorted({atributo_texto(link, "href") for link in links if atributo_texto(link, "href")})
    print(f"  {len(hrefs_unicos)} selecciones encontradas")

    for indice, href in enumerate(hrefs_unicos, start=1):
        seleccion_slug = slug_de_href(href).replace("_seleccion", "")
        try:
            soup_seleccion = fuente.obtener_soup(href)
        except FileNotFoundError:
            continue
        titulo = soup_seleccion.find("h1")
        nombre = limpiar_texto(titulo.get_text()) if isinstance(titulo, Tag) else ""
        nombre = re.sub(r"\s+en los [Mm]undiales.*$", "", nombre).strip()
        if not nombre or "404" in nombre:
            continue

        fila: dict[str, object] = {
            "slug": seleccion_slug,
            "nombre": nombre,
            "participaciones": "",
            "pj": "",
            "pg": "",
            "pe": "",
            "pp": "",
            "gf": "",
            "gc": "",
            "titulos": "",
            "subcampeonatos": "",
            "posicion_historica": "",
        }

        for tabla in soup_seleccion.find_all("table"):
            for fila_tabla in tabla.find_all("tr"):
                celdas = fila_tabla.find_all(["td", "th"])
                if len(celdas) < 2:
                    continue
                etiqueta = limpiar_texto(celdas[0].get_text()).lower()
                valor = limpiar_texto(celdas[-1].get_text())
                numero = extraer_entero(valor)
                if "mundiales" in etiqueta and fila["participaciones"] == "":
                    fila["participaciones"] = numero if numero is not None else ""
                elif "jugados" in etiqueta:
                    fila["pj"] = numero if numero is not None else ""
                elif "ganados" in etiqueta:
                    fila["pg"] = numero if numero is not None else ""
                elif "empat" in etiqueta:
                    fila["pe"] = numero if numero is not None else ""
                elif "perdidos" in etiqueta:
                    fila["pp"] = numero if numero is not None else ""
                elif "a favor" in etiqueta:
                    fila["gf"] = numero if numero is not None else ""
                elif "en contra" in etiqueta:
                    fila["gc"] = numero if numero is not None else ""
                elif "campe" in etiqueta or "título" in etiqueta or "titulo" in etiqueta:
                    fila["titulos"] = numero if numero is not None else ""
                elif "subcampe" in etiqueta:
                    fila["subcampeonatos"] = numero if numero is not None else ""
                elif "posición histórica" in etiqueta or "posicion historica" in etiqueta:
                    fila["posicion_historica"] = valor.split()[0] if valor else ""

        selecciones.append(fila)

        try:
            soup_mundiales = fuente.obtener_soup(f"/selecciones/{seleccion_slug}_mundiales.php")
        except FileNotFoundError:
            continue
        for fila_tabla in soup_mundiales.find_all("tr"):
            celdas = fila_tabla.find_all("td")
            if len(celdas) < 4:
                continue
            enlace_mundial = primer_link(fila_tabla, "mundiales")
            if not enlace_mundial:
                continue
            anio = extraer_entero(limpiar_texto(enlace_mundial.get_text()))
            if anio is None:
                continue
            etapa = limpiar_texto(celdas[3].get_text(" "))
            participo = "no particip" not in etapa.lower()
            participaciones.append({
                "anio": anio,
                "seleccion": nombre,
                "seleccion_slug": seleccion_slug,
                "posicion": extraer_entero(limpiar_texto(celdas[2].get_text())) or "",
                "etapa": etapa,
                "pts": extraer_entero(limpiar_texto(celdas[4].get_text())) if len(celdas) > 4 else "",
                "pj": extraer_entero(limpiar_texto(celdas[5].get_text())) if len(celdas) > 5 else "",
                "pg": extraer_entero(limpiar_texto(celdas[6].get_text())) if len(celdas) > 6 else "",
                "pe": extraer_entero(limpiar_texto(celdas[7].get_text())) if len(celdas) > 7 else "",
                "pp": extraer_entero(limpiar_texto(celdas[8].get_text())) if len(celdas) > 8 else "",
                "gf": extraer_entero(limpiar_texto(celdas[9].get_text())) if len(celdas) > 9 else "",
                "gc": extraer_entero(limpiar_texto(celdas[10].get_text())) if len(celdas) > 10 else "",
                "dif": extraer_entero(limpiar_texto(celdas[11].get_text())) if len(celdas) > 11 else "",
                "participo": participo,
            })

        if indice % 10 == 0:
            print(f"    {indice}/{len(hrefs_unicos)} selecciones")

    guardar_csv(deduplicar(selecciones, ("slug",)), "seleccion.csv", carpeta)
    guardar_csv(deduplicar(participaciones, ("anio", "seleccion_slug")), "participacion_mundial.csv", carpeta)


def extraer_jugadores(fuente: FuenteDatos, carpeta: str, limite: int = 0) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO JUGADORES")
    print("=" * 50)

    soup = fuente.obtener_soup("/jugadores.php")
    vistos: set[str] = set()
    hrefs: list[str] = []

    for link in todos_los_links(soup, "jugadores"):
        href = atributo_texto(link, "href")
        if "indice" in href:
            continue
        slug = slug_de_href(href)
        if slug and slug not in vistos:
            vistos.add(slug)
            hrefs.append(href)

    for link_indice in [link for link in soup.find_all("a", href=True) if "indice_" in atributo_texto(link, "href")]:
        try:
            soup_indice = fuente.obtener_soup(atributo_texto(link_indice, "href"))
        except FileNotFoundError:
            continue
        for link in todos_los_links(soup_indice, "jugadores"):
            href = atributo_texto(link, "href")
            if "indice" in href:
                continue
            slug = slug_de_href(href)
            if slug and slug not in vistos:
                vistos.add(slug)
                hrefs.append(href)

    if limite > 0:
        hrefs = hrefs[:limite]

    filas: list[dict] = []
    print(f"  Procesando {len(hrefs)} jugadores")
    for indice, href in enumerate(hrefs, start=1):
        slug = slug_de_href(href)
        try:
            soup_jugador = fuente.obtener_soup(href)
        except FileNotFoundError:
            continue
        titulo = soup_jugador.find("h1")
        nombre = limpiar_texto(titulo.get_text()) if isinstance(titulo, Tag) else ""
        nombre = re.sub(r"\s+en los [Mm]undiales.*$", "", nombre).strip()
        if not nombre or "404" in nombre:
            continue

        fila: dict[str, object] = {
            "slug": slug,
            "nombre": nombre,
            "nombre_completo": "",
            "seleccion": "",
            "fecha_nacimiento": "",
            "lugar_nacimiento": "",
            "posicion": "",
            "numeros_camiseta": "",
            "altura": "",
            "apodo": "",
            "sitio_web": "",
            "redes_sociales": "",
            "mundiales": "",
            "partidos": "",
            "goles": "",
            "promedio_gol": "",
        }

        link_seleccion = primer_link(soup_jugador, "selecciones")
        if link_seleccion:
            fila["seleccion"] = limpiar_texto(link_seleccion.get_text())

        for tabla in soup_jugador.find_all("table"):
            for fila_tabla in tabla.find_all("tr"):
                celdas = fila_tabla.find_all(["td", "th"])
                if len(celdas) < 2:
                    continue
                etiqueta = limpiar_texto(celdas[0].get_text()).lower().replace(":", "")
                valor = limpiar_texto(celdas[-1].get_text(" "))
                if etiqueta == "nombre completo":
                    fila["nombre_completo"] = valor
                elif "fecha de nacimiento" in etiqueta:
                    fila["fecha_nacimiento"] = valor
                elif "lugar de nacimiento" in etiqueta:
                    fila["lugar_nacimiento"] = valor
                elif etiqueta == "posición" or etiqueta == "posicion":
                    fila["posicion"] = valor
                elif "números de camiseta" in etiqueta or "numeros de camiseta" in etiqueta:
                    fila["numeros_camiseta"] = valor
                elif etiqueta == "altura":
                    fila["altura"] = valor
                elif etiqueta == "apodo":
                    fila["apodo"] = valor
                elif "sitio web oficial" in etiqueta:
                    link_web = fila_tabla.find("a", href=True)
                    fila["sitio_web"] = atributo_texto(link_web, "href") if isinstance(link_web, Tag) else valor
                elif "redes sociales" in etiqueta:
                    fila["redes_sociales"] = valor
                elif etiqueta == "mundiales":
                    numero = extraer_entero(valor)
                    fila["mundiales"] = numero if numero is not None else ""
                elif "total de partidos" in etiqueta or etiqueta == "partidos":
                    numero = extraer_entero(valor)
                    fila["partidos"] = numero if numero is not None else ""
                elif etiqueta == "goles":
                    numero = extraer_entero(valor)
                    fila["goles"] = numero if numero is not None else ""
                elif "promedio de gol" in etiqueta:
                    fila["promedio_gol"] = extraer_decimal(valor)

        filas.append(fila)
        if indice % 100 == 0:
            print(f"    {indice}/{len(hrefs)} jugadores")

    guardar_csv(deduplicar(filas, ("slug",)), "jugador.csv", carpeta)


def extraer_mundiales_info(fuente: FuenteDatos, anios: list[int], carpeta: str) -> None:
    print("\n" + "=" * 50)
    print("EXTRAYENDO MUNDIALES")
    print("=" * 50)

    filas: list[dict] = []
    for anio in anios:
        try:
            soup = fuente.obtener_soup(f"/mundiales/{anio}_mundial.php")
        except FileNotFoundError:
            continue

        fila: dict[str, object] = {
            "anio": anio,
            "sede": "",
            "campeon": "",
            "subcampeon": "",
            "tercer_lugar": "",
            "cuarto_lugar": "",
            "equipos": "",
            "partidos_jugados": "",
            "goles_total": "",
            "promedio_gol": "",
        }

        bloque_resumen = soup.find(string=lambda texto: isinstance(texto, str) and "Organizador" in texto)
        if bloque_resumen:
            contenedor = bloque_resumen.find_parent(["p", "div", "li"])
            if isinstance(contenedor, Tag):
                texto = limpiar_texto(contenedor.get_text(" "))
                sede_match = re.search(
                    r"Organizador:\s*(.+?)(?:\s*-\s*(?:Selecciones|Equipos|Partidos):|\s*(?:Selecciones|Equipos|Partidos):|$)",
                    texto,
                    flags=re.IGNORECASE,
                )
                equipos_match = re.search(r"Selecciones:\s*(\d+)", texto)
                partidos_match = re.search(r"Partidos:\s*(\d+)", texto)
                goles_match = re.search(r"Goles:\s*(\d+)", texto)
                promedio_match = re.search(r"Promedio de Gol:\s*(\d+(?:\.\d+)?)", texto)
                fila["sede"] = limpiar_texto(sede_match.group(1)) if sede_match else fila["sede"]
                fila["equipos"] = equipos_match.group(1) if equipos_match else ""
                fila["partidos_jugados"] = partidos_match.group(1) if partidos_match else ""
                fila["goles_total"] = goles_match.group(1) if goles_match else ""
                fila["promedio_gol"] = promedio_match.group(1) if promedio_match else ""

        try:
            posiciones = fuente.obtener_soup(f"/mundiales/{anio}_posiciones_finales.php")
            ranking: list[tuple[int, str]] = []
            for fila_tabla in posiciones.find_all("tr"):
                posicion = extraer_entero(limpiar_texto(fila_tabla.get_text(" ")))
                seleccion = obtener_nombre_seleccion_desde_imagen(fila_tabla)
                if posicion is not None and seleccion:
                    ranking.append((posicion, seleccion))
            ranking.sort(key=lambda item: item[0])
            if len(ranking) >= 1:
                fila["campeon"] = ranking[0][1]
            if len(ranking) >= 2:
                fila["subcampeon"] = ranking[1][1]
            if len(ranking) >= 3:
                fila["tercer_lugar"] = ranking[2][1]
            if len(ranking) >= 4:
                fila["cuarto_lugar"] = ranking[3][1]
        except FileNotFoundError:
            pass

        filas.append(fila)
        print(f"  {anio}: {fila['campeon'] or 'sin campeón'}")

    guardar_csv(deduplicar(filas, ("anio",)), "mundial.csv", carpeta)


SECCIONES = {
    "partidos": extraer_partidos,
    "grupos": extraer_grupos,
    "posiciones": extraer_posiciones_finales,
    "goleadores": extraer_goleadores,
    "premios": extraer_premios,
    "planteles": extraer_planteles,
    "selecciones": extraer_selecciones,
    "jugadores": extraer_jugadores,
    "mundiales": extraer_mundiales_info,
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Scraper normalizado de mundiales")
    parser.add_argument("--anio", type=int, nargs="*", default=None, help="Año(s) a procesar")
    parser.add_argument(
        "--seccion",
        type=str,
        nargs="*",
        default=None,
        choices=list(SECCIONES.keys()),
        help="Sección(es) a extraer",
    )
    parser.add_argument("--salida", type=str, default="./datos_normalizados", help="Carpeta de salida")
    parser.add_argument("--limite-jugadores", type=int, default=0, help="Máximo de jugadores a procesar")
    parser.add_argument(
        "--origen",
        choices=["web", "local"],
        default="web",
        help="Fuente de datos: web en vivo o carpeta local html_descargados",
    )
    parser.add_argument(
        "--html-dir",
        type=str,
        default="./html_descargados",
        help="Carpeta local con los HTML descargados",
    )
    parser.add_argument("--pausa", type=float, default=0.2, help="Pausa entre requests en modo web")
    parser.add_argument(
        "--reintentos-web",
        type=int,
        default=4,
        help="Número de reintentos web por request.",
    )
    parser.add_argument(
        "--jitter-web",
        type=float,
        default=0.6,
        help="Jitter adicional entre reintentos web (segundos).",
    )
    parser.add_argument(
        "--sin-simular-firefox",
        action="store_true",
        help="No usar user-agent Firefox en estrategias web.",
    )
    parser.add_argument(
        "--sin-forzar-ipv4",
        action="store_true",
        help="No forzar IPv4 en estrategia curl.",
    )
    parser.add_argument(
        "--sin-selenium",
        action="store_true",
        help="Desactivar estrategia Selenium para fetch web.",
    )
    parser.add_argument(
        "--selenium-headless",
        action="store_true",
        help="Usar Selenium en modo headless (puede bloquear más fácil).",
    )
    parser.add_argument(
        "--selenium-timeout",
        type=int,
        default=90,
        help="Timeout de carga en Selenium (segundos).",
    )
    parser.add_argument(
        "--web-estricto",
        action="store_true",
        help="En modo web, aborta si la respuesta viene bloqueada/vacía en lugar de usar fallback local.",
    )
    args = parser.parse_args()

    anios = args.anio if args.anio else ANIOS
    secciones = args.seccion if args.seccion else list(SECCIONES.keys())

    salida_final = os.path.abspath(args.salida)
    os.makedirs(salida_final, exist_ok=True)

    raw_dir = tempfile.mkdtemp(prefix="_raw_intermedio_", dir=salida_final)
    fuente = FuenteDatos(
        origen=args.origen,
        html_dir=os.path.abspath(args.html_dir),
        pausa=0.0 if args.origen == "local" else max(args.pausa, 0.0),
        web_estricto=args.web_estricto if args.origen == "web" else False,
        reintentos_web=max(args.reintentos_web, 1) if args.origen == "web" else 1,
        jitter_web=max(args.jitter_web, 0.0) if args.origen == "web" else 0.0,
        simular_firefox=(not args.sin_simular_firefox) if args.origen == "web" else False,
        forzar_ipv4=(not args.sin_forzar_ipv4) if args.origen == "web" else False,
        usar_selenium=(not args.sin_selenium) if args.origen == "web" else False,
        selenium_headless=args.selenium_headless if args.origen == "web" else False,
        selenium_timeout=max(args.selenium_timeout, 30) if args.origen == "web" else 30,
    )

    print("=" * 60)
    print("SCRAPER NORMALIZADO DE MUNDIALES")
    print("=" * 60)
    print(f"  Origen: {args.origen}")
    print(f"  Años: {anios}")
    print(f"  Secciones: {secciones}")
    print(f"  Salida final: {salida_final}")
    print(f"  Salida temporal raw: {raw_dir}")
    if args.origen == "web":
        print(f"  Web estricto: {'sí' if fuente.web_estricto else 'no'}")
        print(f"  Reintentos web: {fuente.reintentos_web}")
        print(f"  Jitter web: {fuente.jitter_web}")
        print(f"  Simular Firefox: {'sí' if fuente.simular_firefox else 'no'}")
        print(f"  Forzar IPv4: {'sí' if fuente.forzar_ipv4 else 'no'}")
        print(f"  Selenium: {'sí' if fuente.usar_selenium else 'no'}")
        if fuente.usar_selenium:
            print(f"  Selenium headless: {'sí' if fuente.selenium_headless else 'no'}")
            print(f"  Selenium timeout: {fuente.selenium_timeout}")
    if args.origen == "local":
        print(f"  HTML local: {fuente.html_dir}")

    try:
        for seccion in secciones:
            funcion = SECCIONES[seccion]
            if seccion == "selecciones":
                funcion(fuente, raw_dir)
            elif seccion == "jugadores":
                funcion(fuente, raw_dir, limite=args.limite_jugadores)
            else:
                funcion(fuente, anios, raw_dir)

        print("\n" + "=" * 60)
        print("NORMALIZANDO SALIDA FINAL")
        print("=" * 60)
        normalizar_csv_intermedio(raw_dir, salida_final)
    finally:
        fuente.cerrar()
        shutil.rmtree(raw_dir, ignore_errors=True)

    print("\n" + "=" * 60)
    print("EXTRACCIÓN COMPLETADA")
    print("=" * 60)


if __name__ == "__main__":
    main()
