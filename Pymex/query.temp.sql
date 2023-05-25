select prod.Codigo,prod.Descripcion,prod.Categoria,prod.Almacen,
ifnull(ent.Entradas,0)[Entradas],ifnull(sal.Salidas,0)[Salidas],
prod.Stock,
printf("%.2f", ifnull(ent.TotalEgresos,0))[TotalEgresos],printf(" % .2f", ifnull(sal.TotalIngresos,0))[TotalIngresos]
from (
    select DISTINCT * from (
        select p.IdProducto,p.Codigo,p.Descripcion,p.Categoria,p.Almacen,p.Stock from DETALLE_ENTRADA de
        inner join ENTRADA e on e.IdEntrada = de.IdEntrada
        inner join PRODUCTO p on p.IdProducto = de.IdProducto where DATE(e.FechaRegistro) BETWEEN DATE(@pfechainicio1) AND DATE(@pfechafin1)
        UNION ALL
        select p.IdProducto,p.Codigo,p.Descripcion,p.Categoria,p.Almacen,p.Stock from DETALLE_SALIDA ds
        inner join SALIDA s on s.IdSalida = ds.IdSalida
        inner join PRODUCTO p on p.IdProducto = ds.IdProducto where DATE(s.FechaRegistro) BETWEEN DATE(@pfechainicio2) AND DATE(@pfechafin2)
    ) temp
) prod
left join (
select p.IdProducto,sum(de.Cantidad)[Entradas],sum(CAST(de.SubTotal as NUMERIC))[TotalEgresos] from PRODUCTO p
inner join DETALLE_ENTRADA de on de.IdProducto = p.IdProducto
inner join ENTRADA e on e.IdEntrada = de.IdEntrada where DATE(e.FechaRegistro) BETWEEN DATE(@pfechainicio3) AND DATE(@pfechafin3)
group by p.IdProducto,p.Codigo,p.Descripcion,p.Categoria,p.Almacen
) ent on ent.IdProducto = prod.IdProducto
left join (
select p.IdProducto,sum(ds.Cantidad)[Salidas],sum(CAST(ds.SubTotal as NUMERIC))[TotalIngresos] from PRODUCTO p
inner join DETALLE_SALIDA ds on ds.IdProducto = p.IdProducto
inner join SALIDA s on s.IdSalida = ds.IdSalida where DATE(s.FechaRegistro) BETWEEN DATE(@pfechainicio4) AND DATE(@pfechafin4)
group by p.IdProducto
) sal on sal.IdProducto = prod.IdProducto

