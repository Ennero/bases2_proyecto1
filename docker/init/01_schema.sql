:setvar DB_NAME "mundiales"

IF DB_ID(N'$(DB_NAME)') IS NULL
BEGIN
    EXEC (N'CREATE DATABASE [' + REPLACE('$(DB_NAME)', ']', ']]') + N']');
END
GO

USE [$(DB_NAME)];
GO

:r /db_scripts/sqlserver_schema.sql
