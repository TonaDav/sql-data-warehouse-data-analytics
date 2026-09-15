/*
===============================================================================
DDL Script: Creación de Vistas en la Capa de Oro
===============================================================================
*/

-- =================================================
-- Creamos la Tabla de Dimensiones: oro.dim_clientes
-- =================================================
IF OBJECT_ID('oro.dim_clientes', 'V') IS NOT NULL
	DROP VIEW oro.dim_clientes;
GO

CREATE VIEW oro.dim_clientes AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cliente_id) AS cliente_llave,
	CI.cliente_id AS cliente_id,
	CI.cliente_key AS cliente_numero,
	CI.cliente_nombre AS nombre,
	CI.cliente_apellido AS apellido,
	LA.cpais AS pais,
	CI.cliente_estado_marital AS estado_marital,
	CASE
		WHEN CI.cliente_genero != 'n/a' THEN CI.cliente_genero
		ELSE ISNULL(CA.genero, 'n/a')
	END AS genero,
	CA.fechaNacimiento AS fecha_nacimiento,
	CI.cliente_fecha_creacion AS fecha_creacion
FROM plata.crm_cliente_info CI
LEFT JOIN plata.erp_cliente_az12 CA
ON CI.cliente_key = CA.cid
LEFT JOIN plata.erp_loc_a101 LA
ON CI.cliente_key = LA.cid;
GO

-- ==================================================
-- Creamos la Tabla de Dimensiones: oro.dim_productos
-- ==================================================
IF OBJECT_ID('oro.dim_productos', 'V') IS NOT NULL
	DROP VIEW oro.dim_productos;
GO

CREATE VIEW oro.dim_productos AS
SELECT
	ROW_NUMBER() OVER(ORDER BY P.producto_fecha_inicio, P.producto_key) AS producto_key,
	P.producto_id AS producto_id,
	P.producto_key AS producto_numero,
	P.categoria_id AS categoria_id,
	P.producto_nombre AS nombre,
	P.producto_costo AS costo,
	P.producto_linea AS linea,
	P.producto_fecha_inicio AS fecha_inicio,
	PC.categoria AS categoria,
	PC.subcategoria AS subcategoria,
	PC.mantenimiento AS mantenimiento
FROM plata.crm_producto_info P
LEFT JOIN plata.erp_px_cat_g1v2 PC
ON P.categoria_id = PC.id
WHERE producto_fecha_fin IS NULL;
GO

-- ===========================================
-- Creamos la Tabla de Hechos: oro.fact_ventas
-- ===========================================
IF OBJECT_ID('oro.fact_ventas', 'V') IS NOT NULL
	DROP VIEW oro.fact_ventas;
GO

CREATE VIEW oro.fact_ventas AS
SELECT
	VD.venta_id	AS venta_id,
	P.producto_key,
	C.cliente_llave,
	VD.venta_fecha,
	VD.venta_fecha_envio,
	VD.venta_fecha_limite,
	VD.venta_total,
	VD.venta_cantidad,
	VD.venta_precio
FROM plata.crm_ventas_detalles VD
LEFT JOIN oro.dim_productos P
ON vd.venta_producto_key = P.producto_numero
LEFT JOIN oro.dim_clientes C
ON VD.venta_cliente_id = C.cliente_id;
GO