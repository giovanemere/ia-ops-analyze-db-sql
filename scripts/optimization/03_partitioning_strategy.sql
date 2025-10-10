-- Estrategia de Particionamiento para Tablas Grandes
USE [persqldbmotorpromocprd];

-- 1. Crear función de partición por fecha (mensual)
CREATE PARTITION FUNCTION pf_FechaCreacion (datetime2)
AS RANGE RIGHT FOR VALUES (
    '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01',
    '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01',
    '2024-09-01', '2024-10-01', '2024-11-01', '2024-12-01',
    '2025-01-01', '2025-02-01', '2025-03-01', '2025-04-01',
    '2025-05-01', '2025-06-01', '2025-07-01', '2025-08-01',
    '2025-09-01', '2025-10-01', '2025-11-01', '2025-12-01'
);

-- 2. Crear esquema de partición
CREATE PARTITION SCHEME ps_FechaCreacion
AS PARTITION pf_FechaCreacion
ALL TO ([PRIMARY]);

-- 3. Script para crear tabla particionada CuponesDigitales_Partitioned
-- NOTA: Esto requiere migración de datos - ejecutar en ventana de mantenimiento
/*
CREATE TABLE CuponesDigitales_Partitioned (
    IDCupon varchar(50) NOT NULL,
    campannaID int NOT NULL,
    fechaCreacion datetime2 NOT NULL,
    estadoCuponID int NOT NULL,
    coorelativo varchar(50) NULL,
    IDSegmentado varchar(50) NULL,
    ID int IDENTITY(1,1) NOT NULL,
    commerceCode varchar(100) NULL,
    taxIdentifier nvarchar(50) NULL DEFAULT (''),
    identifier nvarchar(20) NULL DEFAULT (''),
    
    CONSTRAINT PK_CuponesDigitales_Partitioned 
    PRIMARY KEY CLUSTERED (ID, fechaCreacion),
    
    CONSTRAINT FK_CuponesDigitales_Partitioned_Campanna 
    FOREIGN KEY (campannaID) REFERENCES Campanna(ID),
    
    CONSTRAINT FK_CuponesDigitales_Partitioned_Estados 
    FOREIGN KEY (estadoCuponID) REFERENCES Estados(ID)
) ON ps_FechaCreacion(fechaCreacion);
*/

-- 4. Script de migración de datos (ejecutar por lotes)
/*
-- Migrar datos en lotes de 100,000 registros
DECLARE @BatchSize INT = 100000;
DECLARE @RowsProcessed INT = 0;

WHILE EXISTS (SELECT 1 FROM CuponesDigitales WHERE ID NOT IN (SELECT ID FROM CuponesDigitales_Partitioned))
BEGIN
    INSERT INTO CuponesDigitales_Partitioned 
    SELECT TOP (@BatchSize) * 
    FROM CuponesDigitales 
    WHERE ID NOT IN (SELECT ID FROM CuponesDigitales_Partitioned);
    
    SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;
    PRINT 'Procesados: ' + CAST(@RowsProcessed AS VARCHAR(20)) + ' registros';
    
    WAITFOR DELAY '00:00:01'; -- Pausa de 1 segundo entre lotes
END;
*/

PRINT 'Esquema de particionamiento creado. Revisar scripts de migración antes de ejecutar.';
