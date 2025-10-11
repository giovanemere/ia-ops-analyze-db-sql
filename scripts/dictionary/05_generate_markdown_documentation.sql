-- =====================================================
-- GENERADOR DE DOCUMENTACIÓN MARKDOWN
-- Crea documentación completa en formato Markdown
-- =====================================================

DECLARE @DatabaseName NVARCHAR(128) = DB_NAME()
DECLARE @GenerationDate NVARCHAR(50) = CONVERT(VARCHAR, GETDATE(), 120)

PRINT '# 📊 Diccionario de Datos Completo'
PRINT ''
PRINT '**Base de Datos:** ' + @DatabaseName
PRINT '**Fecha de Generación:** ' + @GenerationDate
PRINT '**Generado por:** Sistema Automatizado de Documentación'
PRINT ''
PRINT '---'
PRINT ''

-- Índice de contenidos
PRINT '## 📋 Índice de Contenidos'
PRINT ''
PRINT '1. [Información General](#información-general)'
PRINT '2. [Tablas](#tablas)'
PRINT '3. [Vistas](#vistas)'
PRINT '4. [Procedimientos Almacenados](#procedimientos-almacenados)'
PRINT '5. [Funciones](#funciones)'
PRINT '6. [Índices](#índices)'
PRINT '7. [Seguridad y Permisos](#seguridad-y-permisos)'
PRINT '8. [Estadísticas de Rendimiento](#estadísticas-de-rendimiento)'
PRINT ''
PRINT '---'
PRINT ''

-- 1. Información General
PRINT '## 🏢 Información General'
PRINT ''

SELECT 
    '| Propiedad | Valor |' as markdown_line
UNION ALL
SELECT '|-----------|-------|'
UNION ALL
SELECT '| **Nombre de BD** | ' + DB_NAME() + ' |'
UNION ALL
SELECT '| **Collation** | ' + CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS NVARCHAR(128)) + ' |'
UNION ALL
SELECT '| **Edición** | ' + CAST(DATABASEPROPERTYEX(DB_NAME(), 'Edition') AS NVARCHAR(128)) + ' |'
UNION ALL
SELECT '| **Nivel de Compatibilidad** | ' + CAST(compatibility_level AS NVARCHAR(10)) + ' |'
UNION ALL
SELECT '| **Fecha de Creación** | ' + CONVERT(VARCHAR, create_date, 120) + ' |'
FROM sys.databases 
WHERE name = DB_NAME();

PRINT ''

-- Resumen de objetos
PRINT '### 📈 Resumen de Objetos'
PRINT ''

SELECT 
    '| Tipo de Objeto | Cantidad |' as markdown_line
UNION ALL
SELECT '|----------------|----------|'
UNION ALL
SELECT '| **Tablas** | ' + CAST((SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS NVARCHAR(10)) + ' |'
UNION ALL
SELECT '| **Vistas** | ' + CAST((SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped = 0) AS NVARCHAR(10)) + ' |'
UNION ALL
SELECT '| **Procedimientos** | ' + CAST((SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0) AS NVARCHAR(10)) + ' |'
UNION ALL
SELECT '| **Funciones** | ' + CAST((SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND is_ms_shipped = 0) AS NVARCHAR(10)) + ' |'
UNION ALL
SELECT '| **Índices** | ' + CAST((SELECT COUNT(*) FROM sys.indexes i INNER JOIN sys.tables t ON i.object_id = t.object_id WHERE t.is_ms_shipped = 0 AND i.index_id > 0) AS NVARCHAR(10)) + ' |'
UNION ALL
SELECT '| **Triggers** | ' + CAST((SELECT COUNT(*) FROM sys.triggers tr INNER JOIN sys.tables t ON tr.parent_id = t.object_id WHERE t.is_ms_shipped = 0) AS NVARCHAR(10)) + ' |';

PRINT ''
PRINT '---'
PRINT ''

-- 2. Tablas
PRINT '## 📋 Tablas'
PRINT ''

-- Encabezado de tabla
PRINT '| Esquema | Tabla | Registros | Espacio (MB) | Fecha Creación | Fecha Modificación |'
PRINT '|---------|-------|-----------|--------------|----------------|-------------------|'

-- Datos de tablas
SELECT 
    '| ' + SCHEMA_NAME(t.schema_id) + ' | ' + t.name + ' | ' + 
    FORMAT(p.rows, 'N0') + ' | ' + 
    CAST(CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS NVARCHAR(20)) + ' | ' +
    CONVERT(VARCHAR, t.create_date, 120) + ' | ' +
    CONVERT(VARCHAR, t.modify_date, 120) + ' |' as markdown_line
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 AND i.object_id > 255
GROUP BY t.schema_id, t.name, t.create_date, t.modify_date, p.rows
ORDER BY SCHEMA_NAME(t.schema_id), t.name;

PRINT ''

-- Detalle de columnas por tabla
DECLARE @TableName NVARCHAR(128)
DECLARE @SchemaName NVARCHAR(128)

DECLARE table_cursor CURSOR FOR
SELECT SCHEMA_NAME(schema_id), name 
FROM sys.tables 
WHERE is_ms_shipped = 0
ORDER BY SCHEMA_NAME(schema_id), name

OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '### 📊 ' + @SchemaName + '.' + @TableName
    PRINT ''
    PRINT '| Columna | Tipo | Longitud | Precisión | Escala | Nulo | Identidad | Descripción |'
    PRINT '|---------|------|----------|-----------|--------|------|-----------|-------------|'
    
    SELECT 
        '| ' + c.name + ' | ' + ty.name + ' | ' + 
        ISNULL(CAST(CASE 
            WHEN ty.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
            THEN c.max_length
            WHEN ty.name IN ('nvarchar', 'nchar', 'ntext')
            THEN c.max_length / 2
            ELSE NULL
        END AS NVARCHAR(10)), '-') + ' | ' +
        ISNULL(CAST(c.precision AS NVARCHAR(10)), '-') + ' | ' +
        ISNULL(CAST(c.scale AS NVARCHAR(10)), '-') + ' | ' +
        CASE WHEN c.is_nullable = 1 THEN 'Sí' ELSE 'No' END + ' | ' +
        CASE WHEN c.is_identity = 1 THEN 'Sí' ELSE 'No' END + ' | ' +
        ISNULL(ep.value, '') + ' |' as markdown_line
    FROM sys.columns c
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    LEFT JOIN sys.extended_properties ep ON c.object_id = ep.major_id AND c.column_id = ep.minor_id AND ep.name = 'MS_Description'
    WHERE c.object_id = OBJECT_ID(@SchemaName + '.' + @TableName)
    ORDER BY c.column_id;
    
    PRINT ''
    
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName
END

CLOSE table_cursor
DEALLOCATE table_cursor

PRINT '---'
PRINT ''

-- 3. Índices críticos
PRINT '## 🔍 Análisis de Índices'
PRINT ''
PRINT '### Índices con Mayor Fragmentación'
PRINT ''
PRINT '| Esquema | Tabla | Índice | Tipo | Fragmentación (%) | Recomendación |'
PRINT '|---------|-------|--------|------|-------------------|---------------|'

SELECT TOP 10
    '| ' + SCHEMA_NAME(t.schema_id) + ' | ' + t.name + ' | ' + 
    ISNULL(i.name, 'HEAP') + ' | ' + i.type_desc + ' | ' +
    CAST(ROUND(ips.avg_fragmentation_in_percent, 2) AS NVARCHAR(10)) + ' | ' +
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN '🔴 REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN '🟡 REORGANIZE'
        ELSE '🟢 OK'
    END + ' |' as markdown_line
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.tables t ON ips.object_id = t.object_id
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE t.is_ms_shipped = 0
ORDER BY ips.avg_fragmentation_in_percent DESC;

PRINT ''
PRINT '---'
PRINT ''

-- 4. Recomendaciones finales
PRINT '## 🎯 Recomendaciones'
PRINT ''
PRINT '### Mantenimiento Inmediato'
PRINT ''
PRINT '- 🔴 **Crítico**: Índices con fragmentación > 30% requieren REBUILD'
PRINT '- 🟡 **Importante**: Índices con fragmentación > 10% requieren REORGANIZE'
PRINT '- 📊 **Estadísticas**: Actualizar estadísticas en tablas grandes'
PRINT ''
PRINT '### Optimización de Rendimiento'
PRINT ''
PRINT '- 📈 **Monitoreo**: Implementar monitoreo continuo de fragmentación'
PRINT '- 🔧 **Mantenimiento**: Programar mantenimiento automático semanal'
PRINT '- 📋 **Documentación**: Mantener este diccionario actualizado mensualmente'
PRINT ''
PRINT '---'
PRINT ''
PRINT '*Documentación generada automáticamente el ' + @GenerationDate + '*'
