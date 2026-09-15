/*
==================================================
DDL Script: Creación de Tablas en la Capa de Plata
==================================================
*/

/*
==========================================
-- Creamos la Tabla: plata.crm_cliente_info
==========================================
*/
IF OBJECT_ID ('plata.crm_cliente_info', 'U') IS NOT NULL
	DROP TABLE plata.crm_cliente_info;
GO

CREATE TABLE plata.crm_cliente_info(
	cliente_id				INT,
	cliente_key				NVARCHAR(50),
	cliente_nombre			NVARCHAR(50),
	cliente_apellido		NVARCHAR(50),
	cliente_estado_marital	NVARCHAR(50),
	cliente_genero			NVARCHAR(50),
	cliente_fecha_creacion	DATE,
    dwh_fecha_creacion      DATETIME2 DEFAULT GETDATE()
);
GO

/*
============================================
-- Creamos la Tabla: plata.crm_producto_info
============================================
*/
IF OBJECT_ID('plata.crm_producto_info', 'U') IS NOT NULL
    DROP TABLE plata.crm_producto_info;
GO

CREATE TABLE plata.crm_producto_info (
    producto_id				INT,
    categoria_id            NVARCHAR(50),
    producto_key			NVARCHAR(50),
    producto_nombre			NVARCHAR(50),
    producto_costo			INT,
    producto_linea			NVARCHAR(50),
    producto_fecha_inicio	DATE,
    producto_fecha_fin		DATE,
    dwh_fecha_creacion      DATETIME2 DEFAULT GETDATE()
);
GO

/*
==============================================
-- Creamos la Tabla: plata.crm_ventas_detalles
==============================================
*/
IF OBJECT_ID('plata.crm_ventas_detalles', 'U') IS NOT NULL
    DROP TABLE plata.crm_ventas_detalles;
GO

CREATE TABLE plata.crm_ventas_detalles (
    venta_id            NVARCHAR(50),
    venta_producto_key  NVARCHAR(50),
    venta_cliente_id    INT,
    venta_fecha         DATE,
    venta_fecha_envio   DATE,
    venta_fecha_limite  DATE,
    venta_total         INT,
    venta_cantidad      INT,
    venta_precio        INT,
    dwh_fecha_creacion  DATETIME2 DEFAULT GETDATE()
);
GO

/*
=======================================
-- Creamos la Tabla: plata.erp_loc_a101
=======================================
*/
IF OBJECT_ID('plata.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE plata.erp_loc_a101;
GO

CREATE TABLE plata.erp_loc_a101 (
    cid                 NVARCHAR(50),
    cpais               NVARCHAR(50),
    dwh_fecha_creacion  DATETIME2 DEFAULT GETDATE()
);
GO

/*
===========================================
-- Creamos la Tabla: plata.erp_cliente_az12
===========================================
*/
IF OBJECT_ID('plata.erp_cliente_az12', 'U') IS NOT NULL
    DROP TABLE plata.erp_cliente_az12;
GO

CREATE TABLE plata.erp_cliente_az12 (
    cid                 NVARCHAR(50),
    fechaNacimiento     DATE,
    genero              NVARCHAR(50),
    dwh_fecha_creacion  DATETIME2 DEFAULT GETDATE()
);
GO

/*
==========================================
-- Creamos la Tabla: plata.erp_px_cat_g1v2
==========================================
*/
IF OBJECT_ID('plata.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE plata.erp_px_cat_g1v2;
GO

CREATE TABLE plata.erp_px_cat_g1v2 (
    id                  NVARCHAR(50),
    categoria           NVARCHAR(50),
    subcategoria        NVARCHAR(50),
    mantenimiento       NVARCHAR(50),
    dwh_fecha_creacion  DATETIME2 DEFAULT GETDATE()
);
GO