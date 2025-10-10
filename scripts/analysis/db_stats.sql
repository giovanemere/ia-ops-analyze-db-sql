-- Estadísticas Generales de la Base de Datos
USE [persqldbmotorpromocprd];

-- Resumen de tablas
SELECT 
    'Resumen General' as Categoria,
    COUNT(*) as Total_Tablas,
    SUM(p.rows) as Total_Registros,
    AVG(p.rows) as Promedio_Registros_Por_Tabla
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1);

-- Top 10 tablas más grandes
SELECT TOP 10
    t.name as Tabla,
    p.rows as Registros,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS Tamaño_MB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 AND i.object_id > 255
GROUP BY t.name, p.rows
ORDER BY p.rows DESC;
