-- Índices Recomendados para Optimización
USE [persqldbmotorpromocprd];

-- TABLA: CuponesDigitales (45M registros) - CRÍTICO
-- Índice para búsquedas por campaña y estado
CREATE NONCLUSTERED INDEX IX_CuponesDigitales_Campanna_Estado
ON CuponesDigitales (campannaID, estadoCuponID)
INCLUDE (IDCupon, fechaCreacion, taxIdentifier);

-- Índice para búsquedas por fecha
CREATE NONCLUSTERED INDEX IX_CuponesDigitales_FechaCreacion
ON CuponesDigitales (fechaCreacion DESC)
INCLUDE (IDCupon, campannaID, estadoCuponID);

-- Índice para búsquedas por taxIdentifier
CREATE NONCLUSTERED INDEX IX_CuponesDigitales_TaxIdentifier
ON CuponesDigitales (taxIdentifier)
WHERE taxIdentifier != ''
INCLUDE (IDCupon, campannaID, estadoCuponID);

-- TABLA: CuponesFisicoCorreccion (12M registros) - ALTO
-- Índice para búsquedas por campaña y estado
CREATE NONCLUSTERED INDEX IX_CuponesFisico_Campanna_Estado
ON CuponesFisicoCorreccion (campannaID, estadoCuponID)
INCLUDE (IDCupon, fechaCreacion, taxIdentifier);

-- Índice para búsquedas por fecha
CREATE NONCLUSTERED INDEX IX_CuponesFisico_FechaCreacion
ON CuponesFisicoCorreccion (fechaCreacion DESC)
INCLUDE (IDCupon, campannaID, estadoCuponID);

-- TABLA: GeneralEstadosCuyOpClientePromocion (1M registros) - MEDIO
-- Índice compuesto para búsquedas frecuentes
CREATE NONCLUSTERED INDEX IX_GeneralEstados_Tax_Identifier_Campanna
ON GeneralEstadosCuyOpClientePromocion (taxIdentifier, identifier, campannaID)
INCLUDE (estadoID, fechaCreacion);

-- Índice por fecha para reportes
CREATE NONCLUSTERED INDEX IX_GeneralEstados_FechaCreacion
ON GeneralEstadosCuyOpClientePromocion (fechaCreacion DESC)
INCLUDE (taxIdentifier, campannaID, estadoID);

-- TABLA: Campanna - Índice para búsquedas por fechas
CREATE NONCLUSTERED INDEX IX_Campanna_Fechas_Pais
ON Campanna (fechaInicio, fechaFin, pais)
INCLUDE (campannaID, nombre, tipoCampanna);

PRINT 'Índices creados exitosamente. Ejecutar análisis de rendimiento para validar mejoras.';
