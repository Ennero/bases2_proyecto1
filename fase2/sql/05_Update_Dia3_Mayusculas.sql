SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

UPDATE dbo.seleccion
SET nombre = UPPER(nombre)
WHERE nombre <> UPPER(nombre);
GO

EXEC dbo.sp_registrar_logs_diarios @descripcion_carga = N'Update Mayusculas Día 3';
GO
