-- =====================================================
-- SCRIPT PRINCIPAL - DICCIONARIO COMPLETO DE BASE DE DATOS
-- Ejecuta todos los scripts de análisis y genera reporte completo
-- =====================================================

PRINT '=========================================='
PRINT 'INICIANDO GENERACIÓN DE DICCIONARIO COMPLETO'
PRINT 'Base de Datos: ' + DB_NAME()
PRINT 'Fecha/Hora: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '=========================================='

-- Configuración para resultados
SET NOCOUNT ON;

PRINT ''
PRINT '1. EJECUTANDO ANÁLISIS DE ESTRUCTURA BÁSICA...'
PRINT '----------------------------------------------'

-- Ejecutar análisis básico de base de datos
:r 01_complete_database_dictionary.sql

PRINT ''
PRINT '2. EJECUTANDO ANÁLISIS DE OBJETOS PROGRAMABLES...'
PRINT '--------------------------------------------------'

-- Ejecutar análisis de objetos programables
:r 02_programmable_objects.sql

PRINT ''
PRINT '3. EJECUTANDO ANÁLISIS DE SEGURIDAD Y PERMISOS...'
PRINT '--------------------------------------------------'

-- Ejecutar análisis de seguridad
:r 03_security_permissions.sql

PRINT ''
PRINT '4. EJECUTANDO ANÁLISIS DE RENDIMIENTO Y ESTADÍSTICAS...'
PRINT '--------------------------------------------------------'

-- Ejecutar análisis de rendimiento
:r 04_statistics_performance.sql

PRINT ''
PRINT '=========================================='
PRINT 'DICCIONARIO COMPLETO GENERADO EXITOSAMENTE'
PRINT 'Revise los resultados para documentación completa'
PRINT '=========================================='

-- Resumen final
SELECT 
    'SUMMARY' as SECTION,
    'DICTIONARY_GENERATION_COMPLETE' as STATUS,
    DB_NAME() as DATABASE_NAME,
    GETDATE() as COMPLETION_TIME,
    (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) as TOTAL_TABLES,
    (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped = 0) as TOTAL_VIEWS,
    (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0) as TOTAL_PROCEDURES,
    (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND is_ms_shipped = 0) as TOTAL_FUNCTIONS,
    (SELECT COUNT(*) FROM sys.indexes i INNER JOIN sys.tables t ON i.object_id = t.object_id WHERE t.is_ms_shipped = 0 AND i.index_id > 0) as TOTAL_INDEXES,
    (SELECT COUNT(*) FROM sys.triggers tr INNER JOIN sys.tables t ON tr.parent_id = t.object_id WHERE t.is_ms_shipped = 0) as TOTAL_TRIGGERS;
