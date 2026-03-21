# Mundiales de Futbol - Base de Datos Relacional

Autores: David Barrios, Enner Mendizabal, Estefania Mazariegos  
Licencia: MIT  
Version: 2026.1  
Ultima actualizacion: Marzo 20, 2026

## Descripcion general

Proyecto para extraer, normalizar y cargar datos historicos de Copas del Mundo (1930-2026) en SQL Server.

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
