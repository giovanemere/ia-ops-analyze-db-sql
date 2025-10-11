-- Análisis simplificado de fragmentación
SELECT 
    'FRAGMENTATION' as AnalysisType,
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'HIGH'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS FragLevel
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE i.name IS NOT NULL
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Resumen de fragmentación
SELECT 
    'SUMMARY' as SummaryType,
    COUNT(*) as TotalIndexes,
    SUM(CASE WHEN ips.avg_fragmentation_in_percent > 30 THEN 1 ELSE 0 END) as HighFragmentation,
    SUM(CASE WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN 1 ELSE 0 END) as MediumFragmentation,
    AVG(ips.avg_fragmentation_in_percent) as AvgFragmentation
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE i.name IS NOT NULL;
