FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

# Instala Python, dos2unix y sqlcmd
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    python3 \
    dos2unix \
    curl \
    gnupg \
    ca-certificates \
    apt-transport-https \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
    && chmod a+r /etc/apt/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends mssql-tools18 unixodbc-dev \
    && ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copia los scripts de init y convierte CRLF a LF
COPY docker/init/run_init.sh   /docker/init/run_init.sh
COPY docker/init/02_fix_csvs.sh /docker/init/02_fix_csvs.sh
COPY docker/init/01_schema.sql  /docker/init/01_schema.sql
COPY docker/init/03_etl.sql     /docker/init/03_etl.sql

RUN dos2unix /docker/init/run_init.sh /docker/init/02_fix_csvs.sh \
    && chmod +x /docker/init/run_init.sh /docker/init/02_fix_csvs.sh

USER mssql