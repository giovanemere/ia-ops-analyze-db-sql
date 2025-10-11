# 📊 Sistema de Monitoreo Automático en Azure

## 🎯 Objetivo
Configurar monitoreo automático para la base de datos SQL Azure optimizada y detectar degradación de rendimiento.

## 🔧 Componentes de Monitoreo Automático

### 1. 📈 Azure Monitor + Log Analytics

#### Crear Log Analytics Workspace:
```bash
# Crear workspace para logs centralizados
az monitor log-analytics workspace create \
    --resource-group PERRSGRPYPRMTCLLYP \
    --workspace-name "primax-sql-monitoring" \
    --location eastus2 \
    --sku PerGB2018
```

#### Configurar Diagnostic Settings:
```bash
# Habilitar logs de diagnóstico para SQL Database
az monitor diagnostic-settings create \
    --resource "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERRSGRPYPRMTCLLYP/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --name "sql-diagnostics" \
    --workspace "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERRSGRPYPRMTCLLYP/providers/Microsoft.OperationalInsights/workspaces/primax-sql-monitoring" \
    --logs '[
        {"category": "SQLInsights", "enabled": true},
        {"category": "AutomaticTuning", "enabled": true},
        {"category": "QueryStoreRuntimeStatistics", "enabled": true},
        {"category": "QueryStoreWaitStatistics", "enabled": true},
        {"category": "Errors", "enabled": true},
        {"category": "DatabaseWaitStatistics", "enabled": true},
        {"category": "Timeouts", "enabled": true},
        {"category": "Blocks", "enabled": true},
        {"category": "Deadlocks", "enabled": true}
    ]' \
    --metrics '[
        {"category": "Basic", "enabled": true},
        {"category": "InstanceAndAppAdvanced", "enabled": true}
    ]'
```

### 2. 🚨 Alertas Automáticas

#### CPU Alto (>80%):
```bash
az monitor metrics alert create \
    --name "SQL-CPU-High" \
    --resource-group PERRSGRPYPRMTCLLYP \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERRSGRPYPRMTCLLYP/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg cpu_percent > 80" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 2 \
    --description "CPU usage above 80% for 5 minutes"
```

#### DTU Alto (>80%):
```bash
az monitor metrics alert create \
    --name "SQL-DTU-High" \
    --resource-group PERRSGRPYPRMTCLLYP \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERRSGRPYPRMTCLLYP/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg dtu_consumption_percent > 80" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 2 \
    --description "DTU consumption above 80%"
```

#### Bloqueos Prolongados:
```bash
az monitor metrics alert create \
    --name "SQL-Blocks-High" \
    --resource-group PERRSGRPYPRMTCLLYP \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERRSGRPYPRMTCLLYP/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg blocked_by_firewall > 0" \
    --window-size 1m \
    --evaluation-frequency 1m \
    --severity 3 \
    --description "Database blocks detected"
```

### 3. 📊 Dashboard Automático

#### Crear Dashboard:
```bash
# Crear dashboard personalizado
az portal dashboard create \
    --resource-group PERRSGRPYPRMTCLLYP \
    --name "SQL-Performance-Dashboard" \
    --input-path dashboard-config.json
```

### 4. 🔄 Azure Automation para Mantenimiento

#### Crear Automation Account:
```bash
az automation account create \
    --resource-group PERRSGRPYPRMTCLLYP \
    --name "primax-sql-automation" \
    --location eastus2 \
    --sku Basic
```

#### Script de Mantenimiento Automático:
```powershell
# Runbook para mantenimiento semanal
param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName = "persqlmotorpromocprd",
    
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName = "persqldbmotorpromocprd"
)

# Conectar a Azure
$connectionName = "AzureRunAsConnection"
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
Connect-AzAccount -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

# Ejecutar mantenimiento automático
$query = @"
-- Actualizar estadísticas automáticamente
UPDATE STATISTICS CuponesDigitales;
UPDATE STATISTICS CuponesFisicoCorreccion;

-- Verificar fragmentación
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD NEEDED'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE NEEDED'
        ELSE 'OK'
    END AS Action
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 5
ORDER BY ips.avg_fragmentation_in_percent DESC;
"@

Invoke-Sqlcmd -ServerInstance "$ServerName.database.windows.net" -Database $DatabaseName -Query $query
"@
```

### 5. 📱 Notificaciones Automáticas

#### Action Group para Notificaciones:
```bash
az monitor action-group create \
    --resource-group PERRSGRPYPRMTCLLYP \
    --name "sql-alerts-team" \
    --short-name "sqlalerts" \
    --email-receivers name="DBA Team" email="dba@primax.com" \
    --sms-receivers name="OnCall" country-code="57" phone-number="3001234567"
```

### 6. 🤖 Logic Apps para Automatización

#### Crear Logic App para Respuesta Automática:
```bash
az logic workflow create \
    --resource-group PERRSGRPYPRMTCLLYP \
    --name "sql-auto-response" \
    --location eastus2 \
    --definition '{
        "triggers": {
            "When_an_alert_is_fired": {
                "type": "ApiConnection",
                "inputs": {
                    "host": {
                        "connection": {
                            "name": "@parameters(\"$connections\")[\"azuremonitorlogs\"][\"connectionId\"]"
                        }
                    }
                }
            }
        },
        "actions": {
            "Send_notification": {
                "type": "ApiConnection",
                "inputs": {
                    "host": {
                        "connection": {
                            "name": "@parameters(\"$connections\")[\"teams\"][\"connectionId\"]"
                        }
                    },
                    "method": "post",
                    "body": {
                        "text": "🚨 SQL Alert: @{triggerBody()[\"data\"][\"alertContext\"][\"condition\"][\"allOf\"][0][\"metricName\"]} exceeded threshold"
                    }
                }
            }
        }
    }'
```

## 📊 Consultas KQL para Monitoreo

### Rendimiento de Consultas:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.SQL"
| where Category == "QueryStoreRuntimeStatistics"
| summarize avg(avg_duration_d) by bin(TimeGenerated, 1h), query_hash_s
| render timechart
```

### Top Consultas Costosas:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.SQL"
| where Category == "QueryStoreRuntimeStatistics"
| top 10 by avg_cpu_time_d desc
| project TimeGenerated, query_hash_s, avg_cpu_time_d, avg_duration_d
```

### Bloqueos y Deadlocks:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.SQL"
| where Category in ("Blocks", "Deadlocks")
| summarize count() by bin(TimeGenerated, 1h), Category
| render columnchart
```

## 🎯 Configuración Rápida

### Script de Configuración Completa:
```bash
#!/bin/bash
# Configurar monitoreo completo

RESOURCE_GROUP="PERRSGRPYPRMTCLLYP"
LOCATION="eastus2"
SUBSCRIPTION_ID="06974a39-ae7c-476c-a773-2221c1ae76a2"

# 1. Crear Log Analytics
az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name "primax-sql-monitoring" \
    --location $LOCATION \
    --sku PerGB2018

# 2. Crear Action Group
az monitor action-group create \
    --resource-group $RESOURCE_GROUP \
    --name "sql-alerts-team" \
    --short-name "sqlalerts"

# 3. Configurar alertas críticas
az monitor metrics alert create \
    --name "SQL-CPU-Critical" \
    --resource-group $RESOURCE_GROUP \
    --condition "avg cpu_percent > 90" \
    --window-size 5m \
    --severity 1

echo "✅ Monitoreo automático configurado"
```

## 📈 Beneficios del Monitoreo Automático

1. **Detección Proactiva** - Alertas antes de problemas críticos
2. **Mantenimiento Automático** - Estadísticas y reorganización
3. **Visibilidad Completa** - Dashboards en tiempo real
4. **Respuesta Rápida** - Notificaciones inmediatas
5. **Análisis Histórico** - Tendencias y patrones
6. **Optimización Continua** - Ajustes automáticos

## 💰 Costos Estimados

- **Log Analytics:** ~$2-5/GB/mes
- **Alertas:** ~$0.10/alerta/mes
- **Automation Account:** ~$5/mes
- **Logic Apps:** ~$0.000025/acción

**Total estimado:** $10-20/mes para monitoreo completo

---

**Recomendación:** Implementar en fases, comenzando con alertas críticas y expandiendo gradualmente.
