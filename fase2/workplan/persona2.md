# Plan de Trabajo — Persona 2 (Administrador de Respaldos y Restauracion)

## Entorno de trabajo

- Motor: SQL Server 2022 sobre Docker (Linux)
- Contenedor: mundiales_db
- Base de datos principal: mundiales
- Base de datos de restauracion: mundiales_restaurado
- Carpeta de backups dentro del contenedor: /var/opt/mssql/backup/
- Carpeta de backups en el PC: backups/ (raiz del repositorio)

---

## Conceptos rapidos de referencia

**Full Backup:** Copia completa de toda la base de datos en ese momento.
Para restaurar solo necesitas este archivo.

**Differential Backup:** Copia solo lo que cambio desde el ultimo Full Backup.
Para restaurar necesitas primero el Full Backup y luego aplicar el Differential encima.

**Captura ANTES:** Pantallazo tomado antes de ejecutar un script, mostrando el estado
actual de las tablas que van a ser modificadas. Sirve como evidencia del estado inicial.

**Captura DESPUES:** Pantallazo tomado despues de ejecutar un script, mostrando como
quedaron las tablas afectadas. Sirve como evidencia de que la carga fue exitosa.

**Regla de oro:** Todas las capturas deben mostrar la fecha y hora del sistema
operativo visible en la barra de tareas de Windows.

---

## Dia 0 — Preparacion (hacer una sola vez)

### Paso 1 — Levantar la base de datos

```powershell
docker compose up -d --build
docker logs -f mundiales_db
```

Esperar hasta ver en los logs:

```
>>> Inicializacion completada.
```

### Paso 2 — Crear la carpeta de backups

```powershell
docker exec -it mundiales_db bash -c "mkdir -p /var/opt/mssql/backup"
```

### ANTES — Captura 01: Estado inicial de las tablas antes de cualquier carga 2030

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
-- Verificar que no existe nada del 2030 aun (todos deben dar 0)
SELECT COUNT(*) AS mundial_2030             FROM dbo.mundial                WHERE anio = 2030;
SELECT COUNT(*) AS participacion_2030       FROM dbo.participacion_mundial   WHERE anio = 2030;
SELECT COUNT(*) AS grupo_2030               FROM dbo.grupo                   WHERE anio = 2030;
SELECT COUNT(*) AS plantel_jugador_2030     FROM dbo.plantel_jugador         WHERE anio = 2030;

-- Verificar datos historicos cargados correctamente
SELECT COUNT(*) AS partidos_historicos      FROM dbo.partido;
SELECT COUNT(*) AS jugadores_historicos     FROM dbo.jugador;
SELECT COUNT(*) AS selecciones              FROM dbo.seleccion;
```

Valores esperados: los primeros 4 en 0, partidos ~964, jugadores ~8444, selecciones ~144.

### Paso 3 — Ejecutar el script de catalogos 2030

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/02_Carga_Catalogos_2030.sql
```

Debe terminar sin errores. Si lanza THROW 50001 o 50002 significa que faltan
selecciones o jugadores base.

### DESPUES — Captura 02: Estado de las tablas despues de 02_Carga_Catalogos_2030.sql

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

_nota: de ahora en adelante los comandos están diseñados para ejecutar en una herramienta de gestión de base de datos, si deseas continuar usando la terminal del contenedor de docker lo puedes realizar de la siguiente forma:_

```bash
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -Q "CONSULTA A EJECUTAR"
```

```sql
-- Conteos esperados
SELECT COUNT(*) AS mundial_2030             FROM dbo.mundial                WHERE anio = 2030;  -- esperado: 1
SELECT COUNT(*) AS participacion_2030       FROM dbo.participacion_mundial   WHERE anio = 2030;  -- esperado: 4
SELECT COUNT(*) AS grupo_2030               FROM dbo.grupo                   WHERE anio = 2030;  -- esperado: 4
SELECT COUNT(*) AS plantel_jugador_2030     FROM dbo.plantel_jugador         WHERE anio = 2030;  -- esperado: 44

-- Detalle de lo insertado
SELECT * FROM dbo.mundial                WHERE anio = 2030;
SELECT * FROM dbo.participacion_mundial  WHERE anio = 2030;
SELECT * FROM dbo.grupo                  WHERE anio = 2030;
SELECT * FROM dbo.plantel_jugador        WHERE anio = 2030 ORDER BY seleccion_id, jugador_id;
```

---

## Dia 1 — Simulacion de fase de grupos

### Que ocurre en este dia

Se insertan 4 partidos de fase de grupos con apariciones, goles, tarjetas y cambios.
Tablas afectadas: partido, aparicion*partido, gol, tarjeta, cambio, log*\*.

### ANTES — Captura 03: Estado de las tablas antes del Dia 1

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
-- Todas deben dar 0 para anio 2030
SELECT COUNT(*) AS partido_2030         FROM dbo.partido            WHERE anio = 2030;
SELECT COUNT(*) AS aparicion_2030       FROM dbo.aparicion_partido ap
                                        INNER JOIN dbo.partido p ON p.partido_id = ap.partido_id
                                        WHERE p.anio = 2030;
SELECT COUNT(*) AS gol_2030             FROM dbo.gol g
                                        INNER JOIN dbo.partido p ON p.partido_id = g.partido_id
                                        WHERE p.anio = 2030;
SELECT COUNT(*) AS tarjeta_2030         FROM dbo.tarjeta t
                                        INNER JOIN dbo.partido p ON p.partido_id = t.partido_id
                                        WHERE p.anio = 2030;
SELECT COUNT(*) AS cambio_2030          FROM dbo.cambio c
                                        INNER JOIN dbo.partido p ON p.partido_id = c.partido_id
                                        WHERE p.anio = 2030;
```

Valores esperados: todos en 0.

### Paso 1 — Ejecutar el script del Dia 1

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/03_Simulacion_Dia1_Grupos.sql
```

### DESPUES — Captura 04: Estado de las tablas despues del Dia 1

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
-- Conteos esperados
SELECT COUNT(*) AS partido_2030         FROM dbo.partido            WHERE anio = 2030;           -- esperado: 4
SELECT COUNT(*) AS aparicion_2030       FROM dbo.aparicion_partido ap
                                        INNER JOIN dbo.partido p ON p.partido_id = ap.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 32
SELECT COUNT(*) AS gol_2030             FROM dbo.gol g
                                        INNER JOIN dbo.partido p ON p.partido_id = g.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 10
SELECT COUNT(*) AS tarjeta_2030         FROM dbo.tarjeta t
                                        INNER JOIN dbo.partido p ON p.partido_id = t.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 6
SELECT COUNT(*) AS cambio_2030          FROM dbo.cambio c
                                        INNER JOIN dbo.partido p ON p.partido_id = c.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 4

-- Detalle de lo insertado
SELECT * FROM dbo.partido               WHERE anio = 2030 ORDER BY partido_id;
SELECT * FROM dbo.gol g
INNER JOIN dbo.partido p ON p.partido_id = g.partido_id
WHERE p.anio = 2030 ORDER BY g.partido_id, g.minuto;
SELECT * FROM dbo.tarjeta t
INNER JOIN dbo.partido p ON p.partido_id = t.partido_id
WHERE p.anio = 2030;

-- Verificar logs del dia 1
SELECT TOP 3 * FROM dbo.log_partido     ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_seleccion   ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_gol         ORDER BY log_id DESC;
```

### Paso 2 — Full Backup del Dia 1

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH FORMAT, INIT, NAME = 'Full Backup Dia 1', STATS = 10"
```

### DESPUES — Captura 05: Confirmacion Full Backup Dia 1

Que debe verse: mensaje de confirmacion con el tiempo de ejecucion.
Anotar el tiempo en la tabla de registro de tiempos.

### Paso 3 — Differential Backup del Dia 1

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_diff_dia1.bak' WITH DIFFERENTIAL, FORMAT, INIT, NAME = 'Differential Backup Dia 1', STATS = 10"
```

### DESPUES — Captura 06: Confirmacion Differential Backup Dia 1

Que debe verse: mensaje de confirmacion con el tiempo de ejecucion.
Anotar el tiempo en la tabla de registro de tiempos.

---

## Dia 2 — Simulacion de semifinales y final

### Que ocurre en este dia

Se insertan 2 semifinales y 1 final con penales.
Tablas afectadas: partido, aparicion*partido, gol, tarjeta, cambio, penal, log*\*.

### ANTES — Captura 07: Estado de las tablas antes del Dia 2

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
-- Deben mostrar los valores del Dia 1 (estado actual antes de cargar Dia 2)
SELECT COUNT(*) AS partido_2030         FROM dbo.partido            WHERE anio = 2030;           -- esperado: 4
SELECT COUNT(*) AS gol_2030             FROM dbo.gol g
                                        INNER JOIN dbo.partido p ON p.partido_id = g.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 10
SELECT COUNT(*) AS penal_2030           FROM dbo.penal pe
                                        INNER JOIN dbo.partido p ON p.partido_id = pe.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 0
SELECT * FROM dbo.partido               WHERE anio = 2030 ORDER BY partido_id;
```

### Paso 1 — Ejecutar el script del Dia 2

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/04_Simulacion_Dia2_Finales.sql
```

### DESPUES — Captura 08: Estado de las tablas despues del Dia 2

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
-- Conteos acumulados esperados
SELECT COUNT(*) AS partido_2030         FROM dbo.partido            WHERE anio = 2030;           -- esperado: 7
SELECT COUNT(*) AS gol_2030             FROM dbo.gol g
                                        INNER JOIN dbo.partido p ON p.partido_id = g.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 18
SELECT COUNT(*) AS tarjeta_2030         FROM dbo.tarjeta t
                                        INNER JOIN dbo.partido p ON p.partido_id = t.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 10
SELECT COUNT(*) AS cambio_2030          FROM dbo.cambio c
                                        INNER JOIN dbo.partido p ON p.partido_id = c.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 8
SELECT COUNT(*) AS penal_2030           FROM dbo.penal pe
                                        INNER JOIN dbo.partido p ON p.partido_id = pe.partido_id
                                        WHERE p.anio = 2030;                                     -- esperado: 8

-- Detalle de lo insertado
SELECT * FROM dbo.partido               WHERE anio = 2030 ORDER BY partido_id;

SELECT pe.*, p.etapa, p.fecha
FROM dbo.penal pe
INNER JOIN dbo.partido p ON p.partido_id = pe.partido_id
WHERE p.anio = 2030 ORDER BY pe.partido_id, pe.orden;

-- Logs del dia 2
SELECT TOP 3 * FROM dbo.log_partido     ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_penal       ORDER BY log_id DESC;
```

### Paso 2 — Full Backup del Dia 2

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_full_dia2.bak' WITH FORMAT, INIT, NAME = 'Full Backup Dia 2', STATS = 10"
```

### DESPUES — Captura 09: Confirmacion Full Backup Dia 2

Que debe verse: mensaje de confirmacion con el tiempo de ejecucion.
Anotar el tiempo en la tabla de registro de tiempos.

### Paso 3 — Differential Backup del Dia 2

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_diff_dia2.bak' WITH DIFFERENTIAL, FORMAT, INIT, NAME = 'Differential Backup Dia 2', STATS = 10"
```

### DESPUES — Captura 10: Confirmacion Differential Backup Dia 2

Que debe verse: mensaje de confirmacion con el tiempo de ejecucion.
Anotar el tiempo en la tabla de registro de tiempos.

---

## Dia 3 — Update masivo a mayusculas

### Que ocurre en este dia

Se ejecuta UPDATE sobre dbo.seleccion convirtiendo todos los nombres a mayusculas.
Tablas afectadas: seleccion, log\_\*.

### ANTES — Captura 11: Estado de dbo.seleccion antes del Dia 3

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
-- Mostrar nombres en minusculas/mixto antes del UPDATE
SELECT TOP 20 seleccion_id, nombre FROM dbo.seleccion ORDER BY seleccion_id;

-- Contar cuantos nombres NO estan en mayusculas (debe ser > 0)
SELECT COUNT(*) AS nombres_en_minusculas
FROM dbo.seleccion
WHERE nombre <> UPPER(nombre);
```

Valor esperado: nombres en minusculas/mixto, contador mayor a 0.

### Paso 1 — Ejecutar el script del Dia 3

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/05_Update_Dia3_Mayusculas.sql
```

### DESPUES — Captura 12: Estado de dbo.seleccion despues del Dia 3

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
-- Mostrar nombres en mayusculas despues del UPDATE
SELECT TOP 20 seleccion_id, nombre FROM dbo.seleccion ORDER BY seleccion_id;

-- Confirmar que ningun nombre tiene minusculas (debe ser 0)
SELECT COUNT(*) AS nombres_en_minusculas
FROM dbo.seleccion
WHERE nombre <> UPPER(nombre);                                               -- esperado: 0

-- Logs del dia 3
SELECT TOP 3 * FROM dbo.log_seleccion   ORDER BY log_id DESC;
```

### Paso 2 — Ejecutar validacion final

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/06_Validacion_Fase2.sql
```

### DESPUES — Captura 13: Semaforo final de validacion

Que debe verse: todas las filas del semaforo con estado OK.

### Paso 3 — Full Backup del Dia 3

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_full_dia3.bak' WITH FORMAT, INIT, NAME = 'Full Backup Dia 3', STATS = 10"
```

### DESPUES — Captura 14: Confirmacion Full Backup Dia 3

Que debe verse: mensaje de confirmacion con el tiempo de ejecucion.
Anotar el tiempo en la tabla de registro de tiempos.

### Paso 4 — Differential Backup del Dia 3

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_diff_dia3.bak' WITH DIFFERENTIAL, FORMAT, INIT, NAME = 'Differential Backup Dia 3', STATS = 10"
```

### DESPUES — Captura 15: Confirmacion Differential Backup Dia 3

Que debe verse: mensaje de confirmacion con el tiempo de ejecucion.
Anotar el tiempo en la tabla de registro de tiempos.

### Captura 16 — Listado de los 6 archivos de backup

```powershell
docker exec -it mundiales_db bash -c "ls -lh /var/opt/mssql/backup/"
```

Que debe verse: los 6 archivos .bak con sus nombres y tamanios.

---

## Fase 3 — Restauracion de Full Backups

### Que se hace en esta fase

Se elimina la base de datos y se restaura desde cada Full Backup en orden,
en una nueva base llamada mundiales_restaurado. Se mide el tiempo de cada restauracion.

### Paso 1 — Eliminar la base de datos original

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "ALTER DATABASE [mundiales] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [mundiales];"
```

### ANTES — Captura 17: Confirmacion de que la BD fue eliminada

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "SELECT name FROM sys.databases WHERE name IN ('mundiales', 'mundiales_restaurado');"
```

Que debe verse: resultado vacio — ninguna de las dos bases existe.

### Restauracion Full Backup Dia 1

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', REPLACE, STATS = 10"
```

### DESPUES — Captura 18: Validacion Full Backup Dia 1 restaurado

Ejecutar en DBeaver y capturar pantalla con fecha/hora visible:

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido  WHERE anio = 2030;  -- esperado: 4

SELECT COUNT(*) AS apariciones_2030 FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030; -- esperado: 32

SELECT COUNT(*) AS goles_2030 FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030;
 -- esperado: 10

SELECT COUNT(*) AS tarjetas_2030 FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030; -- esperado: 6

SELECT COUNT(*) AS cambios_2030 FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030; -- esperado: 4

-- Detalles

SELECT * FROM dbo.partido WHERE anio = 2030 ORDER BY partido_id;

SELECT * FROM dbo.aparicion_partido ap INNER JOIN dbo.partido p ON p.partido_id = ap.partido_id  WHERE p.anio = 2030;

SELECT * FROM dbo.gol g INNER JOIN dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030 ORDER BY g.partido_id, g.minuto;

SELECT * FROM dbo.tarjeta t INNER JOIN dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030;

SELECT * FROM dbo.cambio c INNER JOIN dbo.partido p ON p.partido_id = c.partido_id  WHERE p.anio = 2030;

-- Verificar los logs

SELECT TOP 3 * FROM dbo.log_partido     ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_seleccion   ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_gol         ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_cambio      ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_tarjeta     ORDER BY log_id DESC;

```

Anotar el tiempo en la tabla de registro.

### Restauracion Full Backup Dia 2

### ANTES — Captura 19: Verificación de datos no existentes

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido  WHERE anio = 2030;  -- esperado: 7

SELECT COUNT(*) AS aparacion_2030  FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030; -- esperado: 32

SELECT COUNT(*) AS gol_2030  FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030; -- esperado: 10

SELECT COUNT(*) AS tarjeta_2030  FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030; -- esperado: 6

SELECT COUNT(*) AS cambio_2030  FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030; -- esperado: 4

SELECT COUNT(*) AS penales_2030  FROM mundiales_restaurado.dbo.penal pe INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = pe.partido_id WHERE p.anio = 2030; -- esperado: 0
```

### Captura 20: Eliminación

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

Confirmar que la DB fue eliminada

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "SELECT name FROM sys.databases WHERE name IN ('mundiales', 'mundiales_restaurado');"
```

### Captura 21: Restauración

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia2.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', REPLACE, STATS = 10"
```

### DESPUES — Captura 22: Validacion Full Backup Dia 2 restaurado

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido  WHERE anio = 2030;  -- esperado: 7

SELECT COUNT(*) AS aparacion_2030  FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030; -- esperado: 56

SELECT COUNT(*) AS gol_2030  FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030; -- esperado: 18

SELECT COUNT(*) AS tarjeta_2030  FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030; -- esperado: 10

SELECT COUNT(*) AS cambio_2030  FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030; -- esperado: 8

SELECT COUNT(*) AS penales_2030  FROM mundiales_restaurado.dbo.penal pe INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = pe.partido_id WHERE p.anio = 2030; -- esperado: 8

-- Especifico

SELECT * FROM mundiales_restaurado.dbo.partido WHERE anio = 2030 ORDER BY partido_id;

SELECT * FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.penal pe INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = pe.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

-- LOGS

SELECT TOP 3 * FROM dbo.log_partido               ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_aparicion_partido     ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_gol                   ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_tarjeta               ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_cambio                ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_penal                 ORDER BY log_id DESC;

```

Anotar el tiempo en la tabla de registro.

### Restauracion Full Backup Dia 3

### ANTES — Captura 23: Verificación de datos no existentes

```sql
SELECT * FROM mundiales_restaurado.dbo.seleccion  WHERE anio = 2030;
```

### Captura 24: Eliminación

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

Verificamos que se elimino la DB

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "SELECT name FROM sys.databases WHERE name IN ('mundiales', 'mundiales_restaurado');"
```

### Captura 25: restauración

Iniciar cronometro antes de ejecutar:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia3.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', REPLACE, STATS = 10"
```

### DESPUES — Captura 26: Validacion Full Backup Dia 3 restaurado

```sql
SELECT COUNT(*) AS partidos_2030        FROM mundiales_restaurado.dbo.partido           WHERE anio = 2030;  -- esperado: 7

SELECT TOP 20 seleccion_id, nombre      FROM mundiales_restaurado.dbo.seleccion         ORDER BY seleccion_id;

SELECT COUNT(*) AS nombres_minusculas   FROM mundiales_restaurado.dbo.seleccion WHERE nombre <> UPPER(nombre);  -- esperado: 0


-- Logs

SELECT TOP 3 * FROM dbo.log_seleccion            ORDER BY log_id DESC;
```

Anotar el tiempo en la tabla de registro.

---

## Fase 4 — Restauracion de Differential Backups

### Que se hace en esta fase

El Differential necesita el Full como base. Se restaura el Full en NORECOVERY
(queda en espera) y luego se aplica el Differential con RECOVERY.

### Paso 1 — Eliminar la base restaurada anterior

### Captura 27: Eliminación

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

Verificamos que se elimino la DB

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "SELECT name FROM sys.databases WHERE name IN ('mundiales', 'mundiales_restaurado');"
```

### Restauracion Full Dia 1 + Differential Dia 1

Iniciar cronometro antes del primer comando:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', NORECOVERY, REPLACE, STATS = 10"
```

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_diff_dia1.bak' WITH RECOVERY, STATS = 10"
```

### DESPUES - Captura 28: Restauración Completada

Detener cronometro al confirmar exito del segundo comando.

### DESPUES — Captura 29: Validacion Full+Diff Dia 1 restaurado

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido  WHERE anio = 2030;  -- esperado: 4

SELECT COUNT(*) AS apariciones_2030 FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030; -- esperado: 32

SELECT COUNT(*) AS goles_2030 FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030;
 -- esperado: 10

SELECT COUNT(*) AS tarjetas_2030 FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030; -- esperado: 6

SELECT COUNT(*) AS cambios_2030 FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030; -- esperado: 4

-- Detalles

SELECT * FROM dbo.partido WHERE anio = 2030 ORDER BY partido_id;

SELECT * FROM dbo.aparicion_partido ap INNER JOIN dbo.partido p ON p.partido_id = ap.partido_id  WHERE p.anio = 2030;

SELECT * FROM dbo.gol g INNER JOIN dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030 ORDER BY g.partido_id, g.minuto;

SELECT * FROM dbo.tarjeta t INNER JOIN dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030;

SELECT * FROM dbo.cambio c INNER JOIN dbo.partido p ON p.partido_id = c.partido_id  WHERE p.anio = 2030;

-- Verificar los logs

SELECT TOP 3 * FROM dbo.log_partido     ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_seleccion   ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_gol         ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_cambio      ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_tarjeta     ORDER BY log_id DESC;
```

Anotar el tiempo total en la tabla de registro.

### Restauracion Full Dia 1 + Differential Dia 2

### ANTES — Captura 30: Verificación de datos no existentes

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido  WHERE anio = 2030;  -- esperado: 7

SELECT COUNT(*) AS aparacion_2030  FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030; -- esperado: 32

SELECT COUNT(*) AS gol_2030  FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030; -- esperado: 10

SELECT COUNT(*) AS tarjeta_2030  FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030; -- esperado: 6

SELECT COUNT(*) AS cambio_2030  FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030; -- esperado: 4

SELECT COUNT(*) AS penales_2030  FROM mundiales_restaurado.dbo.penal pe INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = pe.partido_id WHERE p.anio = 2030; -- esperado: 0
```

### Captura 31: Eliminación

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

Verificamos que se elimino la DB

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "SELECT name FROM sys.databases WHERE name IN ('mundiales', 'mundiales_restaurado');"
```

### Captura 32: Restauración

Iniciar cronometro:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia2.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', NORECOVERY, REPLACE, STATS = 10"
```

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_diff_dia2.bak' WITH RECOVERY, STATS = 10"
```

### DESPUES — Captura 33: Validacion Full+Diff Dia 2 restaurado

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido  WHERE anio = 2030;  -- esperado: 7

SELECT COUNT(*) AS aparacion_2030  FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030; -- esperado: 56

SELECT COUNT(*) AS gol_2030  FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030; -- esperado: 18

SELECT COUNT(*) AS tarjeta_2030  FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030; -- esperado: 10

SELECT COUNT(*) AS cambio_2030  FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030; -- esperado: 8

SELECT COUNT(*) AS penales_2030  FROM mundiales_restaurado.dbo.penal pe INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = pe.partido_id WHERE p.anio = 2030; -- esperado: 8

-- Especifico

SELECT * FROM mundiales_restaurado.dbo.partido WHERE anio = 2030 ORDER BY partido_id;

SELECT * FROM mundiales_restaurado.dbo.aparicion_partido ap INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = ap.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.gol g INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.tarjeta t INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.cambio c INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

SELECT * FROM mundiales_restaurado.dbo.penal pe INNER JOIN mundiales_restaurado.dbo.partido p ON p.partido_id = pe.partido_id WHERE p.anio = 2030 and (p.etapa = 'Final' or p.etapa = 'Semifinal');

-- LOGS

SELECT TOP 3 * FROM dbo.log_partido               ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_aparicion_partido     ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_gol                   ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_tarjeta               ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_cambio                ORDER BY log_id DESC;
SELECT TOP 3 * FROM dbo.log_penal                 ORDER BY log_id DESC;
```

Anotar el tiempo total en la tabla de registro.

### Restauracion Full Dia 1 + Differential Dia 3

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

Iniciar cronometro:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', NORECOVERY, REPLACE, STATS = 10"
```

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_diff_dia3.bak' WITH RECOVERY, STATS = 10"
```

### DESPUES — Captura 23: Validacion Full+Diff Dia 3 restaurado

```sql
SELECT COUNT(*) AS partidos_2030        FROM mundiales_restaurado.dbo.partido           WHERE anio = 2030;  -- esperado: 7
SELECT TOP 20 seleccion_id, nombre      FROM mundiales_restaurado.dbo.seleccion         ORDER BY seleccion_id;
SELECT COUNT(*) AS nombres_minusculas   FROM mundiales_restaurado.dbo.seleccion
                                        WHERE nombre <> UPPER(nombre);                                       -- esperado: 0
```

Anotar el tiempo total en la tabla de registro.

---

## Tabla de registro de tiempos

Llenar con los tiempos medidos con cronometro:

| Operacion                    | Tiempo (segundos) | Tamanio archivo            |
| :--------------------------- | :---------------- | :------------------------- |
| Full Backup Dia 1            | 2.28              | 17.1 MB (17,948,672 bytes) |
| Differential Backup Dia 1    | 1.98              | 2.11 MB (2,220,032 bytes)  |
| Full Backup Dia 2            | 2.47              | 17.1 MB (17,948,672 bytes) |
| Differential Backup Dia 2    | 1.88              | 2.11 MB (2,220,032 bytes)  |
| Full Backup Dia 3            | 2.10              | 17.1 MB (17,948,672 bytes) |
| Differential Backup Dia 3    | 1.89              | 2.11 MB (2,220,032 bytes)  |
| Restauracion Full Dia 1      | 2.60              |                            |
| Restauracion Full Dia 2      | 2.71              |                            |
| Restauracion Full Dia 3      | 3.34              |                            |
| Restauracion Full+Diff Dia 1 | 6.33              |                            |
| Restauracion Full+Diff Dia 2 | 5.55              |                            |
| Restauracion Full+Diff Dia 3 |                   |                            |

---

## Resumen de capturas

| #   | Momento               | Que debe verse                                          |
| :-- | :-------------------- | :------------------------------------------------------ |
| 01  | ANTES Dia 0           | Conteos en 0 para 2030, datos historicos cargados       |
| 02  | DESPUES catalogos     | 1 mundial, 4 participaciones, 4 grupos, 44 planteles    |
| 03  | ANTES Dia 1           | partido, gol, tarjeta, cambio en 0 para 2030            |
| 04  | DESPUES Dia 1         | 4 partidos, 10 goles, 6 tarjetas, 4 cambios, logs       |
| 05  | DESPUES Full Dia 1    | Confirmacion backup con tiempo                          |
| 06  | DESPUES Diff Dia 1    | Confirmacion backup con tiempo                          |
| 07  | ANTES Dia 2           | 4 partidos, 0 penales (estado Dia 1)                    |
| 08  | DESPUES Dia 2         | 7 partidos, 18 goles, 8 penales, logs                   |
| 09  | DESPUES Full Dia 2    | Confirmacion backup con tiempo                          |
| 10  | DESPUES Diff Dia 2    | Confirmacion backup con tiempo                          |
| 11  | ANTES Dia 3           | Nombres de seleccion en minusculas/mixto                |
| 12  | DESPUES Dia 3         | Nombres en mayusculas, 0 filas con minusculas, logs     |
| 13  | DESPUES Validacion    | Semaforo con todas las filas en OK                      |
| 14  | DESPUES Full Dia 3    | Confirmacion backup con tiempo                          |
| 15  | DESPUES Diff Dia 3    | Confirmacion backup con tiempo                          |
| 16  | Listado backups       | 6 archivos .bak con tamanios                            |
| 17  | ANTES Fase 3          | Confirmacion BD eliminada                               |
| 18  | DESPUES Full Dia 1    | 4 partidos, 10 goles, 0 penales en mundiales_restaurado |
| 19  | ANTES Full Dia 2      |                                                         |
| 20  | Eliminación de la DB  |                                                         |
| 21  | Restauración de la DB |                                                         |
| 22  | DESPUES Full Dia 2    | 7 partidos, 8 penales en mundiales_restaurado           |
| 23  | ANTES Full Dia 3      |                                                         |
| 24  | Eliminación de la DB  |                                                         |
| 25  | Restauración de la DB |                                                         |
| 26  | DESPUES Full Dia 3    | 7 partidos, nombres en mayusculas                       |
| 27  | Eliminación de la DB  |                                                         |
| 28  | Restauración de la DB |                                                         |
| 29  | DESPUES F+D Dia 1     | 4 partidos, 0 penales                                   |
| 30  | ANTES F+D Dia 2       |                                                         |
| 31  | Eliminación de la DB  |                                                         |
| 32  | Restauración de la DB |                                                         |
| 33  | DESPUES F+D Dia 2     | 7 partidos, 8 penales                                   |
| 34  | ANTES F+D Dia 3       |                                                         |
| 35  | Eliminación de la DB  |                                                         |
| 36  | Restauración de la DB |                                                         |
| 37  | DESPUES F+D Dia 3     | 7 partidos, nombres en mayusculas                       |
