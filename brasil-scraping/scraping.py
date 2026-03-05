import requests
from bs4 import BeautifulSoup
import pandas as pd
import time # Importante para no saturar el servidor
import re

# 1. La URL de la página de resultados que compartiste
url_resultados = 'https://www.losmundialesdefutbol.com/mundiales/1950_resultados.php'
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}

print("Iniciando extracción de la fase 1...")
respuesta = requests.get(url_resultados, headers=headers)

if respuesta.status_code == 200:
    soup = BeautifulSoup(respuesta.content, 'html.parser')
    
    # En tu HTML, cada partido está dentro de un <div class="game ...">
    contenedores_partidos = soup.find_all('div', class_='game')
    
    datos_mundial = []

    for partido in contenedores_partidos:
        # Extraer el enlace al detalle del partido (está en el <a> del medio)
        enlace_tag = partido.find('a')
        if not enlace_tag:
            continue # Si no hay enlace, saltamos
            
        resultado_texto = enlace_tag.text.strip() # Ej: "4 - 0"
        link_detalle = enlace_tag['href'] # Ej: "https://www.losmundialesdefutbol.com/partidos/1950_brasil_mexico.php"
        
        # Extraer los equipos. En tu HTML, los equipos están en divs con un ancho específico.
        # Usamos una regex sobre el atributo style para encontrarlos.
        equipos = partido.find_all('div', style=re.compile(r'width:\s*129px'))
        
        if len(equipos) >= 2:
            equipo_local = equipos[0].text.strip()
            equipo_visitante = equipos[1].text.strip()
            
            # Separar goles si el partido ya se jugó
            goles_local, goles_visitante = None, None
            if "-" in resultado_texto:
                partes = resultado_texto.split("-")
                goles_local = partes[0].strip()
                goles_visitante = partes[1].strip()

            datos_mundial.append({
                'Equipo_Local': equipo_local,
                'Goles_Local': goles_local,
                'Goles_Visitante': goles_visitante,
                'Equipo_Visitante': equipo_visitante,
                'URL_Detalle': link_detalle # ¡Esta columna es la llave para la fase 2!
            })

    # Crear el DataFrame
    df_partidos = pd.DataFrame(datos_mundial)
    print("\n--- Vista previa de los datos extraídos ---")
    print(df_partidos.head())
    
    # Guardar a CSV
    df_partidos.to_csv('partidos_1950_basico.csv', index=False, encoding='utf-8')
    print(f"\n¡Se extrajeron {len(df_partidos)} partidos y se guardaron en 'partidos_1950_basico.csv'!")

else:
    print(f"Error HTTP: {respuesta.status_code}")