CLEAR SCREEN

-- STORED PROCEDURES: 1

-- Mundial 2022 completo
EXEC dbo.sp_mundial_por_anio @anio = 2022;

EXEC dbo.sp_mundial_por_anio @anio = 2022, @seccion=3;

-- Solo el grupo A del Mundial 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @grupo = 'A';

-- Partidos de Argentina en el Mundial 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @pais = 'Argentina';

-- Partidos del 20 de noviembre de 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @fecha = '20-Nov-2022';

-- Partidos de Espana en el grupo A del Mundial 2022
EXEC dbo.sp_mundial_por_anio @anio = 2022, @grupo = 'A', @pais = 'Paises Bajos';

-- Combinar fecha y pais
EXEC dbo.sp_mundial_por_anio @anio = 2022, @fecha = '20-Nov-2022', @pais = 'Catar';

-- Mundial 1990
EXEC dbo.sp_mundial_por_anio @anio = 1990;





CLEAR SCREEM
-- STORED PROCEDURES: 2
-- Historial completo de Argentina
EXEC dbo.sp_historial_pais @pais = 'Argentina';	
EXEC dbo.sp_historial_pais @pais = 'Argentina', @seccion=9;

-- Historial de Argentina solo en el Mundial 2022
EXEC dbo.sp_historial_pais @pais = 'Argentina', @anio = 2022;

-- Historial de Espana (sin tilde)
EXEC dbo.sp_historial_pais @pais = 'Espana';
	
-- Historial de Mexico (sin tilde)
EXEC dbo.sp_historial_pais @pais = 'Mexico';

-- Historial de Brasil
EXEC dbo.sp_historial_pais @pais = 'Brasil';

-- Alemania en el Mundial 1974
EXEC dbo.sp_historial_pais @pais = 'Alemania', @anio = 1974;

-- Otros paises con normalizacion de caracteres
EXEC dbo.sp_historial_pais @pais = 'Belgica';
EXEC dbo.sp_historial_pais @pais = 'Japon';
EXEC dbo.sp_historial_pais @pais = 'Iran';
EXEC dbo.sp_historial_pais @pais = 'Tunez';
EXEC dbo.sp_historial_pais @pais = 'Peru';
EXEC dbo.sp_historial_pais @pais = 'Camerun';



SELECT TOP 20 seleccion_id, nombre FROM dbo.seleccion ORDER BY seleccion_id;

