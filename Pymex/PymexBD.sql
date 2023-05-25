CREATE DATABASE Pymex
GO

USE Pymex;
GO

-- Schema [dbo], para almacenar caracteristicas del sistema como usuarios y roles

CREATE TABLE [dbo].[Permiso] (
	PermisoID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	Nombre VARCHAR(30) NOT NULL
);
GO

CREATE TABLE [dbo].[Perfil] (
	PerfilID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	Nombre VARCHAR(30) NOT NULL
);
GO

CREATE TABLE [dbo].[PerfilPermiso] (
	PermisoID SMALLINT NOT NULL REFERENCES [dbo].[Permiso] (PermisoID),
	PerfilID SMALLINT NOT NULL REFERENCES [dbo].[Perfil] (PerfilID),
	PRIMARY KEY (PermisoID, PerfilID)
);
GO
 
CREATE TABLE [dbo].[Usuario] (
	UsuarioID INT PRIMARY KEY IDENTITY(1, 1),
	UsuarioLogin NVARCHAR(30) NOT NULL UNIQUE,
	Clave VARBINARY(MAX) NOT NULL,
	Nombre NVARCHAR(50) NOT NULL,
	Apellidos NVARCHAR(80) NOT NULL,
	PerfilID SMALLINT NOT NULL REFERENCES [dbo].[Perfil] (PerfilID),
);
GO


-- Schema para guardar configuracion del sistema e informacion del negocio
CREATE SCHEMA [configuraciones]
GO

-- TODO: Crear un trigger before insert:
-- Al momento de insertar verificar si existe un registro, si es asi, actualizar los datos
-- caso contrario, inserta.
CREATE TABLE [configuraciones].[Sistema] (
	SistemaID INT PRIMARY KEY,
	RazonSocial NVARCHAR(100) NOT NULL,
	RUC CHAR(11) NOT NULL,
	Direccion VARCHAR(200) NOT NULL,
	Logo IMAGE
);
GO

-- Schema para organizar a los clientes, proveedores, etc
CREATE SCHEMA [personas];
GO

CREATE TABLE [personas].[TipoDocumento] (
	TipoDocumentoID TINYINT PRIMARY KEY IDENTITY(1, 1),
	Descripcion VARCHAR(30) NOT NULL
);
GO

-- Solo Personas Juridicas (Empresas, organizacion, etc)
CREATE TABLE [personas].[Proveedor] (
	ProveedorID INT PRIMARY KEY IDENTITY(1, 1),
	TipoDocumentoID TINYINT NOT NULL REFERENCES [personas].[TipoDocumento] (TipoDocumentoID), -- (RUC)
	NumeroDocumento VARCHAR(20) NOT NULL UNIQUE,
	NombreCompleto NVARCHAR(100) NOT NULL,

	FechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
	UsuarioRegistro NVARCHAR(30) NOT NULL,
	FechaModificacion DATETIME,
	UltimoUsuarioModifico NVARCHAR(30)
);
GO

-- Persona juridica y natural
CREATE TABLE [personas].[Cliente] (
	ClienteID INT PRIMARY KEY IDENTITY(1, 1),
	TipoDocumentoID TINYINT NOT NULL REFERENCES [personas].[TipoDocumento] (TipoDocumentoID),
	NumeroDocumento VARCHAR(20) NOT NULL UNIQUE,
	NombreCompleto NVARCHAR(100) NOT NULL,

	FechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
	UsuarioRegistro NVARCHAR(30) NOT NULL,
	FechaModificacion DATETIME,
	UltimoUsuarioModifico NVARCHAR(30)
);
GO

-- Schema para administrar los productos
CREATE SCHEMA [productos];
GO

CREATE TABLE [productos].[Categoria] (
	CategoriaID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	Descripcion VARCHAR(30) NOT NULL
);
GO

CREATE TABLE [productos].[Almacen] (
	AlmacenID SMALLINT PRIMARY KEY IDENTITY(1001, 1),
	Descripcion VARCHAR(30) NOT NULL
);
GO

CREATE TABLE [productos].[Producto] (
	ProductoID INT PRIMARY KEY IDENTITY(1, 1),
	Codigo CHAR(8) NOT NULL UNIQUE,
	Descripcion VARCHAR(50) NOT NULL,
	CategoriaID SMALLINT NOT NULL REFERENCES [productos].[Categoria] (CategoriaID),
	AlmacenID SMALLINT NOT NULL REFERENCES [productos].[Almacen] (AlmacenID),
	UltimoPrecioCompra MONEY,
	UltimoPrecioVenta MONEY,
	Stock INT DEFAULT 0,

	FechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
	UsuarioRegistro NVARCHAR(30) NOT NULL,
	FechaModificacion DATETIME,
	UltimoUsuarioModifico NVARCHAR(30)
);
GO

-- Schema core del negocio, para administrar inventarios, entradas, salidas, etc
CREATE SCHEMA [inventarios];
GO

CREATE TABLE [inventarios].[Entrada] (
	EntradaID INT PRIMARY KEY IDENTITY(1, 1),
	Codigo CHAR(8) NOT NULL UNIQUE, -- Auto generado (con una funcion)
	FechaRegistro DATE NOT NULL,
	ProveedorID INT NOT NULL REFERENCES [personas].[Proveedor] (ProveedorID),
	UsuarioRegistro NVARCHAR(30) NOT NULL,
	FechaHoraRegistro DATETIME NOT NULL DEFAULT GETDATE()

	-- CantidadProductos => Calculado
	-- MontoTotal => Calculado
);
GO

CREATE TABLE [inventarios].[EntradaProducto] (
	EntradaProductoID INT IDENTITY(1, 1),
	EntradaID INT NOT NULL REFERENCES [inventarios].[Entrada] (EntradaID),
	ProductoID INT NOT NULL REFERENCES [productos].[Producto] (ProductoID),
	PrecioCompraUnidad MONEY NOT NULL,
	PrecioVentaUnidad MONEY NOT NULL,
	Cantidad INT NOT NULL,
	PRIMARY KEY (EntradaProductoID, EntradaID)
	-- Subtotal => Calculado
);
GO

CREATE TABLE [inventarios].[Salida] (
	SalidaID  INT PRIMARY KEY IDENTITY(1, 1),
	Codigo CHAR(8) NOT NULL UNIQUE, -- Auto generado (con una funcion)
	FechaRegistro DATE NOT NULL,
	ClienteID INT NOT NULL REFERENCES [personas].[Cliente] (ClienteID),
	UsuarioRegistro NVARCHAR(30) NOT NULL,
	FechaHoraRegistro DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE [inventarios].[SalidaProducto] (
	SalidaProductoID INT IDENTITY(1, 1),
	SalidaID INT REFERENCES [inventarios].[Salida] (SalidaID),
	ProductoID INT NOT NULL REFERENCES [productos].[Producto] (ProductoID),
	PrecioVentaUnidad MONEY NOT NULL,
	Cantidad INT NOT NULL,
	PRIMARY KEY (SalidaProductoID, SalidaID)
);
GO

--=========================================================================================
-- TABLAS DE LOG

CREATE TABLE [productos].[LogProducto] (
	LogID BIGINT PRIMARY KEY IDENTITY(1, 1),
	ProductoID INT,
	Codigo CHAR(8),
	Descripcion VARCHAR(50),
	CategoriaID INT,
	CategoriaDescripcion VARCHAR(30),
	AlmacenID INT,
	AlmacenDescripcion VARCHAR(30),
	UltimoPrecioCompra MONEY,
	UltimoPrecioVenta MONEY,
	Stock INT,
	FechaRegistro DATETIME,
	UsuarioRegistro NVARCHAR(30),
	FechaModificacion DATETIME,
	UltimoUsuarioModifico NVARCHAR(30),

	Accion VARCHAR(10),
	UpdateReference BIGINT REFERENCES [productos].[LogProducto] (LogID),
	FechaAccion DATETIME
);
GO

CREATE TABLE [personas].[LogProveedor] (
	LogID BIGINT PRIMARY KEY IDENTITY(1, 1),
	ProveedorID INT,
	TipoDocumentoID TINYINT,
	TipoDocumentoDescripcion VARCHAR(30),
	NumeroDocumento VARCHAR(20),
	NombreCompleto VARCHAR(100),
	FechaRegistro DATETIME,
	UsuarioRegistro NVARCHAR(30),
	FechaModificacion DATETIME,
	UltimoUsuarioModifico NVARCHAR(30),

	Accion VARCHAR(10),
	UpdateReference BIGINT REFERENCES [personas].[LogProveedor] (LogID),
	FechaAccion DATETIME
);
GO

CREATE TABLE [personas].[LogCliente] (
	LogID BIGINT PRIMARY KEY IDENTITY(1, 1),
	ClienteID INT,
	TipoDocumentoID TINYINT,
	TipoDocumentoDescripcion VARCHAR(30),
	NumeroDocumento VARCHAR(20),
	NombreCompleto VARCHAR(100),
	FechaRegistro DATETIME,
	UsuarioRegistro NVARCHAR(30),
	FechaModificacion DATETIME,
	UltimoUsuarioModifico NVARCHAR(30),

	Accion VARCHAR(10),
	UpdateReference BIGINT REFERENCES [personas].[LogCliente] (LogID),
	FechaAccion DATETIME
);
GO
