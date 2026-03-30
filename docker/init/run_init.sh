#!/bin/bash
set -eu

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
SERVER="localhost"
SA_USER="sa"
DB_NAME="${MSSQL_DATABASE:-mundiales}"
PASSWORD="${MSSQL_SA_PASSWORD:?MSSQL_SA_PASSWORD no definido}"

# Levanta SQL Server en segundo plano.
/opt/mssql/bin/sqlservr &
SQL_PID=$!

cleanup() {
  if ps -p "$SQL_PID" >/dev/null 2>&1; then
    kill "$SQL_PID"
  fi
}
trap cleanup EXIT

# Espera a que SQL Server responda (hasta 180 segundos).
echo ">>> Esperando a SQL Server..."
READY=0
for i in $(seq 1 90); do
  if "$SQLCMD" -C -S "$SERVER" -U "$SA_USER" -P "$PASSWORD" -Q "SELECT 1" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 2
done

if [ "$READY" -eq 0 ]; then
  echo ">>> ERROR: SQL Server no estuvo listo a tiempo"
  exit 1
fi

echo ">>> SQL Server listo."

# Solo inicializa una vez por volumen de datos.
INIT_MARKER="/var/opt/mssql/.init_done"
if [ ! -f "$INIT_MARKER" ]; then
  echo ">>> Primera inicializacion detectada. Ejecutando schema + ETL..."

  CSV_WORKDIR="/var/opt/mssql/csv_work"
  rm -rf "$CSV_WORKDIR"
  mkdir -p "$CSV_WORKDIR"
  cp -a /csv/. "$CSV_WORKDIR"/

  CSV_DIR="$CSV_WORKDIR" /bin/bash /docker/init/02_fix_csvs.sh

  if ! "$SQLCMD" -b -C -S "$SERVER" -U "$SA_USER" -P "$PASSWORD" \
    -i /docker/init/01_schema.sql -v DB_NAME="$DB_NAME"; then
    echo ">>> ERROR: fallo al crear el schema, se mantiene SQL Server en ejecucion."
  elif ! "$SQLCMD" -b -C -S "$SERVER" -U "$SA_USER" -P "$PASSWORD" \
    -d "$DB_NAME" -i /docker/init/03_etl.sql -v CSV_DIR="$CSV_WORKDIR"; then
    echo ">>> ERROR: fallo el ETL, se mantiene SQL Server en ejecucion."
  else
    touch "$INIT_MARKER"
    echo ">>> Inicializacion completada."
  fi
else
  echo ">>> Base ya inicializada; se omiten scripts de init."
fi

wait "$SQL_PID"
