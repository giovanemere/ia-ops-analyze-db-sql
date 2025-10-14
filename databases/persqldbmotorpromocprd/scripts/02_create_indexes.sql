-- =====================================================
-- CREACIÓN DE ÍNDICES OPTIMIZADOS
-- Índices específicos para tablas principales
-- =====================================================

PRINT 'Creando índices optimizados para tablas principales...'

-- 1. ÍNDICES PARA CuponesDigitales (45M registros)
PRINT 'Creando índices para CuponesDigitales...'

-- Índice por fecha de creación (consultas por rango de fechas)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CuponesDigitales_FechaCreacion')
BEGIN
    CREATE NONCLUSTERED INDEX IX_CuponesDigitales_FechaCreacion
    ON CuponesDigitales (fechaCreacion)
    INCLUDE (IDCupon, campannaID, estadoCuponID)
    WITH (ONLINE = ON, FILLFACTOR = 90);
    PRINT '✅ Índice IX_CuponesDigitales_FechaCreacion creado'
END
ELSE
    PRINT '⚠️  Índice IX_CuponesDigitales_FechaCreacion ya existe'

-- Índice por campaña y estado (consultas frecuentes)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CuponesDigitales_Campanna_Estado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_CuponesDigitales_Campanna_Estado
    ON CuponesDigitales (campannaID, estadoCuponID)
    INCLUDE (IDCupon, fechaCreacion, fechaEstado)
    WITH (ONLINE = ON, FILLFACTOR = 90);
    PRINT '✅ Índice IX_CuponesDigitales_Campanna_Estado creado'
END
ELSE
    PRINT '⚠️  Índice IX_CuponesDigitales_Campanna_Estado ya existe'

-- Índice por taxIdentifier para búsquedas de cliente
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CuponesDigitales_TaxIdentifier')
BEGIN
    CREATE NONCLUSTERED INDEX IX_CuponesDigitales_TaxIdentifier
    ON CuponesDigitales (taxIdentifier)
    WHERE taxIdentifier IS NOT NULL AND taxIdentifier != ''
    INCLUDE (IDCupon, campannaID, estadoCuponID)
    WITH (ONLINE = ON, FILLFACTOR = 85);
    PRINT '✅ Índice IX_CuponesDigitales_TaxIdentifier creado'
END
ELSE
    PRINT '⚠️  Índice IX_CuponesDigitales_TaxIdentifier ya existe'

-- 2. ÍNDICES PARA CuponesFisicoCorreccion (12M registros)
PRINT 'Creando índices para CuponesFisicoCorreccion...'

-- Índice por fecha de creación
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CuponesFisicoCorreccion_FechaCreacion')
BEGIN
    CREATE NONCLUSTERED INDEX IX_CuponesFisicoCorreccion_FechaCreacion
    ON CuponesFisicoCorreccion (fechaCreacion)
    INCLUDE (IDCupon, campannaID, estadoCuponID)
    WITH (ONLINE = ON, FILLFACTOR = 90);
    PRINT '✅ Índice IX_CuponesFisicoCorreccion_FechaCreacion creado'
END
ELSE
    PRINT '⚠️  Índice IX_CuponesFisicoCorreccion_FechaCreacion ya existe'

-- Índice por campaña y estado
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CuponesFisicoCorreccion_Campanna_Estado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_CuponesFisicoCorreccion_Campanna_Estado
    ON CuponesFisicoCorreccion (campannaID, estadoCuponID)
    INCLUDE (IDCupon, fechaCreacion, fechaEstado)
    WITH (ONLINE = ON, FILLFACTOR = 90);
    PRINT '✅ Índice IX_CuponesFisicoCorreccion_Campanna_Estado creado'
END
ELSE
    PRINT '⚠️  Índice IX_CuponesFisicoCorreccion_Campanna_Estado ya existe'

-- 3. ÍNDICES PARA GeneralEstadosCuyOpClientePromocion (1M registros)
PRINT 'Creando índices para GeneralEstadosCuyOpClientePromocion...'

-- Índice por taxIdentifier y campaña
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GeneralEstados_Tax_Campanna')
BEGIN
    CREATE NONCLUSTERED INDEX IX_GeneralEstados_Tax_Campanna
    ON GeneralEstadosCuyOpClientePromocion (taxIdentifier, campannaID)
    INCLUDE (identifier, estadoID, fechaCreacion)
    WITH (ONLINE = ON, FILLFACTOR = 85);
    PRINT '✅ Índice IX_GeneralEstados_Tax_Campanna creado'
END
ELSE
    PRINT '⚠️  Índice IX_GeneralEstados_Tax_Campanna ya existe'

-- Índice por fecha para reportes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GeneralEstados_FechaCreacion')
BEGIN
    CREATE NONCLUSTERED INDEX IX_GeneralEstados_FechaCreacion
    ON GeneralEstadosCuyOpClientePromocion (fechaCreacion)
    INCLUDE (taxIdentifier, campannaID, estadoID)
    WITH (ONLINE = ON, FILLFACTOR = 85);
    PRINT '✅ Índice IX_GeneralEstados_FechaCreacion creado'
END
ELSE
    PRINT '⚠️  Índice IX_GeneralEstados_FechaCreacion ya existe'

-- 4. ÍNDICES PARA TABLAS DE REFERENCIA
PRINT 'Creando índices para tablas de referencia...'

-- Índice para Campanna por fechas y país
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Campanna_Fechas_Pais')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Campanna_Fechas_Pais
    ON Campanna (fechaInicio, fechaFin, pais)
    INCLUDE (campannaID, nombre, tipoCampanna)
    WITH (ONLINE = ON, FILLFACTOR = 95);
    PRINT '✅ Índice IX_Campanna_Fechas_Pais creado'
END
ELSE
    PRINT '⚠️  Índice IX_Campanna_Fechas_Pais ya existe'

-- 5. ACTUALIZAR ESTADÍSTICAS
PRINT 'Actualizando estadísticas...'

UPDATE STATISTICS CuponesDigitales WITH FULLSCAN;
UPDATE STATISTICS CuponesFisicoCorreccion WITH FULLSCAN;
UPDATE STATISTICS GeneralEstadosCuyOpClientePromocion WITH FULLSCAN;
UPDATE STATISTICS Campanna WITH FULLSCAN;
UPDATE STATISTICS Estados WITH FULLSCAN;

PRINT '✅ Estadísticas actualizadas'
PRINT '=========================================='
PRINT 'CREACIÓN DE ÍNDICES COMPLETADA EXITOSAMENTE'
PRINT 'Tiempo estimado de mejora: 60-80% en consultas'
PRINT '=========================================='
