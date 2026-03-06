import os
import time
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

# Configuración inicial
URL_INICIAL = 'https://www.losmundialesdefutbol.com/mundiales.php'
DOMINIO_PERMITIDO = 'www.losmundialesdefutbol.com'
MAX_NIVELES = 4
CARPETA_DESTINO = 'html_descargados'

# Evitar procesar la misma URL en memoria durante la misma ejecución
urls_visitadas = set()

if not os.path.exists(CARPETA_DESTINO):
    os.makedirs(CARPETA_DESTINO)

def obtener_nombre_archivo_seguro(url):
    parseado = urlparse(url)
    ruta = parseado.path.strip('/')
    if not ruta:
        ruta = "index"
    
    nombre_archivo = ruta.replace('/', '_')
    if not nombre_archivo.endswith('.html') and not nombre_archivo.endswith('.php'):
        nombre_archivo += '.html'
        
    return os.path.join(CARPETA_DESTINO, nombre_archivo)

def es_enlace_valido(url_absoluta):
    parseado = urlparse(url_absoluta)
    if parseado.netloc != DOMINIO_PERMITIDO:
        return False
    if any(url_absoluta.endswith(ext) for ext in ['.jpg', '.png', '.pdf', '.css', '.js']):
        return False
    return True

def extraer_y_seguir(contenido_html, url_base, nivel_actual):
    """Función auxiliar para buscar enlaces dentro de un HTML (sea descargado o local)"""
    soup = BeautifulSoup(contenido_html, 'html.parser')
    for enlace in soup.find_all('a', href=True):
        enlace_crudo = str(enlace['href'])
        if not enlace_crudo or enlace_crudo.startswith('#') or enlace_crudo.startswith('javascript:'):
            continue
            
        url_absoluta = urljoin(url_base, enlace_crudo).split('#')[0]
        
        if es_enlace_valido(url_absoluta):
            rastrear_y_descargar(url_absoluta, nivel_actual + 1)

def rastrear_y_descargar(url, nivel_actual):
    if nivel_actual > MAX_NIVELES or url in urls_visitadas:
        return
    
    urls_visitadas.add(url)
    ruta_archivo = obtener_nombre_archivo_seguro(url)
    
    # === LA NUEVA LÓGICA DE OPTIMIZACIÓN ===
    if os.path.exists(ruta_archivo):
        print(f"[{nivel_actual}/{MAX_NIVELES}] Omitiendo descarga (Ya existe en disco): {ruta_archivo}")
        # Si aún no llegamos al límite de profundidad, necesitamos los enlaces que tiene adentro
        if nivel_actual < MAX_NIVELES:
            try:
                with open(ruta_archivo, 'r', encoding='utf-8') as f:
                    contenido_local = f.read()
                extraer_y_seguir(contenido_local, url, nivel_actual)
            except Exception as e:
                print(f"Error al leer el archivo local {ruta_archivo}: {e}")
        return # Salimos de la función para no hacer la petición HTTP
    # =======================================

    try:
        time.sleep(0.7) # Pausa de cortesía obligatoria al descargar
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        print(f"[{nivel_actual}/{MAX_NIVELES}] Descargando: {url}")
        respuesta = requests.get(url, headers=headers, timeout=10)
        
        if respuesta.status_code == 200:
            with open(ruta_archivo, 'w', encoding='utf-8') as f:
                f.write(respuesta.text)
                
            if nivel_actual < MAX_NIVELES:
                extraer_y_seguir(respuesta.content, url, nivel_actual)
                
    except Exception as e:
        print(f"Error HTTP al procesar {url}: {e}")

# Iniciar el proceso
print("Iniciando el Crawler...")
rastrear_y_descargar(URL_INICIAL, 1)
print(f"\nProceso terminado. Se rastrearon {len(urls_visitadas)} URLs únicas en esta ejecución.")