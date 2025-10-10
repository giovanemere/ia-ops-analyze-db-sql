-- OPTIMIZACIÓN ADICIONAL - Ejecutar después del mantenimiento urgente
-- Tiempo estimado: 1-2 horas

USE [persqldbmotorpromocprd];

PRINT '=== INICIANDO OPTIMIZACIÓN ADICIONAL ===';

-- 1. CREAR ÍNDICES FALTANTES PARA REPORTES POR FECHA
PRINT '1. Creando índices para consultas por fecha...';

-- CuponesDigitales - Índice por fecha descendente
CREATE NONCLUSTERED INDEX IX_CuponesDigitales_FechaCreacion_Optimizado
ON CuponesDigitales (fechaCreacion DESC)
INCLUDE (IDCupon, campannaID, estadoCuponID, taxIdentifier)
WITH (ONLINE = ON, MAXDOP = 4);
PRINT 'Índice fecha CuponesDigitales creado';

-- CuponesFisicoCorreccion - Índice por fecha descendente  
CREATE NONCLUSTERED INDEX IX_CuponesFisico_FechaCreacion_Optimizado
ON CuponesFisicoCorreccion (fechaCreacion DESC)
INCLUDE (IDCupon, campannaID, estadoCuponID, taxIdentifier)
WITH (ONLINE = ON, MAXDOP = 4);
PRINT 'Índice fecha CuponesFisico creado';

-- 2. ÍNDICE COMPUESTO PARA CONSULTAS FRECUENTES
PRINT '2. Creando índices compuestos optimizados...';

-- Para consultas: WHERE campannaID = X AND fechaCreacion BETWEEN Y AND Z
CREATE NONCLUSTERED INDEX IX_CuponesDigitales_Campanna_Fecha_Optimizado
ON CuponesDigitales (campannaID, fechaCreacion DESC)
INCLUDE (IDCupon, estadoCuponID, taxIdentifier, identifier)
WITH (ONLINE = ON, MAXDOP = 4);
PRINT 'Índice compuesto CuponesDigitales creado';

-- 3. COMPRIMIR TABLAS GRANDES PARA AHORRAR ESPACIO
PRINT '3. Aplicando compresión de datos...';

-- Comprimir CuponesDigitales (45M registros)
ALTER TABLE CuponesDigitales REBUILD WITH (DATA_COMPRESSION = PAGE);
PRINT 'Compresión CuponesDigitales aplicada';

-- Comprimir CuponesFisicoCorreccion (12M registros)
ALTER TABLE CuponesFisicoCorreccion REBUILD WITH (DATA_COMPRESSION = PAGE);
PRINT 'Compresión CuponesFisicoCorreccion aplicada';

PRINT '=== OPTIMIZACIÓN ADICIONAL COMPLETADA ===';
PRINT 'Ahorro de espacio estimado: 40-60%';
PRINT 'Mejora de rendimiento estimada: 20-30% adicional';
