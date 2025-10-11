#!/bin/bash

# Test de conexión simple
SERVER="persqlmotorpromocprd.database.windows.net"
DATABASE="persqldbmotorpromocprd"
USERNAME="u_yairpanqueva"

echo "🔍 Probando conexión a la base de datos..."
echo "Servidor: $SERVER"
echo "Base de Datos: $DATABASE"
echo "Usuario: $USERNAME"
echo ""

# Solicitar password de forma segura
read -s -p "Ingrese la password: " PASSWORD
echo ""

SQLCMD="/opt/mssql-tools/bin/sqlcmd"

# Test básico
echo "Ejecutando test de conexión..."
$SQLCMD -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
        -Q "SELECT 'SUCCESS' as STATUS, DB_NAME() as DATABASE_NAME, SYSTEM_USER as USER_NAME, GETDATE() as CONNECTION_TIME" \
        -t 30

if [ $? -eq 0 ]; then
    echo "✅ Conexión exitosa!"
    echo ""
    echo "Ejecutando análisis básico..."
    $SQLCMD -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
            -Q "SELECT COUNT(*) as TOTAL_TABLES FROM sys.tables WHERE is_ms_shipped = 0" \
            -t 30
else
    echo "❌ Error de conexión. Verificar credenciales."
fi
