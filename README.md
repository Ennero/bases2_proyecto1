# Mundiales de Futbol - Base de Datos Relacional

Autores: David Barrios, Enner Mendizabal, Estefania Mazariegos  
Licencia: MIT  
Version: 2026.2  
Ultima actualizacion: Marzo 28, 2026

## Descripcion general

Proyecto para extraer, normalizar y cargar datos historicos de Copas del Mundo (1930-2026) en SQL Server.

## Estado tecnico actual (mar 2026)

- Parseo de penales corregido: solo toma marcador cuando hay contexto explicito de definicion por penales.
- Si no hay marcador valido en fuente, `penales_local` y `penales_visitante` se mantienen nulos.
- Canonizacion historica activa en selecciones: Alemania Occidental/Oriental, URSS, RF de Yugoslavia, Serbia y Montenegro, Checoslovaquia, Holanda/Paises Bajos.
- El modelo SQL no fuerza unicidad natural en casos historicos canonizados:
  - `participacion_mundial` puede repetir `(anio, seleccion_id)`.
  - `posicion_final` puede repetir `(anio, posicion)` o `(anio, seleccion_id)`.
- Auditoria post-scrapeo web disponible en `logs/auditoria_post_scrapeo_web_20260327_235248.json`.
  - `fk_orphan_total = 0`
  - `penalty_anomalies = 0`

## Inicio rapido

1. Levantar el entorno:

```bash
docker compose up -d --build
```

2. Verificar carga basica:

```bash
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd \
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales \
  -Q "SELECT COUNT(*) AS partidos FROM dbo.partido;"
```

## Manual tecnico unificado

Toda la documentacion tecnica del proyecto se encuentra en:

- [docs/manualtecnico.md](docs/manualtecnico.md)

Ese manual incluye arquitectura, scraping, normalizacion, Docker, esquema SQL, ETL, stored procedures, lineamientos de vistas, operacion y troubleshooting.








| Rol sugerido | Fases a cargo | Responsabilidades principales |
| :--- | :--- | :--- |
| **1. Especialista en Arquitectura y Carga de Datos** | Fase 1 y Fase 2 | • Analizar estrategias y preparar el entorno estableciendo rutas de almacenamiento <br>• Crear la base de datos con claves primarias, foráneas y restricciones .<br>• Agregar una tabla de registro (LOG) para cada tabla principal <br>• Realizar la carga masiva (simular partidos, cambiar nombres a mayúsculas) durante los 3 días simulados 65, 68.<br>• Obtener el nivel de fragmentación e insertarlo en los logs respectivos |
| **2. Administrador de Respaldos y Restauración** | Fase 2  Fase 3 y Fase 4 | • Ejecutar backups completos e incrementales/diferenciales por consola al final de cada día de carga 43, 55.<br>• Eliminar la base de datos y restaurar los backups en orden secuencial en un segundo esquema 46, 72, 74.<br>• Tomar capturas de pantalla de validación (`SELECT *` y `SELECT COUNT(*)`) asegurando que la fecha y hora del sistema operativo sean visibles 47, 77.<br>• Registrar los tiempos precisos de restauración con cronómetro87, 112. |
| **3. Analista de Rendimiento y Documentador Técnico** | Fase 5 y Entregables | • Realizar el análisis comparativo de los tiempos de restauración registrados 76.<br>• Elaborar recomendaciones y conclusiones basadas en datos reales 76.<br>• Redactar la Documentación Técnica en PDF (metodología, modelo ER, especificaciones del servidor) <br>• Crear el Manual de Usuario paso a paso <br>• Consolidar y comentar el Código Fuente (scripts SQL) para la entrega final. |
