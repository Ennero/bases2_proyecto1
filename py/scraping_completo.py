from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from webdriver_manager.firefox import GeckoDriverManager
from bs4 import BeautifulSoup
import pandas as pd
import time
import re
import os

# Cambiar al directorio del script
os.chdir(os.path.dirname(os.path.abspath(__file__)))

def crear_driver():
    """Crear un driver de Firefox en modo headless"""
    options = Options()
    options.add_argument('--headless')
    service = Service(GeckoDriverManager().install())
    driver = webdriver.Firefox(service=service, options=options)
    return driver

def extraer_goleadores(driver, años):
    """Extraer goleadores de cada mundial"""
    print("\n" + "="*50)
    print("EXTRAYENDO GOLEADORES...")
    print("="*50)
    
    datos_goleadores = []
    
    for año in años:
        url = f"https://www.losmundialesdefutbol.com/mundiales/{año}_goleadores.php"
        print(f"  Goleadores {año}...")
        
        try:
            driver.get(url)
            time.sleep(1.5)
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            
            # Buscar filas de la tabla de goleadores
            filas = soup.find_all('tr')
            
            for fila in filas:
                celdas = fila.find_all('td')
                if len(celdas) >= 3:
                    # Buscar imagen de bandera para obtener país
                    img = fila.find('img')
                    pais = img.get('alt', 'Desconocido') if img else 'Desconocido'
                    
                    # Buscar enlace con nombre del jugador
                    enlace_jugador = fila.find('a', href=lambda h: h and 'jugadores' in h)
                    if enlace_jugador:
                        jugador = enlace_jugador.get_text(strip=True)
                        
                        # Buscar goles (última celda numérica)
                        goles = None
                        for celda in reversed(celdas):
                            texto = celda.get_text(strip=True)
                            if texto.isdigit():
                                goles = int(texto)
                                break
                        
                        if goles and jugador:
                            datos_goleadores.append({
                                'Anio': año,
                                'Jugador': jugador,
                                'Seleccion': pais,
                                'Goles': goles
                            })
        except Exception as e:
            print(f"    Error en {año}: {e}")
    
    if datos_goleadores:
        df = pd.DataFrame(datos_goleadores)
        df.to_csv('goleadores.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Goleadores extraídos: {len(datos_goleadores)} registros")
    
    return datos_goleadores

def extraer_posiciones_finales(driver, años):
    """Extraer posiciones finales de cada mundial"""
    print("\n" + "="*50)
    print("EXTRAYENDO POSICIONES FINALES...")
    print("="*50)
    
    datos_posiciones = []
    
    for año in años:
        url = f"https://www.losmundialesdefutbol.com/mundiales/{año}_posiciones_finales.php"
        print(f"  Posiciones {año}...")
        
        try:
            driver.get(url)
            time.sleep(1.5)
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            
            # Buscar filas con posiciones
            filas = soup.find_all('tr')
            
            for fila in filas:
                celdas = fila.find_all('td')
                if len(celdas) >= 2:
                    # Primera celda suele ser la posición
                    pos_texto = celdas[0].get_text(strip=True)
                    
                    # Buscar imagen de bandera
                    img = fila.find('img')
                    pais = img.get('alt', '') if img else ''
                    
                    if pais and pos_texto:
                        # Extraer número de posición
                        pos_match = re.search(r'(\d+)', pos_texto)
                        if pos_match:
                            posicion = int(pos_match.group(1))
                            datos_posiciones.append({
                                'Anio': año,
                                'Posicion': posicion,
                                'Seleccion': pais
                            })
        except Exception as e:
            print(f"    Error en {año}: {e}")
    
    if datos_posiciones:
        df = pd.DataFrame(datos_posiciones)
        df.to_csv('posiciones_finales.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Posiciones extraídas: {len(datos_posiciones)} registros")
    
    return datos_posiciones

def extraer_info_mundiales(driver, años):
    """Extraer información general de cada mundial (sede, campeón, etc.)"""
    print("\n" + "="*50)
    print("EXTRAYENDO INFO DE MUNDIALES...")
    print("="*50)
    
    datos_mundiales = []
    
    for año in años:
        url = f"https://www.losmundialesdefutbol.com/mundiales/{año}_mundial.php"
        print(f"  Info Mundial {año}...")
        
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
                'Equipos': '',
                'Partidos': '',
                'Goles': ''
            }
            
            # Buscar datos en la página
            texto_pagina = soup.get_text()
            
            # Buscar campeón - generalmente está destacado
            campeon_div = soup.find('div', class_='negri')
            if campeon_div:
                img_campeon = campeon_div.find_previous('img')
                if img_campeon:
                    info['Campeon'] = img_campeon.get('alt', '')
            
            # Buscar en elementos con información estructurada
            for elemento in soup.find_all(['div', 'span', 'p']):
                texto = elemento.get_text(strip=True).lower()
                
                if 'sede:' in texto or 'país organizador' in texto:
                    img = elemento.find('img') or elemento.find_next('img')
                    if img:
                        info['Sede'] = img.get('alt', '')
                
                if 'campeón' in texto or 'campeon' in texto:
                    img = elemento.find('img') or elemento.find_next('img')
                    if img and not info['Campeon']:
                        info['Campeon'] = img.get('alt', '')
            
            # Extraer de la tabla de posiciones si existe
            posiciones = soup.find_all('tr')
            for i, pos in enumerate(posiciones[:5]):
                img = pos.find('img')
                if img:
                    pais = img.get('alt', '')
                    if i == 0 or '1' in pos.get_text():
                        if not info['Campeon']:
                            info['Campeon'] = pais
                    elif i == 1 or '2' in pos.get_text():
                        if not info['Subcampeon']:
                            info['Subcampeon'] = pais
                    elif i == 2 or '3' in pos.get_text():
                        if not info['TercerLugar']:
                            info['TercerLugar'] = pais
                    elif i == 3 or '4' in pos.get_text():
                        if not info['CuartoLugar']:
                            info['CuartoLugar'] = pais
            
            datos_mundiales.append(info)
            
        except Exception as e:
            print(f"    Error en {año}: {e}")
    
    if datos_mundiales:
        df = pd.DataFrame(datos_mundiales)
        df.to_csv('mundiales_info.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Info mundiales extraída: {len(datos_mundiales)} registros")
    
    return datos_mundiales

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
        time.sleep(2)
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # Buscar enlaces a selecciones
        enlaces_selecciones = soup.find_all('a', href=lambda h: h and '/selecciones/' in h)
        
        selecciones_urls = set()
        for enlace in enlaces_selecciones:
            href = enlace.get('href', '')
            if href and '.php' in href:
                selecciones_urls.add(href)
        
        print(f"  Encontradas {len(selecciones_urls)} selecciones")
        
        for i, url_sel in enumerate(selecciones_urls):
            if not url_sel.startswith('http'):
                url_completa = f"https://www.losmundialesdefutbol.com/{url_sel.replace('../', '')}"
            else:
                url_completa = url_sel
            
            try:
                driver.get(url_completa)
                time.sleep(1)
                soup_sel = BeautifulSoup(driver.page_source, 'html.parser')
                
                # Extraer nombre del país del título
                titulo = soup_sel.find('h1')
                nombre_pais = titulo.get_text(strip=True) if titulo else 'Desconocido'
                nombre_pais = nombre_pais.replace(' en los Mundiales', '').replace(' en los mundiales', '').strip()
                
                info_sel = {
                    'Seleccion': nombre_pais,
                    'Participaciones': 0,
                    'PartidosJugados': 0,
                    'Ganados': 0,
                    'Empatados': 0,
                    'Perdidos': 0,
                    'GolesFavor': 0,
                    'GolesContra': 0,
                    'Titulos': 0
                }
                
                # Buscar estadísticas en la página
                texto = soup_sel.get_text()
                
                # Buscar números de participaciones, títulos, etc.
                matches_part = re.search(r'(\d+)\s*(?:participacion|mundial)', texto.lower())
                if matches_part:
                    info_sel['Participaciones'] = int(matches_part.group(1))
                
                matches_tit = re.search(r'(\d+)\s*(?:título|campeon|copa)', texto.lower())
                if matches_tit:
                    info_sel['Titulos'] = int(matches_tit.group(1))
                
                # Buscar tabla de estadísticas
                tablas = soup_sel.find_all('table')
                for tabla in tablas:
                    filas = tabla.find_all('tr')
                    for fila in filas:
                        celdas = fila.find_all(['td', 'th'])
                        texto_fila = ' '.join([c.get_text(strip=True) for c in celdas]).lower()
                        
                        if 'jugados' in texto_fila or 'pj' in texto_fila:
                            numeros = re.findall(r'\d+', texto_fila)
                            if numeros:
                                info_sel['PartidosJugados'] = int(numeros[-1])
                        
                        if 'ganados' in texto_fila or ' g ' in texto_fila:
                            numeros = re.findall(r'\d+', texto_fila)
                            if numeros:
                                info_sel['Ganados'] = int(numeros[-1])
                
                datos_selecciones.append(info_sel)
                
                if (i + 1) % 10 == 0:
                    print(f"    Procesadas {i + 1}/{len(selecciones_urls)} selecciones...")
                    
            except Exception as e:
                print(f"    Error en {url_sel}: {e}")
                
    except Exception as e:
        print(f"  Error general: {e}")
    
    if datos_selecciones:
        df = pd.DataFrame(datos_selecciones)
        df.to_csv('selecciones.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Selecciones extraídas: {len(datos_selecciones)} registros")
    
    return datos_selecciones

def extraer_estadisticas_generales(driver):
    """Extraer estadísticas generales históricas"""
    print("\n" + "="*50)
    print("EXTRAYENDO ESTADÍSTICAS GENERALES...")
    print("="*50)
    
    url = "https://www.losmundialesdefutbol.com/estadisticas.php"
    
    try:
        driver.get(url)
        time.sleep(2)
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # Guardar el HTML para análisis
        with open('estadisticas_raw.html', 'w', encoding='utf-8') as f:
            f.write(soup.prettify())
        
        print("  ✓ HTML de estadísticas guardado para análisis")
        
        # Extraer lo que podamos
        datos_stats = []
        
        # Buscar tablas con datos
        tablas = soup.find_all('table')
        for tabla in tablas:
            filas = tabla.find_all('tr')
            for fila in filas:
                celdas = fila.find_all(['td', 'th'])
                if len(celdas) >= 2:
                    # Buscar país
                    img = fila.find('img')
                    if img:
                        pais = img.get('alt', '')
                        valores = [c.get_text(strip=True) for c in celdas]
                        datos_stats.append({
                            'Seleccion': pais,
                            'Datos': ' | '.join(valores)
                        })
        
        if datos_stats:
            df = pd.DataFrame(datos_stats)
            df.to_csv('estadisticas_generales.csv', index=False, encoding='utf-8-sig')
            print(f"\n✓ Estadísticas extraídas: {len(datos_stats)} registros")
            
    except Exception as e:
        print(f"  Error: {e}")

def extraer_grupos(driver, años):
    """Extraer información de grupos de cada mundial"""
    print("\n" + "="*50)
    print("EXTRAYENDO GRUPOS...")
    print("="*50)
    
    datos_grupos = []
    
    for año in años:
        # Probar diferentes grupos (A-H)
        for grupo in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']:
            url = f"https://www.losmundialesdefutbol.com/mundiales/{año}_grupo_{grupo}.php"
            
            try:
                driver.get(url)
                time.sleep(1)
                soup = BeautifulSoup(driver.page_source, 'html.parser')
                
                # Verificar si la página existe (no es 404)
                if '404' in driver.title or 'No encontrado' in driver.title:
                    continue
                
                # Buscar tabla de posiciones del grupo
                filas = soup.find_all('tr')
                posicion = 1
                
                for fila in filas:
                    celdas = fila.find_all('td')
                    if len(celdas) >= 5:
                        img = fila.find('img')
                        if img:
                            pais = img.get('alt', '')
                            
                            # Extraer estadísticas (PJ, G, E, P, GF, GC, Pts)
                            valores = [c.get_text(strip=True) for c in celdas]
                            numeros = [v for v in valores if v.isdigit() or v.lstrip('-').isdigit()]
                            
                            if pais and len(numeros) >= 5:
                                datos_grupos.append({
                                    'Anio': año,
                                    'Grupo': grupo.upper(),
                                    'Posicion': posicion,
                                    'Seleccion': pais,
                                    'PJ': numeros[0] if len(numeros) > 0 else 0,
                                    'G': numeros[1] if len(numeros) > 1 else 0,
                                    'E': numeros[2] if len(numeros) > 2 else 0,
                                    'P': numeros[3] if len(numeros) > 3 else 0,
                                    'GF': numeros[4] if len(numeros) > 4 else 0,
                                    'GC': numeros[5] if len(numeros) > 5 else 0,
                                    'Pts': numeros[6] if len(numeros) > 6 else 0
                                })
                                posicion += 1
                                
            except Exception as e:
                pass  # Silenciosamente ignorar grupos que no existen
        
        print(f"  Grupos {año} procesados")
    
    if datos_grupos:
        df = pd.DataFrame(datos_grupos)
        df.to_csv('grupos.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Grupos extraídos: {len(datos_grupos)} registros")
    
    return datos_grupos

def extraer_jugadores(driver):
    """Extraer información de jugadores destacados"""
    print("\n" + "="*50)
    print("EXTRAYENDO JUGADORES...")
    print("="*50)
    
    datos_jugadores = []
    
    url = "https://www.losmundialesdefutbol.com/jugadores.php"
    
    try:
        driver.get(url)
        time.sleep(2)
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # Buscar enlaces a jugadores
        enlaces_jugadores = soup.find_all('a', href=lambda h: h and '/jugadores/' in h)
        
        jugadores_urls = set()
        for enlace in enlaces_jugadores:
            href = enlace.get('href', '')
            if href and '.php' in href:
                jugadores_urls.add(href)
        
        print(f"  Encontrados {len(jugadores_urls)} jugadores")
        
        for i, url_jug in enumerate(list(jugadores_urls)[:100]):  # Limitar a 100 para no tardar mucho
            if not url_jug.startswith('http'):
                url_completa = f"https://www.losmundialesdefutbol.com/{url_jug.replace('../', '')}"
            else:
                url_completa = url_jug
            
            try:
                driver.get(url_completa)
                time.sleep(0.8)
                soup_jug = BeautifulSoup(driver.page_source, 'html.parser')
                
                # Extraer nombre del jugador
                titulo = soup_jug.find('h1')
                nombre = titulo.get_text(strip=True) if titulo else 'Desconocido'
                nombre = nombre.replace(' en los Mundiales', '').strip()
                
                # Buscar país
                img = soup_jug.find('img', alt=True)
                pais = img.get('alt', 'Desconocido') if img else 'Desconocido'
                
                # Buscar goles
                texto = soup_jug.get_text()
                goles_match = re.search(r'(\d+)\s*gol', texto.lower())
                goles = int(goles_match.group(1)) if goles_match else 0
                
                # Buscar partidos
                partidos_match = re.search(r'(\d+)\s*partido', texto.lower())
                partidos = int(partidos_match.group(1)) if partidos_match else 0
                
                datos_jugadores.append({
                    'Jugador': nombre,
                    'Seleccion': pais,
                    'Goles': goles,
                    'Partidos': partidos
                })
                
                if (i + 1) % 20 == 0:
                    print(f"    Procesados {i + 1} jugadores...")
                    
            except Exception as e:
                pass
                
    except Exception as e:
        print(f"  Error: {e}")
    
    if datos_jugadores:
        df = pd.DataFrame(datos_jugadores)
        df.to_csv('jugadores.csv', index=False, encoding='utf-8-sig')
        print(f"\n✓ Jugadores extraídos: {len(datos_jugadores)} registros")
    
    return datos_jugadores

def main():
    print("="*60)
    print("   EXTRACCIÓN COMPLETA DE DATOS DE MUNDIALES")
    print("="*60)
    
    driver = crear_driver()
    
    try:
        # Lista de años de mundiales
        años = [2026, 2022, 2018, 2014, 2010, 2006, 2002, 1998, 1994, 1990,
                1986, 1982, 1978, 1974, 1970, 1966, 1962, 1958, 1954, 1950,
                1938, 1934, 1930]
        
        # 1. Goleadores
        extraer_goleadores(driver, años)
        
        # 2. Posiciones finales
        extraer_posiciones_finales(driver, años)
        
        # 3. Información de mundiales
        extraer_info_mundiales(driver, años)
        
        # 4. Grupos
        extraer_grupos(driver, años)
        
        # 5. Selecciones
        extraer_selecciones(driver)
        
        # 6. Jugadores (limitado a 100)
        extraer_jugadores(driver)
        
        # 7. Estadísticas generales
        extraer_estadisticas_generales(driver)
        
        print("\n" + "="*60)
        print("   ¡EXTRACCIÓN COMPLETADA!")
        print("="*60)
        print("\nArchivos generados:")
        print("  - fuente_partidos_mundiales.csv (ya existente)")
        print("  - goleadores.csv")
        print("  - posiciones_finales.csv")
        print("  - mundiales_info.csv")
        print("  - grupos.csv")
        print("  - selecciones.csv")
        print("  - jugadores.csv")
        print("  - estadisticas_generales.csv")
        
    finally:
        driver.quit()

if __name__ == "__main__":
    main()
