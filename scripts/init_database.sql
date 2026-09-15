/*
=============================================
Creamos la Base de Datos y Esquemas (Schemas)
=============================================
*/

USE master;
GO

-- Eliminamos y recreamos la base de datos 'AlmacenDatos'
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'AlmacenDatos')
BEGIN
	ALTER DATABASE AlmacenDatos SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE AlmacenDatos
END;
GO

-- Creamos la base de datos 'AlmacenDatos'
CREATE DATABASE AlmacenDatos;
GO

USE AlmacenDatos;
GO

-- Creamos los esquemas (schemas)
CREATE SCHEMA bronce;
GO

CREATE SCHEMA plata;
GO

CREATE SCHEMA oro;
GO