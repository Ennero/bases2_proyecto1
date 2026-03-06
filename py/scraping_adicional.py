from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from webdriver_manager.firefox import GeckoDriverManager
from bs4 import BeautifulSoup
import pandas as pd
import time
import re
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

def crear_driver():
    options = Options()
    options.add_argument('--headless')
    service = Service(GeckoDriverManager().install())
    driver = webdriver.Firefox(service=service, options=options)
    return driver

def extraer_selecciones(driver):
    """Extraer información de todas las selecciones"""
    print("\n" + "="*50)
    print("EXTRAYENDO SELECCIONES...")
    print("="*50)
    
    datos_selecciones = []
    
    url = "https://www.losmundialesdefutbol.com/selecciones.php"
    print(f"  Cargando lista de selecciones...")
    
    try:
        driver.get(url)
        time.sleep(3)
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # Buscar todos los enlaces a selecciones individuales
        enlaces = soup.find_all('a', href=lambda h: h and '/selecciones/' in h and '.php' in h)
        
        urls_unicas = set()
        for enlace in enlaces:
            href = enlace.get('href', '')
            if href:
                urls_unicas.add(href)
        
        print(f"  Encontradas {len(urls_unicas)} selecciones únicas")
        
        for i, url_rel in enumerate(urls_unicas):
            if url_rel.startswith('../'):
                url_completa = f"https://www.losmundialesdefutbol.com/{url_rel[3:]}"
            elif url_rel.startswith('/'):
                url_completa = f"https://www.losmundialesdefutbol.com{url_rel}"
            else:
                url_completa = f"https://www.losmundialesdefutbol.com/{url_rel}"
            
            try:
                driver.get(url_completa)
                time.sleep(1)
                soup_sel = BeautifulSoup(driver.page_source, 'html.parser')
                
                # Nombre del país
                h1 = soup_sel.find('h1')
                nombre = h1.get_text(strip=True) if h1 else ''
                nombre = nombre.replace(' en los Mundiales', '').replace(' en los mundiales', '').strip()
                
                if not nombre or 'error' in nombre.lower() or '404' in nombre.lower():
                    continue
                
                info = {
                    'Seleccion': nombre,
                    'Participaciones': 0,
                    'PJ': 0,
                    'G': 0,
                    'E': 0,
                    'P': 0,
                    'GF': 0,
                    'GC': 0,
                    'Titulos': 0,
                    'Subcampeonatos': 0,
                    'TercerosLugares': 0
                }
                
                # Buscar datos numéricos en tablas
                for tabla in soup_sel.find_all('table'):
                    texto_tabla = tabla.get_text().lower()
                    
                    for fila in tabla.find_all('tr'):
                        celdas = fila.find_all(['td', 'th'])
                        if len(celdas) >= 2:
                            label = celdas[0].get_text(strip=True).lower()
                            valor = celdas[-1].get_text(strip=True)
                            
                            try:
                                num = int(re.search(r'\d+', valor).group()) if re.search(r'\d+', valor) else 0
                            except:
                                num = 0
                            
                            if 'participacion' in label or 'mundial' in label:
                                info['Participaciones'] = max(info['Participaciones'], num)
                            elif 'jugados' in label or 'pj' == label:
                                info['PJ'] = num
                            elif 'ganados' in label or label == 'g':
                                info['G'] = num
                            elif 'empat' in label or label == 'e':
                                info['E'] = num
                            elif 'perdidos' in label or label == 'p':
                                info['P'] = num
                            elif 'favor' in label or 'gf' in label:
                                info['GF'] = num
                            elif 'contra' in label or 'gc' in label:
                                info['GC'] = num
                            elif 'título' in label or 'campeon' in label:
                                info['Titulos'] = num
                
                # Buscar en el texto general
                texto = soup_sel.get_text()
                
                # Títulos mundiales
                tit_match = re.search(r'(\d+)\s*(?:vez|veces|título)', texto.lower())
                if tit_match and info['Titulos'] == 0:
                    info['Titulos'] = int(tit_match.group(1))
                
                datos_selecciones.append(info)
                
                if (i + 1) % 10 == 0:
                    print(f"    Procesadas {i + 1}/{len(urls_unicas)} selecciones...")
                    
            except Exception as e:
                print(f"    Error: {e}")
                continue
                
    except Exception as e:
        print(f"  Error general: {e}")
    
    if datos_selecciones:
        df = pd.DataFrame(datos_selecciones)
        df.to_csv('selecciones.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Selecciones extraídas: {len(datos_selecciones)} registros")
    
    return datos_selecciones

def extraer_jugadores_top(driver):
    """Extraer jugadores destacados de los mundiales"""
    print("\n" + "="*50)
    print("EXTRAYENDO JUGADORES TOP...")
    print("="*50)
    
    datos_jugadores = []
    
    # Obtener jugadores de la página principal de jugadores
    url = "https://www.losmundialesdefutbol.com/jugadores.php"
    
    try:
        driver.get(url)
        time.sleep(2)
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # Buscar todas las filas con información de jugadores
        filas = soup.find_all('tr')
        
        for fila in filas:
            celdas = fila.find_all('td')
            if len(celdas) >= 2:
                # Buscar enlace al jugador
                enlace = fila.find('a', href=lambda h: h and 'jugadores' in h)
                if enlace:
                    nombre = enlace.get_text(strip=True)
                    
                    # Buscar bandera para país
                    img = fila.find('img')
                    pais = img.get('alt', 'Desconocido') if img else 'Desconocido'
                    
                    # Buscar números (goles, partidos)
                    numeros = []
                    for celda in celdas:
                        texto = celda.get_text(strip=True)
                        if texto.isdigit():
                            numeros.append(int(texto))
                    
                    if nombre and nombre != 'Jugador':
                        datos_jugadores.append({
                            'Jugador': nombre,
                            'Seleccion': pais,
                            'Goles': numeros[0] if len(numeros) > 0 else 0,
                            'Partidos': numeros[1] if len(numeros) > 1 else 0
                        })
        
        print(f"  Jugadores de página principal: {len(datos_jugadores)}")
        
    except Exception as e:
        print(f"  Error: {e}")
    
    if datos_jugadores:
        df = pd.DataFrame(datos_jugadores)
        df.to_csv('jugadores.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Jugadores extraídos: {len(datos_jugadores)} registros")
    
    return datos_jugadores

def extraer_mundiales_detallado(driver):
    """Extraer información detallada de cada mundial"""
    print("\n" + "="*50)
    print("EXTRAYENDO INFO DETALLADA DE MUNDIALES...")
    print("="*50)
    
    años = [2026, 2022, 2018, 2014, 2010, 2006, 2002, 1998, 1994, 1990,
            1986, 1982, 1978, 1974, 1970, 1966, 1962, 1958, 1954, 1950,
            1938, 1934, 1930]
    
    datos_mundiales = []
    
    for año in años:
        url = f"https://www.losmundialesdefutbol.com/mundiales/{año}_mundial.php"
        print(f"  Mundial {año}...")
        
        try:
            driver.get(url)
            time.sleep(1.5)
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            
            info = {
                'Anio': año,
                'Sede': '',
                'Campeon': '',
                'Subcampeon': '',
                'TercerLugar': '',
                'CuartoLugar': '',
                'GoleadorOro': '',
                'GoleadorGoles': 0,
                'MejorJugador': '',
                'MejorArquero': ''
            }
            
            # Buscar datos en divs y spans
            texto_pagina = soup.get_text()
            
            # Extraer sede del título o contenido
            paises_posibles = ['Argentina', 'Brasil', 'Alemania', 'Francia', 'Italia', 
                             'España', 'México', 'Estados Unidos', 'Rusia', 'Sudáfrica',
                             'Japón', 'Corea del Sur', 'Inglaterra', 'Chile', 'Suecia',
                             'Suiza', 'Uruguay', 'Qatar', 'Catar', 'Canadá']
            
            # Buscar posiciones finales para determinar campeón, etc.
            url_pos = f"https://www.losmundialesdefutbol.com/mundiales/{año}_posiciones_finales.php"
            driver.get(url_pos)
            time.sleep(1)
            soup_pos = BeautifulSoup(driver.page_source, 'html.parser')
            
            posiciones = []
            for fila in soup_pos.find_all('tr'):
                img = fila.find('img')
                if img:
                    pais = img.get('alt', '')
                    celdas = fila.find_all('td')
                    if celdas:
                        pos_texto = celdas[0].get_text(strip=True)
                        if pos_texto.isdigit():
                            posiciones.append((int(pos_texto), pais))
            
            # Ordenar por posición
            posiciones.sort(key=lambda x: x[0])
            
            if len(posiciones) >= 1:
                info['Campeon'] = posiciones[0][1]
            if len(posiciones) >= 2:
                info['Subcampeon'] = posiciones[1][1]
            if len(posiciones) >= 3:
                info['TercerLugar'] = posiciones[2][1]
            if len(posiciones) >= 4:
                info['CuartoLugar'] = posiciones[3][1]
            
            # Buscar goleador
            url_gol = f"https://www.losmundialesdefutbol.com/mundiales/{año}_goleadores.php"
            driver.get(url_gol)
            time.sleep(1)
            soup_gol = BeautifulSoup(driver.page_source, 'html.parser')
            
            for fila in soup_gol.find_all('tr'):
                enlace = fila.find('a', href=lambda h: h and 'jugadores' in h)
                if enlace:
                    info['GoleadorOro'] = enlace.get_text(strip=True)
                    # Buscar goles
                    celdas = fila.find_all('td')
                    for celda in reversed(celdas):
                        texto = celda.get_text(strip=True)
                        if texto.isdigit():
                            info['GoleadorGoles'] = int(texto)
                            break
                    break  # Solo el primero
            
            # Buscar premios
            url_premios = f"https://www.losmundialesdefutbol.com/mundiales/{año}_premios.php"
            driver.get(url_premios)
            time.sleep(1)
            soup_premios = BeautifulSoup(driver.page_source, 'html.parser')
            
            texto_premios = soup_premios.get_text().lower()
            
            # Buscar mejor jugador (Balón de Oro)
            for fila in soup_premios.find_all('tr'):
                texto_fila = fila.get_text().lower()
                if 'balón de oro' in texto_fila or 'mejor jugador' in texto_fila:
                    enlace = fila.find('a', href=lambda h: h and 'jugadores' in h)
                    if enlace:
                        info['MejorJugador'] = enlace.get_text(strip=True)
                elif 'guante de oro' in texto_fila or 'mejor arquero' in texto_fila or 'mejor portero' in texto_fila:
                    enlace = fila.find('a', href=lambda h: h and 'jugadores' in h)
                    if enlace:
                        info['MejorArquero'] = enlace.get_text(strip=True)
            
            datos_mundiales.append(info)
            
        except Exception as e:
            print(f"    Error en {año}: {e}")
    
    if datos_mundiales:
        df = pd.DataFrame(datos_mundiales)
        df.to_csv('mundiales_info.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Info mundiales extraída: {len(datos_mundiales)} registros")
    
    return datos_mundiales

def extraer_planteles(driver):
    """Extraer planteles de cada selección por mundial"""
    print("\n" + "="*50)
    print("EXTRAYENDO PLANTELES...")
    print("="*50)
    
    años = [2022, 2018, 2014, 2010, 2006, 2002, 1998, 1994, 1990,
            1986, 1982, 1978, 1974, 1970, 1966, 1962, 1958, 1954, 1950,
            1938, 1934, 1930]
    
    datos_planteles = []
    
    for año in años:
        url = f"https://www.losmundialesdefutbol.com/mundiales/{año}_planteles.php"
        print(f"  Planteles {año}...")
        
        try:
            driver.get(url)
            time.sleep(1.5)
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            
            # Buscar enlaces a planteles de cada país
            enlaces_planteles = soup.find_all('a', href=lambda h: h and 'plantel' in h.lower())
            
            for enlace in enlaces_planteles:
                img = enlace.find('img') or enlace.find_previous('img')
                if img:
                    pais = img.get('alt', '')
                    if pais:
                        datos_planteles.append({
                            'Anio': año,
                            'Seleccion': pais
                        })
            
        except Exception as e:
            print(f"    Error en {año}: {e}")
    
    # Eliminar duplicados
    datos_unicos = []
    vistos = set()
    for d in datos_planteles:
        key = (d['Anio'], d['Seleccion'])
        if key not in vistos:
            vistos.add(key)
            datos_unicos.append(d)
    
    if datos_unicos:
        df = pd.DataFrame(datos_unicos)
        df.to_csv('participaciones.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Participaciones extraídas: {len(datos_unicos)} registros")
    
    return datos_unicos

def extraer_tarjetas(driver):
    """Extraer tarjetas de cada mundial"""
    print("\n" + "="*50)
    print("EXTRAYENDO TARJETAS...")
    print("="*50)
    
    años = [2022, 2018, 2014, 2010, 2006, 2002, 1998, 1994, 1990, 1986, 1982]
    
    datos_tarjetas = []
    
    for año in años:
        url = f"https://www.losmundialesdefutbol.com/mundiales/{año}_tarjetas.php"
        print(f"  Tarjetas {año}...")
        
        try:
            driver.get(url)
            time.sleep(1.5)
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            
            for fila in soup.find_all('tr'):
                enlace = fila.find('a', href=lambda h: h and 'jugadores' in h)
                if enlace:
                    jugador = enlace.get_text(strip=True)
                    
                    img = fila.find('img')
                    pais = img.get('alt', '') if img else ''
                    
                    celdas = fila.find_all('td')
                    amarillas = 0
                    rojas = 0
                    
                    for celda in celdas:
                        texto = celda.get_text(strip=True)
                        # Buscar números para tarjetas
                        if texto.isdigit():
                            if amarillas == 0:
                                amarillas = int(texto)
                            else:
                                rojas = int(texto)
                    
                    if jugador and (amarillas > 0 or rojas > 0):
                        datos_tarjetas.append({
                            'Anio': año,
                            'Jugador': jugador,
                            'Seleccion': pais,
                            'Amarillas': amarillas,
                            'Rojas': rojas
                        })
                        
        except Exception as e:
            print(f"    Error en {año}: {e}")
    
    if datos_tarjetas:
        df = pd.DataFrame(datos_tarjetas)
        df.to_csv('tarjetas.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Tarjetas extraídas: {len(datos_tarjetas)} registros")
    
    return datos_tarjetas

def main():
    print("="*60)
    print("   EXTRACCIÓN ADICIONAL DE DATOS")
    print("="*60)
    
    driver = crear_driver()
    
    try:
        # 1. Selecciones
        extraer_selecciones(driver)
        
        # 2. Jugadores
        extraer_jugadores_top(driver)
        
        # 3. Info detallada de mundiales
        extraer_mundiales_detallado(driver)
        
        # 4. Participaciones por mundial
        extraer_planteles(driver)
        
        # 5. Tarjetas
        extraer_tarjetas(driver)
        
        print("\n" + "="*60)
        print("   ¡EXTRACCIÓN ADICIONAL COMPLETADA!")
        print("="*60)
        
    finally:
        driver.quit()

if __name__ == "__main__":
    main()
