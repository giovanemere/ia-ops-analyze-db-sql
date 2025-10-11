-- =====================================================
-- ANÁLISIS COMPLETO DE RENDIMIENTO
-- Identifica problemas específicos de la BD
-- =====================================================

-- 1. ANÁLISIS DE FRAGMENTACIÓN CRÍTICA
SELECT 
    'FRAGMENTATION_ANALYSIS' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    i.name as INDEX_NAME,
    ips.avg_fragmentation_in_percent as FRAGMENTATION_PERCENT,
    ips.page_count as PAGE_COUNT,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'CRÍTICO - REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'ALTO - REORGANIZE'
        ELSE 'OK'
    END as RECOMMENDATION,
    CASE 
        WHEN t.name = 'CuponesDigitales' THEN 'TABLA PRINCIPAL - PRIORIDAD ALTA'
        WHEN t.name = 'CuponesFisicoCorreccion' THEN 'TABLA PRINCIPAL - PRIORIDAD ALTA'
        WHEN t.name = 'GeneralEstadosCuyOpClientePromocion' THEN 'TABLA IMPORTANTE - PRIORIDAD MEDIA'
        ELSE 'PRIORIDAD BAJA'
    END as PRIORITY
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.tables t ON ips.object_id = t.object_id
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE t.is_ms_shipped = 0 AND ips.avg_fragmentation_in_percent > 5
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- 2. ANÁLISIS DE CONSULTAS COSTOSAS
SELECT TOP 10
    'EXPENSIVE_QUERIES' as SECTION,
    qs.total_elapsed_time / qs.execution_count as AVG_ELAPSED_TIME_MS,
    qs.total_worker_time / qs.execution_count as AVG_CPU_TIME_MS,
    qs.total_logical_reads / qs.execution_count as AVG_LOGICAL_READS,
    qs.execution_count as EXECUTION_COUNT,
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

-- 3. ÍNDICES FALTANTES CRÍTICOS
SELECT 
    'MISSING_INDEXES' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    mid.equality_columns as EQUALITY_COLUMNS,
    mid.inequality_columns as INEQUALITY_COLUMNS,
    mid.included_columns as INCLUDED_COLUMNS,
    migs.user_seeks as USER_SEEKS,
    migs.avg_total_user_cost as AVG_TOTAL_USER_COST,
    migs.avg_user_impact as AVG_USER_IMPACT,
    (migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) as IMPROVEMENT_MEASURE,
    CASE 
        WHEN t.name IN ('CuponesDigitales', 'CuponesFisicoCorreccion') THEN 'CRÍTICO'
        WHEN t.name = 'GeneralEstadosCuyOpClientePromocion' THEN 'ALTO'
        ELSE 'MEDIO'
    END as PRIORITY
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
INNER JOIN sys.tables t ON mid.object_id = t.object_id
WHERE mid.database_id = DB_ID()
ORDER BY (migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) DESC;

-- 4. ESTADÍSTICAS DESACTUALIZADAS
SELECT 
    'OUTDATED_STATISTICS' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    s.name as STATS_NAME,
    STATS_DATE(s.object_id, s.stats_id) as LAST_UPDATED,
    DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) as DAYS_OLD,
    CASE 
        WHEN DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) > 7 THEN 'CRÍTICO - Actualizar'
        WHEN DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) > 3 THEN 'ALTO - Actualizar'
        ELSE 'OK'
    END as RECOMMENDATION
FROM sys.stats s
INNER JOIN sys.tables t ON s.object_id = t.object_id
WHERE t.is_ms_shipped = 0
    AND STATS_DATE(s.object_id, s.stats_id) IS NOT NULL
ORDER BY DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) DESC;

-- 2. Consultas más costosas (requiere Query Store habilitado)
SELECT TOP 10
    qt.query_sql_text,
    rs.avg_duration/1000 as avg_duration_ms,
    rs.avg_cpu_time/1000 as avg_cpu_time_ms,
    rs.avg_logical_io_reads,
    rs.count_executions
FROM sys.query_store_query_text qt
INNER JOIN sys.query_store_query q ON qt.query_text_id = q.query_text_id
INNER JOIN sys.query_store_runtime_stats rs ON q.query_id = rs.query_id
WHERE rs.avg_duration > 1000000 -- > 1 segundo
ORDER BY rs.avg_duration DESC;

-- 3. Estadísticas de fragmentación
SELECT 
    OBJECT_NAME(ips.object_id) AS Tabla,
    i.name AS Indice,
    ips.avg_fragmentation_in_percent AS Fragmentacion_Pct,
    ips.page_count AS Total_Paginas,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END AS Accion_Recomendada
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
AND ips.page_count > 1000
ORDER BY ips.avg_fragmentation_in_percent DESC;
