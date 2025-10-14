-- =====================================================
-- CÓDIGO FUENTE COMPLETO: sp_UpdateRegisCouponsFiCo
-- Extraído: 2025-10-13 14:55:17
-- Creado: 2025-10-09 21:25:37.440000
-- Modificado: 2025-10-13 19:37:11.173000
-- =====================================================


CREATE PROCEDURE [dbo].[sp_UpdateRegisCouponsFiCo]
    @EstadoID INT,
    @SourceApp NVARCHAR(255),
    @IdSource NVARCHAR(255),
    @CampannaID INT,
    @CouponType NVARCHAR(100) = NULL,
    @Identifier NVARCHAR(255) = NULL,
    @TaxIdentifier NVARCHAR(255) = NULL,
    @CouponList NVARCHAR(MAX) -- Lista de cupones separados por coma: 'CUP001','CUP002','CUP003'
AS
BEGIN
    /************************************************************************************
     Proyecto  : Motor de Promociones
     N1 - N2   : Clientes - Loyalty
     API       : perfuncmotorcnsregprd
     Operation : RegistroCupones
     EndPoint  : /apis/perfuncmotorcnsregprd/operations/registrocupones

     Objetivo  : Actualizar estado del Cupon Fisico Fisico / Corrección
                 con el fin de "Registrar" (Estado = 3) un Cupon
     Autor     : Danilo Herazo - Periferia IT
     Revisado  : Maria Jose Arone - Primax
     
     @CouponList --> Soporta el envio de una Lista de Cupones separados por coma ","
     ************************************************************************************/

    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @RowsAffected INT = 0;
    DECLARE @ListCupon VARCHAR(MAX) = @CouponList;
    DECLARE @IDCupon NVARCHAR(10);
    
    BEGIN TRY
        DECLARE c CURSOR LOCAL FAST_FORWARD -- opciones recomendadas
        FOR
        SELECT TRIM(value)
        FROM STRING_SPLIT(@CouponList, ',')
        WHERE TRIM(value) <> '';;
                
        OPEN c;
        FETCH NEXT FROM c INTO @IDCupon;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE CuponesFisicoCorreccion
            SET    estadoCuponID = @EstadoID
                   , sourceApp = @SourceApp
                   , IdSource = @IdSource               
                   , identifier = @Identifier
                   , taxIdentifier = @TaxIdentifier
            WHERE  IDCupon = @IdCupon
                   AND campannaID = @CampannaID
                   AND estadoCuponID = 1;

            SET @RowsAffected = @RowsAffected + @@ROWCOUNT;

            FETCH NEXT FROM c INTO @IDCupon;
        END
        
        CLOSE c;
        DEALLOCATE c;

        SELECT @RowsAffected AS RowsAffected;
        
    END TRY
    BEGIN CATCH
        -- En caso de error, retornar -1
        SELECT @RowsAffected = -1;
        
        -- Opcional: Registrar el error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
