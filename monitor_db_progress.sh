#!/bin/bash

# Monitor Database Progress Script
# Ejecuta queries de monitoreo y genera logs

SERVER="persqlmotorpromocprd.database.windows.net"
DATABASE="persqldbmotorpromocprd"
USER="u_yairpanqueva"
PASSWORD="0x2E0403602967FDD263E5"
LOG_FILE="logs/db_progress_$(date +%Y%m%d).log"

# Crear directorio de logs si no existe
mkdir -p logs

echo "=== Database Progress Monitor - $(date) ===" >> $LOG_FILE

# Ejecutar query de progreso
echo "--- OPERATIONS PROGRESS ---" >> $LOG_FILE
sqlcmd -S $SERVER -d $DATABASE -U $USER -P $PASSWORD -Q "
SELECT 
    GETDATE() as timestamp_check,
    session_id,
    command,
    CAST(percent_complete AS DECIMAL(5,2)) as percent_complete,
    CAST(estimated_completion_time/1000.0/60 AS DECIMAL(10,2)) as estimated_minutes_remaining,
    start_time,
    DATEDIFF(MINUTE, start_time, GETDATE()) as elapsed_minutes,
    status
FROM sys.dm_exec_requests 
WHERE percent_complete > 0
ORDER BY percent_complete DESC;
" >> $LOG_FILE 2>&1

echo "" >> $LOG_FILE

# Mostrar también en pantalla
echo "=== CURRENT PROGRESS ==="
sqlcmd -S $SERVER -d $DATABASE -U $USER -P $PASSWORD -Q "
SELECT 
    session_id,
    command,
    CAST(percent_complete AS DECIMAL(5,2)) as percent_complete,
    CAST(estimated_completion_time/1000.0/60 AS DECIMAL(10,2)) as minutes_remaining,
    DATEDIFF(MINUTE, start_time, GETDATE()) as elapsed_minutes
FROM sys.dm_exec_requests 
WHERE percent_complete > 0;
"

echo "Log guardado en: $LOG_FILE"
