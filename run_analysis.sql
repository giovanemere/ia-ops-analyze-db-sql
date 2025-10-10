-- Script Principal: Análisis Completo de Base de Datos
-- Ejecutar este script para obtener el EDR completo y análisis de problemas

USE [persqldbmotorpromocprd];

PRINT '=== INICIANDO ANÁLISIS DE BASE DE DATOS ===';
PRINT 'Fecha: ' + CAST(GETDATE() AS VARCHAR);
PRINT '';

-- 1. Verificar conexión
PRINT '1. VERIFICANDO CONEXIÓN...';
SELECT @@SERVERNAME as Servidor, DB_NAME() as BaseDatos, SYSTEM_USER as Usuario;
PRINT '';

-- 2. Estadísticas generales
PRINT '2. ESTADÍSTICAS GENERALES...';
SELECT 
    COUNT(DISTINCT TABLE_NAME) as Total_Tablas,
    COUNT(*) as Total_Columnas
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME IN (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE');
PRINT '';

-- 3. Tablas principales
PRINT '3. LISTADO DE TABLAS...';
SELECT TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
ORDER BY TABLE_SCHEMA, TABLE_NAME;
PRINT '';

-- 4. Problemas identificados
PRINT '4. PROBLEMAS IDENTIFICADOS...';
PRINT 'Tablas sin Primary Key:';
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
AND NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    WHERE tc.TABLE_NAME = t.TABLE_NAME 
    AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
);

PRINT '';
PRINT '=== ANÁLISIS COMPLETADO ===';
PRINT 'Para análisis detallado, ejecutar scripts individuales en /scripts/';
