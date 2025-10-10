-- MANTENIMIENTO URGENTE - Ventana de Trabajo
-- Base de Datos: persqldbmotorpromocprd
-- Tiempo estimado: 2-4 horas

USE [persqldbmotorpromocprd];

PRINT '=== INICIANDO MANTENIMIENTO URGENTE ===';
PRINT 'Fecha: ' + CAST(GETDATE() AS VARCHAR);

-- 1. REBUILD CRÍTICO (>50% fragmentación)
PRINT '1. REBUILD de índices críticos...';

-- GeneralEstadosCuyOpClientePromocion (92-99% fragmentado)
ALTER INDEX PK__GeneralE__3214EC27FE1489B2 ON GeneralEstadosCuyOpClientePromocion REBUILD 
WITH (ONLINE = OFF, MAXDOP = 4);
PRINT 'REBUILD: GeneralEstados PK completado';

ALTER INDEX IX_taxidentifier ON GeneralEstadosCuyOpClientePromocion REBUILD 
WITH (ONLINE = OFF, MAXDOP = 4);
PRINT 'REBUILD: GeneralEstados IX_taxidentifier completado';

-- CuponesFisicoCorreccion (52-66% fragmentado)
ALTER INDEX PK_CuponesFisicoCorreccion ON CuponesFisicoCorreccion REBUILD 
WITH (ONLINE = OFF, MAXDOP = 4);
PRINT 'REBUILD: CuponesFisico PK completado';

ALTER INDEX idx_cupon_campanna_estado ON CuponesFisicoCorreccion REBUILD 
WITH (ONLINE = OFF, MAXDOP = 4);
PRINT 'REBUILD: CuponesFisico idx_cupon_campanna_estado completado';

-- 2. REORGANIZE MEDIO (10-50% fragmentación)
PRINT '2. REORGANIZE de índices medios...';

ALTER INDEX PK_CuponesDigitales_CampannaID_ID ON CuponesDigitales REORGANIZE;
PRINT 'REORGANIZE: CuponesDigitales PK completado';

ALTER INDEX IX_Cupones_Campanna_Estado ON CuponesDigitales REORGANIZE;
PRINT 'REORGANIZE: CuponesDigitales IX_Cupones_Campanna_Estado completado';

ALTER INDEX IX_Cupones_CampannaID ON CuponesDigitales REORGANIZE;
PRINT 'REORGANIZE: CuponesDigitales IX_Cupones_CampannaID completado';

ALTER INDEX idx_tax_campanna_estado ON CuponesDigitales REORGANIZE;
PRINT 'REORGANIZE: CuponesDigitales idx_tax_campanna_estado completado';

-- 3. ACTUALIZAR ESTADÍSTICAS
PRINT '3. Actualizando estadísticas...';

UPDATE STATISTICS CuponesDigitales WITH FULLSCAN;
PRINT 'Estadísticas CuponesDigitales actualizadas';

UPDATE STATISTICS CuponesFisicoCorreccion WITH FULLSCAN;
PRINT 'Estadísticas CuponesFisicoCorreccion actualizadas';

UPDATE STATISTICS GeneralEstadosCuyOpClientePromocion WITH FULLSCAN;
PRINT 'Estadísticas GeneralEstados actualizadas';

PRINT '=== MANTENIMIENTO URGENTE COMPLETADO ===';
PRINT 'Tiempo finalización: ' + CAST(GETDATE() AS VARCHAR);
