<div align="center">

# ⚽ FIFA World Cup Database & Automated ETL Pipeline

**Entregas de bases de datos sobre mundiales: scraping, normalización, SQL Server y fases de simulación/migración**

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org/)
[![SQL Server](https://img.shields.io/badge/SQL_Server-2022-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![University](https://img.shields.io/badge/USAC-Bases_de_Datos_2-003366?style=for-the-badge)](https://ingenieria.usac.edu.gt/)

</div>

---

## 📌 Descripción General

Este proyecto implementa una solución de **Ingeniería de Datos y Bases de Datos Relacionales** para la recolección, limpieza, modelado y explotación analítica de datos de Copas Mundiales de la FIFA incluidos en los archivos de la entrega:

- **Extracción & Web Scraping:** Scripts en Python para capturar resultados, alineaciones, estadísticas de penales y detalles de partidos.
- **Normalización & Calidad de Datos:** Reglas de canonización histórica (e.g., Alemania Occidental/Oriental, URSS, Yugoslavia, Países Bajos), resolución de anomalías y validación de integridad referencial.
- **Base de Datos Relacional (SQL Server):** Despliegue contenerizado en Docker con esquema relacional optimizado, llaves foráneas, índices, vistas y procedimientos almacenados para reportería analítica.
- **Auditoría Automatizada:** Reportes JSON de validación post-scraping (`fk_orphan_total = 0`, validación de penales y métricas).

---

## 🚀 Inicio Rápido con Docker

### 1. Levantar SQL Server y la inicialización configurada
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

## Entregas y fases incluidas

| Ruta | Contenido y documentación |
|---|---|
| [py/](py/) | Scraping, normalización y scripts de datos. |
| [docs/manualtecnico.md](docs/manualtecnico.md) | Modelo y explicación técnica de la base de mundiales. |
| [fase2/](fase2/) | Simulación de cargas por días y respaldos; [orden de scripts](fase2/sql/README.md). |
| [fase3/](fase3/) y [fase4/](fase4/) | Archivos de las fases posteriores conservados en la entrega. |
| [Proyecto3/](Proyecto3/README.md) | Aplicación Python de consultas/migración con configuración y dependencias propias. |

Para Proyecto3, copiar `Proyecto3/.env.example` a `.env` dentro de esa carpeta, instalar `Proyecto3/requirements.txt` y seguir su README. No asumir que todos los scripts de fases se ejecutan al levantar el Compose principal.

La cobertura temporal y las métricas de calidad corresponden a los CSV y auditorías incluidos; no se afirma una historia exhaustiva por el rango del título. Las contraseñas visibles en el Compose y los comandos son de un entorno local de demostración. Cambiarlas si se reutiliza la configuración fuera de ese entorno.
