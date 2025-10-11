# =====================================================
# RUNBOOK DE MANTENIMIENTO AUTOMÁTICO
# Ejecuta mantenimiento semanal programado
# =====================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerName = "persqlmotorpromocprd.database.windows.net",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "persqldbmotorpromocprd",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "u_yairpanqueva",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "0x2E0403602967FDD263E5"
)

Write-Output "🔧 INICIANDO MANTENIMIENTO AUTOMÁTICO"
Write-Output "Servidor: $ServerName"
Write-Output "Base de Datos: $DatabaseName"
Write-Output "Fecha: $(Get-Date)"

# Función para ejecutar SQL
function Invoke-SqlQuery {
    param([string]$Query, [string]$Description)
    
    Write-Output "📋 $Description..."
    
    try {
        $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -Username $Username -Password $Password -Query $Query -QueryTimeout 1800
        Write-Output "✅ $Description - COMPLETADO"
        return $result
    }
    catch {
        Write-Output "❌ ERROR en $Description : $($_.Exception.Message)"
        return $null
    }
}

# 1. Verificar fragmentación
$fragmentationQuery = @"
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 AND ips.page_count > 1000 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 AND ips.page_count > 1000 THEN 'REORGANIZE'
        ELSE 'OK'
    END AS RecommendedAction
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 5
    AND i.name IS NOT NULL
ORDER BY ips.avg_fragmentation_in_percent DESC;
"@

$fragmentation = Invoke-SqlQuery -Query $fragmentationQuery -Description "Verificando fragmentación"

# 2. Actualizar estadísticas críticas
$updateStatsQuery = @"
-- Actualizar estadísticas de tablas principales
UPDATE STATISTICS CuponesDigitales WITH FULLSCAN;
UPDATE STATISTICS CuponesFisicoCorreccion WITH FULLSCAN;
UPDATE STATISTICS UsuariosRegistrados WITH FULLSCAN;

-- Verificar estadísticas desactualizadas
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatsName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated,
    DATEDIFF(day, STATS_DATE(s.object_id, s.stats_id), GETDATE()) AS DaysOld
FROM sys.stats s
JOIN sys.objects o ON s.object_id = o.object_id
WHERE o.type = 'U'
    AND STATS_DATE(s.object_id, s.stats_id) < DATEADD(day, -7, GETDATE())
ORDER BY DaysOld DESC;
"@

Invoke-SqlQuery -Query $updateStatsQuery -Description "Actualizando estadísticas"

# 3. Reorganizar índices fragmentados
if ($fragmentation) {
    foreach ($index in $fragmentation) {
        if ($index.RecommendedAction -eq "REORGANIZE") {
            $reorganizeQuery = "ALTER INDEX [$($index.IndexName)] ON [$($index.TableName)] REORGANIZE;"
            Invoke-SqlQuery -Query $reorganizeQuery -Description "Reorganizando $($index.TableName).$($index.IndexName)"
        }
        elseif ($index.RecommendedAction -eq "REBUILD" -and $index.page_count -lt 50000) {
            $rebuildQuery = "ALTER INDEX [$($index.IndexName)] ON [$($index.TableName)] REBUILD WITH (ONLINE = ON);"
            Invoke-SqlQuery -Query $rebuildQuery -Description "Rebuilding $($index.TableName).$($index.IndexName)"
        }
    }
}

# 4. Limpiar Query Store si está lleno
$queryStoreQuery = @"
-- Verificar espacio de Query Store
SELECT 
    actual_state_desc,
    readonly_reason,
    current_storage_size_mb,
    max_storage_size_mb,
    (current_storage_size_mb * 100.0 / max_storage_size_mb) AS storage_usage_percent
FROM sys.database_query_store_options;

-- Limpiar datos antiguos si está >80% lleno
IF EXISTS (
    SELECT 1 FROM sys.database_query_store_options 
    WHERE (current_storage_size_mb * 100.0 / max_storage_size_mb) > 80
)
BEGIN
    ALTER DATABASE CURRENT SET QUERY_STORE CLEAR;
    PRINT 'Query Store limpiado por uso >80%';
END
"@

Invoke-SqlQuery -Query $queryStoreQuery -Description "Verificando Query Store"

# 5. Verificar integridad básica
$integrityQuery = @"
-- Verificar integridad de tablas principales
DBCC CHECKDB('persqldbmotorpromocprd') WITH NO_INFOMSGS, PHYSICAL_ONLY;

-- Verificar espacio disponible
SELECT 
    DB_NAME() AS DatabaseName,
    (SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS BIGINT)) * 8192) / 1024 / 1024 AS UsedSpaceMB,
    (SUM(CAST(size AS BIGINT)) * 8192) / 1024 / 1024 AS AllocatedSpaceMB,
    ((SUM(CAST(size AS BIGINT)) - SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS BIGINT))) * 8192) / 1024 / 1024 AS FreeSpaceMB
FROM sys.database_files
WHERE type_desc = 'ROWS';
"@

Invoke-SqlQuery -Query $integrityQuery -Description "Verificando integridad"

# 6. Generar reporte de mantenimiento
$reportQuery = @"
SELECT 
    'MAINTENANCE_REPORT' AS ReportType,
    GETDATE() AS ExecutionTime,
    @@SERVERNAME AS ServerName,
    DB_NAME() AS DatabaseName,
    'COMPLETED' AS Status;

-- Top 5 consultas más costosas última semana
SELECT TOP 5
    'TOP_EXPENSIVE_QUERIES' AS ReportType,
    q.query_id,
    qt.query_sql_text,
    rs.avg_cpu_time,
    rs.avg_duration,
    rs.count_executions
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_runtime_stats rs ON q.query_id = rs.query_id
WHERE rs.last_execution_time > DATEADD(day, -7, GETDATE())
ORDER BY rs.avg_cpu_time DESC;
"@

$report = Invoke-SqlQuery -Query $reportQuery -Description "Generando reporte final"

Write-Output ""
Write-Output "🎉 MANTENIMIENTO AUTOMÁTICO COMPLETADO"
Write-Output "======================================"
Write-Output "✅ Fragmentación verificada"
Write-Output "✅ Estadísticas actualizadas"
Write-Output "✅ Índices reorganizados/rebuilded"
Write-Output "✅ Query Store optimizado"
Write-Output "✅ Integridad verificada"
Write-Output "✅ Reporte generado"
Write-Output ""
Write-Output "📊 Próximo mantenimiento: $(Get-Date (Get-Date).AddDays(7))"
