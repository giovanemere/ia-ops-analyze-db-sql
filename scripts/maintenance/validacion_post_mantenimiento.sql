-- VALIDACIÓN POST-MANTENIMIENTO
-- Ejecutar después del mantenimiento para verificar mejoras

USE [persqldbmotorpromocprd];

PRINT '=== VALIDACIÓN POST-MANTENIMIENTO ===';

-- 1. VERIFICAR FRAGMENTACIÓN DESPUÉS DEL MANTENIMIENTO
PRINT '1. Verificando fragmentación actual...';

SELECT 
    OBJECT_NAME(ips.object_id) AS Tabla,
    i.name AS Indice,
    CAST(ips.avg_fragmentation_in_percent AS DECIMAL(5,2)) AS Fragmentacion_Pct,
    ips.page_count AS Total_Paginas,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN '🔴 CRÍTICO'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN '🟡 MEDIO'
        ELSE '✅ BUENO'
    END AS Estado
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE OBJECT_NAME(ips.object_id) IN ('CuponesDigitales', 'CuponesFisicoCorreccion', 'GeneralEstadosCuyOpClientePromocion')
AND ips.page_count > 100
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- 2. PROBAR CONSULTAS TÍPICAS Y MEDIR RENDIMIENTO
PRINT '2. Probando consultas típicas...';

-- Test 1: Consulta por campaña (antes: ~15 segundos)
DECLARE @start_time DATETIME2 = SYSDATETIME();
SELECT COUNT(*) as Total_Cupones
FROM CuponesDigitales 
WHERE campannaID = 1 AND estadoCuponID = 1;
DECLARE @end_time DATETIME2 = SYSDATETIME();
PRINT 'Test 1 - Consulta por campaña: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';

-- Test 2: Consulta por cliente (antes: ~25 segundos)  
SET @start_time = SYSDATETIME();
SELECT COUNT(*) as Total_Cupones_Cliente
FROM CuponesDigitales 
WHERE taxIdentifier = '12345678' AND campannaID = 1;
SET @end_time = SYSDATETIME();
PRINT 'Test 2 - Consulta por cliente: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';

-- Test 3: Reporte por fecha (antes: ~45 segundos)
SET @start_time = SYSDATETIME();
SELECT COUNT(*) as Cupones_Ultimo_Mes
FROM CuponesDigitales 
WHERE fechaCreacion >= DATEADD(MONTH, -1, GETDATE());
SET @end_time = SYSDATETIME();
PRINT 'Test 3 - Reporte por fecha: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';

-- 3. VERIFICAR ESPACIO UTILIZADO
PRINT '3. Verificando uso de espacio...';

SELECT 
    t.name AS Tabla,
    p.rows AS Registros,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS Tamaño_MB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS Usado_MB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS Libre_MB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name IN ('CuponesDigitales', 'CuponesFisicoCorreccion', 'GeneralEstadosCuyOpClientePromocion')
AND i.index_id <= 1
GROUP BY t.name, p.rows
ORDER BY SUM(a.total_pages) DESC;

-- 4. RESUMEN DE MEJORAS
PRINT '4. Resumen de mejoras esperadas:';
PRINT '   ✅ Fragmentación: <10% en todos los índices críticos';
PRINT '   ✅ Consultas: 80-90% más rápidas';
PRINT '   ✅ Espacio: 40-60% menos uso de disco';
PRINT '   ✅ CPU: Reducción del 30-40%';

PRINT '=== VALIDACIÓN COMPLETADA ===';
PRINT 'Si los tiempos siguen altos, revisar planes de ejecución específicos.';
