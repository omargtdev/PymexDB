# Pymex (2023-05-24)

## Schemas
`new` configuraciones -> Relacionado a la empresa y configuraciones del sistema
`new` dbo -> Schema por defecto, tablas relacionadas a seguridad, usuarios, etc
`new` inventarios -> Relacionado a las entradas y salidas de los productos (Core)
`new` personas -> Relacionado a las personas del negocio (personas y proveedores)
`new` productos -> Relacionado todo a los productos, almacenes y categorias

## Tablas

### configuraciones
`new` Sistema -> Guarda un unico registra, con los campos del sistema

### dbo
`new` Usuario -> Usuarios del sistema/negocio
`new` Permiso -> Permisos del sistema, pudiendo acceder a distintos modulos
`new` Perfil -> Perfiles del sistmea, ligado a un usuario
`new` PerfilPermiso -> Un perfil, puede tener muchos permisos y viceversa

### inventarios
`new` Entrada -> Entradas del sistema de los recursos de los proveedores
`new` EntradaProducto -> Detalle de una entrada
`new` Salida -> Salidas del sistema  para los clientes
`new` SalidaProducto -> Detalle de la salida

### personas
`new` Cliente -> Clientes del sistema, pudiendo ser personas juridicas o naturales
`new` Proveedor -> Proveedores del sistema, pudiendo ser solo persona juridicas (RUC)
`new` LogCliente -> Auditoria del mantenimiento de los clientes
`new` LogProveedor -> Auditoria del mantenimiento de los proveedores

### productos
`new` Producto -> Productos del sistema
`new` LogProducto -> Auditoria del mantenimiento de los productos 
`new` Categoria -> Categorias de los productos
`new` Almacen -> Almacen de los productos

## Procedures

### inventarios
`new` usp_ObtenerResumen ->  Obtener un resumen de todas las ganancias, es decir, compras y ventas por producto
`new` usp_RegistrarEntrada -> Registra una entrada recibiendo un XML de los productos
`new` usp_RegistrarSalida -> Registra una saldia recibiendo un XML de los productos

## Funciones

### inventarios
`new` usp_GenerarCodigo -> Genero un codigo para una entrada o salida

## Triggers

### configuraciones
`new` trg_datosSistema -> Validar que solo exista un registro (UPSERT) a la tabla `Configuraciones`

### personas
`new` trg_logClienteInsert -> Log de insert en la tabla LogCliente
`new` trg_logClienteUpdate-> Log de update en la tabla LogCliente
`new` trg_logClienteDelete-> Log de delete en la tabla LogCliente
`new` trg_logProveedorInsert -> Log de insert en la tabla LogProveedor
`new` trg_logProveedorUpdate-> Log de update en la tabla LogProveedor
`new` trg_logProveedorDelete-> Log de delete en la tabla LogProveedor

### productos
`new` trg_logProductoInsert -> Log de insert en la tabla LogProducto
`new` trg_logProductoUpdate-> Log de update en la tabla LogProducto
`new` trg_logProductoDelete-> Log de delete en la tabla LogProducto
