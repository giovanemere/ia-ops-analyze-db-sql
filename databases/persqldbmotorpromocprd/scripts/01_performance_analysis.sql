-- =====================================================
-- ANÁLISIS DE RENDIMIENTO (SIN QUERY STORE)
-- Análisis completo sin dependencia de Query Store
-- =====================================================

PRINT '🔍 INICIANDO ANÁLISIS DE RENDIMIENTO';
PRINT '====================================';

-- Información básica de la base de datos
PRINT '📊 INFORMACIÓN BÁSICA DE LA BASE DE DATOS';
SELECT 
    'DATABASE_INFO' as InfoType,
    DB_NAME() as DatabaseName,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') as Collation,
    DATABASEPROPERTYEX(DB_NAME(), 'Edition') as Edition,
    DATABASEPROPERTYEX(DB_NAME(), 'ServiceObjective') as ServiceTier,
    DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeInBytes') as MaxSizeBytes,
    create_date,
    compatibility_level
FROM sys.databases 
WHERE name = DB_NAME();

-- Análisis de fragmentación de índices
PRINT '🔧 ANÁLISIS DE FRAGMENTACIÓN DE ÍNDICES';
SELECT 
    'FRAGMENTATION_ANALYSIS' as AnalysisType,
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 AND ips.page_count > 1000 THEN 'REBUILD NEEDED'
        WHEN ips.avg_fragmentation_in_percent > 10 AND ips.page_count > 1000 THEN 'REORGANIZE NEEDED'
        ELSE 'OK'
    END AS RecommendedAction
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 5
    AND i.name IS NOT NULL
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Estadísticas desactualizadas
PRINT '📈 ESTADÍSTICAS DESACTUALIZADAS';
SELECT 
    'STATISTICS_ANALYSIS' as AnalysisType,
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatsName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated,
    DATEDIFF(day, STATS_DATE(s.object_id, s.stats_id), GETDATE()) AS DaysOld,
    CASE 
        WHEN STATS_DATE(s.object_id, s.stats_id) IS NULL THEN 'NEVER UPDATED'
        WHEN DATEDIFF(day, STATS_DATE(s.object_id, s.stats_id), GETDATE()) > 30 THEN 'CRITICAL - UPDATE NEEDED'
        WHEN DATEDIFF(day, STATS_DATE(s.object_id, s.stats_id), GETDATE()) > 7 THEN 'UPDATE RECOMMENDED'
        ELSE 'OK'
    END AS Status
FROM sys.stats s
JOIN sys.objects o ON s.object_id = o.object_id
WHERE o.type = 'U'
    AND (STATS_DATE(s.object_id, s.stats_id) IS NULL 
         OR STATS_DATE(s.object_id, s.stats_id) < DATEADD(day, -7, GETDATE()))
ORDER BY DaysOld DESC;

-- Análisis de tablas grandes
PRINT '📊 ANÁLISIS DE TABLAS GRANDES';
SELECT 
    'TABLE_SIZE_ANALYSIS' as AnalysisType,
    t.name AS TableName,
    p.rows AS RowCount,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB,
    CASE 
        WHEN p.rows > 10000000 THEN 'VERY LARGE'
        WHEN p.rows > 1000000 THEN 'LARGE'
        WHEN p.rows > 100000 THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS TableSize
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.object_id > 255
GROUP BY t.name, s.name, p.rows
HAVING p.rows > 1000
ORDER BY p.rows DESC;

-- Índices faltantes sugeridos por SQL Server
PRINT '🔍 ÍNDICES FALTANTES SUGERIDOS';
SELECT 
    'MISSING_INDEXES' as AnalysisType,
    OBJECT_NAME(mid.object_id) AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,
    'CREATE INDEX IX_' + OBJECT_NAME(mid.object_id) + '_Missing_' + CAST(mid.index_handle AS VARCHAR(10)) + 
    ' ON ' + OBJECT_NAME(mid.object_id) + 
    ' (' + ISNULL(mid.equality_columns, '') + 
    CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END +
    ISNULL(mid.inequality_columns, '') + ')' +
    ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS CreateIndexStatement
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 10
ORDER BY improvement_measure DESC;

-- Análisis de esperas (Wait Stats)
PRINT '⏳ ANÁLISIS DE ESPERAS (WAIT STATS)';
WITH WaitStats AS (
    SELECT 
        wait_type,
        wait_time_ms,
        waiting_tasks_count,
        signal_wait_time_ms,
        wait_time_ms - signal_wait_time_ms AS resource_wait_time_ms
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
        'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
        'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
        'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
        'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
        'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT',
        'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
    )
    AND wait_time_ms > 0
)
SELECT TOP 10
    'WAIT_STATS_ANALYSIS' as AnalysisType,
    wait_type,
    CAST(wait_time_ms / 1000.0 AS DECIMAL(12, 2)) AS wait_time_seconds,
    waiting_tasks_count,
    CAST(wait_time_ms / waiting_tasks_count AS DECIMAL(12, 2)) AS avg_wait_time_ms,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS DECIMAL(5, 2)) AS percentage,
    CASE wait_type
        WHEN 'PAGEIOLATCH_SH' THEN 'Disk I/O - Reading data pages'
        WHEN 'PAGEIOLATCH_EX' THEN 'Disk I/O - Writing data pages'
        WHEN 'LCK_M_S' THEN 'Lock waits - Shared locks'
        WHEN 'LCK_M_X' THEN 'Lock waits - Exclusive locks'
        WHEN 'CXPACKET' THEN 'Parallelism - Query coordination'
        WHEN 'SOS_SCHEDULER_YIELD' THEN 'CPU pressure - Scheduler yields'
        WHEN 'WRITELOG' THEN 'Log I/O - Transaction log writes'
        ELSE 'Other wait type'
    END AS wait_description
FROM WaitStats
ORDER BY wait_time_ms DESC;

-- Verificar configuración de Query Store
PRINT '🗃️ CONFIGURACIÓN DE QUERY STORE';
SELECT 
    'QUERY_STORE_CONFIG' as ConfigType,
    actual_state_desc as CurrentState,
    readonly_reason_desc as ReadOnlyReason,
    desired_state_desc as DesiredState,
    current_storage_size_mb,
    max_storage_size_mb,
    flush_interval_seconds,
    interval_length_minutes,
    max_plans_per_query,
    query_capture_mode_desc,
    size_based_cleanup_mode_desc
FROM sys.database_query_store_options;

-- Resumen de recomendaciones
PRINT '💡 RESUMEN DE RECOMENDACIONES';
SELECT 
    'RECOMMENDATIONS_SUMMARY' as SummaryType,
    'HIGH_PRIORITY' as Priority,
    'Rebuild highly fragmented indexes (>30%)' as Recommendation,
    (SELECT COUNT(*) FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
     JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
     WHERE ips.avg_fragmentation_in_percent > 30 AND ips.page_count > 1000 AND i.name IS NOT NULL) as AffectedObjects

UNION ALL

SELECT 
    'RECOMMENDATIONS_SUMMARY',
    'MEDIUM_PRIORITY',
    'Update outdated statistics (>7 days)',
    (SELECT COUNT(*) FROM sys.stats s
     JOIN sys.objects o ON s.object_id = o.object_id
     WHERE o.type = 'U' AND STATS_DATE(s.object_id, s.stats_id) < DATEADD(day, -7, GETDATE()))

UNION ALL

SELECT 
    'RECOMMENDATIONS_SUMMARY',
    'LOW_PRIORITY',
    'Consider creating missing indexes',
    (SELECT COUNT(*) FROM sys.dm_db_missing_index_groups mig
     INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
     WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 10);

PRINT '✅ ANÁLISIS DE RENDIMIENTO COMPLETADO';
PRINT '======================================';
