-- Plan de Mantenimiento para Optimización Continua
USE [persqldbmotorpromocprd];

-- 1. Actualizar estadísticas de tablas grandes
UPDATE STATISTICS CuponesDigitales WITH FULLSCAN;
UPDATE STATISTICS CuponesFisicoCorreccion WITH FULLSCAN;
UPDATE STATISTICS GeneralEstadosCuyOpClientePromocion WITH FULLSCAN;

-- 2. Reorganizar/Reconstruir índices fragmentados
DECLARE @sql NVARCHAR(MAX);
DECLARE @TableName NVARCHAR(128);
DECLARE @IndexName NVARCHAR(128);
DECLARE @Fragmentation FLOAT;

DECLARE index_cursor CURSOR FOR
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
AND ips.page_count > 1000
AND i.name IS NOT NULL;

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Fragmentation > 30
    BEGIN
        SET @sql = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD WITH (ONLINE = ON, MAXDOP = 4)';
        PRINT 'REBUILD: ' + @sql;
        -- EXEC sp_executesql @sql; -- Descomentar para ejecutar
    END
    ELSE IF @Fragmentation > 10
    BEGIN
        SET @sql = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REORGANIZE';
        PRINT 'REORGANIZE: ' + @sql;
        -- EXEC sp_executesql @sql; -- Descomentar para ejecutar
    END
    
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
END;

CLOSE index_cursor;
DEALLOCATE index_cursor;

-- 3. Limpiar datos antiguos (ejemplo: cupones de más de 2 años)
/*
-- Ejecutar en ventana de mantenimiento
DELETE FROM CuponesDigitales 
WHERE fechaCreacion < DATEADD(YEAR, -2, GETDATE())
AND estadoCuponID IN (SELECT ID FROM Estados WHERE nombre IN ('Usado', 'Expirado'));

DELETE FROM CuponesFisicoCorreccion 
WHERE fechaCreacion < DATEADD(YEAR, -2, GETDATE())
AND estadoCuponID IN (SELECT ID FROM Estados WHERE nombre IN ('Usado', 'Expirado'));
*/

-- 4. Comprimir tablas grandes para ahorrar espacio
/*
ALTER TABLE CuponesDigitales REBUILD WITH (DATA_COMPRESSION = PAGE);
ALTER TABLE CuponesFisicoCorreccion REBUILD WITH (DATA_COMPRESSION = PAGE);
*/

PRINT 'Plan de mantenimiento preparado. Revisar y ejecutar según ventana de mantenimiento.';
