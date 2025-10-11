-- =====================================================
-- ANÁLISIS DE ALMACENAMIENTO Y I/O
-- Discos, latencia, throughput, espacio
-- =====================================================

-- 1. ESTADÍSTICAS DETALLADAS DE I/O POR ARCHIVO
SELECT 
    'FILE_IO_STATS' as SECTION,
    DB_NAME(vfs.database_id) as DATABASE_NAME,
    mf.name as FILE_NAME,
    mf.type_desc as FILE_TYPE,
    mf.physical_name as PHYSICAL_PATH,
    vfs.num_of_reads as TOTAL_READS,
    vfs.num_of_writes as TOTAL_WRITES,
    vfs.num_of_bytes_read / 1024 / 1024 as TOTAL_READ_MB,
    vfs.num_of_bytes_written / 1024 / 1024 as TOTAL_WRITTEN_MB,
    vfs.io_stall_read_ms as TOTAL_READ_STALL_MS,
    vfs.io_stall_write_ms as TOTAL_WRITE_STALL_MS,
    vfs.io_stall as TOTAL_IO_STALL_MS,
    CASE 
        WHEN vfs.num_of_reads = 0 THEN 0 
        ELSE vfs.io_stall_read_ms / vfs.num_of_reads 
    END as AVG_READ_STALL_MS,
    CASE 
        WHEN vfs.num_of_writes = 0 THEN 0 
        ELSE vfs.io_stall_write_ms / vfs.num_of_writes 
    END as AVG_WRITE_STALL_MS,
    CASE 
        WHEN (vfs.num_of_reads + vfs.num_of_writes) = 0 THEN 0 
        ELSE vfs.io_stall / (vfs.num_of_reads + vfs.num_of_writes) 
    END as AVG_IO_STALL_MS,
    vfs.size_on_disk_bytes / 1024 / 1024 as SIZE_ON_DISK_MB
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
INNER JOIN sys.master_files mf ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
WHERE vfs.database_id = DB_ID()
ORDER BY vfs.io_stall DESC;

-- 2. ANÁLISIS DE LATENCIA POR TIPO DE OPERACIÓN
SELECT 
    'IO_LATENCY_ANALYSIS' as SECTION,
    'READ' as OPERATION_TYPE,
    COUNT(*) as FILE_COUNT,
    SUM(num_of_reads) as TOTAL_OPERATIONS,
    SUM(num_of_bytes_read) / 1024 / 1024 as TOTAL_MB,
    SUM(io_stall_read_ms) as TOTAL_STALL_MS,
    AVG(CASE WHEN num_of_reads = 0 THEN 0 ELSE io_stall_read_ms / num_of_reads END) as AVG_LATENCY_MS,
    MIN(CASE WHEN num_of_reads = 0 THEN 0 ELSE io_stall_read_ms / num_of_reads END) as MIN_LATENCY_MS,
    MAX(CASE WHEN num_of_reads = 0 THEN 0 ELSE io_stall_read_ms / num_of_reads END) as MAX_LATENCY_MS
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL)
WHERE num_of_reads > 0

UNION ALL

SELECT 
    'IO_LATENCY_ANALYSIS' as SECTION,
    'write' as OPERATION_TYPE,
    COUNT(*) as FILE_COUNT,
    SUM(num_of_writes) as TOTAL_OPERATIONS,
    SUM(num_of_bytes_written) / 1024 / 1024 as TOTAL_MB,
    SUM(io_stall_write_ms) as TOTAL_STALL_MS,
    AVG(CASE WHEN num_of_writes = 0 THEN 0 ELSE io_stall_write_ms / num_of_writes END) as AVG_LATENCY_MS,
    MIN(CASE WHEN num_of_writes = 0 THEN 0 ELSE io_stall_write_ms / num_of_writes END) as MIN_LATENCY_MS,
    MAX(CASE WHEN num_of_writes = 0 THEN 0 ELSE io_stall_write_ms / num_of_writes END) as MAX_LATENCY_MS
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL)
WHERE num_of_writes > 0;

-- 3. ESPACIO EN DISCO Y CRECIMIENTO
SELECT 
    'DISK_SPACE_ANALYSIS' as SECTION,
    f.name as FILE_NAME,
    f.type_desc as FILE_TYPE,
    f.physical_name as PHYSICAL_PATH,
    CAST(f.size * 8.0 / 1024 AS DECIMAL(12,2)) as CURRENT_SIZE_MB,
    CAST(f.size * 8.0 / 1024 / 1024 AS DECIMAL(12,2)) as CURRENT_SIZE_GB,
    CASE 
        WHEN f.max_size = -1 THEN 'UNLIMITED'
        WHEN f.max_size = 268435456 THEN 'UNLIMITED'
        ELSE CAST(f.max_size * 8.0 / 1024 AS VARCHAR(20))
    END as MAX_SIZE_MB,
    CASE 
        WHEN f.is_percent_growth = 1 THEN CAST(f.growth AS VARCHAR(10)) + '%'
        ELSE CAST(f.growth * 8.0 / 1024 AS VARCHAR(20)) + ' MB'
    END as GROWTH_SETTING,
    CAST(FILEPROPERTY(f.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(12,2)) as USED_SPACE_MB,
    CAST((f.size - FILEPROPERTY(f.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(12,2)) as FREE_SPACE_MB,
    CAST(FILEPROPERTY(f.name, 'SpaceUsed') * 100.0 / f.size AS DECIMAL(5,2)) as USED_PERCENTAGE,
    f.state_desc as FILE_STATE
FROM sys.database_files f
ORDER BY f.type, CAST(f.size * 8.0 / 1024 AS DECIMAL(12,2)) DESC;

-- 4. ANÁLISIS DE TEMPDB (si aplica)
IF DB_NAME() = 'tempdb'
BEGIN
    SELECT 
        'TEMPDB_ANALYSIS' as SECTION,
        SUM(unallocated_extent_page_count) as UNALLOCATED_PAGES,
        SUM(version_store_reserved_page_count) as VERSION_STORE_PAGES,
        SUM(internal_object_reserved_page_count) as INTERNAL_OBJECT_PAGES,
        SUM(user_object_reserved_page_count) as USER_OBJECT_PAGES,
        SUM(mixed_extent_page_count) as MIXED_EXTENT_PAGES,
        SUM(unallocated_extent_page_count) * 8 / 1024 as UNALLOCATED_MB,
        SUM(version_store_reserved_page_count) * 8 / 1024 as VERSION_STORE_MB,
        SUM(internal_object_reserved_page_count) * 8 / 1024 as INTERNAL_OBJECT_MB,
        SUM(user_object_reserved_page_count) * 8 / 1024 as USER_OBJECT_MB
    FROM sys.dm_db_file_space_usage;
END

-- 5. BUFFER POOL Y CACHE
SELECT 
    'BUFFER_POOL_USAGE' as SECTION,
    COUNT(*) as TOTAL_PAGES,
    COUNT(*) * 8 / 1024 as TOTAL_MB,
    SUM(CASE WHEN is_modified = 1 THEN 1 ELSE 0 END) as DIRTY_PAGES,
    SUM(CASE WHEN is_modified = 1 THEN 1 ELSE 0 END) * 8 / 1024 as DIRTY_MB,
    SUM(CASE WHEN is_modified = 0 THEN 1 ELSE 0 END) as CLEAN_PAGES,
    SUM(CASE WHEN is_modified = 0 THEN 1 ELSE 0 END) * 8 / 1024 as CLEAN_MB,
    CAST(SUM(CASE WHEN is_modified = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as DIRTY_PERCENTAGE
FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID();

-- 6. PÁGINAS EN BUFFER POR OBJETO
SELECT TOP 20
    'BUFFER_USAGE_BY_OBJECT' as SECTION,
    OBJECT_SCHEMA_NAME(p.object_id) as SCHEMA_NAME,
    OBJECT_NAME(p.object_id) as OBJECT_NAME,
    p.index_id as INDEX_ID,
    i.name as INDEX_NAME,
    i.type_desc as INDEX_TYPE,
    COUNT(*) as PAGES_IN_BUFFER,
    COUNT(*) * 8 / 1024 as MB_IN_BUFFER,
    SUM(CASE WHEN bd.is_modified = 1 THEN 1 ELSE 0 END) as DIRTY_PAGES,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sys.dm_os_buffer_descriptors WHERE database_id = DB_ID()) AS DECIMAL(5,2)) as PERCENTAGE_OF_BUFFER
FROM sys.dm_os_buffer_descriptors bd
INNER JOIN sys.allocation_units au ON bd.allocation_unit_id = au.allocation_unit_id
INNER JOIN sys.partitions p ON au.container_id = p.hobt_id
LEFT JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
WHERE bd.database_id = DB_ID()
    AND p.object_id > 100
GROUP BY p.object_id, p.index_id, i.name, i.type_desc
ORDER BY COUNT(*) DESC;

-- 7. ESTADÍSTICAS DE CHECKPOINT
SELECT 
    'CHECKPOINT_STATS' as SECTION,
    cntr_value as CHECKPOINT_PAGES_SEC
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Checkpoint pages/sec'
    AND instance_name = DB_NAME();

-- 8. ANÁLISIS DE FRAGMENTACIÓN DE ARCHIVOS
SELECT 
    'FILE_FRAGMENTATION' as SECTION,
    f.name as FILE_NAME,
    f.type_desc as FILE_TYPE,
    f.physical_name as PHYSICAL_PATH,
    fg.name as FILEGROUP_NAME,
    fg.type_desc as FILEGROUP_TYPE,
    fg.is_default as IS_DEFAULT_FILEGROUP,
    fg.is_read_only as IS_READ_ONLY,
    CASE 
        WHEN f.growth = 0 THEN 'FIXED'
        WHEN f.is_percent_growth = 1 THEN 'PERCENTAGE'
        ELSE 'ABSOLUTE'
    END as GROWTH_TYPE
FROM sys.database_files f
LEFT JOIN sys.filegroups fg ON f.data_space_id = fg.data_space_id
ORDER BY f.type, f.file_id;
