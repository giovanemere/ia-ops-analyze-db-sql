-- Análisis de Problemas en Tablas
USE [persqldbmotorpromocprd];

-- 1. Tablas sin Primary Key
SELECT 'Sin Primary Key' as Issue, TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
AND NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    WHERE tc.TABLE_NAME = t.TABLE_NAME 
    AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
);

-- 2. Columnas con muchos valores NULL
SELECT 
    'Muchos NULLs' as Issue,
    TABLE_NAME,
    COLUMN_NAME,
    COUNT(*) as Total_Rows,
    SUM(CASE WHEN COLUMN_NAME IS NULL THEN 1 ELSE 0 END) as Null_Count
FROM INFORMATION_SCHEMA.COLUMNS c
CROSS APPLY (SELECT COUNT(*) as row_count FROM sys.tables WHERE name = c.TABLE_NAME) rc
WHERE IS_NULLABLE = 'YES'
GROUP BY TABLE_NAME, COLUMN_NAME
HAVING SUM(CASE WHEN COLUMN_NAME IS NULL THEN 1 ELSE 0 END) > (COUNT(*) * 0.5);

-- 3. Índices faltantes (tablas grandes sin índices)
SELECT 
    'Posible falta de índices' as Issue,
    t.name as TABLE_NAME,
    p.rows as Row_Count
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
AND p.rows > 10000
AND NOT EXISTS (
    SELECT 1 FROM sys.indexes i 
    WHERE i.object_id = t.object_id 
    AND i.index_id > 1
);
