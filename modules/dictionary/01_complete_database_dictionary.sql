-- =====================================================
-- DICCIONARIO COMPLETO DE BASE DE DATOS
-- Genera documentación completa de todos los objetos
-- =====================================================

-- 1. INFORMACIÓN GENERAL DE LA BASE DE DATOS
SELECT 
    'DATABASE_INFO' as SECTION,
    DB_NAME() as DATABASE_NAME,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') as COLLATION,
    DATABASEPROPERTYEX(DB_NAME(), 'Edition') as EDITION,
    DATABASEPROPERTYEX(DB_NAME(), 'ServiceObjective') as SERVICE_TIER,
    DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeInBytes') as MAX_SIZE_BYTES,
    create_date as CREATED_DATE,
    compatibility_level as COMPATIBILITY_LEVEL
FROM sys.databases 
WHERE name = DB_NAME();

-- 2. TABLAS Y SUS PROPIEDADES
SELECT 
    'TABLES' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    t.type_desc as TABLE_TYPE,
    t.create_date as CREATED_DATE,
    t.modify_date as MODIFIED_DATE,
    p.rows as ROW_COUNT,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as TOTAL_SPACE_MB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as USED_SPACE_MB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) as UNUSED_SPACE_MB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.object_id > 255
GROUP BY t.schema_id, t.name, t.type_desc, t.create_date, t.modify_date, p.rows
ORDER BY SCHEMA_NAME(t.schema_id), t.name;

-- 3. COLUMNAS DETALLADAS
SELECT 
    'COLUMNS' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    c.name as COLUMN_NAME,
    c.column_id as ORDINAL_POSITION,
    ty.name as DATA_TYPE,
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
        THEN c.max_length
        WHEN ty.name IN ('nvarchar', 'nchar', 'ntext')
        THEN c.max_length / 2
        ELSE NULL
    END as CHARACTER_MAXIMUM_LENGTH,
    c.precision as NUMERIC_PRECISION,
    c.scale as NUMERIC_SCALE,
    CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END as IS_NULLABLE,
    ISNULL(dc.definition, '') as DEFAULT_VALUE,
    CASE WHEN c.is_identity = 1 THEN 'YES' ELSE 'NO' END as IS_IDENTITY,
    CASE WHEN c.is_computed = 1 THEN 'YES' ELSE 'NO' END as IS_COMPUTED,
    ISNULL(cc.definition, '') as COMPUTED_DEFINITION,
    ISNULL(ep.value, '') as COLUMN_DESCRIPTION
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
LEFT JOIN sys.computed_columns cc ON t.object_id = cc.object_id AND c.column_id = cc.column_id
LEFT JOIN sys.extended_properties ep ON t.object_id = ep.major_id AND c.column_id = ep.minor_id AND ep.name = 'MS_Description'
WHERE t.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(t.schema_id), t.name, c.column_id;

-- 4. CLAVES PRIMARIAS
SELECT 
    'PRIMARY_KEYS' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    kc.name as CONSTRAINT_NAME,
    c.name as COLUMN_NAME,
    ic.key_ordinal as ORDINAL_POSITION,
    CASE WHEN i.is_unique = 1 THEN 'YES' ELSE 'NO' END as IS_UNIQUE,
    i.type_desc as INDEX_TYPE
FROM sys.tables t
INNER JOIN sys.key_constraints kc ON t.object_id = kc.parent_object_id
INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE kc.type = 'PK'
ORDER BY SCHEMA_NAME(t.schema_id), t.name, ic.key_ordinal;

-- 5. CLAVES FORÁNEAS
SELECT 
    'FOREIGN_KEYS' as SECTION,
    SCHEMA_NAME(tp.schema_id) as PARENT_SCHEMA,
    tp.name as PARENT_TABLE,
    cp.name as PARENT_COLUMN,
    fk.name as CONSTRAINT_NAME,
    SCHEMA_NAME(tr.schema_id) as REFERENCED_SCHEMA,
    tr.name as REFERENCED_TABLE,
    cr.name as REFERENCED_COLUMN,
    fk.delete_referential_action_desc as DELETE_RULE,
    fk.update_referential_action_desc as UPDATE_RULE,
    CASE WHEN fk.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END as STATUS
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
ORDER BY SCHEMA_NAME(tp.schema_id), tp.name, fk.name;

-- 6. ÍNDICES
SELECT 
    'INDEXES' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    i.name as INDEX_NAME,
    i.type_desc as INDEX_TYPE,
    CASE WHEN i.is_unique = 1 THEN 'YES' ELSE 'NO' END as IS_UNIQUE,
    CASE WHEN i.is_primary_key = 1 THEN 'YES' ELSE 'NO' END as IS_PRIMARY_KEY,
    CASE WHEN i.is_unique_constraint = 1 THEN 'YES' ELSE 'NO' END as IS_UNIQUE_CONSTRAINT,
    STRING_AGG(c.name + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END, ', ') 
        WITHIN GROUP (ORDER BY ic.key_ordinal) as KEY_COLUMNS,
    i.fill_factor as FILL_FACTOR,
    CASE WHEN i.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END as STATUS
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.is_ms_shipped = 0 AND i.type > 0
GROUP BY t.schema_id, t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key, 
         i.is_unique_constraint, i.fill_factor, i.is_disabled
ORDER BY SCHEMA_NAME(t.schema_id), t.name, i.name;

-- 7. RESTRICCIONES CHECK
SELECT 
    'CHECK_CONSTRAINTS' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    cc.name as CONSTRAINT_NAME,
    cc.definition as CHECK_CLAUSE,
    CASE WHEN cc.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END as STATUS
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(t.schema_id), t.name, cc.name;

-- 8. TRIGGERS
SELECT 
    'TRIGGERS' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TABLE_NAME,
    tr.name as TRIGGER_NAME,
    tr.type_desc as TRIGGER_TYPE,
    CASE WHEN tr.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END as STATUS,
    tr.create_date as CREATED_DATE,
    tr.modify_date as MODIFIED_DATE
FROM sys.triggers tr
INNER JOIN sys.tables t ON tr.parent_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(t.schema_id), t.name, tr.name;
