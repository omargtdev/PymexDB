# Pymex (2023-06-21)

## Tablas

### inventarios
- `modified` EntradaProducto -> Se agregó el constraint de FK (ProductoID) hacia Producto (ProductoID)
- `modified` SalidaProducto -> Se agregó el constraint de FK (ProductoID) hacia Producto (ProductoID)

# Pymex (2023-06-21)

## Tablas

### productos
- `modified` Producto -> Se agregó la columna Activo, para evitar eliminar productos

# Pymex (2023-06-20)

## Tablas

### productos
- `modified` Almacen -> Se eliminó la columna UsuarioResponsable y se agregó la columna Aforo

## Procedures

### inventarios
- `new` usp_ListarSalidas -> Lista las salidas con la información del cliente que lo realizó, incluyendo a clientes eliminados
- `new` usp_ListarEntradas -> Lista las entradas con la información del proveedor que lo realizó, incluyendo a proveedores eliminados
- `new` usp_BuscarEntradaPorCodigo -> Obtiene una entrada con todos sus datos por un código dado
- `new` usp_BuscarSalidaPorCodigo -> Obtiene una salida con todos sus datos por un código dado

# Pymex (2023-06-16)

## Tablas

### dbo
- `modified` Usuario -> Se cambio el tipo de dato de Clave por varchar(256) (Para almacenarlo encriptado con SHA256)

# Pymex (2023-05-27)

## Tablas

### inventarios
- `Entrada` -> Se quito la FK con referencia a Proveedor
- `EntradaProducto` -> Se quito la FK con referencia a Producto
- `Salida` -> Se quito la FK con referencia a Cliente
- `SalidaProducto` -> Se quito la FK con referencia a Producto

# Pymex (2023-05-25)

## Tablas

### personas
- `deleted` TipoDocumento -> Se manejará como un flag el tipo de documento en las tablas de `personas`
- `modified` LogCliente -> Se quito la descripción del tipo de documento
- `modified` LogProveedor -> Se quito la descripción del tipo de documento

### productos
- `modified` LogProducto ->  Se quito la descripción de la categoría y almacen
- `modified` Almacen -> Se agregó mas campos

## Triggers

### personas
- `modified` trg_logClienteInsert -> Se quitó la descripcion de las tablas relacionadas
- `modified` trg_logClienteUpdate-> Se quitó la descripcion de las tablas relacionadas
- `modified` trg_logClienteDelete-> Se quitó la descripcion de las tablas relacionadas
- `modified` trg_logProveedorInsert -> Se quitó la descripcion de las tablas relacionadas
- `modified` trg_logProveedorUpdate-> Se quitó la descripcion de las tablas relacionadas
- `modified` trg_logProveedorDelete-> Se quitó la descripcion de las tablas relacionadas

### productos
- `modified` trg_logProductoInsert -> Se quitó la descripcion de las tablas relacionadas
- `modified` trg_logProductoUpdate-> Se quitó la descripcion de las tablas relacionadas
- `modified` trg_logProductoDelete-> Se quitó la descripcion de las tablas relacionadas

# Pymex (2023-05-24)

## Schemas
- `new` configuraciones -> Relacionado a la empresa y configuraciones del sistema
- `new` dbo -> Schema por defecto, tablas relacionadas a seguridad, usuarios, etc
- `new` inventarios -> Relacionado a las entradas y salidas de los productos (Core)
- `new` personas -> Relacionado a las personas del negocio (personas y proveedores)
- `new` productos -> Relacionado todo a los productos, almacenes y categorias

## Tablas

### configuraciones
- `new` Sistema -> Guarda un unico registra, con los campos del sistema

### dbo
- `new` Usuario -> Usuarios del sistema/negocio
- `new` Permiso -> Permisos del sistema, pudiendo acceder a distintos modulos
- `new` Perfil -> Perfiles del sistmea, ligado a un usuario
- `new` PerfilPermiso -> Un perfil, puede tener muchos permisos y viceversa

### inventarios
- `new` Entrada -> Entradas del sistema de los recursos de los proveedores
- `new` EntradaProducto -> Detalle de una entrada
- `new` Salida -> Salidas del sistema  para los clientes
- `new` SalidaProducto -> Detalle de la salida

### personas
- `new` TipoDocumento -> Tabla que contiene los tipos de documento
- `new` Cliente -> Clientes del sistema, pudiendo ser personas juridicas o naturales
- `new` Proveedor -> Proveedores del sistema, pudiendo ser solo persona juridicas (RUC)
- `new` LogCliente -> Auditoria del mantenimiento de los clientes
- `new` LogProveedor -> Auditoria del mantenimiento de los proveedores

### productos
- `new` Producto -> Productos del sistema
- `new` LogProducto -> Auditoria del mantenimiento de los productos 
- `new` Categoria -> Categorias de los productos
- `new` Almacen -> Almacen de los productos

## Procedures

### inventarios
- `new` usp_ObtenerResumen ->  Obtener un resumen de todas las ganancias, es decir, compras y ventas por producto
- `new` usp_RegistrarEntrada -> Registra una entrada recibiendo un XML de los productos
- `new` usp_RegistrarSalida -> Registra una saldia recibiendo un XML de los productos

## Funciones

### inventarios
- `new` usp_GenerarCodigo -> Genero un codigo para una entrada o salida

## Triggers

### configuraciones
- `new` trg_datosSistema -> Validar que solo exista un registro (UPSERT) a la tabla `Configuraciones`

### personas
- `new` trg_logClienteInsert -> Log de insert en la tabla LogCliente
- `new` trg_logClienteUpdate-> Log de update en la tabla LogCliente
- `new` trg_logClienteDelete-> Log de delete en la tabla LogCliente
- `new` trg_logProveedorInsert -> Log de insert en la tabla LogProveedor
- `new` trg_logProveedorUpdate-> Log de update en la tabla LogProveedor
- `new` trg_logProveedorDelete-> Log de delete en la tabla LogProveedor

### productos
- `new` trg_logProductoInsert -> Log de insert en la tabla LogProducto
- `new` trg_logProductoUpdate-> Log de update en la tabla LogProducto
- `new` trg_logProductoDelete-> Log de delete en la tabla LogProducto
