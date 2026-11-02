<div align="center">

# ⚽ FIFA World Cup Database & Automated ETL Pipeline

**Pipeline integral de extracción (Web Scraping), normalización y modelado de datos históricos de Copas del Mundo (1930-2026) en SQL Server con Docker**

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org/)
[![SQL Server](https://img.shields.io/badge/SQL_Server-2022-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![University](https://img.shields.io/badge/USAC-Bases_de_Datos_2-003366?style=for-the-badge)](https://ingenieria.usac.edu.gt/)

</div>

---

## 📌 Descripción General

Este proyecto implementa una solución de **Ingeniería de Datos y Bases de Datos Relacionales** para la recolección, limpieza, modelado y explotación analítica de la historia completa de las Copas Mundiales de la FIFA (1930 a 2026):

- **Extracción & Web Scraping:** Scripts en Python para capturar resultados, alineaciones, estadísticas de penales y detalles de partidos.
- **Normalización & Calidad de Datos:** Reglas de canonización histórica (e.g., Alemania Occidental/Oriental, URSS, Yugoslavia, Países Bajos), resolución de anomalías y validación de integridad referencial.
- **Base de Datos Relacional (SQL Server):** Despliegue contenerizado en Docker con esquema relacional optimizado, llaves foráneas, índices, vistas y procedimientos almacenados para reportería analítica.
- **Auditoría Automatizada:** Reportes JSON de validación post-scraping (`fk_orphan_total = 0`, validación de penales y métricas).

---

## 🚀 Inicio Rápido con Docker

### 1. Levantar el Contenedor y Carga Automática
```bash
docker compose up -d --build
```

### 2. Verificar la Carga de Datos en SQL Server
```bash
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd \
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales \
  -Q "SELECT COUNT(*) AS total_partidos FROM dbo.partido;"
```

---

## 📦 Estructura del Repositorio

```
bases2_proyecto1/
├── db/                       # Scripts DDL, procedimientos almacenados y vistas SQL
├── docker/                   # Configuración y Dockerfiles para SQL Server
├── docs/                     # Documentación completa
│   └── manualtecnico.md      # Manual técnico unificado (Arquitectura, ETL, Modelo E-R)
├── py/                       # Scripts de scraping, limpieza y carga ETL en Python
├── logs/                     # Reportes y logs de auditoría de datos
├── docker-compose.yml        # Orquestación de servicios
├── LICENSE                   # Licencia MIT
└── README.md                 # Este documento
```

---

## 📚 Documentación Técnica

Para conocer a fondo el modelo entidad-relación, detalles de normalización, endpoints de scraping y diseño de procedimientos almacenados, consulta el **[Manual Técnico Unificado](docs/manualtecnico.md)**.

---

## 📄 Licencia

Este proyecto está liberado bajo la Licencia **MIT**. Consulta el archivo [LICENSE](LICENSE) para más información.

---

## 👨‍💻 Autores

- **Enner Mendizabal** - [@Ennero](https://github.com/Ennero)
- **David Barrios**
- **Estefania Mazariegos**

*Facultad de Ingeniería, Universidad de San Carlos de Guatemala.*
