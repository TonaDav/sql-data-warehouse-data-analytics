-- Calculamos cuántos años de ventas disponibles hay
SELECT
	DATEDIFF(YEAR,MIN(venta_fecha),MAX(venta_fecha)) AS number_of_years
FROM oro.fact_ventas

-- Hallamos al cliente más joven y al cliente más adulto
SELECT
	MIN(DATEDIFF(YEAR, fecha_nacimiento, GETDATE())),
	MAX(DATEDIFF(YEAR, fecha_nacimiento, GETDATE()))
FROM oro.dim_clientes

-- Calculamos los ingresos totales
SELECT
	'S/. ' + CAST(SUM(venta_total) AS VARCHAR) AS [Ingresos Totales]
FROM oro.fact_ventas
-- Calculamos el número de productos vendidos
SELECT
	SUM(venta_cantidad) AS [Productos Vendidos]
FROM oro.fact_ventas
-- Calculamos el precio promedio de los productos vendidos
SELECT
	'S/. ' + CAST(AVG(venta_precio) AS VARCHAR) AS [Precio Promedio]
FROM oro.fact_ventas
-- Calculamos el total de pedidos
SELECT
	CAST(COUNT(DISTINCT venta_id) AS VARCHAR) AS [Total de Pedidos]
FROM oro.fact_ventas
-- Calculamos el total de productos
SELECT
	COUNT(*) AS [Total de Productos]
FROM oro.dim_productos
-- Calculamos el total de clientes
SELECT
	COUNT(*) AS [Total de Clientes]
FROM oro.dim_clientes
-- Calculamos el total de clientes que han hecho al menos un pedido
SELECT
	COUNT(DISTINCT cliente_llave) AS [Total de Clientes]
FROM oro.fact_ventas

-- Generamos un reporte de todas las métricas clave del negocio
SELECT 
	'Ingresos Totales' AS Medida,
	'S/. ' + CAST(SUM(venta_total) AS VARCHAR) AS Valor
FROM oro.fact_ventas
UNION ALL
SELECT
	'Total de Productos Vendidos',
	CAST(SUM(venta_cantidad) AS VARCHAR)
FROM oro.fact_ventas
UNION ALL
SELECT
	'Precio Promedio en Ventas',
	'S/. ' + CAST(AVG(venta_precio) AS VARCHAR)
FROM oro.fact_ventas
UNION ALL
SELECT
	'Total de Pedidos',
	CAST(COUNT(DISTINCT venta_id) AS VARCHAR)
FROM oro.fact_ventas
UNION ALL
SELECT
	'Total de Clientes',
	CAST(COUNT(*) AS VARCHAR)
FROM oro.dim_clientes
UNION ALL
SELECT
	'Total de Productos',
	CAST(COUNT(*) AS VARCHAR)
FROM oro.dim_productos

-- Hallamos el total de clientes por país
SELECT
	pais AS País,
	COUNT(cliente_llave) AS [Total de Clientes]
FROM oro.dim_clientes
GROUP BY pais
ORDER BY [Total de Clientes] DESC

-- Hallamos el total de clientes por género
SELECT
	genero AS Género,
	COUNT(cliente_llave) AS [Total de Clientes]
FROM oro.dim_clientes
GROUP BY genero
ORDER BY [Total de Clientes] DESC

-- Hallamos el total de productos por categoría
SELECT
	categoria AS Categoría,
	COUNT(producto_key) AS [Total de Productos]
FROM oro.dim_productos
GROUP BY categoria
ORDER BY [Total de Productos] DESC

-- Calculamos el costo promedio por categoría
SELECT
	categoria AS Categoría,
	AVG(costo) AS [Costo Promedio]
FROM oro.dim_productos
GROUP BY categoria
ORDER BY [Costo Promedio] DESC

-- Calculamos los ingresos totales para cada categoría de producto
SELECT
	P.categoria AS Categoría,
	SUM(V.venta_cantidad * V.venta_precio) AS [Ingresos Totales]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_productos P
ON V.producto_key = P.producto_key
GROUP BY P.categoria
ORDER BY [Ingresos Totales] DESC

-- Calculamos los ingresos totales generados por cada cliente
SELECT
	C.cliente_llave AS Cliente,
	C.nombre AS Nombre,
	C.apellido AS Apellido,
	SUM(venta_cantidad * venta_precio) AS [Ingresos Totales]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_clientes C
ON V.cliente_llave = C.cliente_llave
GROUP BY C.cliente_llave, C.nombre, C.apellido
ORDER BY [Ingresos Totales] DESC

-- Hallamos los top 5 productos (ingresos totales)
SELECT TOP 5
	P.producto_key,
	P.nombre,
	P.categoria,
	SUM(V.venta_cantidad * V.venta_precio) AS [Ingresos Totales]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_productos P
ON V.producto_key = P.producto_key
GROUP BY P.producto_key, P.nombre, P.categoria
ORDER BY [Ingresos Totales] DESC

SELECT *
FROM (
	SELECT
		P.producto_key,
		P.nombre,
		P.categoria,
		SUM(V.venta_cantidad * V.venta_precio) AS [Ingresos Totales],
		ROW_NUMBER() OVER(ORDER BY SUM(V.venta_cantidad * V.venta_precio) DESC) AS Rango
	FROM oro.fact_ventas V
	LEFT JOIN oro.dim_productos P
	ON V.producto_key = P.producto_key
	GROUP BY P.producto_key, P.nombre, P.categoria
	) T
WHERE Rango <= 5

-- Hallamos los bottom 5 productos (ingresos totales)
SELECT TOP 5
	P.producto_key,
	P.nombre,
	P.categoria,
	SUM(V.venta_cantidad * V.venta_precio) AS [Ingresos Totales]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_productos P
ON V.producto_key = P.producto_key
GROUP BY P.producto_key, P.nombre, P.categoria
ORDER BY [Ingresos Totales] ASC

SELECT *
FROM
	(
		SELECT
		P.producto_key,
		P.nombre,
		P.categoria,
		SUM(V.venta_cantidad * V.venta_precio) AS [Ingresos Totales],
		ROW_NUMBER() OVER(ORDER BY SUM(V.venta_cantidad * V.venta_precio) ASC) AS Rango
	FROM oro.fact_ventas V
	LEFT JOIN oro.dim_productos P
	ON V.producto_key = P.producto_key
	GROUP BY P.producto_key, P.nombre, P.categoria
	) T
WHERE Rango <= 5

-- Hallamos los top 10 clientes (ingresos totales)
SELECT *
FROM
	(
		SELECT
		C.cliente_llave AS [Cliente Key],
		C.nombre, 
		C.apellido,
		SUM(V.venta_cantidad * V.venta_precio) AS [Ingresos Totales],
		ROW_NUMBER() OVER(ORDER BY SUM(V.venta_cantidad * V.venta_precio) DESC) AS [Rango]
	FROM oro.fact_ventas V
	LEFT JOIN oro.dim_clientes C
	ON V.cliente_llave = C.cliente_llave
	GROUP BY C.cliente_llave, C.nombre, C.apellido
	) T
WHERE Rango <= 10


-- Hallamos los 3 clientes con menor cantidad de pedidos
SELECT TOP 3
	C.cliente_llave,
	C.nombre,
	C.apellido,
	COUNT(DISTINCT V.venta_id) AS [Pedidos Totales]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_clientes C
ON V.cliente_llave = C.cliente_llave
GROUP BY C.cliente_llave, C.nombre, C.apellido
ORDER BY [Pedidos Totales]