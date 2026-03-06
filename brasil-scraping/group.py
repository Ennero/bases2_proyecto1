import os
import shutil

# ==========================================
# CONFIGURACIÓN
# ==========================================
CARPETA_ORIGEN = 'html_descargados'   # La carpeta donde tu crawler guardó todo
CARPETA_DESTINO = 'txt_agrupados'     # Cambié el nombre para reflejar el nuevo formato
ARCHIVOS_POR_LOTE = 50                # Cambia este número a 100 si tienes NotebookLM Plus

def agrupar_archivos():
    # 1. Verificar si la carpeta de origen existe
    if not os.path.exists(CARPETA_ORIGEN):
        print(f"Error: No se encontró la carpeta '{CARPETA_ORIGEN}'.")
        return

    # 2. Crear la carpeta de destino principal si no existe
    if not os.path.exists(CARPETA_DESTINO):
        os.makedirs(CARPETA_DESTINO)

    # 3. Obtener la lista de todos los archivos
    archivos = [f for f in os.listdir(CARPETA_ORIGEN) if os.path.isfile(os.path.join(CARPETA_ORIGEN, f))]
    
    total_archivos = len(archivos)
    print(f"Se encontraron {total_archivos} archivos para agrupar y convertir.")

    if total_archivos == 0:
        return

    # 4. Procesar los archivos en lotes
    numero_lote = 1
    
    for i in range(0, total_archivos, ARCHIVOS_POR_LOTE):
        lote_actual = archivos[i : i + ARCHIVOS_POR_LOTE]
        
        nombre_carpeta_lote = f"Lote_{numero_lote}"
        ruta_lote = os.path.join(CARPETA_DESTINO, nombre_carpeta_lote)
        
        if not os.path.exists(ruta_lote):
            os.makedirs(ruta_lote)
            
        print(f"Creando {nombre_carpeta_lote} y copiando {len(lote_actual)} archivos a formato .txt...")

        # 5. Copiar y renombrar cada archivo
        for archivo in lote_actual:
            ruta_origen = os.path.join(CARPETA_ORIGEN, archivo)
            
            # === LA MAGIA OCURRE AQUÍ ===
            # Separamos el nombre del archivo de su extensión original (.php o .html)
            nombre_sin_extension, _ = os.path.splitext(archivo)
            
            # Creamos el nuevo nombre forzando la extensión .txt
            nuevo_nombre = f"{nombre_sin_extension}.txt"
            
            ruta_destino = os.path.join(ruta_lote, nuevo_nombre)
            
            # Copiamos el archivo con su nuevo nombre
            shutil.copy2(ruta_origen, ruta_destino) 
            
        numero_lote += 1

    print("\n¡Proceso terminado con éxito!")
    print(f"Se crearon {numero_lote - 1} carpetas en '{CARPETA_DESTINO}' listas para NotebookLM.")

# Ejecutar el script
if __name__ == "__main__":
    agrupar_archivos()