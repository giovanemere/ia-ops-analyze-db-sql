-- =====================================================
-- ANÁLISIS DE RECURSOS DEL SISTEMA
-- CPU, Memoria, Configuración del servidor
-- =====================================================

PRINT '🖥️ ANÁLISIS DE RECURSOS DEL SISTEMA';
PRINT '===================================';

-- Información del servidor
SELECT 
    'SERVER_INFO' as InfoType,
    @@SERVERNAME as ServerName,
    @@VERSION as SQLVersion,
    SERVERPROPERTY('ProductVersion') as ProductVersion,
    SERVERPROPERTY('ProductLevel') as ProductLevel,
    SERVERPROPERTY('Edition') as Edition,
    SERVERPROPERTY('EngineEdition') as EngineEdition,
    SERVERPROPERTY('MachineName') as MachineName,
    GETDATE() as CurrentTime;

-- Configuración de memoria
SELECT 
    'MEMORY_CONFIG' as ConfigType,
    name,
    value,
    value_in_use,
    description
FROM sys.configurations
WHERE name IN ('max server memory (MB)', 'min server memory (MB)', 'cost threshold for parallelism', 'max degree of parallelism');

-- Uso actual de CPU y memoria (Azure SQL Database)
SELECT 
    'RESOURCE_USAGE' as UsageType,
    'CPU_PERCENT' as MetricName,
    avg_cpu_percent as CurrentValue,
    'Last hour average' as Description
FROM sys.dm_db_resource_stats
WHERE end_time > DATEADD(hour, -1, GETUTCDATE())

UNION ALL

SELECT 
    'RESOURCE_USAGE',
    'DATA_IO_PERCENT',
    avg_data_io_percent,
    'Last hour average'
FROM sys.dm_db_resource_stats
WHERE end_time > DATEADD(hour, -1, GETUTCDATE())

UNION ALL

SELECT 
    'RESOURCE_USAGE',
    'LOG_IO_PERCENT',
    avg_log_write_percent,
    'Last hour average'
FROM sys.dm_db_resource_stats
WHERE end_time > DATEADD(hour, -1, GETUTCDATE());

-- Información de la base de datos actual
SELECT 
    'DATABASE_CONFIG' as ConfigType,
    DB_NAME() as DatabaseName,
    DATABASEPROPERTYEX(DB_NAME(), 'Status') as Status,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') as Collation,
    DATABASEPROPERTYEX(DB_NAME(), 'Edition') as Edition,
    DATABASEPROPERTYEX(DB_NAME(), 'ServiceObjective') as ServiceTier,
    compatibility_level,
    create_date
FROM sys.databases
WHERE name = DB_NAME();

PRINT '✅ ANÁLISIS DE RECURSOS COMPLETADO';
