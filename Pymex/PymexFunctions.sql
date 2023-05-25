USE Pymex;
GO

CREATE OR ALTER FUNCTION [inventarios].[fn_GenerarCodigo] (@letraInicial CHAR(1), @numero INT)
RETURNS CHAR(8)
AS
BEGIN
	RETURN @letraInicial + RIGHT(@numero + 100000000, 7);
END
GO
