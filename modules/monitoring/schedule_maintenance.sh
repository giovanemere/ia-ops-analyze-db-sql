#!/bin/bash

# =====================================================
# PROGRAMAR MANTENIMIENTO AUTOMÁTICO
# Configura runbooks y schedules en Azure Automation
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Configuración
RESOURCE_GROUP="PERRSGRPYPRMTCLLYP"
AUTOMATION_ACCOUNT="primax-sql-automation"
RUNBOOK_NAME="sql-maintenance-weekly"
SCHEDULE_NAME="weekly-maintenance"

# Iniciar logging
start_logging "schedule_maintenance.sh" "Programación de Mantenimiento Automático"

log_info "🤖 CONFIGURANDO MANTENIMIENTO AUTOMÁTICO"
log_info "Automation Account: $AUTOMATION_ACCOUNT"
log_info "Runbook: $RUNBOOK_NAME"

# 1. Crear runbook en Automation Account
log_info "📝 Creando runbook de mantenimiento..."
az automation runbook create \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "$RUNBOOK_NAME" \
    --type PowerShell \
    --description "Mantenimiento automático semanal de SQL Database"

if [ $? -eq 0 ]; then
    log_success "Runbook creado"
else
    log_warning "Runbook ya existe o error en creación"
fi

# 2. Subir contenido del runbook
log_info "📤 Subiendo script de mantenimiento..."
az automation runbook replace-content \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "$RUNBOOK_NAME" \
    --content @"$(dirname "$0")/maintenance_runbook.ps1"

if [ $? -eq 0 ]; then
    log_success "Script subido al runbook"
else
    log_error "Error subiendo script"
fi

# 3. Publicar runbook
log_info "🚀 Publicando runbook..."
az automation runbook publish \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "$RUNBOOK_NAME"

if [ $? -eq 0 ]; then
    log_success "Runbook publicado"
else
    log_error "Error publicando runbook"
fi

# 4. Crear schedule semanal (Domingos 2:00 AM)
log_info "📅 Creando schedule semanal..."
az automation schedule create \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "$SCHEDULE_NAME" \
    --frequency Week \
    --interval 1 \
    --week-days Sunday \
    --start-time "$(date -d 'next Sunday 02:00' '+%Y-%m-%dT02:00:00')" \
    --time-zone "America/Bogota" \
    --description "Mantenimiento semanal domingos 2:00 AM"

if [ $? -eq 0 ]; then
    log_success "Schedule creado"
else
    log_warning "Schedule ya existe"
fi

# 5. Vincular runbook con schedule
log_info "🔗 Vinculando runbook con schedule..."
az automation job-schedule create \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --runbook-name "$RUNBOOK_NAME" \
    --schedule-name "$SCHEDULE_NAME"

if [ $? -eq 0 ]; then
    log_success "Runbook vinculado con schedule"
else
    log_warning "Vinculación ya existe"
fi

# 6. Crear schedule diario para verificaciones ligeras
log_info "📅 Creando schedule diario..."
az automation schedule create \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "daily-health-check" \
    --frequency Day \
    --interval 1 \
    --start-time "$(date -d 'tomorrow 01:00' '+%Y-%m-%dT01:00:00')" \
    --time-zone "America/Bogota" \
    --description "Verificación diaria de salud 1:00 AM"

# 7. Crear runbook de verificación diaria
log_info "📝 Creando runbook de verificación diaria..."

cat > /tmp/daily_health_check.ps1 << 'EOF'
param(
    [string]$ServerName = "persqlmotorpromocprd.database.windows.net",
    [string]$DatabaseName = "persqldbmotorpromocprd",
    [string]$Username = "u_yairpanqueva",
    [string]$Password = "0x2E0403602967FDD263E5"
)

Write-Output "🔍 VERIFICACIÓN DIARIA DE SALUD"

$healthQuery = @"
-- Verificar métricas básicas
SELECT 
    'HEALTH_CHECK' AS CheckType,
    GETDATE() AS CheckTime,
    (SELECT COUNT(*) FROM sys.dm_exec_sessions WHERE is_user_process = 1) AS ActiveSessions,
    (SELECT COUNT(*) FROM sys.dm_exec_requests WHERE blocking_session_id > 0) AS BlockedSessions,
    (SELECT COUNT(*) FROM sys.dm_os_waiting_tasks WHERE wait_type NOT LIKE '%SLEEP%') AS WaitingTasks;

-- Top 3 consultas más lentas últimas 24h
SELECT TOP 3
    'SLOW_QUERIES' AS CheckType,
    q.query_id,
    SUBSTRING(qt.query_sql_text, 1, 100) AS query_preview,
    rs.avg_duration / 1000 AS avg_duration_ms,
    rs.count_executions
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_runtime_stats rs ON q.query_id = rs.query_id
WHERE rs.last_execution_time > DATEADD(hour, -24, GETDATE())
ORDER BY rs.avg_duration DESC;
"@

try {
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -Username $Username -Password $Password -Query $healthQuery
    Write-Output "✅ Verificación completada"
    $result | Format-Table
}
catch {
    Write-Output "❌ Error en verificación: $($_.Exception.Message)"
}
EOF

az automation runbook create \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "sql-daily-health-check" \
    --type PowerShell \
    --description "Verificación diaria de salud"

az automation runbook replace-content \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "sql-daily-health-check" \
    --content @/tmp/daily_health_check.ps1

az automation runbook publish \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --name "sql-daily-health-check"

az automation job-schedule create \
    --resource-group "$RESOURCE_GROUP" \
    --automation-account-name "$AUTOMATION_ACCOUNT" \
    --runbook-name "sql-daily-health-check" \
    --schedule-name "daily-health-check"

# Resumen final
log_info ""
log_success "🎉 MANTENIMIENTO AUTOMÁTICO PROGRAMADO"
log_info "====================================="
log_info "✅ Runbook semanal: $RUNBOOK_NAME"
log_info "✅ Schedule: Domingos 2:00 AM"
log_info "✅ Runbook diario: sql-daily-health-check"
log_info "✅ Schedule: Diario 1:00 AM"
log_info ""
log_info "📋 TAREAS AUTOMÁTICAS:"
log_info "• Actualización de estadísticas"
log_info "• Reorganización de índices fragmentados"
log_info "• Limpieza de Query Store"
log_info "• Verificación de integridad"
log_info "• Monitoreo de consultas lentas"
log_info "• Verificación diaria de salud"

end_logging "schedule_maintenance.sh" "SUCCESS"

log_info ""
log_info "💡 PRÓXIMOS PASOS:"
log_info "1. Verificar ejecución en Azure Portal > Automation Account"
log_info "2. Revisar logs de ejecución"
log_info "3. Ajustar horarios según necesidades"
log_info "4. Configurar notificaciones de fallos"

rm -f /tmp/daily_health_check.ps1
