-- =====================================================
-- TEMPLATE: OPTIMIZACIÓN SQL AZURE DATABASE
-- Generado: {{timestamp}}
-- Base de Datos: {{database_name}}
-- =====================================================

-- Análisis de fragmentación
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > {{fragmentation_threshold}}
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Crear índices optimizados
{{#indexes}}
CREATE NONCLUSTERED INDEX [{{index_name}}] 
ON [{{table_name}}] ({{columns}})
{{#include_columns}}INCLUDE ({{include_columns}}){{/include_columns}}
WITH (ONLINE = ON, FILLFACTOR = {{fill_factor}});
{{/indexes}}

-- Estadísticas de performance
SELECT 
    'Optimización completada' AS Status,
    GETDATE() AS Timestamp;
