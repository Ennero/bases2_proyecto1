## Ubicacion de los backups

Los archivos de backup generados durante la Fase 2 se almacenan en:

- Dentro del contenedor: `/var/opt/mssql/backup/`
- En tu PC: carpeta `backups/` en la raiz del repositorio

Esta carpeta esta mapeada como volumen en `docker-compose.yml`. Los archivos
.bak son accesibles directamente desde tu sistema de archivos sin necesidad
de copiarlos desde el contenedor.

Archivos esperados al finalizar los 3 dias de carga:

| Archivo                 | Contenido                          |
| :---------------------- | :--------------------------------- |
| mundiales_full_dia1.bak | Estado completo al final del Dia 1 |
| mundiales_diff_dia1.bak | Cambios del Dia 1 vs base inicial  |
| mundiales_full_dia2.bak | Estado completo al final del Dia 2 |
| mundiales_diff_dia2.bak | Cambios del Dia 2 vs Full Dia 1    |
| mundiales_full_dia3.bak | Estado completo al final del Dia 3 |
| mundiales_diff_dia3.bak | Cambios del Dia 3 vs Full Dia 1    |
