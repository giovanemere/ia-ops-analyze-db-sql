-- =====================================================
-- BACKUP COMPLETO DE BASE DE DATOS
-- SQL Azure Database - Export/Backup
-- =====================================================

-- NOTA: SQL Azure no soporta BACKUP TO DISK tradicional
-- Se debe usar EXPORT o BACPAC para backup completo

PRINT '=========================================='
PRINT 'INICIANDO BACKUP COMPLETO DE BASE DE DATOS'
PRINT 'Base de Datos: ' + DB_NAME()
PRINT 'Servidor: ' + @@SERVERNAME
PRINT 'Fecha/Hora: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '=========================================='

-- 1. INFORMACIÓN PRE-BACKUP
SELECT 
    'PRE_BACKUP_INFO' as SECTION,
    DB_NAME() as DATABASE_NAME,
    DATABASEPROPERTYEX(DB_NAME(), 'Status') as DATABASE_STATUS,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') as COLLATION,
    DATABASEPROPERTYEX(DB_NAME(), 'Edition') as EDITION,
    DATABASEPROPERTYEX(DB_NAME(), 'ServiceObjective') as SERVICE_TIER,
    GETDATE() as BACKUP_START_TIME;

-- 2. TAMAÑO DE LA BASE DE DATOS
SELECT 
    'DATABASE_SIZE' as SECTION,
    f.name as FILE_NAME,
    f.type_desc as FILE_TYPE,
    CAST(f.size * 8.0 / 1024 AS DECIMAL(12,2)) as SIZE_MB,
    CAST(f.size * 8.0 / 1024 / 1024 AS DECIMAL(12,2)) as SIZE_GB,
    CAST(FILEPROPERTY(f.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(12,2)) as USED_MB,
    CAST((f.size - FILEPROPERTY(f.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(12,2)) as FREE_MB
FROM sys.database_files f;

-- 3. CONTEO DE REGISTROS POR TABLA
SELECT 
    'TABLE_RECORD_COUNT' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    p.rows as RECORD_COUNT,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as SIZE_MB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 AND i.object_id > 255
GROUP BY t.schema_id, t.name, p.rows
ORDER BY p.rows DESC;

-- 4. VERIFICACIÓN DE INTEGRIDAD PRE-BACKUP
PRINT ''
PRINT 'Ejecutando verificación de integridad...'

-- Verificar integridad de la base de datos
DBCC CHECKDB WITH NO_INFOMSGS, ALL_ERRORMSGS;

PRINT 'Verificación de integridad completada.'

-- 5. ESTADÍSTICAS DE BACKUP
SELECT 
    'BACKUP_STATISTICS' as SECTION,
    COUNT(*) as TOTAL_TABLES,
    SUM(p.rows) as TOTAL_RECORDS,
    CAST(SUM(ROUND(((a.total_pages * 8) / 1024.00), 2)) AS NUMERIC(36, 2)) as TOTAL_SIZE_MB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 AND i.object_id > 255;

PRINT ''
PRINT '=========================================='
PRINT 'INFORMACIÓN DE BACKUP RECOPILADA'
PRINT 'Para SQL Azure, use Azure Portal o PowerShell'
PRINT 'para exportar BACPAC o configurar backup automático'
PRINT '=========================================='

-- 6. SCRIPT PARA EXPORT (comentado - requiere Azure Storage)
/*
-- EJEMPLO DE EXPORT A AZURE STORAGE (requiere configuración previa)
-- Reemplazar con sus valores reales

DECLARE @StorageAccount NVARCHAR(128) = 'mystorageaccount'
DECLARE @ContainerName NVARCHAR(128) = 'backups'
DECLARE @FileName NVARCHAR(128) = 'persqldbmotorpromocprd_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bacpac'
DECLARE @StorageKey NVARCHAR(128) = 'your_storage_key_here'

-- Crear credencial para Azure Storage
CREATE DATABASE SCOPED CREDENTIAL [https://mystorageaccount.blob.core.windows.net/backups]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'your_sas_token_here';

-- Exportar base de datos
EXPORT DATABASE [persqldbmotorpromocprd]
TO 'https://mystorageaccount.blob.core.windows.net/backups/persqldbmotorpromocprd_backup.bacpac'
WITH (
    CREDENTIAL = 'https://mystorageaccount.blob.core.windows.net/backups'
);
*/
