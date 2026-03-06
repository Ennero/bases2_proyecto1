from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from webdriver_manager.firefox import GeckoDriverManager
from bs4 import BeautifulSoup
import pandas as pd
import time
import re

def crear_driver():
    """Crear un driver de Firefox en modo headless"""
    options = Options()
    options.add_argument('--headless')
    
    service = Service(GeckoDriverManager().install())
    driver = webdriver.Firefox(service=service, options=options)
    return driver

def scraping_mundial():
    print("Iniciando navegador Firefox...")
    driver = crear_driver()
    
    try:
        url_principal = "https://www.losmundialesdefutbol.com/mundiales.php"
        
        print("Conectando a la página principal...")
        driver.get(url_principal)
        time.sleep(2)
        
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # Buscar enlaces a resultados
        enlaces = [a['href'] for a in soup.select('a[href*="_resultados.php"]')]
        print(f"Se encontraron {len(enlaces)} enlaces de mundiales")
        
        datos_finales = []

        for rel_link in enlaces:
            año_match = re.search(r'(\d{4})', rel_link)
            año = año_match.group(1) if año_match else "Desconocido"
            
            # Construir URL completa
            if rel_link.startswith('../'):
                url_año = f"https://www.losmundialesdefutbol.com/{rel_link[3:]}"
            elif rel_link.startswith('/'):
                url_año = f"https://www.losmundialesdefutbol.com{rel_link}"
            elif not rel_link.startswith('http'):
                url_año = f"https://www.losmundialesdefutbol.com/{rel_link}"
            else:
                url_año = rel_link

            print(f"Extrayendo Mundial {año}...")
            try:
                driver.get(url_año)
                time.sleep(1.5)
                
                soup_año = BeautifulSoup(driver.page_source, 'html.parser')
                
                # Buscar todos los partidos (div con clase 'game')
                games = soup_año.find_all('div', class_='game')
                
                for game in games:
                    # Extraer fecha del h3 anterior
                    h3 = game.find_previous('h3')
                    fecha = h3.get_text(strip=True).replace('Fecha:', '').strip() if h3 else 'No disponible'
                    
                    # Extraer etapa del enlace anterior con 'grupo' o 'fase'
                    etapa_link = game.find_previous('a', href=lambda h: h and ('grupo' in h.lower() or 'fase' in h.lower()))
                    etapa = etapa_link.get_text(strip=True) if etapa_link else 'Desconocida'
                    
                    # Extraer resultado del enlace a 'partidos'
                    resultado_link = game.find('a', href=lambda h: h and 'partidos' in h)
                    resultado = resultado_link.get_text(strip=True) if resultado_link else 'No disponible'
                    
                    # Extraer equipos de las imágenes (atributo alt)
                    imgs = game.find_all('img')
                    if len(imgs) >= 2:
                        local = imgs[0].get('alt', 'Desconocido')
                        visitante = imgs[1].get('alt', 'Desconocido')
                    else:
                        local = 'Desconocido'
                        visitante = 'Desconocido'
                    
                    # Solo agregar si tenemos datos válidos
                    if local != 'Desconocido' and resultado != 'No disponible':
                        datos_finales.append({
                            'Anio': año,
                            'Fecha': fecha,
                            'Etapa': etapa,
                            'Local': local,
                            'Resultado': resultado,
                            'Visitante': visitante
                        })
                
                print(f"  Partidos extraídos: {len(games)}")
                
            except Exception as e:
                print(f"Error procesando {año}: {e}")

        if datos_finales:
            df = pd.DataFrame(datos_finales)
            df.to_csv('fuente_partidos_mundiales.csv', index=False, encoding='utf-8-sig')
            print(f"\n¡Listo! Se han extraído {len(datos_finales)} partidos.")
            print("Archivo guardado: fuente_partidos_mundiales.csv")
        else:
            print("\nNo se pudo extraer ningún dato.")
            
    finally:
        driver.quit()

if __name__ == "__main__":
    scraping_mundial()