# Fase 2 - Scripts SQL

Este directorio contiene los scripts para la simulacion de la Fase 2 del proyecto (carga masiva por dias y auditoria de rendimiento con logs).

## Archivos y objetivo

1. `02_Carga_Catalogos_2030.sql`
- Valida precondiciones de catalogo:
  - Deben existir selecciones con `seleccion_id` 1, 2, 3 y 4.
  - Deben existir jugadores con `jugador_id` del 1 al 44.
- Inserta el mundial 2030 en `dbo.mundial` (si no existe).
- Inserta catalogo base para 2030 en:
  - `dbo.participacion_mundial`
  - `dbo.grupo`
  - `dbo.plantel_jugador`
- Es idempotente para evitar duplicados en re-ejecuciones.

2. `03_Simulacion_Dia1_Grupos.sql`
- Simula el Dia 1 del torneo 2030 (fase de grupos).
- Inserta datos en:
  - `dbo.partido`
  - `dbo.aparicion_partido`
  - `dbo.gol`
  - `dbo.tarjeta`
  - `dbo.cambio`
- Al final ejecuta:
  - `EXEC dbo.sp_registrar_logs_diarios @descripcion_carga = N'Carga Masiva Día 1 - Grupos 2030';`

3. `04_Simulacion_Dia2_Finales.sql`
- Simula el Dia 2 del torneo 2030 (semifinales y final).
- Inserta datos en:
  - `dbo.partido`
  - `dbo.aparicion_partido`
  - `dbo.gol`
  - `dbo.tarjeta`
  - `dbo.cambio`
  - `dbo.penal`
- Al final ejecuta:
  - `EXEC dbo.sp_registrar_logs_diarios @descripcion_carga = N'Carga Masiva Día 2 - Finales 2030';`

4. `05_Update_Dia3_Mayusculas.sql`
- Simula el Dia 3 con un update masivo:
  - `UPDATE dbo.seleccion SET nombre = UPPER(nombre)`
- Al final ejecuta:
  - `EXEC dbo.sp_registrar_logs_diarios @descripcion_carga = N'Update Mayusculas Día 3';`

5. `06_Validacion_Fase2.sql`
- Ejecuta una validacion integral posterior a la simulacion:
  - Verifica existencia de catalogos requeridos (selecciones 1-4 y jugadores 1-44).
  - Muestra conteos por tablas impactadas para anio 2030.
  - Lista resumen de partidos del torneo 2030.
  - Muestra evidencia de logs para Dia 1, Dia 2 y Dia 3.
  - Emite semaforo final (`OK` o `REVISAR`) contra valores esperados.

## Orden de ejecucion recomendado

1. `02_Carga_Catalogos_2030.sql`
2. `03_Simulacion_Dia1_Grupos.sql`
3. `04_Simulacion_Dia2_Finales.sql`
4. `05_Update_Dia3_Mayusculas.sql`
5. `06_Validacion_Fase2.sql`

## Requisitos previos

- Base de datos `mundiales` creada y cargada.
- Esquema y tablas de logs creados (incluye `dbo.sp_registrar_logs_diarios`).
- Permisos de lectura/escritura sobre tablas de negocio y tablas `log_*`.

## Ejecucion

### Opcion A: SQL Server local o remoto con sqlcmd

```bash
sqlcmd -S <server> -U <user> -P <password> -d mundiales -i fase2/sql/02_Carga_Catalogos_2030.sql
sqlcmd -S <server> -U <user> -P <password> -d mundiales -i fase2/sql/03_Simulacion_Dia1_Grupos.sql
sqlcmd -S <server> -U <user> -P <password> -d mundiales -i fase2/sql/04_Simulacion_Dia2_Finales.sql
sqlcmd -S <server> -U <user> -P <password> -d mundiales -i fase2/sql/05_Update_Dia3_Mayusculas.sql
sqlcmd -S <server> -U <user> -P <password> -d mundiales -i fase2/sql/06_Validacion_Fase2.sql
```

### Opcion B: contenedor Docker del proyecto

```bash
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "Mundiales2026!" -d mundiales -i /db_scripts/../../fase2/sql/02_Carga_Catalogos_2030.sql
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "Mundiales2026!" -d mundiales -i /db_scripts/../../fase2/sql/03_Simulacion_Dia1_Grupos.sql
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "Mundiales2026!" -d mundiales -i /db_scripts/../../fase2/sql/04_Simulacion_Dia2_Finales.sql
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "Mundiales2026!" -d mundiales -i /db_scripts/../../fase2/sql/05_Update_Dia3_Mayusculas.sql
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "Mundiales2026!" -d mundiales -i /db_scripts/../../fase2/sql/06_Validacion_Fase2.sql
```

## Validacion rapida posterior

```sql
SELECT COUNT(*) AS partidos_2030 FROM dbo.partido WHERE anio = 2030;
SELECT COUNT(*) AS plantel_2030 FROM dbo.plantel_jugador WHERE anio = 2030;
SELECT TOP (10) * FROM dbo.log_partido ORDER BY log_id DESC;
SELECT TOP (10) * FROM dbo.log_seleccion ORDER BY log_id DESC;
```

## Compatibilidad con modelo canonico historico

- En el dataset historico (1930-2026), `dbo.participacion_mundial` puede tener mas de una fila para la misma combinacion `(anio, seleccion_id)`.
- En el dataset historico (1930-2026), `dbo.posicion_final` puede repetir `(anio, posicion)` por posiciones compartidas o canonizacion de selecciones historicas.
- Los scripts de Fase 2 para 2030 siguen insertando una fila por seleccion en `participacion_mundial`; esto es intencional para una simulacion controlada.
- Estas reglas no son conflicto: Fase 2 simula carga operativa, mientras el historico prioriza fidelidad de fuente.

## Notas

- Los scripts estan preparados para minimizar duplicados con validaciones `NOT EXISTS`.
- Si faltan catalogos base (selecciones 1-4 o jugadores 1-44), `02_Carga_Catalogos_2030.sql` detiene la ejecucion con `THROW`.
