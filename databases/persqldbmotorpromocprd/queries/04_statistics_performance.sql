-- =====================================================
-- ESTADÍSTICAS Y RENDIMIENTO DE LA BASE DE DATOS
-- Estadísticas, fragmentación, uso de espacio, etc.
-- =====================================================

-- 1. ESTADÍSTICAS DE TABLAS
SELECT 
    'TABLE_STATISTICS' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    s.name as STATS_NAME,
    s.stats_id as STATS_ID,
    s.auto_created as IS_AUTO_CREATED,
    s.user_created as IS_USER_CREATED,
    s.no_recompute as NO_RECOMPUTE,
    s.has_filter as HAS_FILTER,
    s.filter_definition as FILTER_DEFINITION,
    STATS_DATE(s.object_id, s.stats_id) as LAST_UPDATED,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY sc.stats_column_id) as COLUMNS
FROM sys.stats s
INNER JOIN sys.tables t ON s.object_id = t.object_id
INNER JOIN sys.stats_columns sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
INNER JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id
WHERE t.is_ms_shipped = 0
GROUP BY t.schema_id, t.name, s.name, s.stats_id, s.auto_created, s.user_created, 
         s.no_recompute, s.has_filter, s.filter_definition, s.object_id
ORDER BY SCHEMA_NAME(t.schema_id), t.name, s.name;

-- 2. FRAGMENTACIÓN DE ÍNDICES
SELECT 
    'INDEX_FRAGMENTATION' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    i.name as INDEX_NAME,
    i.type_desc as INDEX_TYPE,
    ips.avg_fragmentation_in_percent as FRAGMENTATION_PERCENT,
    ips.fragment_count as FRAGMENT_COUNT,
    ips.page_count as PAGE_COUNT,
    ips.avg_page_space_used_in_percent as AVG_PAGE_SPACE_USED,
    ips.record_count as RECORD_COUNT,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END as RECOMMENDATION
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.tables t ON ips.object_id = t.object_id
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE t.is_ms_shipped = 0 AND i.index_id > 0
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- 3. USO DE ESPACIO POR TABLA
SELECT 
    'SPACE_USAGE' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    p.rows as ROW_COUNT,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as TOTAL_SPACE_MB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as USED_SPACE_MB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) as UNUSED_SPACE_MB,
    CAST(ROUND(((SUM(a.data_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as DATA_SPACE_MB,
    CAST(ROUND(((SUM(a.used_pages) - SUM(a.data_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) as INDEX_SPACE_MB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 AND i.object_id > 255
GROUP BY t.schema_id, t.name, p.rows
ORDER BY CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) DESC;

-- 4. ÍNDICES FALTANTES (SUGERENCIAS)
SELECT 
    'MISSING_INDEXES' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    mid.equality_columns as EQUALITY_COLUMNS,
    mid.inequality_columns as INEQUALITY_COLUMNS,
    mid.included_columns as INCLUDED_COLUMNS,
    migs.unique_compiles as UNIQUE_COMPILES,
    migs.user_seeks as USER_SEEKS,
    migs.user_scans as USER_SCANS,
    migs.last_user_seek as LAST_USER_SEEK,
    migs.avg_total_user_cost as AVG_TOTAL_USER_COST,
    migs.avg_user_impact as AVG_USER_IMPACT,
    (migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) as IMPROVEMENT_MEASURE
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
INNER JOIN sys.tables t ON mid.object_id = t.object_id
WHERE mid.database_id = DB_ID()
ORDER BY (migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) DESC;

-- 5. ÍNDICES NO UTILIZADOS
SELECT 
    'UNUSED_INDEXES' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    i.name as INDEX_NAME,
    i.type_desc as INDEX_TYPE,
    ISNULL(ius.user_seeks, 0) as USER_SEEKS,
    ISNULL(ius.user_scans, 0) as USER_SCANS,
    ISNULL(ius.user_lookups, 0) as USER_LOOKUPS,
    ISNULL(ius.user_updates, 0) as USER_UPDATES,
    ius.last_user_seek as LAST_USER_SEEK,
    ius.last_user_scan as LAST_USER_SCAN,
    ius.last_user_lookup as LAST_USER_LOOKUP,
    ius.last_user_update as LAST_USER_UPDATE,
    CASE 
        WHEN ius.user_seeks + ius.user_scans + ius.user_lookups = 0 THEN 'NEVER_USED'
        WHEN ius.user_updates > (ius.user_seeks + ius.user_scans + ius.user_lookups) * 2 THEN 'RARELY_USED'
        ELSE 'USED'
    END as USAGE_STATUS
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
LEFT JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = DB_ID()
WHERE t.is_ms_shipped = 0 AND i.index_id > 0 AND i.is_primary_key = 0 AND i.is_unique_constraint = 0
ORDER BY ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) ASC;

-- 6. CONSULTAS MÁS COSTOSAS
SELECT TOP 20
    'EXPENSIVE_QUERIES' as SECTION,
    qs.sql_handle,
    qs.plan_handle,
    qs.total_elapsed_time / qs.execution_count as AVG_ELAPSED_TIME_MS,
    qs.total_worker_time / qs.execution_count as AVG_CPU_TIME_MS,
    qs.total_logical_reads / qs.execution_count as AVG_LOGICAL_READS,
    qs.total_physical_reads / qs.execution_count as AVG_PHYSICAL_READS,
    qs.execution_count as EXECUTION_COUNT,
    qs.creation_time as PLAN_CREATION_TIME,
    qs.last_execution_time as LAST_EXECUTION_TIME,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) as QUERY_TEXT
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.dbid = DB_ID()
ORDER BY qs.total_elapsed_time / qs.execution_count DESC;

-- 7. ESPERAS MÁS COMUNES
SELECT TOP 20
    'WAIT_STATISTICS' as SECTION,
    wait_type as WAIT_TYPE,
    waiting_tasks_count as WAITING_TASKS_COUNT,
    wait_time_ms as TOTAL_WAIT_TIME_MS,
    max_wait_time_ms as MAX_WAIT_TIME_MS,
    signal_wait_time_ms as SIGNAL_WAIT_TIME_MS,
    wait_time_ms - signal_wait_time_ms as RESOURCE_WAIT_TIME_MS,
    CASE 
        WHEN waiting_tasks_count = 0 THEN 0
        ELSE wait_time_ms / waiting_tasks_count
    END as AVG_WAIT_TIME_MS
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
    'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
    'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
    'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
    'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
    'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN'
)
ORDER BY wait_time_ms DESC;
