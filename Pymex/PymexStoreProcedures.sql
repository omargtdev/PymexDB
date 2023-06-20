USE Pymex;
GO

CREATE OR ALTER PROCEDURE [inventarios].[usp_RegistrarEntrada]
@fechaRegistro DATE,
@usuarioRegistro NVARCHAR(30),
@proveedorId INT,
@productos XML -- ProductoID, PrecioCompraUnidad, PrecioVentaUnidad, Cantidad
AS
BEGIN
	IF OBJECT_ID('tempdb..#tmpProductos') IS NOT NULL DROP TABLE #tmpProductos
	CREATE TABLE #tmpProductos (
		ProductoID INT,
		PrecioCompraUnidad MONEY,
		PrecioVentaUnidad MONEY,
		Cantidad INT
	);

	INSERT INTO #tmpProductos
	SELECT -- Buscando cada campo de cada nodo Producto y obteniendo su valor
		PRD.RootNode.query('./ProductoID').value('.', 'INT') AS ProductoID,
		PRD.RootNode.query('./PrecioCompraUnidad').value('.', 'MONEY') AS PrecioCompraUnidad,
		PRD.RootNode.query('./PrecioVentaUnidad').value('.', 'MONEY') AS PrecioVentaUnidad,
		PRD.RootNode.query('./Cantidad').value('.', 'INT') AS Cantidad
	FROM @productos.nodes('/Productos/Producto') AS PRD(RootNode); -- Conviertiendo los nodos "Producto" en una tabla

	-- Comenzando la operacion
	BEGIN TRAN InserccionEntrada
		BEGIN TRY
			DECLARE @ultimoCodigo INT,
					@entradaIdentity INT; 
			SET @ultimoCodigo = ISNULL((SELECT MAX(RIGHT(Codigo, 7)) FROM [inventarios].[Entrada]) + 1, 1);

			-- Insertando Cabecera
			INSERT INTO [inventarios].[Entrada] (Codigo, FechaRegistro, ProveedorID, UsuarioRegistro)
			VALUES ((SELECT [inventarios].[fn_GenerarCodigo]('E', @ultimoCodigo)), @fechaRegistro, @proveedorId, @usuarioRegistro);

			SET @entradaIdentity = SCOPE_IDENTITY();

			-- Insertando detalle de los productos (XML)
			INSERT INTO [inventarios].[EntradaProducto] (EntradaID, ProductoID, PrecioCompraUnidad, PrecioVentaUnidad, Cantidad)
			SELECT @entradaIdentity, ProductoID, PrecioCompraUnidad, PrecioVentaUnidad, Cantidad FROM #tmpProductos;

			-- Actualizando los datos de los productos
			UPDATE PRD
				SET PRD.UltimoPrecioCompra = TEMP.PrecioCompraUnidad,
					PRD.UltimoPrecioVenta = TEMP.PrecioVentaUnidad,
					PRD.Stock += TEMP.Cantidad
			FROM [productos].[Producto] PRD
			JOIN #tmpProductos TEMP ON TEMP.ProductoID = PRD.ProductoID;
			 		
 			COMMIT TRAN InserccionEntrada;
		END TRY
		BEGIN CATCH
			-- Cancelando la transaccion y lanzando el error
			ROLLBACK TRAN InserccionEntrada;
			THROW;
		END CATCH
END
GO

--[inventarios].[usp_RegistrarEntrada] '2022-12-21', 'omar', 2, '<Productos><Producto><ProductoID>1</ProductoID><PrecioCompraUnidad>30</PrecioCompraUnidad></Producto><Producto><ProductoID>2</ProductoID><PrecioCompraUnidad>30</PrecioCompraUnidad></Producto><Producto><ProductoID>3</ProductoID><PrecioCompraUnidad>25</PrecioCompraUnidad></Producto></Productos>'

CREATE OR ALTER PROCEDURE [inventarios].[usp_RegistrarSalida]
@fechaRegistro DATE,
@usuarioRegistro NVARCHAR(30),
@clienteId INT,
@productos XML -- ProductoID, PrecioCompraUnidad, PrecioVentaUnidad, Cantidad
AS
BEGIN
	IF OBJECT_ID('tempdb..#tmpProductos') IS NOT NULL DROP TABLE #tmpProductos
	CREATE TABLE #tmpProductos (
		ProductoID INT,
		PrecioVentaUnidad MONEY,
		Cantidad INT
	);

	INSERT INTO #tmpProductos
	SELECT -- Buscando cada campo de cada nodo Producto y obteniendo su valor
		PRD.RootNode.query('./ProductoID').value('.', 'INT') AS ProductoID,
		PRD.RootNode.query('./PrecioVentaUnidad').value('.', 'MONEY') AS PrecioVentaUnidad,
		PRD.RootNode.query('./Cantidad').value('.', 'INT') AS Cantidad
	FROM @productos.nodes('/Productos/Producto') AS PRD(RootNode); -- Conviertiendo los nodos "Producto" en una tabla

	-- Comenzando la operacion
	BEGIN TRAN InserccionSalida
		BEGIN TRY
			DECLARE @ultimoCodigo INT,
					@entradaIdentity INT; 
			SET @ultimoCodigo = ISNULL((SELECT MAX(RIGHT(Codigo, 7)) FROM [inventarios].[Salida]) + 1, 1);

			-- Insertando Cabecera
			INSERT INTO [inventarios].[Salida] (Codigo, FechaRegistro, ClienteID, UsuarioRegistro)
			VALUES ((SELECT [inventarios].[fn_GenerarCodigo]('S', @ultimoCodigo)), @fechaRegistro, @clienteId, @usuarioRegistro);

			SET @entradaIdentity = SCOPE_IDENTITY();

			-- Insertando detalle de los productos (XML)
			INSERT INTO [inventarios].[SalidaProducto] (SalidaID, ProductoID, PrecioVentaUnidad, Cantidad)
			SELECT @entradaIdentity, ProductoID, PrecioVentaUnidad, Cantidad FROM #tmpProductos;

			-- Bajando el stock
			UPDATE PRD
				SET PRD.Stock -= TEMP.Cantidad
			FROM [productos].[Producto] PRD
			JOIN #tmpProductos TEMP ON TEMP.ProductoID = PRD.ProductoID;

 			COMMIT TRAN InserccionSalida;
		END TRY
		BEGIN CATCH
			-- Cancelando la transaccion y lanzando el error
			ROLLBACK TRAN InserccionSalida;
			THROW;
		END CATCH
END
GO

----------

CREATE OR ALTER PROCEDURE [inventarios].[usp_ObtenerResumen]
@fechaInicio DATE,
@fechaFin DATE
AS
BEGIN
	SELECT 
		P.Codigo, P.Descripcion, C.Descripcion [Categoria], A.Descripcion [Almacen],
		SUM(EP.Cantidad) [Entradas], 0 [Salidas], 0 [TotalIngresos], SUM(EP.PrecioCompraUnidad * EP.Cantidad) [TotalEgresos] 
	FROM [inventarios].[EntradaProducto] EP
	JOIN [inventarios].[Entrada] E ON (E.EntradaID = EP.EntradaID)
	JOIN [productos].[Producto] P ON (P.ProductoID = EP.ProductoID)
	JOIN [productos].[Categoria] C ON (C.CategoriaID = P.CategoriaID)
	JOIN [productos].[Almacen] A ON (A.AlmacenID = P.AlmacenID)
	LEFT JOIN [inventarios].[SalidaProducto] SP ON (SP.ProductoID = P.ProductoID)
	LEFT JOIN [inventarios].[Salida] S ON (S.SalidaID = SP.SalidaID)
	WHERE 
		CAST(E.FechaHoraRegistro AS DATE) BETWEEN @fechaInicio AND @fechaFin AND
		CAST(S.FechaHoraRegistro AS DATE) BETWEEN @fechaInicio AND @fechaFin
	GROUP BY P.Codigo, P.Descripcion, C.Descripcion, A.Descripcion
END
GO

----------

CREATE OR ALTER PROCEDURE [inventarios].[usp_ListarEntradas]
AS
BEGIN
	SELECT
		E.EntradaID,
		E.Codigo,
		E.FechaRegistro,
		E.ProveedorID,
		P.TipoDocumento,
		P.NumeroDocumento,
		P.NombreCompleto,
		P.FechaRegistro [ProveedorFechaRegistro],
		P.UsuarioRegistro [ProveedorUsuarioRegistro],
		P.FechaModificacion [ProveedorFechaModificacion],
		P.UltimoUsuarioModifico [ProveedorUltimoUsuarioModifico],
		E.FechaHoraRegistro [EntradaFechaRegistro],
		E.UsuarioRegistro [EntradaUsuarioRegistro]
	FROM [inventarios].[Entrada] E
	JOIN [personas].[Proveedor] P ON (P.ProveedorID = E.ProveedorID)
	UNION
	SELECT
		E.EntradaID,
		E.Codigo,
		E.FechaRegistro,
		E.ProveedorID,
		P.TipoDocumento,
		P.NumeroDocumento,
		P.NombreCompleto,
		P.FechaRegistro [ProveedorFechaRegistro],
		P.UsuarioRegistro [ProveedorUsuarioRegistro],
		P.FechaModificacion [ProveedorFechaModificacion],
		P.UltimoUsuarioModifico [ProveedorUltimoUsuarioModifico],
		E.FechaHoraRegistro [EntradaFechaRegistro],
		E.UsuarioRegistro [EntradaUsuarioRegistro]
	FROM [inventarios].[Entrada] E
	JOIN [personas].[LogProveedor] P ON (P.ProveedorID = E.ProveedorID)
	WHERE P.Accion = 'DELETE'
	ORDER BY EntradaID
END
GO


CREATE OR ALTER PROCEDURE [inventarios].[usp_ListarSalidas]
AS
BEGIN
	SELECT
		S.SalidaID,
		S.Codigo,
		S.FechaRegistro,
		S.ClienteID,
		C.TipoDocumento,
		C.NumeroDocumento,
		C.NombreCompleto,
		C.FechaRegistro [ClienteFechaRegistro],
		C.UsuarioRegistro [ClienteUsuarioRegistro],
		C.FechaModificacion [ClienteFechaModificacion],
		C.UltimoUsuarioModifico [ClienteUltimoUsuarioModifico],
		S.FechaHoraRegistro [SalidaFechaRegistro],
		S.UsuarioRegistro [SalidaUsuarioRegistro]
	FROM [inventarios].[Salida] S
	JOIN [personas].[Cliente] C ON (S.ClienteID = C.ClienteID)
	UNION
	SELECT
		S.SalidaID,
		S.Codigo,
		S.FechaRegistro,
		S.ClienteID,
		C.TipoDocumento,
		C.NumeroDocumento,
		C.NombreCompleto,
		C.FechaRegistro [ClienteFechaRegistro],
		C.UsuarioRegistro [ClienteUsuarioRegistro],
		C.FechaModificacion [ClienteFechaModificacion],
		C.UltimoUsuarioModifico [ClienteUltimoUsuarioModifico],
		S.FechaHoraRegistro [SalidaFechaRegistro],
		S.UsuarioRegistro [SalidaUsuarioRegistro]
	FROM [inventarios].[Salida] S
	JOIN [personas].[LogCliente] C ON (S.ClienteID = C.ClienteID)
	WHERE C.Accion = 'DELETE'
	ORDER BY SalidaID
END
GO

CREATE OR ALTER PROCEDURE [inventarios].[usp_BuscarEntradaPorCodigo]
@codigo CHAR(8)
AS
BEGIN
	DECLARE @entrada TABLE (
		EntradaID INT,
		Codigo CHAR(8),
		FechaRegistro DATE,
		ProveedorID INT,
		TipoDocumento TINYINT,
		NumeroDocumento VARCHAR(20),
		NombreCompleto NVARCHAR(200),
		ProveedorFechaRegistro DATETIME,
		ProveedorUsuarioRegistro NVARCHAR(60),
		ProveedorFechaModificacion DATETIME,
		ProveedorUltimoUsuarioModifico NVARCHAR(60),
		EntradaFechaRegistro DATETIME,
		EntradaUsuarioRegistro NVARCHAR(60)
	);

	-- Buscando la entrada
	INSERT INTO @entrada (EntradaID, Codigo, FechaRegistro, ProveedorID, EntradaFechaRegistro, EntradaUsuarioRegistro)
	SELECT
		E.EntradaID,
		E.Codigo,
		E.FechaRegistro,
		E.ProveedorID,
		E.FechaHoraRegistro,
		E.UsuarioRegistro
	FROM [inventarios].[Entrada] E
	WHERE E.Codigo = @codigo

	-- Si no existe, pues paramos ahi
	IF NOT EXISTS (SELECT EntradaID FROM @entrada)
	BEGIN
		SELECT * FROM @entrada;
		RETURN;
	END

	-- Si el proveedor no fue eliminado obtenemos de la tabla proveedor
	IF EXISTS (SELECT ProveedorID FROM personas.Proveedor WHERE ProveedorID = (SELECT ProveedorID FROM @entrada))
		UPDATE E
		SET E.TipoDocumento = P.TipoDocumento,
			E.NumeroDocumento = P.NumeroDocumento,
			E.NombreCompleto = P.NombreCompleto,
			E.ProveedorFechaRegistro = P.FechaRegistro,
			E.ProveedorUsuarioRegistro = P.UsuarioRegistro,
			E.ProveedorFechaModificacion = P.FechaModificacion,
			E.ProveedorUltimoUsuarioModifico = P.UltimoUsuarioModifico
		FROM @entrada E
		JOIN [personas].[Proveedor] P ON (E.ProveedorID = P.ProveedorID);
	ELSE -- Caso contrario, buscamos en la tabla de log
		UPDATE E
		SET E.TipoDocumento = P.TipoDocumento,
			E.NumeroDocumento = P.NumeroDocumento,
			E.NombreCompleto = P.NombreCompleto,
			E.ProveedorFechaRegistro = P.FechaRegistro,
			E.ProveedorUsuarioRegistro = P.UsuarioRegistro,
			E.ProveedorFechaModificacion = P.FechaModificacion,
			E.ProveedorUltimoUsuarioModifico = P.UltimoUsuarioModifico
		FROM @entrada E
		JOIN [personas].[LogProveedor] P ON (E.ProveedorID = P.ProveedorID);

	SELECT * FROM @entrada;
END
GO

CREATE OR ALTER PROCEDURE [inventarios].[usp_BuscarSalidaPorCodigo]
@codigo CHAR(8)
AS
BEGIN
	DECLARE @salida TABLE (
		SalidaID INT,
		Codigo CHAR(8),
		FechaRegistro DATE,
		ClienteID INT,
		TipoDocumento TINYINT,
		NumeroDocumento VARCHAR(20),
		NombreCompleto NVARCHAR(200),
		ClienteFechaRegistro DATETIME,
		ClienteUsuarioRegistro NVARCHAR(60),
		ClienteFechaModificacion DATETIME,
		ClienteUltimoUsuarioModifico NVARCHAR(60),
		SalidaFechaRegistro DATETIME,
		SalidaUsuarioRegistro NVARCHAR(60)
	);

	-- Buscando la salida
	INSERT INTO @salida (SalidaID, Codigo, FechaRegistro, ClienteID, SalidaFechaRegistro, SalidaUsuarioRegistro)
	SELECT
		S.SalidaID,
		S.Codigo,
		S.FechaRegistro,
		S.ClienteID,
		S.FechaHoraRegistro,
		S.UsuarioRegistro
	FROM [inventarios].[Salida] S
	WHERE S.Codigo = @codigo

	-- Si no existe, pues paramos ahi
	IF NOT EXISTS (SELECT SalidaID FROM @salida)
	BEGIN
		SELECT * FROM @salida;
		RETURN;
	END

	-- Si el cliente no fue eliminado obtenemos de la tabla cliente
	IF EXISTS (SELECT ClienteID FROM personas.Cliente WHERE ClienteID = (SELECT ClienteID FROM @salida))
		UPDATE S
		SET S.TipoDocumento = C.TipoDocumento,
			S.NumeroDocumento = C.NumeroDocumento,
			S.NombreCompleto = C.NombreCompleto,
			S.ClienteFechaRegistro = C.FechaRegistro,
			S.ClienteUsuarioRegistro = C.UsuarioRegistro,
			S.ClienteFechaModificacion = C.FechaModificacion,
			S.ClienteUltimoUsuarioModifico = C.UltimoUsuarioModifico
		FROM @salida S
		JOIN [personas].[Cliente] C ON (S.ClienteID = C.ClienteID);
	ELSE -- Caso contrario, buscamos en la tabla de log
		UPDATE S
		SET S.TipoDocumento = C.TipoDocumento,
			S.NumeroDocumento = C.NumeroDocumento,
			S.NombreCompleto = C.NombreCompleto,
			S.ClienteFechaRegistro = C.FechaRegistro,
			S.ClienteUsuarioRegistro = C.UsuarioRegistro,
			S.ClienteFechaModificacion = C.FechaModificacion,
			S.ClienteUltimoUsuarioModifico = C.UltimoUsuarioModifico
		FROM @salida S
		JOIN [personas].[LogCliente] C ON (S.ClienteID = C.ClienteID);

	SELECT * FROM @salida;
END
GO