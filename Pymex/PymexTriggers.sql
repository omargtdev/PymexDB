USE Pymex;
GO

CREATE OR ALTER TRIGGER [configuraciones].[trg_datosSistema]
ON [configuraciones].[Sistema]
INSTEAD OF INSERT
AS
BEGIN
	/* Este trigger es para manejar que esta tabla, solo tenga un registro, 
	   cada vez que se quiera insertar, se actualizar???. (UPSERT) */

	IF NOT EXISTS (SELECT TOP(1) SistemaID FROM [configuraciones].[Sistema])
	BEGIN
		INSERT INTO [configuraciones].[Sistema] (SistemaID, RazonSocial, RUC, Direccion, Logo)
		SELECT 1, RazonSocial, RUC, Direccion, Logo FROM inserted; -- ID 1 porque solo es un sistema
		RETURN;
	END
	ELSE
	
	DECLARE @razonSocial NVARCHAR(200),
			@ruc CHAR(11),
			@direccion VARCHAR(200);

	SELECT @razonSocial = RazonSocial, @ruc = RUC, @direccion = Direccion FROM inserted;

	UPDATE [configuraciones].[Sistema]
	SET RazonSocial = @razonSocial,
		RUC = @ruc,
		Direccion = @direccion,
		Logo = (SELECT Logo FROM inserted);
END
GO


---- CLIENTE

CREATE OR ALTER TRIGGER [personas].[trg_logClienteInsert]
ON [personas].[Cliente]
AFTER INSERT
AS
BEGIN
	INSERT INTO [personas].[LogCliente]
		(ClienteID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
		 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
		 Accion, FechaAccion)
	SELECT 
		C.ClienteID, C.TipoDocumentoID, TD.Descripcion, C.NumeroDocumento, C.NombreCompleto, C.FechaRegistro,
		C.UsuarioRegistro, C.FechaModificacion, C.UltimoUsuarioModifico, 
		'INSERT', GETDATE()
	FROM inserted C
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = C.TipoDocumentoID);
END
GO

CREATE OR ALTER TRIGGER [personas].[trg_logClienteUpdate]
ON [personas].[Cliente]
AFTER UPDATE
AS
BEGIN
	-- Antes del update
	INSERT INTO [personas].[LogCliente]
		(ClienteID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
		 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
		 Accion, FechaAccion)
	SELECT 
		C.ClienteID, C.TipoDocumentoID, TD.Descripcion, C.NumeroDocumento, C.NombreCompleto, C.FechaRegistro,
		C.UsuarioRegistro, C.FechaModificacion, C.UltimoUsuarioModifico, 
		'BEFORE UPD', GETDATE()
	FROM deleted C
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = C.TipoDocumentoID);

		-- Con el update
	INSERT INTO [personas].[LogCliente]
		(ClienteID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
		 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
		 Accion, UpdateReference, FechaAccion)
	SELECT 
		C.ClienteID, C.TipoDocumentoID, TD.Descripcion, C.NumeroDocumento, C.NombreCompleto, C.FechaRegistro,
		C.UsuarioRegistro, C.FechaModificacion, C.UltimoUsuarioModifico, 
		'AFTER UPD', SCOPE_IDENTITY(), GETDATE()
	FROM inserted C
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = C.TipoDocumentoID);
END
GO

CREATE OR ALTER TRIGGER [personas].[trg_logClienteDelete]
ON [personas].[Cliente]
AFTER DELETE
AS
BEGIN
	INSERT INTO [personas].[LogCliente]
		(ClienteID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
		 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
		 Accion, FechaAccion)
	SELECT 
		C.ClienteID, C.TipoDocumentoID, TD.Descripcion, C.NumeroDocumento, C.NombreCompleto, C.FechaRegistro,
		C.UsuarioRegistro, C.FechaModificacion, C.UltimoUsuarioModifico, 
		'DELETE', GETDATE()
	FROM deleted C
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = C.TipoDocumentoID);
END
GO

-- PROVEEDOR

CREATE OR ALTER TRIGGER [personas].[trg_ProveedorInsert]
ON [personas].[Proveedor]
AFTER INSERT
AS
BEGIN
	INSERT INTO [personas].[LogProveedor]
			(ProveedorID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
			 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
			 Accion, FechaAccion)
		SELECT 
			P.ProveedorID, P.TipoDocumentoID, TD.Descripcion, P.NumeroDocumento, P.NombreCompleto, P.FechaRegistro,
			P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico, 
			'INSERT', GETDATE()
	FROM inserted P
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = P.TipoDocumentoID);
END
GO


CREATE OR ALTER TRIGGER [personas].[trg_logProveedorUpdate]
ON [personas].[Proveedor]
AFTER UPDATE
AS
BEGIN
	-- Antes del update
	INSERT INTO [personas].[LogProveedor]
		(ProveedorID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
		 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
		 Accion, FechaAccion)
	SELECT 
		P.ProveedorID, P.TipoDocumentoID, TD.Descripcion, P.NumeroDocumento, P.NombreCompleto, P.FechaRegistro,
		P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico, 
		'BEFORE UPD', GETDATE()
	FROM deleted P
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = P.TipoDocumentoID);

		-- Con el update
	INSERT INTO [personas].[LogProveedor]
		(ProveedorID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
		 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
		 Accion, UpdateReference, FechaAccion)
	SELECT 
		P.ProveedorID, P.TipoDocumentoID, TD.Descripcion, P.NumeroDocumento, P.NombreCompleto, P.FechaRegistro,
		P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico, 
		'AFTER UPD', SCOPE_IDENTITY(), GETDATE()
	FROM inserted P
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = P.TipoDocumentoID);
END
GO

CREATE OR ALTER TRIGGER [personas].[trg_logProveedorDelete]
ON [personas].[Proveedor]
AFTER DELETE
AS
BEGIN
	INSERT INTO [personas].[LogProveedor]
		(ProveedorID, TipoDocumentoID, TipoDocumentoDescripcion,  NumeroDocumento, NombreCompleto, FechaRegistro, 
		 UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico, 
		 Accion, FechaAccion)
	SELECT 
		P.ProveedorID, P.TipoDocumentoID, TD.Descripcion, P.NumeroDocumento, P.NombreCompleto, P.FechaRegistro,
		P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico, 
		'DELETE', GETDATE()
	FROM deleted P
	JOIN [personas].[TipoDocumento] TD ON (TD.TipoDocumentoID = P.TipoDocumentoID);
END
GO

---- PRODUCTO

CREATE OR ALTER TRIGGER [productos].[trg_logProductoInsert]
ON [productos].[Producto]
AFTER INSERT
AS
BEGIN
	INSERT INTO [productos].[LogProducto]
			(ProductoID, Codigo, Descripcion,  CategoriaID, CategoriaDescripcion, AlmacenID, AlmacenDescripcion,
			 UltimoPrecioCompra, UltimoPrecioVenta, Stock, FechaRegistro, UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico,
			 Accion, FechaAccion)
		SELECT 
			P.ProductoID, P.Codigo, P.Descripcion, P.CategoriaID, C.Descripcion, P.AlmacenID, A.Descripcion,
			P.UltimoPrecioCompra, P.UltimoPrecioVenta, P.Stock, P.FechaRegistro, P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico,
			'INSERT', GETDATE()
	FROM inserted P
	JOIN [productos].[Almacen] A ON (A.AlmacenID = P.AlmacenID)
	JOIN [productos].[Categoria] C ON (C.CategoriaID = P.CategoriaID);
END
GO

CREATE OR ALTER TRIGGER [productos].[trg_logProductoUpdate]
ON [productos].[Producto]
AFTER UPDATE
AS
BEGIN
	-- Antes del update
	INSERT INTO [productos].[LogProducto]
			(ProductoID, Codigo, Descripcion,  CategoriaID, CategoriaDescripcion, AlmacenID, AlmacenDescripcion,
			 UltimoPrecioCompra, UltimoPrecioVenta, Stock, FechaRegistro, UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico,
			 Accion, FechaAccion)
		SELECT 
			P.ProductoID, P.Codigo, P.Descripcion, P.CategoriaID, C.Descripcion, P.AlmacenID, A.Descripcion,
			P.UltimoPrecioCompra, P.UltimoPrecioVenta, P.Stock, P.FechaRegistro, P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico,
			'BEFORE UPD', GETDATE()
	FROM deleted P
	JOIN [productos].[Almacen] A ON (A.AlmacenID = P.AlmacenID)
	JOIN [productos].[Categoria] C ON (C.CategoriaID = P.CategoriaID);

	-- Con el update
	INSERT INTO [productos].[LogProducto]
			(ProductoID, Codigo, Descripcion,  CategoriaID, CategoriaDescripcion, AlmacenID, AlmacenDescripcion,
			 UltimoPrecioCompra, UltimoPrecioVenta, Stock, FechaRegistro, UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico,
			 Accion, UpdateReference, FechaAccion)
		SELECT 
			P.ProductoID, P.Codigo, P.Descripcion, P.CategoriaID, C.Descripcion, P.AlmacenID, A.Descripcion,
			P.UltimoPrecioCompra, P.UltimoPrecioVenta, P.Stock, P.FechaRegistro, P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico,
			'AFTER UPD', SCOPE_IDENTITY(), GETDATE()
	FROM inserted P
	JOIN [productos].[Almacen] A ON (A.AlmacenID = P.AlmacenID)
	JOIN [productos].[Categoria] C ON (C.CategoriaID = P.CategoriaID);
END
GO

CREATE OR ALTER TRIGGER [productos].[trg_logProductoUpdate]
ON [productos].[Producto]
AFTER DELETE
AS
BEGIN
	INSERT INTO [productos].[LogProducto]
			(ProductoID, Codigo, Descripcion,  CategoriaID, CategoriaDescripcion, AlmacenID, AlmacenDescripcion,
			 UltimoPrecioCompra, UltimoPrecioVenta, Stock, FechaRegistro, UsuarioRegistro, FechaModificacion, UltimoUsuarioModifico,
			 Accion, FechaAccion)
		SELECT 
			P.ProductoID, P.Codigo, P.Descripcion, P.CategoriaID, C.Descripcion, P.AlmacenID, A.Descripcion,
			P.UltimoPrecioCompra, P.UltimoPrecioVenta, P.Stock, P.FechaRegistro, P.UsuarioRegistro, P.FechaModificacion, P.UltimoUsuarioModifico,
			'DELETE', GETDATE()
	FROM deleted P
	JOIN [productos].[Almacen] A ON (A.AlmacenID = P.AlmacenID)
	JOIN [productos].[Categoria] C ON (C.CategoriaID = P.CategoriaID);
END
GO

/*INSERT INTO personas.Cliente (TipoDocumentoID, NumeroDocumento, NombreCompleto, UsuarioRegistro)
VALUES (2, '20203012342', 'Ferreteria Juan S.A.C', 'omargtdev')

SELECT * FROM personas.Cliente
SELECT * FROM personas.LogCliente

UPDATE personas.Cliente SET TipoDocumentoID = 2, NombreCompleto = 'Algun nombre', NumeroDocumento = '20203012347' ,UltimoUsuarioModifico = 'omargtdev', FechaModificacion = GETDATE()
WHERE ClienteID = 2*/
