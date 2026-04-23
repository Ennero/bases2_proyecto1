# 🏆 Sistema de Consultas - Mundial de Fútbol (MongoDB)

Este módulo proporciona una interfaz en Python para consultar información histórica de los mundiales almacenada en MongoDB. Permite obtener reportes detallados de torneos, estadísticas de selecciones y rendimientos por año.

## 🚀 Requisitos Previos

Antes de ejecutar los scripts, asegúrate de tener instaladas las librerías necesarias. Puedes instalarlas usando el archivo `requirements.txt`:

```bash
pip install -r requirements.txt
```

> **Nota:** Se requiere `pymongo` para la conexión y `certifi` para gestionar los certificados de seguridad SSL de MongoDB Atlas.

---

## 📂 Estructura del Proyecto

- **`main.py`**: Punto de entrada principal. Contiene un menú interactivo para ejecutar las consultas de forma sencilla.
- **`conexion.py`**: Centraliza la conexión a la base de datos para evitar duplicidad de código.
- **`metodo_c.py`**: Contiene la lógica para reportes de **Mundiales por Año** (incluye podio, grupos y partidos).
- **`metodo_d.py`**: Contiene la lógica para el **Expediente de Selecciones** (historial como sede, rendimiento y partidos).
- **`consultas.py`**: Script con consultas rápidas y resúmenes generales.

---

## 🛠️ Guía de Uso

### 1. Menú Interactivo (Recomendado)
Para ejecutar la herramienta con una interfaz amigable en la terminal, usa:
```bash
python main.py
```

### 2. Consultas Específicas (Métodos)

#### Método C: Info Mundial por Año
Busca toda la información de un mundial específico. Permite filtrar por grupo, país o fecha.
```python
from metodo_c import info_mundial_por_anio
info_mundial_por_anio(1998, filtro_pais="Brasil")
```

#### Método D: Info por País
Genera un expediente completo de una selección. Permite filtrar por año o etapa del torneo.
```python
from metodo_d import info_por_pais
info_por_pais("Argentina", filtro_anio=2022)
```

#### Consultas Rápidas (`consultas.py`)
Muestra resúmenes generales de todos los mundiales registrados.
```bash
python consultas.py
```

---

## 📋 Funcionalidades Principales
- **Filtros Flexibles**: Puedes buscar partidos exactos por fecha o grupos específicos.
- **Búsqueda Inteligente**: Los nombres de los países se buscan ignorando mayúsculas y minúsculas (Regex).
- **Reportes Visuales**: Uso de emojis y formatos tabulares en consola para mejor lectura.