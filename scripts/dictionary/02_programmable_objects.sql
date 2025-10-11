-- =====================================================
-- OBJETOS PROGRAMABLES DE LA BASE DE DATOS
-- Vistas, Procedimientos, Funciones, etc.
-- =====================================================

-- 1. VISTAS
SELECT 
    'VIEWS' as SECTION,
    SCHEMA_NAME(v.schema_id) as SCHEMA_NAME,
    v.name as VIEW_NAME,
    v.create_date as CREATED_DATE,
    v.modify_date as MODIFIED_DATE,
    CASE WHEN v.is_replicated = 1 THEN 'YES' ELSE 'NO' END as IS_REPLICATED,
    CASE WHEN v.has_replication_filter = 1 THEN 'YES' ELSE 'NO' END as HAS_REPLICATION_FILTER,
    CASE WHEN v.has_opaque_metadata = 1 THEN 'YES' ELSE 'NO' END as HAS_OPAQUE_METADATA,
    ISNULL(ep.value, '') as DESCRIPTION
FROM sys.views v
LEFT JOIN sys.extended_properties ep ON v.object_id = ep.major_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
WHERE v.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(v.schema_id), v.name;

-- 2. COLUMNAS DE VISTAS
SELECT 
    'VIEW_COLUMNS' as SECTION,
    SCHEMA_NAME(v.schema_id) as SCHEMA_NAME,
    v.name as VIEW_NAME,
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
    ISNULL(ep.value, '') as COLUMN_DESCRIPTION
FROM sys.views v
INNER JOIN sys.columns c ON v.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.extended_properties ep ON v.object_id = ep.major_id AND c.column_id = ep.minor_id AND ep.name = 'MS_Description'
WHERE v.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(v.schema_id), v.name, c.column_id;

-- 3. PROCEDIMIENTOS ALMACENADOS
SELECT 
    'STORED_PROCEDURES' as SECTION,
    SCHEMA_NAME(p.schema_id) as SCHEMA_NAME,
    p.name as PROCEDURE_NAME,
    p.type_desc as OBJECT_TYPE,
    p.create_date as CREATED_DATE,
    p.modify_date as MODIFIED_DATE,
    CASE WHEN p.is_replication_filter_procedure = 1 THEN 'YES' ELSE 'NO' END as IS_REPLICATION_FILTER,
    CASE WHEN p.is_auto_executed = 1 THEN 'YES' ELSE 'NO' END as IS_AUTO_EXECUTED,
    ISNULL(ep.value, '') as DESCRIPTION
FROM sys.procedures p
LEFT JOIN sys.extended_properties ep ON p.object_id = ep.major_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
WHERE p.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(p.schema_id), p.name;

-- 4. PARÁMETROS DE PROCEDIMIENTOS
SELECT 
    'PROCEDURE_PARAMETERS' as SECTION,
    SCHEMA_NAME(o.schema_id) as SCHEMA_NAME,
    o.name as PROCEDURE_NAME,
    p.name as PARAMETER_NAME,
    p.parameter_id as ORDINAL_POSITION,
    ty.name as DATA_TYPE,
    p.max_length as MAX_LENGTH,
    p.precision as PRECISION,
    p.scale as SCALE,
    CASE WHEN p.is_output = 1 THEN 'OUTPUT' ELSE 'INPUT' END as PARAMETER_MODE,
    CASE WHEN p.has_default_value = 1 THEN 'YES' ELSE 'NO' END as HAS_DEFAULT,
    ISNULL(p.default_value, '') as DEFAULT_VALUE
FROM sys.objects o
INNER JOIN sys.parameters p ON o.object_id = p.object_id
INNER JOIN sys.types ty ON p.user_type_id = ty.user_type_id
WHERE o.type IN ('P', 'PC') AND o.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(o.schema_id), o.name, p.parameter_id;

-- 5. FUNCIONES
SELECT 
    'FUNCTIONS' as SECTION,
    SCHEMA_NAME(o.schema_id) as SCHEMA_NAME,
    o.name as FUNCTION_NAME,
    o.type_desc as FUNCTION_TYPE,
    o.create_date as CREATED_DATE,
    o.modify_date as MODIFIED_DATE,
    CASE WHEN o.type = 'FN' THEN 'SCALAR'
         WHEN o.type = 'IF' THEN 'INLINE_TABLE_VALUED'
         WHEN o.type = 'TF' THEN 'TABLE_VALUED'
         ELSE o.type_desc
    END as FUNCTION_CATEGORY,
    ISNULL(ep.value, '') as DESCRIPTION
FROM sys.objects o
LEFT JOIN sys.extended_properties ep ON o.object_id = ep.major_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
WHERE o.type IN ('FN', 'IF', 'TF') AND o.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(o.schema_id), o.name;

-- 6. PARÁMETROS DE FUNCIONES
SELECT 
    'FUNCTION_PARAMETERS' as SECTION,
    SCHEMA_NAME(o.schema_id) as SCHEMA_NAME,
    o.name as FUNCTION_NAME,
    p.name as PARAMETER_NAME,
    p.parameter_id as ORDINAL_POSITION,
    ty.name as DATA_TYPE,
    p.max_length as MAX_LENGTH,
    p.precision as PRECISION,
    p.scale as SCALE,
    CASE WHEN p.has_default_value = 1 THEN 'YES' ELSE 'NO' END as HAS_DEFAULT,
    ISNULL(p.default_value, '') as DEFAULT_VALUE
FROM sys.objects o
INNER JOIN sys.parameters p ON o.object_id = p.object_id
INNER JOIN sys.types ty ON p.user_type_id = ty.user_type_id
WHERE o.type IN ('FN', 'IF', 'TF') AND o.is_ms_shipped = 0 AND p.parameter_id > 0
ORDER BY SCHEMA_NAME(o.schema_id), o.name, p.parameter_id;

-- 7. TIPOS DE DATOS DEFINIDOS POR EL USUARIO
SELECT 
    'USER_DEFINED_TYPES' as SECTION,
    SCHEMA_NAME(t.schema_id) as SCHEMA_NAME,
    t.name as TYPE_NAME,
    bt.name as BASE_TYPE,
    t.max_length as MAX_LENGTH,
    t.precision as PRECISION,
    t.scale as SCALE,
    CASE WHEN t.is_nullable = 1 THEN 'YES' ELSE 'NO' END as IS_NULLABLE,
    ISNULL(dc.definition, '') as DEFAULT_VALUE,
    ISNULL(ep.value, '') as DESCRIPTION
FROM sys.types t
INNER JOIN sys.types bt ON t.system_type_id = bt.system_type_id AND bt.user_type_id = bt.system_type_id
LEFT JOIN sys.default_constraints dc ON t.default_object_id = dc.object_id
LEFT JOIN sys.extended_properties ep ON t.user_type_id = ep.major_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
WHERE t.is_user_defined = 1
ORDER BY SCHEMA_NAME(t.schema_id), t.name;

-- 8. SINÓNIMOS
SELECT 
    'SYNONYMS' as SECTION,
    SCHEMA_NAME(s.schema_id) as SCHEMA_NAME,
    s.name as SYNONYM_NAME,
    s.base_object_name as BASE_OBJECT_NAME,
    s.create_date as CREATED_DATE,
    s.modify_date as MODIFIED_DATE,
    ISNULL(ep.value, '') as DESCRIPTION
FROM sys.synonyms s
LEFT JOIN sys.extended_properties ep ON s.object_id = ep.major_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
ORDER BY SCHEMA_NAME(s.schema_id), s.name;
