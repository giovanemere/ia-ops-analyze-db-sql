-- =====================================================
-- ANÁLISIS DE INFRAESTRUCTURA Y RECURSOS DEL SISTEMA
-- CPU, Memoria, I/O, Configuración del Servidor
-- =====================================================

-- 1. INFORMACIÓN GENERAL DEL SERVIDOR
SELECT 
    'SERVER_INFO' as SECTION,
    @@SERVERNAME as SERVER_NAME,
    @@VERSION as SQL_VERSION,
    SERVERPROPERTY('ProductVersion') as PRODUCT_VERSION,
    SERVERPROPERTY('ProductLevel') as PRODUCT_LEVEL,
    SERVERPROPERTY('Edition') as EDITION,
    SERVERPROPERTY('EngineEdition') as ENGINE_EDITION,
    SERVERPROPERTY('MachineName') as MACHINE_NAME,
    SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as PHYSICAL_NAME,
    SERVERPROPERTY('IsClustered') as IS_CLUSTERED,
    SERVERPROPERTY('IsHadrEnabled') as IS_HADR_ENABLED,
    GETDATE() as ANALYSIS_TIME;

-- 2. CONFIGURACIÓN DE CPU
SELECT 
    'CPU_CONFIG' as SECTION,
    cpu_count as LOGICAL_CPU_COUNT,
    hyperthread_ratio as HYPERTHREAD_RATIO,
    cpu_count / hyperthread_ratio as PHYSICAL_CPU_COUNT,
    physical_memory_kb / 1024 as PHYSICAL_MEMORY_MB,
    virtual_memory_kb / 1024 as VIRTUAL_MEMORY_MB,
    committed_kb / 1024 as COMMITTED_MEMORY_MB,
    committed_target_kb / 1024 as COMMITTED_TARGET_MB,
    visible_target_kb / 1024 as VISIBLE_TARGET_MB,
    stack_size_in_bytes / 1024 as STACK_SIZE_KB,
    os_quantum as OS_QUANTUM,
    os_error_mode as OS_ERROR_MODE,
    os_priority_class as OS_PRIORITY_CLASS
FROM sys.dm_os_sys_info;

-- 3. ESTADÍSTICAS DE CPU EN TIEMPO REAL
SELECT 
    'CPU_USAGE' as SECTION,
    record_id,
    DATEADD(ms, -1 * ((SELECT cpu_ticks / (cpu_ticks / ms_ticks) FROM sys.dm_os_sys_info) - [timestamp]), GETDATE()) as EVENT_TIME,
    SQLProcessUtilization as SQL_CPU_USAGE,
    SystemIdle as SYSTEM_IDLE,
    100 - SystemIdle - SQLProcessUtilization as OTHER_PROCESS_CPU_USAGE
FROM (
    SELECT 
        record.value('(./Record/@id)[1]', 'int') as record_id,
        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle,
        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQLProcessUtilization,
        timestamp
    FROM (
        SELECT timestamp, CONVERT(xml, record) as record 
        FROM sys.dm_os_ring_buffers 
        WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
        AND record LIKE '%<SystemHealth>%'
    ) as x
) as y 
ORDER BY record_id DESC;

-- 4. MEMORIA DEL SISTEMA
SELECT 
    'MEMORY_USAGE' as SECTION,
    type as MEMORY_TYPE,
    SUM(pages_kb) / 1024 as MEMORY_MB,
    SUM(pages_kb) * 100.0 / (SELECT SUM(pages_kb) FROM sys.dm_os_memory_clerks) as PERCENTAGE
FROM sys.dm_os_memory_clerks
GROUP BY type
HAVING SUM(pages_kb) > 1024
ORDER BY SUM(pages_kb) DESC;

-- 5. CONTADORES DE RENDIMIENTO CRÍTICOS
SELECT 
    'PERFORMANCE_COUNTERS' as SECTION,
    object_name as OBJECT_NAME,
    counter_name as COUNTER_NAME,
    instance_name as INSTANCE_NAME,
    cntr_value as COUNTER_VALUE,
    cntr_type as COUNTER_TYPE,
    CASE 
        WHEN counter_name LIKE '%CPU%' THEN 'CPU'
        WHEN counter_name LIKE '%Memory%' OR counter_name LIKE '%Buffer%' THEN 'MEMORY'
        WHEN counter_name LIKE '%Disk%' OR counter_name LIKE '%I/O%' THEN 'DISK'
        WHEN counter_name LIKE '%Network%' THEN 'NETWORK'
        ELSE 'OTHER'
    END as CATEGORY
FROM sys.dm_os_performance_counters
WHERE (
    counter_name IN (
        'Buffer cache hit ratio',
        'Page life expectancy',
        'Lazy writes/sec',
        'Page reads/sec',
        'Page writes/sec',
        'Checkpoint pages/sec',
        'Memory Grants Pending',
        'Target Server Memory (KB)',
        'Total Server Memory (KB)',
        'SQL Compilations/sec',
        'SQL Re-Compilations/sec',
        'Batch Requests/sec',
        'Logins/sec',
        'Logouts/sec',
        'User Connections',
        'Lock Waits/sec',
        'Lock Wait Time (ms)',
        'Number of Deadlocks/sec',
        'Transactions/sec'
    )
    OR object_name LIKE '%Buffer Manager%'
    OR object_name LIKE '%Memory Manager%'
    OR object_name LIKE '%SQL Statistics%'
)
ORDER BY CATEGORY, object_name, counter_name;

-- 6. ESTADÍSTICAS DE I/O POR BASE DE DATOS
SELECT 
    'DATABASE_IO' as SECTION,
    DB_NAME(database_id) as DATABASE_NAME,
    SUM(num_of_reads) as TOTAL_READS,
    SUM(num_of_writes) as TOTAL_WRITES,
    SUM(num_of_bytes_read) / 1024 / 1024 as TOTAL_READ_MB,
    SUM(num_of_bytes_written) / 1024 / 1024 as TOTAL_WRITTEN_MB,
    SUM(io_stall_read_ms) as TOTAL_READ_STALL_MS,
    SUM(io_stall_write_ms) as TOTAL_WRITE_STALL_MS,
    CASE 
        WHEN SUM(num_of_reads) = 0 THEN 0 
        ELSE SUM(io_stall_read_ms) / SUM(num_of_reads) 
    END as AVG_READ_STALL_MS,
    CASE 
        WHEN SUM(num_of_writes) = 0 THEN 0 
        ELSE SUM(io_stall_write_ms) / SUM(num_of_writes) 
    END as AVG_WRITE_STALL_MS
FROM sys.dm_io_virtual_file_stats(NULL, NULL)
WHERE database_id > 4  -- Excluir bases de datos del sistema
GROUP BY database_id
ORDER BY SUM(num_of_reads) + SUM(num_of_writes) DESC;

-- 7. ARCHIVOS DE BASE DE DATOS Y ESPACIO
SELECT 
    'DATABASE_FILES' as SECTION,
    DB_NAME() as DATABASE_NAME,
    f.name as FILE_NAME,
    f.type_desc as FILE_TYPE,
    f.physical_name as PHYSICAL_PATH,
    CAST(f.size * 8.0 / 1024 AS DECIMAL(10,2)) as SIZE_MB,
    CAST(f.max_size * 8.0 / 1024 AS DECIMAL(10,2)) as MAX_SIZE_MB,
    f.growth as GROWTH_SETTING,
    CASE 
        WHEN f.is_percent_growth = 1 THEN 'PERCENT'
        ELSE 'MB'
    END as GROWTH_TYPE,
    CAST(FILEPROPERTY(f.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(10,2)) as USED_MB,
    CAST((f.size - FILEPROPERTY(f.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(10,2)) as FREE_MB,
    CAST(FILEPROPERTY(f.name, 'SpaceUsed') * 100.0 / f.size AS DECIMAL(5,2)) as USED_PERCENT
FROM sys.database_files f
ORDER BY f.type, f.file_id;

-- 8. CONFIGURACIÓN DE SQL SERVER
SELECT 
    'SQL_CONFIG' as SECTION,
    name as CONFIG_NAME,
    value as CURRENT_VALUE,
    value_in_use as VALUE_IN_USE,
    minimum as MIN_VALUE,
    maximum as MAX_VALUE,
    is_dynamic as IS_DYNAMIC,
    is_advanced as IS_ADVANCED,
    description as DESCRIPTION
FROM sys.configurations
WHERE name IN (
    'max server memory (MB)',
    'min server memory (MB)',
    'max degree of parallelism',
    'cost threshold for parallelism',
    'optimize for ad hoc workloads',
    'backup compression default',
    'database mail XPs',
    'remote admin connections',
    'show advanced options'
)
ORDER BY name;
