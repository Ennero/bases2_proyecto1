# Plan de Trabajo — Persona 2 (Administrador de Respaldos y Restauracion)

## Entorno de trabajo

- Motor: SQL Server 2022 sobre Docker (Linux)
- Contenedor: mundiales_db
- Base de datos principal: mundiales
- Base de datos de restauracion: mundiales_restaurado
- Carpeta de backups dentro del contenedor: /var/opt/mssql/backup/

---

## Conceptos rapidos de referencia

**Full Backup:** Copia completa de toda la base de datos en ese momento.
Para restaurar solo necesitamos este archivo.

**Differential Backup:** Copia solo lo que cambio desde el ultimo Full Backup.
Para restaurar necesitas primero el Full Backup y luego aplicar el Differential encima.

**Captura de validacion:** Pantallazo que muestra SELECT _ y SELECT COUNT(_) de las
tablas afectadas, con la fecha y hora del sistema operativo visible en la barra de tareas.

**Tiempo de restauracion:** Segundos que tarda en ejecutarse el comando RESTORE.
Se mide con cronometro desde que se ejecuta hasta que SQL Server confirma que termino.

---

## Preparacion previa (hacer una sola vez antes del Dia 1)

### Paso 1 — Levantar la base de datos

```powershell
docker compose up -d --build
docker logs -f mundiales_db
```

Esperar hasta ver en los logs:

```
>>> Inicializacion completada.
```

### Paso 2 — Verificar que los datos historicos cargaron correctamente

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -Q "SELECT COUNT(*) AS partidos FROM dbo.partido; SELECT COUNT(*) AS jugadores FROM dbo.jugador;"
```

Resultado esperado: 964 partidos, 8444 jugadores aproximadamente.

### Paso 3 — Crear la carpeta de backups dentro del contenedor

```powershell
docker exec -it mundiales_db bash -c "mkdir -p /var/opt/mssql/backup"
```

### Paso 4 — Ejecutar el script de catalogos 2030

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/02_Carga_Catalogos_2030.sql
```

Debe terminar sin errores. Si lanza THROW 50001 o 50002 significa que faltan
selecciones o jugadores base — revisar que el ETL historico cargó correctamente.

**Tomar captura de pantalla** mostrando que el comando termino sin errores,
con la fecha y hora del sistema operativo visible.

---

## Dia 1 — Simulacion de fase de grupos

### Que ocurre en este dia

Se insertan 4 partidos de fase de grupos del Mundial 2030, con sus apariciones,
goles, tarjetas y cambios. Al final se registran los logs de fragmentacion
e indices en todas las tablas de auditoria.

### Paso 1 — Ejecutar el script del Dia 1

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/sql/03_Simulacion_Dia1_Grupos.sql
```

### Paso 2 — Tomar capturas de validacion

Ejecutar en DBeaver o sqlcmd y capturar pantalla con fecha/hora visible:

```sql
-- Conteos generales
SELECT COUNT(*) AS partidos_2030    FROM dbo.partido          WHERE anio = 2030;
SELECT COUNT(*) AS goles_2030       FROM dbo.gol g
                                    INNER JOIN dbo.partido p ON p.partido_id = g.partido_id
                                    WHERE p.anio = 2030;
SELECT COUNT(*) AS tarjetas_2030    FROM dbo.tarjeta t
                                    INNER JOIN dbo.partido p ON p.partido_id = t.partido_id
                                    WHERE p.anio = 2030;
SELECT COUNT(*) AS cambios_2030     FROM dbo.cambio c
                                    INNER JOIN dbo.partido p ON p.partido_id = c.partido_id
                                    WHERE p.anio = 2030;

-- Detalle de partidos insertados
SELECT * FROM dbo.partido WHERE anio = 2030 ORDER BY partido_id;

-- Verificar logs del dia 1
SELECT TOP 5 * FROM dbo.log_partido   ORDER BY log_id DESC;
SELECT TOP 5 * FROM dbo.log_seleccion ORDER BY log_id DESC;
```

### Paso 3 — Full Backup del Dia 1

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH FORMAT, INIT, NAME = 'Full Backup Dia 1', STATS = 10"
```

**Iniciar cronometro** antes de ejecutar este comando.
**Detener cronometro** cuando aparezca en la salida:

```
BACKUP DATABASE successfully processed X pages in X.XXX seconds
```

Anotar el tiempo. Tomar captura de pantalla del resultado con fecha/hora visible.

### Paso 4 — Differential Backup del Dia 1

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_diff_dia1.bak' WITH DIFFERENTIAL, FORMAT, INIT, NAME = 'Differential Backup Dia 1', STATS = 10"
```

**Iniciar cronometro** antes de ejecutar.
**Detener cronometro** al confirmar exito.
Anotar el tiempo. Tomar captura de pantalla con fecha/hora visible.

### Paso 5 — Verificar que los archivos de backup existen

```powershell
docker exec -it mundiales_db bash -c "ls -lh /var/opt/mssql/backup/"
```

Tomar captura mostrando los archivos .bak con sus tamanios.

---

## Dia 2 — Simulacion de semifinales y final

### Que ocurre en este dia

Se insertan 2 semifinales y 1 final del Mundial 2030. La final incluye
definicion por penales. Se registran logs de auditoria.

### Paso 1 — Ejecutar el script del Dia 2

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/sql/04_Simulacion_Dia2_Finales.sql
```

### Paso 2 — Tomar capturas de validacion

```sql
-- Conteo acumulado de partidos (debe ser 7 ahora)
SELECT COUNT(*) AS partidos_2030 FROM dbo.partido WHERE anio = 2030;

-- Detalle de todos los partidos incluyendo finales
SELECT * FROM dbo.partido WHERE anio = 2030 ORDER BY partido_id;

-- Penales de la final
SELECT * FROM dbo.penal pe
INNER JOIN dbo.partido p ON p.partido_id = pe.partido_id
WHERE p.anio = 2030;

-- Logs del dia 2
SELECT TOP 5 * FROM dbo.log_partido ORDER BY log_id DESC;
```

### Paso 3 — Full Backup del Dia 2

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_full_dia2.bak' WITH FORMAT, INIT, NAME = 'Full Backup Dia 2', STATS = 10"
```

Cronometrar y anotar tiempo. Tomar captura con fecha/hora visible.

### Paso 4 — Differential Backup del Dia 2

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_diff_dia2.bak' WITH DIFFERENTIAL, FORMAT, INIT, NAME = 'Differential Backup Dia 2', STATS = 10"
```

Cronometrar y anotar tiempo. Tomar captura con fecha/hora visible.

---

## Dia 3 — Update masivo a mayusculas

### Que ocurre en este dia

Se ejecuta un UPDATE sobre toda la tabla seleccion convirtiendo los nombres
a mayusculas. Esto simula una operacion masiva de modificacion de datos.
Se registran logs de auditoria.

### Paso 1 — Ejecutar el script del Dia 3

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/sql/05_Update_Dia3_Mayusculas.sql
```

### Paso 2 — Tomar capturas de validacion

```sql
-- Verificar que los nombres quedaron en mayusculas
SELECT TOP 20 seleccion_id, nombre FROM dbo.seleccion ORDER BY seleccion_id;

-- Confirmar que ningun nombre tiene minusculas
SELECT COUNT(*) AS nombres_sin_mayusculas
FROM dbo.seleccion
WHERE nombre <> UPPER(nombre);

-- Logs del dia 3
SELECT TOP 5 * FROM dbo.log_seleccion ORDER BY log_id DESC;
```

### Paso 3 — Full Backup del Dia 3

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_full_dia3.bak' WITH FORMAT, INIT, NAME = 'Full Backup Dia 3', STATS = 10"
```

Cronometrar y anotar tiempo. Tomar captura con fecha/hora visible.

### Paso 4 — Differential Backup del Dia 3

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "BACKUP DATABASE [mundiales] TO DISK = '/var/opt/mssql/backup/mundiales_diff_dia3.bak' WITH DIFFERENTIAL, FORMAT, INIT, NAME = 'Differential Backup Dia 3', STATS = 10"
```

Cronometrar y anotar tiempo. Tomar captura con fecha/hora visible.

### Paso 5 — Ejecutar validacion final de Fase 2

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/sql/06_Validacion_Fase2.sql
```

Todas las filas del semaforo deben mostrar OK. Tomar captura con fecha/hora visible.

### Paso 6 — Verificar los 6 archivos de backup generados

```powershell
docker exec -it mundiales_db bash -c "ls -lh /var/opt/mssql/backup/"
```

Deben existir exactamente 6 archivos:

- mundiales_full_dia1.bak
- mundiales_diff_dia1.bak
- mundiales_full_dia2.bak
- mundiales_diff_dia2.bak
- mundiales_full_dia3.bak
- mundiales_diff_dia3.bak

Tomar captura mostrando los 6 archivos con sus tamanios.

---

## Fase 3 — Restauracion de Full Backups

### Que se hace en esta fase

Se elimina la base de datos mundiales y se restaura desde cada Full Backup
en orden secuencial, en una nueva base llamada mundiales_restaurado.
Se mide el tiempo de cada restauracion.

### Paso 1 — Eliminar la base de datos original

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "ALTER DATABASE [mundiales] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [mundiales];"
```

Tomar captura confirmando que la BD fue eliminada.

### Paso 2 — Restaurar Full Backup Dia 1

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', REPLACE, STATS = 10"
```

Cronometrar desde que se ejecuta hasta que aparece:

```
RESTORE DATABASE successfully processed X pages in X.XXX seconds
```

Anotar tiempo. Tomar captura con fecha/hora visible.

Validar integridad:

```sql
USE mundiales_restaurado;
SELECT COUNT(*) AS partidos FROM dbo.partido;
SELECT COUNT(*) AS partidos_2030 FROM dbo.partido WHERE anio = 2030;
-- Dia 1: debe haber 4 partidos 2030
```

### Paso 3 — Eliminar y restaurar Full Backup Dia 2

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia2.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', REPLACE, STATS = 10"
```

Cronometrar y anotar tiempo. Tomar captura.

Validar:

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido WHERE anio = 2030;
-- Debe haber 7 partidos 2030
```

### Paso 4 — Eliminar y restaurar Full Backup Dia 3

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia3.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', REPLACE, STATS = 10"
```

Cronometrar y anotar tiempo. Tomar captura.

Validar:

```sql
-- Nombres deben estar en mayusculas
SELECT TOP 10 nombre FROM mundiales_restaurado.dbo.seleccion ORDER BY seleccion_id;
```

---

## Fase 4 — Restauracion de Differential Backups

### Que se hace en esta fase

El Differential Backup no es independiente — necesita el Full Backup como base.
El proceso es: restaurar el Full en modo NORECOVERY, luego aplicar el Differential.

### Paso 1 — Eliminar la base restaurada

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

### Paso 2 — Restaurar Full Dia 1 + Differential Dia 1

Primero el Full en modo NORECOVERY (queda en estado de espera):

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', NORECOVERY, REPLACE, STATS = 10"
```

Luego aplicar el Differential (cronometrar este paso):

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_diff_dia1.bak' WITH RECOVERY, STATS = 10"
```

Cronometrar el tiempo total (Full NORECOVERY + Differential RECOVERY).
Tomar captura con fecha/hora visible.

Validar:

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido WHERE anio = 2030;
-- Debe haber 4 partidos
```

### Paso 3 — Eliminar y restaurar Full Dia 1 + Differential Dia 2

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

Full en NORECOVERY:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', NORECOVERY, REPLACE, STATS = 10"
```

Differential Dia 2:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_diff_dia2.bak' WITH RECOVERY, STATS = 10"
```

Cronometrar tiempo total. Tomar captura.

Validar:

```sql
SELECT COUNT(*) AS partidos_2030 FROM mundiales_restaurado.dbo.partido WHERE anio = 2030;
-- Debe haber 7 partidos
```

### Paso 4 — Eliminar y restaurar Full Dia 1 + Differential Dia 3

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "DROP DATABASE [mundiales_restaurado];"
```

Full en NORECOVERY:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_full_dia1.bak' WITH MOVE 'mundiales' TO '/var/opt/mssql/data/mundiales_restaurado.mdf', MOVE 'mundiales_log' TO '/var/opt/mssql/data/mundiales_restaurado_log.ldf', NORECOVERY, REPLACE, STATS = 10"
```

Differential Dia 3:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" `
  -Q "RESTORE DATABASE [mundiales_restaurado] FROM DISK = '/var/opt/mssql/backup/mundiales_diff_dia3.bak' WITH RECOVERY, STATS = 10"
```

Cronometrar tiempo total. Tomar captura.

Validar:

```sql
-- Nombres deben estar en mayusculas
SELECT TOP 10 nombre FROM mundiales_restaurado.dbo.seleccion ORDER BY seleccion_id;
```

---

## Tabla de registro de tiempos

Llenar esta tabla con los tiempos medidos durante la ejecucion:

| Operacion                    | Tiempo (segundos) | Tamanio archivo |
| :--------------------------- | :---------------- | :-------------- |
| Full Backup Dia 1            |                   |                 |
| Differential Backup Dia 1    |                   |                 |
| Full Backup Dia 2            |                   |                 |
| Differential Backup Dia 2    |                   |                 |
| Full Backup Dia 3            |                   |                 |
| Differential Backup Dia 3    |                   |                 |
| Restauracion Full Dia 1      |                   |                 |
| Restauracion Full Dia 2      |                   |                 |
| Restauracion Full Dia 3      |                   |                 |
| Restauracion Full+Diff Dia 1 |                   |                 |
| Restauracion Full+Diff Dia 2 |                   |                 |
| Restauracion Full+Diff Dia 3 |                   |                 |

---

## Lista de capturas requeridas

Todas deben mostrar la fecha y hora del sistema operativo visible en la barra de tareas.
Sugerencia: en Windows dejar la barra de tareas visible en la parte inferior antes de capturar.

---

### Dia 0 — Preparacion

**Captura 01 — Verificacion de carga historica**

- [ ] Hecha
- Que debe verse: resultado del comando sqlcmd con los conteos de partidos (~964) y jugadores (~8444).
- Comando ejecutado:

```powershell
docker exec -it mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -Q "SELECT COUNT(*) AS partidos FROM dbo.partido; SELECT COUNT(*) AS jugadores FROM dbo.jugador;"
```

**Captura 02 — Carga de catalogos 2030**

- [ ] Hecha
- Que debe verse: terminal mostrando que el script 02_Carga_Catalogos_2030.sql termino sin mensajes de error. Si no hay output de error, SQL Server lo proceso correctamente.
- Comando ejecutado:

```powershell
docker exec -i mundiales_db /opt/mssql-tools18/bin/sqlcmd `
  -C -S localhost -U sa -P "Mundiales2026!" -d mundiales `
  -i /fase2/02_Carga_Catalogos_2030.sql
```

---

### Dia 1 — Fase de grupos

**Captura 03 — Conteos post-carga Dia 1**

- [ ] Hecha
- Que debe verse: resultados de SELECT COUNT(\*) mostrando 4 partidos, 10 goles, 6 tarjetas y 4 cambios para anio 2030.
- Ejecutar en DBeaver:

```sql
SELECT COUNT(*) AS partidos_2030 FROM dbo.partido WHERE anio = 2030;
SELECT COUNT(*) AS goles_2030 FROM dbo.gol g
  INNER JOIN dbo.partido p ON p.partido_id = g.partido_id WHERE p.anio = 2030;
SELECT COUNT(*) AS tarjetas_2030 FROM dbo.tarjeta t
  INNER JOIN dbo.partido p ON p.partido_id = t.partido_id WHERE p.anio = 2030;
SELECT COUNT(*) AS cambios_2030 FROM dbo.cambio c
  INNER JOIN dbo.partido p ON p.partido_id = c.partido_id WHERE p.anio = 2030;
```

**Captura 04 — Detalle de partidos Dia 1**

- [ ] Hecha
- Que debe verse: SELECT \* de dbo.partido filtrando anio 2030, mostrando las 4 filas con partido_id 6001 al 6004, fechas, equipos y marcadores.
- Ejecutar en DBeaver:

```sql
SELECT * FROM dbo.partido WHERE anio = 2030 ORDER BY partido_id;
```

**Captura 05 — Full Backup Dia 1**

- [ ] Hecha
- Que debe verse: terminal mostrando el mensaje de confirmacion de SQL Server con el tiempo que tardo. Ejemplo: "BACKUP DATABASE successfully processed 12345 pages in 4.532 seconds".
- Anotar el tiempo en la tabla de registro.

**Captura 06 — Differential Backup Dia 1**

- [ ] Hecha
- Que debe verse: terminal mostrando confirmacion del Differential Backup con el tiempo que tardo.
- Anotar el tiempo en la tabla de registro.

---

### Dia 2 — Semifinales y final

**Captura 07 — Conteos post-carga Dia 2**

- [ ] Hecha
- Que debe verse: SELECT COUNT(\*) mostrando 7 partidos acumulados para anio 2030 (4 del Dia 1 + 3 del Dia 2).
- Ejecutar en DBeaver:

```sql
SELECT COUNT(*) AS partidos_2030 FROM dbo.partido WHERE anio = 2030;
SELECT * FROM dbo.partido WHERE anio = 2030 ORDER BY partido_id;
```

**Captura 08 — Detalle de penales**

- [ ] Hecha
- Que debe verse: SELECT \* de dbo.penal mostrando los 8 penales de la semifinal y la final del 2030 con sus resultados (Gol, Atajado, Fuera).
- Ejecutar en DBeaver:

```sql
SELECT pe.*, p.etapa, p.fecha
FROM dbo.penal pe
INNER JOIN dbo.partido p ON p.partido_id = pe.partido_id
WHERE p.anio = 2030
ORDER BY pe.partido_id, pe.orden;
```

**Captura 09 — Full Backup Dia 2**

- [ ] Hecha
- Que debe verse: terminal con confirmacion del Full Backup y tiempo de ejecucion.
- Anotar el tiempo en la tabla de registro.

**Captura 10 — Differential Backup Dia 2**

- [ ] Hecha
- Que debe verse: terminal con confirmacion del Differential Backup y tiempo de ejecucion.
- Anotar el tiempo en la tabla de registro.

---

### Dia 3 — Update masivo a mayusculas

**Captura 11 — Verificacion de nombres en mayusculas**

- [ ] Hecha
- Que debe verse: SELECT TOP 20 de dbo.seleccion mostrando que todos los nombres estan en mayusculas. Tambien el COUNT(\*) confirmando que 0 filas tienen minusculas.
- Ejecutar en DBeaver:

```sql
SELECT TOP 20 seleccion_id, nombre FROM dbo.seleccion ORDER BY seleccion_id;
SELECT COUNT(*) AS nombres_sin_mayusculas FROM dbo.seleccion WHERE nombre <> UPPER(nombre);
```

**Captura 12 — Semaforo final de validacion**

- [ ] Hecha
- Que debe verse: resultado del script 06_Validacion_Fase2.sql con todas las filas del semaforo mostrando OK en la columna estado.

**Captura 13 — Full Backup Dia 3**

- [ ] Hecha
- Que debe verse: terminal con confirmacion del Full Backup y tiempo de ejecucion.
- Anotar el tiempo en la tabla de registro.

**Captura 14 — Differential Backup Dia 3**

- [ ] Hecha
- Que debe verse: terminal con confirmacion del Differential Backup y tiempo de ejecucion.
- Anotar el tiempo en la tabla de registro.

**Captura 15 — Listado de los 6 archivos de backup**

- [ ] Hecha
- Que debe verse: resultado de ls -lh mostrando los 6 archivos .bak con sus nombres y tamanios en disco.
- Comando:

```powershell
docker exec -it mundiales_db bash -c "ls -lh /var/opt/mssql/backup/"
```

---

### Fase 3 — Restauracion de Full Backups

**Captura 16 — Restauracion Full Dia 1**

- [ ] Hecha
- Que debe verse: terminal con confirmacion de RESTORE exitoso y tiempo. Luego SELECT COUNT(\*) mostrando 4 partidos 2030 en mundiales_restaurado.
- Valor esperado: 4 partidos para anio 2030.

**Captura 17 — Restauracion Full Dia 2**

- [ ] Hecha
- Que debe verse: terminal con confirmacion de RESTORE exitoso y tiempo. Luego SELECT COUNT(\*) mostrando 7 partidos 2030 en mundiales_restaurado.
- Valor esperado: 7 partidos para anio 2030.

**Captura 18 — Restauracion Full Dia 3**

- [ ] Hecha
- Que debe verse: terminal con confirmacion de RESTORE exitoso y tiempo. Luego SELECT TOP 10 de seleccion mostrando nombres en mayusculas.
- Valor esperado: todos los nombres en mayusculas.

---

### Fase 4 — Restauracion de Differential Backups

**Captura 19 — Restauracion Full+Diff Dia 1**

- [ ] Hecha
- Que debe verse: terminal mostrando los dos pasos (NORECOVERY y luego RECOVERY) con sus confirmaciones. SELECT COUNT(\*) con 4 partidos 2030.
- Valor esperado: 4 partidos para anio 2030.

**Captura 20 — Restauracion Full+Diff Dia 2**

- [ ] Hecha
- Que debe verse: terminal con los dos pasos de restauracion. SELECT COUNT(\*) con 7 partidos 2030.
- Valor esperado: 7 partidos para anio 2030.

**Captura 21 — Restauracion Full+Diff Dia 3**

- [ ] Hecha
- Que debe verse: terminal con los dos pasos de restauracion. SELECT TOP 10 de seleccion con nombres en mayusculas.
- Valor esperado: todos los nombres en mayusculas.
