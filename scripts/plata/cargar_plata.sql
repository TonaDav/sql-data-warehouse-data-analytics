/*
=================================================
Procedimiento Almacenado: Cargar la Capa de Plata
=================================================
*/

CREATE OR ALTER PROCEDURE plata.cargar_plata AS
BEGIN
	BEGIN TRY
		-- Poblamos la tabla de crm_cliente_info
		TRUNCATE TABLE plata.crm_cliente_info;
		INSERT INTO plata.crm_cliente_info(
			cliente_id,
			cliente_key,
			cliente_nombre,
			cliente_apellido,
			cliente_estado_marital,
			cliente_genero,
			cliente_fecha_creacion)
		SELECT
			cliente_id,
			cliente_key,
			TRIM(cliente_nombre) AS cliente_nombre, -- Trimming
			TRIM(cliente_apellido) AS cliente_apellido, -- Trimming
			CASE
				WHEN UPPER(TRIM(cliente_estado_marital)) = 'M' THEN 'Casado'
				WHEN UPPER(TRIM(cliente_estado_marital)) = 'S' THEN 'Soltero'
				ELSE 'n/a'
			END AS cliente_estado_marital, -- Estandarización de Datos
			CASE 
				WHEN UPPER(TRIM(cliente_genero)) = 'M' THEN 'Masculino'
				WHEN UPPER(TRIM(cliente_genero)) = 'F' THEN 'Femenino'
				ELSE 'n/a'
			END AS cliente_genero, -- Estandarización de Datos
			cliente_fecha_creacion
		FROM (
			SELECT
			*,
			ROW_NUMBER() OVER(PARTITION BY cliente_id ORDER BY cliente_fecha_creacion DESC) AS flag_last
		FROM bronce.crm_cliente_info
		WHERE cliente_id IS NOT NULL -- Eliminación de duplicados
		) T WHERE flag_last = 1

		-- Poblamos la tabla de crm_producto_info
		TRUNCATE TABLE plata.crm_producto_info;
		INSERT INTO plata.crm_producto_info(
		producto_id,
		categoria_id,
		producto_key,
		producto_nombre,
		producto_costo,
		producto_linea,
		producto_fecha_inicio,
		producto_fecha_fin
		)
		SELECT
			producto_id,
			REPLACE(SUBSTRING(producto_key, 1, 5), '-', '_') AS categoria_id,
			SUBSTRING(producto_key, 7, LEN(producto_key)) AS producto_key,
			producto_nombre,
			ISNULL(producto_costo, 0) AS producto_costo, -- Columna derivada
			CASE
				WHEN UPPER(TRIM(producto_linea)) = 'M' THEN 'Mountain'
				WHEN UPPER(TRIM(producto_linea)) = 'R' THEN 'Road'
				WHEN UPPER(TRIM(producto_linea)) = 'S' THEN 'Other Sales'
				WHEN UPPER(TRIM(producto_linea)) = 'T' THEN 'Touring'
				ELSE 'n/a' -- Columna derivada
			END AS producto_linea,
			CAST(producto_fecha_inicio AS DATE) AS producto_fecha_inicio,
			CAST(LEAD(producto_fecha_inicio) OVER(PARTITION BY producto_key ORDER BY producto_fecha_inicio)-1 AS DATE) AS producto_fecha_fin
		FROM bronce.crm_producto_info;

		-- Poblamos la tabla de crm_ventas_detalles
		TRUNCATE TABLE plata.crm_ventas_detalles;
		INSERT INTO plata.crm_ventas_detalles(
			venta_id,
			venta_producto_key,
			venta_cliente_id,
			venta_fecha,
			venta_fecha_envio,
			venta_fecha_limite,
			venta_total,
			venta_cantidad,
			venta_precio
		)
		SELECT
			venta_id,
			venta_producto_key,
			venta_cliente_id,
			CASE 
				WHEN venta_fecha = 0 OR LEN(venta_fecha) != 8 THEN NULL
				ELSE CAST(CAST(venta_fecha AS VARCHAR) AS DATE)
			END AS venta_fecha,
			CASE
				WHEN venta_fecha_envio = 0 OR LEN(venta_fecha_envio) != 8 THEN NULL
				ELSE CAST(CAST(venta_fecha_envio AS VARCHAR) AS DATE)
			END AS venta_fecha_envio,
			CASE
				WHEN venta_fecha_limite = 0 OR LEN(venta_fecha_limite) != 8 THEN NULL
				ELSE CAST(CAST(venta_fecha_limite AS VARCHAR) AS DATE)
			END AS venta_fecha_limite,
			CASE
				WHEN venta_total IS NULL OR venta_total <= 0 OR venta_total != venta_cantidad * ABS(venta_precio)
				THEN venta_cantidad * ABS(venta_precio)
				ELSE venta_total
			END AS venta_total,
			venta_cantidad,
			CASE 
				WHEN venta_precio IS NULL OR venta_precio <= 0
				THEN venta_total / NULLIF(venta_cantidad, 0)
				ELSE venta_precio
			END AS venta_precio
		FROM bronce.crm_ventas_detalles;

		-- Poblamos la tabla erp_cliente_az12
		TRUNCATE TABLE plata.erp_cliente_az12;
		INSERT INTO plata.erp_cliente_az12
		(
			cid,
			fechaNacimiento,
			genero
		)
		SELECT
			CASE
				WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
				ELSE cid
			END AS cid,
			CASE
				WHEN fechaNacimiento > GETDATE() THEN NULL
				ELSE fechaNacimiento
			END AS fechaNacimiento,
			CASE
				WHEN UPPER(TRIM(genero)) = 'Female' THEN 'Femenino'
				WHEN UPPER(TRIM(genero)) = 'Male' THEN 'Masculino'
				ELSE 'n/a'
			END AS genero -- Data Standarization
		FROM bronce.erp_cliente_az12;

		-- Poblamos la tabla erp_loc_a101
		TRUNCATE TABLE plata.erp_loc_a101
		INSERT INTO plata.erp_loc_a101
		(
			cid,
			cpais
		)
		SELECT
			REPLACE(cid,'-','') AS cid,
			CASE
				WHEN TRIM(cpais) = 'DE' THEN 'Germany'
				WHEN TRIM(cpais) IN ('US','USA') THEN 'United States'
				WHEN TRIM(cpais) = '' OR cpais IS NULL THEN 'n/a'
				ELSE TRIM(cpais) -- Data Standarization
			END AS cpais
		FROM bronce.erp_loc_a101

		-- Poblamos la tabla erp_px_cat_g1v2
		TRUNCATE TABLE plata.erp_px_cat_g1v2
		INSERT INTO plata.erp_px_cat_g1v2
		(
			id,
			categoria,
			subcategoria,
			mantenimiento
		)
		SELECT
			id,
			categoria,
			subcategoria,
			mantenimiento
		FROM bronce.erp_px_cat_g1v2
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ALGO SALIÓ MAL CARGANDO LA CAPA DE BRONCE'
		PRINT 'Mensaje de Error: ' + ERROR_MESSAGE();
		PRINT 'Número de Error' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Estado de Error' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END