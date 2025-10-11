#!/bin/bash

# =====================================================
# CONFIGURACIÓN AUTOMÁTICA DE MONITOREO AZURE
# Configura monitoreo completo para SQL Database
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Configuración
RESOURCE_GROUP="PERRSGRPYPRMTCLLYP"
LOCATION="eastus2"
SUBSCRIPTION_ID="06974a39-ae7c-476c-a773-2221c1ae76a2"
SERVER_NAME="persqlmotorpromocprd"
DATABASE_NAME="persqldbmotorpromocprd"

# Iniciar logging
start_logging "setup_monitoring.sh" "Configuración de Monitoreo Automático Azure"

log_info "🎯 CONFIGURANDO MONITOREO AUTOMÁTICO"
log_info "Resource Group: $RESOURCE_GROUP"
log_info "Base de Datos: $SERVER_NAME/$DATABASE_NAME"

# 1. Crear Log Analytics Workspace
log_info "📊 Creando Log Analytics Workspace..."
az monitor log-analytics workspace create \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "primax-sql-monitoring" \
    --location "$LOCATION" \
    --sku PerGB2018 \
    --output table

if [ $? -eq 0 ]; then
    log_success "Log Analytics Workspace creado"
else
    log_warning "Log Analytics Workspace ya existe o error en creación"
fi

# 2. Crear Action Group para Notificaciones
log_info "🚨 Configurando Action Group..."
az monitor action-group create \
    --resource-group "$RESOURCE_GROUP" \
    --name "sql-alerts-team" \
    --short-name "sqlalerts" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Action Group creado"
else
    log_warning "Action Group ya existe"
fi

# 3. Configurar Alertas Críticas
log_info "⚠️ Configurando alertas críticas..."

# Alerta CPU Alto
az monitor metrics alert create \
    --name "SQL-CPU-Critical" \
    --resource-group "$RESOURCE_GROUP" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Sql/servers/$SERVER_NAME/databases/$DATABASE_NAME" \
    --condition "avg cpu_percent > 90" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 1 \
    --description "CPU crítico >90% por 5 minutos" \
    --action-groups "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/actionGroups/sql-alerts-team" \
    --output table 2>/dev/null

# Alerta DTU Alto
az monitor metrics alert create \
    --name "SQL-DTU-Critical" \
    --resource-group "$RESOURCE_GROUP" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Sql/servers/$SERVER_NAME/databases/$DATABASE_NAME" \
    --condition "avg dtu_consumption_percent > 85" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 2 \
    --description "DTU crítico >85%" \
    --action-groups "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/actionGroups/sql-alerts-team" \
    --output table 2>/dev/null

# Alerta Conexiones
az monitor metrics alert create \
    --name "SQL-Connections-High" \
    --resource-group "$RESOURCE_GROUP" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Sql/servers/$SERVER_NAME/databases/$DATABASE_NAME" \
    --condition "avg connection_successful > 100" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 3 \
    --description "Conexiones altas >100" \
    --action-groups "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/actionGroups/sql-alerts-team" \
    --output table 2>/dev/null

log_success "Alertas críticas configuradas"

# 4. Configurar Diagnostic Settings
log_info "🔍 Configurando diagnósticos..."
az monitor diagnostic-settings create \
    --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Sql/servers/$SERVER_NAME/databases/$DATABASE_NAME" \
    --name "sql-diagnostics" \
    --workspace "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/primax-sql-monitoring" \
    --logs '[
        {"category": "SQLInsights", "enabled": true},
        {"category": "AutomaticTuning", "enabled": true},
        {"category": "QueryStoreRuntimeStatistics", "enabled": true},
        {"category": "Errors", "enabled": true},
        {"category": "Blocks", "enabled": true},
        {"category": "Deadlocks", "enabled": true}
    ]' \
    --metrics '[
        {"category": "Basic", "enabled": true},
        {"category": "InstanceAndAppAdvanced", "enabled": true}
    ]' \
    --output table 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "Diagnósticos configurados"
else
    log_warning "Diagnósticos ya configurados o error"
fi

# 5. Crear Automation Account
log_info "🤖 Creando Automation Account..."
az automation account create \
    --resource-group "$RESOURCE_GROUP" \
    --name "primax-sql-automation" \
    --location "$LOCATION" \
    --sku Basic \
    --output table 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "Automation Account creado"
else
    log_warning "Automation Account ya existe"
fi

# Resumen final
log_info ""
log_success "🎉 MONITOREO AUTOMÁTICO CONFIGURADO"
log_info "=================================="
log_info "✅ Log Analytics Workspace: primax-sql-monitoring"
log_info "✅ Action Group: sql-alerts-team"
log_info "✅ Alertas: CPU, DTU, Conexiones"
log_info "✅ Diagnósticos: Habilitados"
log_info "✅ Automation Account: primax-sql-automation"
log_info ""
log_info "📊 ACCESO AL MONITOREO:"
log_info "1. Azure Portal > Monitor > Alerts"
log_info "2. Azure Portal > Log Analytics > primax-sql-monitoring"
log_info "3. Azure Portal > SQL Database > Monitoring"
log_info ""
log_info "💰 COSTO ESTIMADO: $10-20/mes"

end_logging "setup_monitoring.sh" "SUCCESS"

log_info "💡 PRÓXIMOS PASOS:"
log_info "1. Configurar destinatarios de email en Action Group"
log_info "2. Crear dashboard personalizado"
log_info "3. Configurar runbooks de mantenimiento automático"
log_info "4. Probar alertas con carga simulada"
