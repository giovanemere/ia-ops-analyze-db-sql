-- =====================================================
-- VERIFICACIÓN POST-BACKUP/RESTORE
-- Valida integridad y consistencia de datos
-- =====================================================

PRINT '=========================================='
PRINT 'INICIANDO VERIFICACIÓN POST-BACKUP/RESTORE'
PRINT 'Base de Datos: ' + DB_NAME()
PRINT 'Servidor: ' + @@SERVERNAME
PRINT 'Fecha/Hora: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '=========================================='

SET NOCOUNT ON;

-- 1. INFORMACIÓN GENERAL DE LA BASE DE DATOS
SELECT 
    'DATABASE_INFO' as SECTION,
    DB_NAME() as DATABASE_NAME,
    DATABASEPROPERTYEX(DB_NAME(), 'Status') as DATABASE_STATUS,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') as COLLATION,
    DATABASEPROPERTYEX(DB_NAME(), 'Edition') as EDITION,
    DATABASEPROPERTYEX(DB_NAME(), 'ServiceObjective') as SERVICE_TIER,
    GETDATE() as VERIFICATION_TIME;

-- 2. CONTEO DE OBJETOS
SELECT 
    'OBJECT_COUNT' as SECTION,
    'TABLES' as OBJECT_TYPE,
    COUNT(*) as OBJECT_COUNT
FROM sys.tables 
WHERE is_ms_shipped = 0

UNION ALL

SELECT 
    'OBJECT_COUNT' as SECTION,
    'VIEWS' as OBJECT_TYPE,
    COUNT(*) as OBJECT_COUNT
FROM sys.views 
WHERE is_ms_shipped = 0

UNION ALL

SELECT 
    'OBJECT_COUNT' as SECTION,
    'PROCEDURES' as OBJECT_TYPE,
    COUNT(*) as OBJECT_COUNT
FROM sys.procedures 
WHERE is_ms_shipped = 0

UNION ALL

SELECT 
    'OBJECT_COUNT' as SECTION,
    'FUNCTIONS' as OBJECT_TYPE,
    COUNT(*) as OBJECT_COUNT
FROM sys.objects 
WHERE type IN ('FN', 'IF', 'TF') AND is_ms_shipped = 0

UNION ALL

SELECT 
    'OBJECT_COUNT' as SECTION,
    'INDEXES' as OBJECT_TYPE,
    COUNT(*) as OBJECT_COUNT
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0 AND i.index_id > 0;

-- 3. CONTEO DE REGISTROS POR TABLA
SELECT 
    'RECORD_COUNT' as SECTION,
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

-- 4. VERIFICACIÓN DE INTEGRIDAD
PRINT ''
PRINT 'Ejecutando verificación de integridad de la base de datos...'

DBCC CHECKDB WITH NO_INFOMSGS, ALL_ERRORMSGS;

PRINT 'Verificación de integridad completada.'

-- 5. VERIFICACIÓN DE ÍNDICES
SELECT 
    'INDEX_VERIFICATION' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    i.name as INDEX_NAME,
    i.type_desc as INDEX_TYPE,
    CASE WHEN i.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END as INDEX_STATUS,
    CASE WHEN i.is_primary_key = 1 THEN 'YES' ELSE 'NO' END as IS_PRIMARY_KEY,
    CASE WHEN i.is_unique = 1 THEN 'YES' ELSE 'NO' END as IS_UNIQUE
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0 AND i.index_id > 0
ORDER BY SCHEMA_NAME(t.schema_id), t.name, i.name;

-- 6. VERIFICACIÓN DE CLAVES FORÁNEAS
SELECT 
    'FOREIGN_KEY_VERIFICATION' as SECTION,
    SCHEMA_NAME(tp.schema_id) as PARENT_SCHEMA,
    tp.name as PARENT_TABLE,
    fk.name as CONSTRAINT_NAME,
    SCHEMA_NAME(tr.schema_id) as REFERENCED_SCHEMA,
    tr.name as REFERENCED_TABLE,
    CASE WHEN fk.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END as FK_STATUS,
    CASE WHEN fk.is_not_trusted = 1 THEN 'NOT_TRUSTED' ELSE 'TRUSTED' END as TRUST_STATUS
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
ORDER BY SCHEMA_NAME(tp.schema_id), tp.name, fk.name;

-- 7. VERIFICACIÓN DE TRIGGERS
SELECT 
    'TRIGGER_VERIFICATION' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    tr.name as TRIGGER_NAME,
    tr.type_desc as TRIGGER_TYPE,
    CASE WHEN tr.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END as TRIGGER_STATUS
FROM sys.triggers tr
INNER JOIN sys.tables t ON tr.parent_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(t.schema_id), t.name, tr.name;

-- 8. VERIFICACIÓN DE USUARIOS Y PERMISOS
SELECT 
    'USER_VERIFICATION' as SECTION,
    dp.name as PRINCIPAL_NAME,
    dp.type_desc as PRINCIPAL_TYPE,
    dp.authentication_type_desc as AUTHENTICATION_TYPE,
    dp.default_schema_name as DEFAULT_SCHEMA
FROM sys.database_principals dp
WHERE dp.type NOT IN ('R') AND dp.principal_id > 4
ORDER BY dp.type_desc, dp.name;

-- 9. ESTADÍSTICAS DE ESPACIO
SELECT 
    'SPACE_USAGE' as SECTION,
    f.name as FILE_NAME,
    f.type_desc as FILE_TYPE,
    CAST(f.size * 8.0 / 1024 AS DECIMAL(12,2)) as SIZE_MB,
    CAST(FILEPROPERTY(f.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(12,2)) as USED_MB,
    CAST((f.size - FILEPROPERTY(f.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(12,2)) as FREE_MB,
    CAST(FILEPROPERTY(f.name, 'SpaceUsed') * 100.0 / f.size AS DECIMAL(5,2)) as USED_PERCENTAGE
FROM sys.database_files f
ORDER BY f.type, f.file_id;

-- 10. RESUMEN DE VERIFICACIÓN
SELECT 
    'VERIFICATION_SUMMARY' as SECTION,
    'VERIFICATION_COMPLETE' as STATUS,
    DB_NAME() as DATABASE_NAME,
    GETDATE() as COMPLETION_TIME,
    (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) as TOTAL_TABLES,
    (SELECT SUM(p.rows) FROM sys.tables t 
     INNER JOIN sys.partitions p ON t.object_id = p.object_id 
     WHERE t.is_ms_shipped = 0 AND p.index_id IN (0,1)) as TOTAL_RECORDS,
    (SELECT COUNT(*) FROM sys.indexes i 
     INNER JOIN sys.tables t ON i.object_id = t.object_id 
     WHERE t.is_ms_shipped = 0 AND i.index_id > 0) as TOTAL_INDEXES,
    (SELECT COUNT(*) FROM sys.foreign_keys) as TOTAL_FOREIGN_KEYS;

PRINT ''
PRINT '=========================================='
PRINT 'VERIFICACIÓN COMPLETADA EXITOSAMENTE'
PRINT 'Revise los resultados para confirmar integridad'
PRINT '=========================================='

-- 11. CONSULTAS DE PRUEBA BÁSICAS (opcional)
PRINT ''
PRINT 'Ejecutando consultas de prueba básicas...'

-- Verificar que las tablas principales tienen datos
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CuponesDigitales')
BEGIN
    DECLARE @CuponesCount INT
    SELECT @CuponesCount = COUNT(*) FROM CuponesDigitales
    PRINT 'CuponesDigitales: ' + CAST(@CuponesCount AS VARCHAR(20)) + ' registros'
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CuponesFisicoCorreccion')
BEGIN
    DECLARE @FisicoCount INT
    SELECT @FisicoCount = COUNT(*) FROM CuponesFisicoCorreccion
    PRINT 'CuponesFisicoCorreccion: ' + CAST(@FisicoCount AS VARCHAR(20)) + ' registros'
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Campanna')
BEGIN
    DECLARE @CampannaCount INT
    SELECT @CampannaCount = COUNT(*) FROM Campanna
    PRINT 'Campanna: ' + CAST(@CampannaCount AS VARCHAR(20)) + ' registros'
END

PRINT 'Consultas de prueba completadas.'
PRINT ''
PRINT '✅ VERIFICACIÓN POST-BACKUP/RESTORE FINALIZADA'
