-- Analizamos las ventas mensuales (Diciembre 2010 - Enero 2014)
SELECT
	EOMONTH(venta_fecha) AS Fecha,
	'S/ ' + CAST(SUM(venta_total) AS VARCHAR) AS [Ingresos Totales]
FROM oro.fact_ventas
WHERE venta_fecha IS NOT NULL
GROUP BY EOMONTH(venta_fecha)
ORDER BY EOMONTH(venta_fecha) DESC

-- Analizamos la cantidad de clientes mensuales (Diciembre 2010 - Enero 2014)
SELECT
	EOMONTH(venta_fecha) AS Fecha,
	COUNT(DISTINCT cliente_llave) AS [Clientes Totales]
FROM oro.fact_ventas
WHERE venta_fecha IS NOT NULL
GROUP BY EOMONTH(venta_fecha)
ORDER BY EOMONTH(venta_fecha) DESC

-- Analizamos las unidades vendidas mensuales (Diciembre 2010 - Enero 2014)
SELECT
	EOMONTH(venta_fecha) AS Fecha,
	SUM(venta_cantidad) AS [Unidades Vendidas]
FROM oro.fact_ventas
WHERE venta_fecha IS NOT NULL
GROUP BY EOMONTH(venta_fecha)
ORDER BY EOMONTH(venta_fecha) DESC

-- Calculamos los ingresos anuales y el total acumulado de ventas (Diciembre 2010 - Enero 2014)
SELECT
	Fecha,
	'S/ ' + CAST([Ingresos Anuales] AS VARCHAR) AS [Ingresos Anuales],
	'S/ ' + CAST(SUM([Ingresos Anuales]) OVER(ORDER BY Fecha) AS VARCHAR) AS [Ingresos Acumulados]
FROM 
	(
		SELECT
		DATETRUNC(YEAR, venta_fecha) AS Fecha,
		SUM(venta_total) AS [Ingresos Anuales]
	FROM oro.fact_ventas
	WHERE venta_fecha IS NOT NULL
	GROUP BY DATETRUNC(YEAR, venta_fecha)
	) T

-- Analizamos el desempeño de ingresos de los productos, 
-- comparando los ingresos actuales, con los ingresos promedio 
-- y los ingresos del año pasado
WITH ingresos_anuales_producto AS (
SELECT
	YEAR(V.venta_fecha) AS [Año Venta],
	P.nombre AS [Nombre Producto],
	SUM(V.venta_total) AS [Ingresos Totales]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_productos P
ON V.producto_key = P.producto_key
WHERE V.venta_fecha IS NOT NULL
GROUP BY YEAR(V.venta_fecha), P.nombre
)

SELECT
	[Año Venta],
	[Nombre Producto],
	[Ingresos Totales],
	AVG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto]) AS [Ingresos Promedio],
	[Ingresos Totales] - AVG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto]) AS [Diferencia],
	CASE
		WHEN [Ingresos Totales] - AVG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto]) > 0 THEN 'Sobre el Promedio'
		WHEN [Ingresos Totales] - AVG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto]) < 0 THEN 'Debajo del Promedio'
		ELSE 'Promedio'
	END AS [Estado_Diferencia],
	LAG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto] ORDER BY [Año Venta]) AS [Ingresos Año Pasado],
	[Ingresos Totales] - LAG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto] ORDER BY [Año Venta]) AS [Diferencia con Año Pasado],
	CASE
		WHEN [Ingresos Totales] - LAG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto] ORDER BY [Año Venta]) > 0 THEN 'Aumento'
		WHEN [Ingresos Totales] - LAG([Ingresos Totales]) OVER(PARTITION BY [Nombre Producto] ORDER BY [Año Venta]) < 0 THEN 'Disminucion'
		ELSE 'Sin cambio'
	END AS [Estado]
FROM ingresos_anuales_producto
ORDER BY [Nombre Producto], [Año Venta]

-- Hallamos las categorías que contribuyen más ingresos
WITH ingresos_categoria AS (
SELECT
	categoria AS Categoria,
	SUM(venta_total) AS [Ingresos]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_productos P
ON V.producto_key = P.producto_key
GROUP BY categoria
)
SELECT
	Categoria,
	[Ingresos],
	SUM([Ingresos]) OVER() [Ingresos Totales],
	CONCAT(ROUND((CAST(Ingresos AS FLOAT) / SUM(Ingresos) OVER()) * 100, 2), '%') AS [Porcentaje]
FROM ingresos_categoria
ORDER BY Ingresos DESC

-- Segmentamos los productos en rangos de costo y contamos
-- cuántos productos caen en cada segmento
WITH segmentos_producto AS(
SELECT
	producto_key,
	nombre,
	costo,
	CASE 
		WHEN costo < 100 THEN 'Por debajo de 100'
		WHEN costo BETWEEN 100 AND 500 THEN '100 - 500'
		WHEN costo BETWEEN 500 AND 1000 THEN '500 - 1000'
		ELSE 'Por encima de 1000'
	END rango_costo
FROM oro.dim_productos
)
SELECT
	rango_costo,
	COUNT(producto_key) AS [Productos Totales]
FROM segmentos_producto
GROUP BY rango_costo
ORDER BY [Productos Totales] DESC

-- Segmentamos a los clientes según su comportamiento:
-- VIP: Tienen al menos 12 meses de historial de compras y han gastado más de S/5000.
-- Regular: Tienen al menos 12 meses de historial de compras y han gastado S/5000 o menos.
-- Nuevo: Tienen menos de 12 meses.

GO
WITH comportamientos_clientes AS(
SELECT
	C.cliente_llave AS [Cliente Key],
	SUM(V.venta_total) AS [Ingresos Totales],
	DATEDIFF(MONTH, MIN(V.venta_fecha), MAX(venta_fecha)) AS [Antiguedad]
FROM oro.fact_ventas V
LEFT JOIN oro.dim_clientes C
ON V.cliente_llave = C.cliente_llave
GROUP BY C.cliente_llave, C.fecha_creacion
)
SELECT
	[Segmento],
	COUNT([Cliente Key]) AS [Clientes Totales]
FROM 
	(
	SELECT
	[Cliente Key],
	Antiguedad,
	[Ingresos Totales],
	CASE
		WHEN Antiguedad >= 12 AND [Ingresos Totales] > 5000 THEN 'VIP'
		WHEN Antiguedad >= 12 AND [Ingresos Totales] <= 5000 THEN 'Regular'
		ELSE 'Nuevo'
	END AS [Segmento]
	FROM comportamientos_clientes
	) T
GROUP BY Segmento
ORDER BY [Clientes Totales] DESC;

-- Construimos el Reporte Final de Clientes:
-- 1) Consulta Base: Consultamos las columnas clave de todas las tablas.
CREATE VIEW oro.reporte_clientes AS
WITH query_base AS (
SELECT
	V.venta_id,
	V.producto_key,
	V.venta_fecha,
	V.venta_total,
	V.venta_cantidad,
	C.cliente_llave,
	C.cliente_id,
	C.nombre,
	C.apellido,
	C.fecha_nacimiento,
	CONCAT(C.nombre, ' ', C.apellido) AS [Nombre Completo Cliente],
	DATEDIFF(YEAR, C.fecha_nacimiento, GETDATE()) AS [Edad]
	FROM oro.fact_ventas V
LEFT JOIN oro.dim_clientes C
ON V.cliente_llave = C.cliente_llave
WHERE venta_fecha IS NOT NULL)
-- 2) Agregación de Clientes: Reunimos las métricas clave a nivel de clientes
, agregacion_clientes AS (
SELECT
	cliente_llave,
	cliente_id,
	nombre,
	Edad,
	COUNT(DISTINCT venta_id) AS [Pedidos Totales],
	SUM(venta_total) AS [Ingresos Totales],
	SUM(venta_cantidad) AS [Unidades Vendidas Totales],
	COUNT(DISTINCT producto_key) AS [Productos Totales],
	MAX(venta_fecha) AS [Fecha Ultimo Pedido],
	DATEDIFF(MONTH, MIN(venta_fecha), MAX(venta_fecha)) AS [Antiguedad]
FROM query_base
GROUP BY cliente_llave,
	cliente_id,
	nombre,
	Edad)
-- 3) Segmentamos los clientes en categorías (VIP, Regular, Nuevo) y grupos de edad
SELECT
	cliente_llave AS [Cliente Key],
	cliente_id AS [Cliente ID],
	nombre [Nombre],
	Edad,
	CASE
		WHEN Edad < 20 THEN 'Por debajo de 20'
		WHEN Edad BETWEEN 20 AND 29 THEN '20 - 29'
		WHEN Edad BETWEEN 30 AND 39 THEN '30 - 39'
		WHEN Edad BETWEEN 40 AND 49 THEN '40 - 49'
		ELSE 'Mayor de 50'
	END AS [Grupo Edad],
	CASE
		WHEN Antiguedad >= 12 AND [Ingresos Totales] > 5000 THEN 'VIP'
		WHEN Antiguedad >= 12 AND [Ingresos Totales] <= 5000 THEN 'Regular'
		ELSE 'Nuevo'
	END AS [Segmento],
	[Ingresos Totales],
	[Unidades Vendidas Totales],
	[Productos Totales],
	Antiguedad AS [Antiguedad (Meses)],
	-- 3) Calculamos KPIs (Tiempo desde último pedido, valor promedio por pedido, gasto promedio mensual)
	[Fecha Ultimo Pedido],
	DATEDIFF(MONTH, [Fecha Ultimo Pedido], GETDATE()) AS [Tiempo Desde Utimo Pedido (Meses)],
	[Pedidos Totales],
	CASE
		WHEN [Pedidos Totales] = 0 THEN 0
		ELSE [Ingresos Totales] / [Pedidos Totales]
	END AS [Valor Promedio Pedidos],
	CASE
		WHEN Antiguedad = 0 THEN 0
		ELSE [Ingresos Totales] / Antiguedad
	END AS [Gasto Promedio Mensual]
FROM agregacion_clientes;
GO

-- Construimos el Reporte Final de Productos:
-- 1) Creamos la consulta base para reunir las columnas clave de las tablas.
CREATE VIEW oro.reporte_productos AS
WITH query_base_productos AS (
SELECT
	V.venta_id,
	V.venta_fecha,
	V.cliente_llave,
	V.venta_total,
	V.venta_cantidad,
	P.producto_key,
	P.nombre,
	P.categoria,
	P.subcategoria,
	P.costo
FROM oro.fact_ventas V
LEFT JOIN oro.dim_productos P
ON V.producto_key = P.producto_key
WHERE V.venta_fecha IS NOT NULL),
-- 2) Agregación de Productos: Reunimos las métricas clave a nivel de productos
agregacion_productos AS (
SELECT
	producto_key,
	nombre,
	categoria,
	subcategoria,
	costo,
	DATEDIFF(MONTH, MIN(venta_fecha), MAX(venta_fecha)) AS Antiguedad,
	MAX(venta_fecha) AS fecha_ultimo_pedido,
	COUNT(DISTINCT venta_id) AS pedidos_totales,
	COUNT(DISTINCT cliente_llave) AS clientes_totales,
	SUM(venta_total) AS ingresos_totales,
	SUM(venta_cantidad) AS unidades_vendidas_totales,
	ROUND(AVG(CAST(venta_total AS FLOAT) / NULLIF(venta_cantidad, 0)), 1) AS precio_promedio_venta
FROM query_base_productos
GROUP BY 
	producto_key,
	nombre,
	categoria,
	subcategoria,
	costo)
-- 3) Query Final: Combinamos los resultados y damos una sola salida
SELECT
	producto_key AS [Producto Key],
	nombre AS Nombre,
	categoria AS Categoria,
	subcategoria AS Subcategoria,
	costo AS Costo,
	fecha_ultimo_pedido AS [Fecha Ultimo Pedido],
	DATEDIFF(MONTH, fecha_ultimo_pedido, GETDATE()) AS [Tiempo Desde Ultimo Pedido (Meses)],
	CASE
		WHEN ingresos_totales > 50000 THEN 'Gran Desempeño'
		WHEN ingresos_totales >= 10000 THEN 'Desempeño Medio'
		ELSE 'Desempeño Bajo'
	END AS [Segmento],
	Antiguedad AS [Antiguedad (Meses)],
	pedidos_totales [Pedidos Totales],
	ingresos_totales AS [Ingresos Totales],
	unidades_vendidas_totales AS [Unidades Vendidas Totales],
	clientes_totales AS [Clientes Totales],
	precio_promedio_venta AS [Precio Promedio Ventas],
	CASE
		WHEN pedidos_totales = 0 THEN 0
		ELSE ingresos_totales / pedidos_totales
	END AS [Ingreso Promedio Venta],
	CASE
		WHEN Antiguedad = 0 THEN 0
		ELSE ingresos_totales / Antiguedad
	END AS [Ingreso Promedio Mensual]
FROM agregacion_productos
