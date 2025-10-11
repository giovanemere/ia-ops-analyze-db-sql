-- =====================================================
-- OPTIMIZACIÓN COMPLETA DE BASE DE DATOS
-- Script principal integrado
-- =====================================================

PRINT '=========================================='
PRINT 'INICIANDO OPTIMIZACIÓN COMPLETA'
PRINT 'Base de Datos: ' + DB_NAME()
PRINT 'Fecha/Hora: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '=========================================='

SET NOCOUNT ON;

-- 1. ANÁLISIS DE RENDIMIENTO ACTUAL
PRINT ''
PRINT '1. EJECUTANDO ANÁLISIS DE RENDIMIENTO...'
PRINT '----------------------------------------'

:r 01_performance_analysis.sql

-- 2. MANTENIMIENTO URGENTE
PRINT ''
PRINT '2. EJECUTANDO MANTENIMIENTO URGENTE...'
PRINT '--------------------------------------'

:r 05_maintenance_urgent.sql

-- 3. CREACIÓN DE ÍNDICES OPTIMIZADOS
PRINT ''
PRINT '3. CREANDO ÍNDICES OPTIMIZADOS...'
PRINT '---------------------------------'

:r 02_create_indexes.sql

-- 4. OPTIMIZACIÓN ADICIONAL
PRINT ''
PRINT '4. EJECUTANDO OPTIMIZACIÓN ADICIONAL...'
PRINT '---------------------------------------'

:r 06_additional_optimization.sql

-- 5. VALIDACIÓN POST-OPTIMIZACIÓN
PRINT ''
PRINT '5. VALIDANDO RESULTADOS...'
PRINT '--------------------------'

:r 07_validation.sql

PRINT ''
PRINT '=========================================='
PRINT 'OPTIMIZACIÓN COMPLETA FINALIZADA'
PRINT 'Mejoras esperadas: 60-80% en rendimiento'
PRINT '=========================================='
