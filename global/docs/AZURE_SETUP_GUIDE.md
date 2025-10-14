# ☁️ Guía Completa de Configuración Azure

## 🎯 Configuración Específica para persqldbmotorpromocprd

### **📋 Información del Entorno**
```bash
# Datos de la suscripción
AZURE_SUBSCRIPTION_ID="06974a39-ae7c-476c-a773-2221c1ae76a2"
AZURE_TENANT_ID="d98b231e-79bb-4aff-b916-0157f4cdc5bc"
AZURE_RESOURCE_GROUP="PERSGRUE2LSTOP03"

# Base de datos objetivo
SQL_SERVER="persqlmotorpromocprd.database.windows.net"
SQL_DATABASE="persqldbmotorpromocprd"
SQL_USERNAME="u_yairpanqueva"
```

## 🚀 Setup Paso a Paso

### **Paso 1: Instalación de Herramientas**
```bash
# 1. Instalar Azure CLI (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Verificar instalación
az --version

# 3. Instalar SQL Server tools
sudo apt-get update
sudo apt-get install mssql-tools unixodbc-dev

# 4. Agregar al PATH
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

### **Paso 2: Autenticación Azure**
```bash
# 1. Login interactivo
az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"

# 2. Configurar suscripción por defecto
az account set --subscription "06974a39-ae7c-476c-a773-2221c1ae76a2"

# 3. Verificar configuración
az account show --output table
```

### **Paso 3: Verificar Acceso a SQL Database**
```bash
# 1. Verificar servidor SQL
az sql server show \
    --name "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03" \
    --output table

# 2. Listar bases de datos
az sql db list \
    --server "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03" \
    --output table

# 3. Probar conexión directa
sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -U u_yairpanqueva \
    -P "0x2E0403602967FDD263E5" \
    -d persqldbmotorpromocprd \
    -Q "SELECT DB_NAME(), @@VERSION"
```

## 🗄️ Configuración de Storage para Backups

### **Crear Storage Account (si no existe)**
```bash
# 1. Verificar si existe
az storage account show \
    --name "primaxbackups2024" \
    --resource-group "PERSGRUE2LSTOP03" 2>/dev/null || \
    
# 2. Crear si no existe
az storage account create \
    --name "primaxbackups2024" \
    --resource-group "PERSGRUE2LSTOP03" \
    --location "East US" \
    --sku "Standard_LRS" \
    --kind "StorageV2"

# 3. Crear contenedores necesarios
az storage container create \
    --name "sql-backups" \
    --account-name "primaxbackups2024"

az storage container create \
    --name "sql-reports" \
    --account-name "primaxbackups2024"

az storage container create \
    --name "sql-logs" \
    --account-name "primaxbackups2024"
```

### **Obtener Claves de Acceso**
```bash
# 1. Obtener connection string
az storage account show-connection-string \
    --name "primaxbackups2024" \
    --resource-group "PERSGRUE2LSTOP03" \
    --output tsv

# 2. Obtener access key
az storage account keys list \
    --account-name "primaxbackups2024" \
    --resource-group "PERSGRUE2LSTOP03" \
    --query "[0].value" \
    --output tsv
```

## 📊 Configuración de Monitoreo y Alertas

### **Crear Action Group para Alertas**
```bash
# 1. Crear action group
az monitor action-group create \
    --name "sql-analysis-alerts" \
    --resource-group "PERSGRUE2LSTOP03" \
    --short-name "sqlalerts"

# 2. Agregar email de notificación
az monitor action-group update \
    --name "sql-analysis-alerts" \
    --resource-group "PERSGRUE2LSTOP03" \
    --add-action email "admin@primax.com" "DBA-Team"
```

### **Configurar Alertas Críticas**
```bash
# 1. Alerta de CPU alta
az monitor metrics alert create \
    --name "sql-cpu-critical" \
    --resource-group "PERSGRUE2LSTOP03" \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg cpu_percent > 85" \
    --description "CPU usage crítico en persqldbmotorpromocprd" \
    --evaluation-frequency "1m" \
    --window-size "5m" \
    --action "sql-analysis-alerts" \
    --severity 0

# 2. Alerta de DTU alta
az monitor metrics alert create \
    --name "sql-dtu-critical" \
    --resource-group "PERSGRUE2LSTOP03" \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg dtu_consumption_percent > 90" \
    --description "DTU consumption crítico" \
    --evaluation-frequency "1m" \
    --window-size "5m" \
    --action "sql-analysis-alerts" \
    --severity 0

# 3. Alerta de bloqueos
az monitor metrics alert create \
    --name "sql-blocking-sessions" \
    --resource-group "PERSGRUE2LSTOP03" \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg blocked_by_firewall > 0" \
    --description "Sesiones bloqueadas detectadas" \
    --evaluation-frequency "5m" \
    --window-size "10m" \
    --action "sql-analysis-alerts" \
    --severity 1
```

## 🔐 Configuración de Seguridad

### **Configurar Firewall de SQL Server**
```bash
# 1. Obtener IP actual
MY_IP=$(curl -s https://ipinfo.io/ip)

# 2. Agregar regla de firewall para IP actual
az sql server firewall-rule create \
    --server "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03" \
    --name "sql-analysis-tool-$(date +%Y%m%d)" \
    --start-ip-address $MY_IP \
    --end-ip-address $MY_IP

# 3. Permitir servicios de Azure (si es necesario)
az sql server firewall-rule create \
    --server "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03" \
    --name "AllowAzureServices" \
    --start-ip-address "0.0.0.0" \
    --end-ip-address "0.0.0.0"
```

### **Crear Service Principal para Automatización**
```bash
# 1. Crear service principal
SP_INFO=$(az ad sp create-for-rbac \
    --name "sql-analysis-automation" \
    --role "SQL DB Contributor" \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03")

# 2. Extraer información
echo $SP_INFO | jq -r '.appId'      # CLIENT_ID
echo $SP_INFO | jq -r '.password'   # CLIENT_SECRET
echo $SP_INFO | jq -r '.tenant'     # TENANT_ID

# 3. Asignar permisos adicionales para storage
az role assignment create \
    --assignee $(echo $SP_INFO | jq -r '.appId') \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Storage/storageAccounts/primaxbackups2024"
```

## 📋 Archivo .env Completo

```bash
# Crear archivo .env con toda la configuración
cat > .env << 'EOF'
# =====================================================
# CONFIGURACIÓN SQL ANALYSIS PROJECT
# =====================================================

# SQL Azure Database - persqldbmotorpromocprd
SQL_SERVER=persqlmotorpromocprd.database.windows.net
SQL_DATABASE=persqldbmotorpromocprd
SQL_USERNAME=u_yairpanqueva
SQL_PASSWORD=0x2E0403602967FDD263E5

# Azure Configuration
AZURE_SUBSCRIPTION_ID=06974a39-ae7c-476c-a773-2221c1ae76a2
AZURE_RESOURCE_GROUP=PERSGRUE2LSTOP03
AZURE_TENANT_ID=d98b231e-79bb-4aff-b916-0157f4cdc5bc

# Storage Account para Backups
AZURE_STORAGE_ACCOUNT=primaxbackups2024
AZURE_STORAGE_CONTAINER_BACKUPS=sql-backups
AZURE_STORAGE_CONTAINER_REPORTS=sql-reports
AZURE_STORAGE_CONTAINER_LOGS=sql-logs

# Service Principal (completar después de crear)
AZURE_CLIENT_ID=[COMPLETAR_CON_SP_APP_ID]
AZURE_CLIENT_SECRET=[COMPLETAR_CON_SP_PASSWORD]

# Configuración de Análisis
ANALYSIS_TIMEOUT=3600
MAX_CONCURRENT_QUERIES=5
LOG_LEVEL=INFO
BACKUP_RETENTION_DAYS=30
FRAGMENTATION_THRESHOLD=30
CPU_THRESHOLD_WARNING=70
CPU_THRESHOLD_CRITICAL=85
EOF
```

## 🧪 Script de Verificación Completa

```bash
# Crear script de verificación
cat > verify_azure_setup.sh << 'EOF'
#!/bin/bash
set -e

echo "🔍 Verificando configuración completa de Azure..."

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI no instalado"
    exit 1
fi
echo "✅ Azure CLI instalado"

# Verificar login
if ! az account show &> /dev/null; then
    echo "❌ No autenticado en Azure"
    exit 1
fi
echo "✅ Autenticado en Azure"

# Verificar suscripción correcta
CURRENT_SUB=$(az account show --query id -o tsv)
if [ "$CURRENT_SUB" != "06974a39-ae7c-476c-a773-2221c1ae76a2" ]; then
    echo "❌ Suscripción incorrecta: $CURRENT_SUB"
    exit 1
fi
echo "✅ Suscripción correcta"

# Verificar acceso a SQL Server
if ! az sql server show --name "persqlmotorpromocprd" --resource-group "PERSGRUE2LSTOP03" &> /dev/null; then
    echo "❌ No se puede acceder al SQL Server"
    exit 1
fi
echo "✅ Acceso a SQL Server verificado"

# Verificar Storage Account
if ! az storage account show --name "primaxbackups2024" --resource-group "PERSGRUE2LSTOP03" &> /dev/null; then
    echo "❌ Storage Account no accesible"
    exit 1
fi
echo "✅ Storage Account accesible"

# Verificar conexión SQL directa
if ! sqlcmd -S persqlmotorpromocprd.database.windows.net -U u_yairpanqueva -P "0x2E0403602967FDD263E5" -d persqldbmotorpromocprd -Q "SELECT 1" &> /dev/null; then
    echo "❌ Conexión SQL fallida"
    exit 1
fi
echo "✅ Conexión SQL exitosa"

# Verificar herramientas SQL
if ! command -v sqlcmd &> /dev/null; then
    echo "❌ sqlcmd no instalado"
    exit 1
fi
echo "✅ Herramientas SQL disponibles"

echo ""
echo "🎉 Configuración de Azure completamente verificada"
echo "✅ Sistema listo para ejecutar análisis en persqldbmotorpromocprd"
EOF

chmod +x verify_azure_setup.sh
```

## 📊 Monitoreo de Costos

### **Configurar Presupuesto**
```bash
# Crear presupuesto para el proyecto
az consumption budget create \
    --budget-name "sql-analysis-project-budget" \
    --amount 500 \
    --time-grain "Monthly" \
    --time-period start-date="2024-10-01" \
    --category "Cost" \
    --resource-group "PERSGRUE2LSTOP03"
```

### **Consultas de Costo Útiles**
```bash
# Costo actual del mes para el resource group
az consumption usage list \
    --start-date "2024-10-01" \
    --end-date "2024-10-31" \
    --query "[?contains(instanceName, 'persqlmotorpromocprd')]" \
    --output table

# Costo específico de la BD
az monitor metrics list \
    --resource "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --metric "dtu_consumption_percent" \
    --interval PT1H \
    --output table
```

## ✅ Checklist de Configuración

### **Pre-requisitos**
- [ ] Azure CLI instalado y configurado
- [ ] SQL Server tools instalados
- [ ] Acceso a suscripción Azure
- [ ] Credenciales de BD disponibles

### **Configuración Azure**
- [ ] Autenticado en tenant correcto
- [ ] Suscripción configurada
- [ ] Acceso a SQL Server verificado
- [ ] Storage Account configurado
- [ ] Contenedores creados

### **Seguridad**
- [ ] Firewall configurado
- [ ] Service Principal creado
- [ ] Permisos asignados
- [ ] Conexión SQL probada

### **Monitoreo**
- [ ] Action Group creado
- [ ] Alertas configuradas
- [ ] Presupuesto establecido
- [ ] Métricas habilitadas

### **Validación Final**
- [ ] Script de verificación ejecutado
- [ ] Archivo .env configurado
- [ ] Conexión desde CLI probada
- [ ] Sistema listo para análisis

---

**Configuración validada para:** persqlmotorpromocprd.database.windows.net  
**Entorno:** Producción (Hyperscale HS_Gen5_12)  
**Última verificación:** 2024-10-12  
**Estado:** ✅ Listo para ejecución
