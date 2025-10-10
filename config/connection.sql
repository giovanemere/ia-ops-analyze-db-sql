-- Configuración de conexión a SQL Server
-- Server: persqlmotorpromocprd.database.windows.net
-- Database: persqldbmotorpromocprd
-- User: u_yairpanqueva

USE [persqldbmotorpromocprd];

-- Verificar conexión
SELECT 
    @@SERVERNAME as ServerName,
    DB_NAME() as DatabaseName,
    SYSTEM_USER as CurrentUser,
    GETDATE() as ConnectionTime;
