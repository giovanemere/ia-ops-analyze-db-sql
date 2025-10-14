-- =====================================================
-- TEMPLATE: OPTIMIZACIÓN SQL AZURE DATABASE
-- Generado: 2025-10-12 13:25:19
-- Base de Datos: persqldbmotorpromocprd
-- =====================================================

-- Análisis de fragmentación
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Crear índices optimizados
CREATE NONCLUSTERED INDEX [IX_CuponesDigitales_FechaCreacion] 
ON [CuponesDigitales] (FechaCreacion, Estado)
INCLUDE (CodigoPromocion)
WITH (ONLINE = ON, FILLFACTOR = 90);



CREATE NONCLUSTERED INDEX [] 
ON [] ()
{{#include_columns}}INCLUDE (){{/include_columns}}
WITH (ONLINE = ON, FILLFACTOR = );


-- Estadísticas de performance
SELECT 
    'Optimización completada' AS Status,
    GETDATE() AS Timestamp;
