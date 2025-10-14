-- =====================================================
-- ANÁLISIS DE ALMACENAMIENTO Y I/O
-- Espacio, latencia, estadísticas de I/O
-- =====================================================

PRINT '💾 ANÁLISIS DE ALMACENAMIENTO Y I/O';
PRINT '==================================';

-- Uso de espacio de la base de datos
SELECT 
    'DATABASE_SPACE' as SpaceType,
    DB_NAME() as DatabaseName,
    type_desc as FileType,
    name as LogicalName,
    physical_name as PhysicalName,
    CAST(size * 8.0 / 1024 AS DECIMAL(10,2)) as SizeMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(10,2)) as UsedMB,
    CAST((size - FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(10,2)) as FreeMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') * 100.0 / size AS DECIMAL(5,2)) as UsedPercent
FROM sys.database_files;

-- Estadísticas de I/O por archivo
SELECT 
    'FILE_IO_STATS' as IOType,
    DB_NAME() as DatabaseName,
    df.name as LogicalName,
    df.type_desc as FileType,
    vfs.num_of_reads,
    vfs.num_of_writes,
    vfs.num_of_bytes_read / 1024 / 1024 as MBRead,
    vfs.num_of_bytes_written / 1024 / 1024 as MBWritten,
    vfs.io_stall_read_ms,
    vfs.io_stall_write_ms,
    CASE 
        WHEN vfs.num_of_reads > 0 
        THEN vfs.io_stall_read_ms / vfs.num_of_reads 
        ELSE 0 
    END as AvgReadLatencyMs,
    CASE 
        WHEN vfs.num_of_writes > 0 
        THEN vfs.io_stall_write_ms / vfs.num_of_writes 
        ELSE 0 
    END as AvgWriteLatencyMs
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) vfs
JOIN sys.database_files df ON vfs.file_id = df.file_id;

-- Uso de espacio por tabla
SELECT TOP 20
    'TABLE_SPACE_USAGE' as UsageType,
    t.name as TableName,
    p.rows as RowCount,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as TotalSpaceMB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as UsedSpaceMB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) as UnusedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.object_id > 255
GROUP BY t.name, p.rows
ORDER BY SUM(a.total_pages) DESC;

-- Estadísticas de espera relacionadas con I/O
SELECT TOP 10
    'IO_WAIT_STATS' as WaitType,
    wait_type,
    waiting_tasks_count,
    CAST(wait_time_ms / 1000.0 AS DECIMAL(12, 2)) as WaitTimeSeconds,
    CAST(wait_time_ms / waiting_tasks_count AS DECIMAL(12, 2)) as AvgWaitTimeMs,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS DECIMAL(5, 2)) as PercentageOfTotal
FROM sys.dm_os_wait_stats
WHERE wait_type LIKE 'PAGEIOLATCH%'
    OR wait_type LIKE 'WRITELOG%'
    OR wait_type LIKE 'LOGBUFFER%'
    OR wait_type LIKE 'IO_COMPLETION%'
    OR wait_type LIKE 'ASYNC_IO_COMPLETION%'
ORDER BY wait_time_ms DESC;

-- Información de índices y su uso de espacio
SELECT TOP 15
    'INDEX_SPACE_USAGE' as IndexType,
    OBJECT_NAME(i.object_id) as TableName,
    i.name as IndexName,
    i.type_desc as IndexType,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    CAST(ips.page_count * 8.0 / 1024 AS DECIMAL(10,2)) as IndexSizeMB
FROM sys.indexes i
JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips 
    ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE i.name IS NOT NULL
    AND ips.page_count > 100
ORDER BY ips.page_count DESC;

PRINT '✅ ANÁLISIS DE ALMACENAMIENTO COMPLETADO';
