from metodo_c import info_mundial_por_anio
from metodo_d import info_por_pais

def input_opcional(mensaje):
    """Retorna el input del usuario o None si solo presionó Enter."""
    valor = input(mensaje).strip()
    return valor if valor else None

if __name__ == "__main__":
    while True:
        print("\n" + "="*40)
        print("   MENÚ DE CONSULTAS - FASE 3")
        print("="*40)
        print("1. Buscar Mundial por Año (Método C)")
        print("2. Buscar Selección por País (Método D)")
        print("0. Salir")
        
        opcion = input("\nElige una opción para ejecutar: ")
        
        if opcion == '1':
            try:
                anio = int(input("\n▶ Ingresa el año del mundial (ej. 1998): "))
                print("\n--- Filtros Opcionales (Presiona Enter para omitir) ---")
                grupo = input_opcional("Filtro - Grupo (ej. A, B): ")
                pais = input_opcional("Filtro - País participante (ej. Brasil): ")
                fecha = input_opcional("Filtro - Fecha exacta (ej. 12-Jul-1998): ")
                
                info_mundial_por_anio(anio, filtro_grupo=grupo, filtro_pais=pais, filtro_fecha=fecha)
            except ValueError:
                print("⚠️ Error: El año debe ser un número entero.")
                
        elif opcion == '2':
            pais = input("\n▶ Ingresa el nombre del país (ej. Argentina): ")
            print("\n--- Filtros Opcionales (Presiona Enter para omitir) ---")
            anio_str = input_opcional("Filtro - Año específico (ej. 2022): ")
            anio = int(anio_str) if anio_str else None
            etapa = input_opcional("Filtro - Etapa específica (ej. Final, Cuartos): ")
            
            info_por_pais(pais, filtro_anio=anio, filtro_etapa=etapa)
            
        elif opcion == '0':
            print("Saliendo de la terminal de consultas...")
            break
        else:
            print("⚠️ Opción no válida. Intenta de nuevo.")