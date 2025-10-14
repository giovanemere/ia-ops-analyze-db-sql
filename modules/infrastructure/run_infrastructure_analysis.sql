-- =====================================================
-- ANÁLISIS COMPLETO DE INFRAESTRUCTURA
-- Ejecuta todos los scripts de análisis de sistema
-- =====================================================

PRINT '=========================================='
PRINT 'INICIANDO ANÁLISIS COMPLETO DE INFRAESTRUCTURA'
PRINT 'Base de Datos: ' + DB_NAME()
PRINT 'Servidor: ' + @@SERVERNAME
PRINT 'Fecha/Hora: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '=========================================='

SET NOCOUNT ON;

PRINT ''
PRINT '1. EJECUTANDO ANÁLISIS DE RECURSOS DEL SISTEMA...'
PRINT '---------------------------------------------------'

-- Ejecutar análisis de recursos del sistema
:r 01_system_resources.sql

PRINT ''
PRINT '2. EJECUTANDO ANÁLISIS DE SESIONES Y CONEXIONES...'
PRINT '----------------------------------------------------'

-- Ejecutar análisis de sesiones
:r 02_sessions_connections.sql

PRINT ''
PRINT '3. EJECUTANDO ANÁLISIS DE ALMACENAMIENTO Y I/O...'
PRINT '--------------------------------------------------'

-- Ejecutar análisis de I/O
:r 03_storage_io_analysis.sql

PRINT ''
PRINT '=========================================='
PRINT 'ANÁLISIS DE INFRAESTRUCTURA COMPLETADO'
PRINT 'Revise los resultados para optimización'
PRINT '=========================================='

-- Resumen ejecutivo
SELECT 
    'EXECUTIVE_SUMMARY' as SECTION,
    'INFRASTRUCTURE_ANALYSIS_COMPLETE' as STATUS,
    @@SERVERNAME as SERVER_NAME,
    DB_NAME() as DATABASE_NAME,
    GETDATE() as COMPLETION_TIME,
    (SELECT cpu_count FROM sys.dm_os_sys_info) as LOGICAL_CPUS,
    (SELECT physical_memory_kb / 1024 / 1024 FROM sys.dm_os_sys_info) as PHYSICAL_MEMORY_GB,
    (SELECT COUNT(*) FROM sys.dm_exec_sessions WHERE is_user_process = 1) as ACTIVE_USER_SESSIONS,
    (SELECT COUNT(*) FROM sys.database_files) as DATABASE_FILES,
    (SELECT SUM(size) * 8 / 1024 FROM sys.database_files) as TOTAL_DATABASE_SIZE_MB;
