-- Test de conexión básico
SELECT 
    'CONNECTION_TEST' as TEST_TYPE,
    DB_NAME() as DATABASE_NAME,
    SYSTEM_USER as CURRENT_USER,
    GETDATE() as CONNECTION_TIME,
    @@VERSION as SQL_VERSION;

-- Test básico de permisos
SELECT 
    'PERMISSIONS_TEST' as TEST_TYPE,
    COUNT(*) as TABLE_COUNT
FROM sys.tables 
WHERE is_ms_shipped = 0;
