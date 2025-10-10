-- Análisis de Rendimiento y Consultas Lentas
USE [persqldbmotorpromocprd];

-- 1. Identificar tablas sin índices adecuados
SELECT 
    t.name AS Tabla,
    p.rows AS Registros,
    COUNT(i.index_id) AS Total_Indices,
    CASE 
        WHEN p.rows > 1000000 AND COUNT(i.index_id) <= 1 THEN 'CRÍTICO - Falta índices'
        WHEN p.rows > 100000 AND COUNT(i.index_id) <= 2 THEN 'ALTO - Pocos índices'
        ELSE 'OK'
    END AS Estado_Indices
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.index_id > 1
WHERE t.is_ms_shipped = 0
GROUP BY t.name, p.rows
ORDER BY p.rows DESC;

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
