:setvar DB_NAME "mundiales"

IF DB_ID(N'$(DB_NAME)') IS NULL
BEGIN
    DECLARE @create_db_sql NVARCHAR(MAX);
    SET @create_db_sql = N'CREATE DATABASE ' + QUOTENAME(N'$(DB_NAME)');
    EXEC (@create_db_sql);
END
GO

USE [$(DB_NAME)];
GO

:r /db_scripts/sqlserver_schema.sql
:r /db_scripts/performance_audit_logs.sql
:r /db_scripts/stored_procedures.sql