/*
==================================================
Procedimiento Almacenado: Cargar la Capa de Bronce
==================================================
*/

CREATE OR ALTER PROCEDURE bronce.cargar_bronce AS
BEGIN
	BEGIN TRY
		TRUNCATE TABLE bronce.crm_cliente_info;

		BULK INSERT bronce.crm_cliente_info
		FROM 'C:\Users\Tomas\OneDrive\SQL Projects\sql-data-warehouse-data-analytics\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2, -- Saltamos la primera fila.
			FIELDTERMINATOR = ',', -- Especificamos el separador.
			TABLOCK -- Optimizamos la inserción de datos, pero bloqueamos cualquier otra conexión o consulta que se puede tener con esta tabla.
		);

		TRUNCATE TABLE bronce.crm_producto_info;

		BULK INSERT bronce.crm_producto_info
		FROM 'C:\Users\Tomas\OneDrive\SQL Projects\sql-data-warehouse-data-analytics\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		TRUNCATE TABLE bronce.crm_ventas_detalles;

		BULK INSERT bronce.crm_ventas_detalles
		FROM 'C:\Users\Tomas\OneDrive\SQL Projects\sql-data-warehouse-data-analytics\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',', 
			TABLOCK 
		);

		TRUNCATE TABLE bronce.erp_cliente_az12;

		BULK INSERT bronce.erp_cliente_az12
		FROM 'C:\Users\Tomas\OneDrive\SQL Projects\sql-data-warehouse-data-analytics\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		TRUNCATE TABLE bronce.erp_loc_a101;

		BULK INSERT bronce.erp_loc_a101
		FROM 'C:\Users\Tomas\OneDrive\SQL Projects\sql-data-warehouse-data-analytics\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		TRUNCATE TABLE bronce.erp_px_cat_g1v2;

		BULK INSERT bronce.erp_px_cat_g1v2
		FROM 'C:\Users\Tomas\OneDrive\SQL Projects\sql-data-warehouse-data-analytics\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);
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