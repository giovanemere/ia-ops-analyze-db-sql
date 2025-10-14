# ☁️ Configuración de Azure - SQL Analysis Project

## 🎯 Configuración Completa de Azure

### **📋 Pre-requisitos Azure**

#### **1. Suscripción y Recursos**
```bash
# Información de la suscripción
AZURE_SUBSCRIPTION_ID="06974a39-ae7c-476c-a773-2221c1ae76a2"
AZURE_TENANT_ID="d98b231e-79bb-4aff-b916-0157f4cdc5bc"
AZURE_RESOURCE_GROUP="PERSGRUE2LSTOP03"
```

#### **2. SQL Azure Database**
```bash
# Base de datos principal
SQL_SERVER="persqlmotorpromocprd.database.windows.net"
SQL_DATABASE="persqldbmotorpromocprd"
SQL_EDITION="Hyperscale"
SQL_TIER="HS_Gen5_12"
```

## 🔧 Instalación y Configuración

### **Paso 1: Instalar Azure CLI**
```bash
# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar instalación
az --version
```

### **Paso 2: Autenticación**
```bash
# Login interactivo
az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"

# Configurar suscripción por defecto
az account set --subscription "06974a39-ae7c-476c-a773-2221c1ae76a2"

# Verificar configuración
az account show
```

### **Paso 3: Configurar Acceso a SQL Database**
```bash
# Verificar acceso a SQL Server
az sql server show \
    --name "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03"

# Listar bases de datos
az sql db list \
    --server "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03" \
    --output table
```

## 🗄️ Configuración de Storage Account

### **Para Backups y Reportes**
```bash
# Crear Storage Account (si no existe)
az storage account create \
    --name "primaxbackups2024" \
    --resource-group "PERSGRUE2LSTOP03" \
    --location "East US" \
    --sku "Standard_LRS" \
    --kind "StorageV2"

# Crear contenedores
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
# Obtener connection string
az storage account show-connection-string \
    --name "primaxbackups2024" \
    --resource-group "PERSGRUE2LSTOP03"

# Obtener access keys
az storage account keys list \
    --account-name "primaxbackups2024" \
    --resource-group "PERSGRUE2LSTOP03"
```

## 📊 Configuración de Monitoreo

### **Azure Monitor y Alertas**
```bash
# Crear Action Group para alertas
az monitor action-group create \
    --name "sql-analysis-alerts" \
    --resource-group "PERSGRUE2LSTOP03" \
    --short-name "sqlalerts"

# Agregar email al action group
az monitor action-group update \
    --name "sql-analysis-alerts" \
    --resource-group "PERSGRUE2LSTOP03" \
    --add-action email "admin@primax.com" "Admin"
```

### **Métricas de SQL Database**
```bash
# Configurar alerta de CPU
az monitor metrics alert create \
    --name "sql-cpu-high" \
    --resource-group "PERSGRUE2LSTOP03" \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg cpu_percent > 80" \
    --description "CPU usage is above 80%" \
    --evaluation-frequency "1m" \
    --window-size "5m" \
    --action "sql-analysis-alerts"

# Configurar alerta de DTU
az monitor metrics alert create \
    --name "sql-dtu-high" \
    --resource-group "PERSGRUE2LSTOP03" \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Sql/servers/persqlmotorpromocprd/databases/persqldbmotorpromocprd" \
    --condition "avg dtu_consumption_percent > 85" \
    --description "DTU consumption is above 85%" \
    --evaluation-frequency "1m" \
    --window-size "5m" \
    --action "sql-analysis-alerts"
```

## 🔐 Configuración de Seguridad

### **Service Principal para Automatización**
```bash
# Crear Service Principal
az ad sp create-for-rbac \
    --name "sql-analysis-sp" \
    --role "SQL DB Contributor" \
    --scopes "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03"

# Asignar permisos adicionales
az role assignment create \
    --assignee [SERVICE_PRINCIPAL_ID] \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/06974a39-ae7c-476c-a773-2221c1ae76a2/resourceGroups/PERSGRUE2LSTOP03/providers/Microsoft.Storage/storageAccounts/primaxbackups2024"
```

### **Configuración de Firewall**
```bash
# Agregar IP actual al firewall
MY_IP=$(curl -s https://ipinfo.io/ip)
az sql server firewall-rule create \
    --server "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03" \
    --name "sql-analysis-tool" \
    --start-ip-address $MY_IP \
    --end-ip-address $MY_IP

# Permitir servicios de Azure
az sql server firewall-rule create \
    --server "persqlmotorpromocprd" \
    --resource-group "PERSGRUE2LSTOP03" \
    --name "AllowAzureServices" \
    --start-ip-address "0.0.0.0" \
    --end-ip-address "0.0.0.0"
```

## 📋 Variables de Entorno

### **Archivo .env Completo**
```bash
# SQL Azure Database
SQL_SERVER=persqlmotorpromocprd.database.windows.net
SQL_DATABASE=persqldbmotorpromocprd
SQL_USERNAME=u_yairpanqueva
SQL_PASSWORD=0x2E0403602967FDD263E5

# Azure Configuration
AZURE_SUBSCRIPTION_ID=06974a39-ae7c-476c-a773-2221c1ae76a2
AZURE_RESOURCE_GROUP=PERSGRUE2LSTOP03
AZURE_TENANT_ID=d98b231e-79bb-4aff-b916-0157f4cdc5bc

# Storage Account
AZURE_STORAGE_ACCOUNT=primaxbackups2024
AZURE_STORAGE_CONTAINER_BACKUPS=sql-backups
AZURE_STORAGE_CONTAINER_REPORTS=sql-reports
AZURE_STORAGE_CONTAINER_LOGS=sql-logs

# Service Principal (para automatización)
AZURE_CLIENT_ID=[SERVICE_PRINCIPAL_ID]
AZURE_CLIENT_SECRET=[SERVICE_PRINCIPAL_SECRET]

# Configuración de Análisis
ANALYSIS_TIMEOUT=3600
MAX_CONCURRENT_QUERIES=5
LOG_LEVEL=INFO
BACKUP_RETENTION_DAYS=30
```

## 🧪 Verificación de Configuración

### **Script de Verificación**
```bash
#!/bin/bash
# verify_azure_config.sh

echo "🔍 Verificando configuración de Azure..."

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI no instalado"
    exit 1
fi

# Verificar login
if ! az account show &> /dev/null; then
    echo "❌ No autenticado en Azure"
    exit 1
fi

# Verificar suscripción
CURRENT_SUB=$(az account show --query id -o tsv)
if [ "$CURRENT_SUB" != "06974a39-ae7c-476c-a773-2221c1ae76a2" ]; then
    echo "❌ Suscripción incorrecta"
    exit 1
fi

# Verificar acceso a SQL Server
if ! az sql server show --name "persqlmotorpromocprd" --resource-group "PERSGRUE2LSTOP03" &> /dev/null; then
    echo "❌ No se puede acceder al SQL Server"
    exit 1
fi

# Verificar Storage Account
if ! az storage account show --name "primaxbackups2024" --resource-group "PERSGRUE2LSTOP03" &> /dev/null; then
    echo "❌ Storage Account no accesible"
    exit 1
fi

echo "✅ Configuración de Azure verificada correctamente"
```

## 📊 Monitoreo de Costos

### **Configurar Alertas de Costo**
```bash
# Crear presupuesto
az consumption budget create \
    --budget-name "sql-analysis-budget" \
    --amount 1000 \
    --time-grain "Monthly" \
    --time-period start-date="2024-10-01" \
    --category "Cost" \
    --resource-group "PERSGRUE2LSTOP03"
```

### **Consultas de Costo Útiles**
```bash
# Costo actual del mes
az consumption usage list \
    --start-date "2024-10-01" \
    --end-date "2024-10-31" \
    --output table

# Costo por recurso
az consumption usage list \
    --start-date "2024-10-01" \
    --end-date "2024-10-31" \
    --query "[?contains(instanceName, 'persqlmotorpromocprd')]" \
    --output table
```

## 🎯 Mejores Prácticas

### **Seguridad**
1. **Usar Service Principal** para automatización
2. **Rotar credenciales** regularmente
3. **Principio de menor privilegio** en permisos
4. **Auditar accesos** regularmente

### **Costos**
1. **Monitorear uso** de DTU/vCore
2. **Configurar alertas** de presupuesto
3. **Revisar métricas** semanalmente
4. **Optimizar tier** según uso real

### **Performance**
1. **Usar métricas nativas** de Azure
2. **Configurar alertas** proactivas
3. **Revisar Query Store** regularmente
4. **Monitorear fragmentación** automáticamente

---

**Configuración validada para:** persqlmotorpromocprd.database.windows.net  
**Última actualización:** 2024-10-12  
**Responsable:** Equipo de Análisis DB
