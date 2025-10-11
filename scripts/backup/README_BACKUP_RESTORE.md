# 💾 Guía Completa de Backup y Restore

## 🎯 Objetivo

Proporcionar scripts completos y automatizados para realizar backup y restore de la base de datos SQL Azure `persqldbmotorpromocprd`.

## 📁 Estructura de Archivos

```
scripts/backup/
├── 01_full_backup.sql                  # Análisis pre-backup y verificación
├── 02_azure_backup.ps1                 # Backup usando PowerShell + Azure CLI
├── 03_restore_database.ps1             # Restore usando PowerShell + Azure CLI
├── 04_backup_azure_cli.sh              # Backup usando Bash + Azure CLI
├── 05_verify_backup_restore.sql        # Verificación post-backup/restore
├── get_azure_info.sh                   # Script para obtener info de Azure
├── azure_commands.md                   # Comandos para configuración
└── README_BACKUP_RESTORE.md            # Esta guía
```

## 🚀 Inicio Rápido

### Para hacer backup AHORA:

1. **Obtener Resource Group:**
   ```bash
   # Opción más fácil: Azure Portal
   # Ve a https://portal.azure.com y busca "persqlmotorpromocprd"
   
   # O usar Azure CLI:
   az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"
   az sql server list --query "[?contains(name, 'persqlmotorpromocprd')]" --output table
   ```

2. **Crear Storage Account:**
   ```bash
   # Reemplazar [TU_RESOURCE_GROUP] con el valor real
   az storage account create \
       --name primaxbackups2024 \
       --resource-group [TU_RESOURCE_GROUP] \
       --location eastus \
       --sku Standard_LRS
   
   az storage container create \
       --name backups \
       --account-name primaxbackups2024
   ```

3. **Ejecutar Backup:**
   ```powershell
   # PowerShell - Actualizar $ResourceGroupName
   $ResourceGroupName = "[TU_RESOURCE_GROUP]"
   
   .\scripts\backup\02_azure_backup.ps1 `
       -ResourceGroupName $ResourceGroupName `
       -ServerName "persqlmotorpromocprd" `
       -DatabaseName "persqldbmotorpromocprd" `
       -StorageAccountName "primaxbackups2024" `
       -ContainerName "backups" `
       -AdminLogin "u_yairpanqueva" `
       -AdminPassword "0x2E0403602967FDD263E5"
   ```

### Tiempo estimado: 60-90 minutos para ~30GB

---

## ⚙️ Configuración Inicial Requerida

### 1. Obtener Resource Group y Storage Account

**Opción A: Usar Azure Portal (Recomendado)**
1. Ve a https://portal.azure.com
2. Busca "persqlmotorpromocprd"
3. Anota el **Resource Group** mostrado
4. Ve a "Storage accounts" para ver los disponibles

**Opción B: Usar Azure CLI**
```bash
# Login en Azure
az logout
az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"

# Buscar el servidor y su resource group
az sql server list --query "[?contains(name, 'persqlmotorpromocprd')]" --output table

# Ver storage accounts disponibles
az storage account list --output table
```

**Opción C: Usar script automatizado**
```bash
./scripts/backup/get_azure_info.sh
```

### 2. Crear Storage Account (si no existe)

```bash
# Crear storage account para backups
az storage account create \
    --name primaxbackups2024 \
    --resource-group [TU_RESOURCE_GROUP] \
    --location eastus \
    --sku Standard_LRS \
    --kind StorageV2

# Crear contenedor para backups
az storage container create \
    --name backups \
    --account-name primaxbackups2024
```

## 🚀 Métodos de Backup

### Información de la Base de Datos:
- **Servidor:** persqlmotorpromocprd.database.windows.net
- **Base de Datos:** persqldbmotorpromocprd
- **Usuario:** u_yairpanqueva
- **Tamaño Estimado:** ~30 GB (58M registros)
- **Tenant ID:** d98b231e-79bb-4aff-b916-0157f4cdc5bc

### Método 1: PowerShell + Azure CLI (Recomendado)

```powershell
# PASO 1: Configurar variables (ACTUALIZAR CON TUS VALORES)
$ResourceGroupName = "TU_RESOURCE_GROUP"        # Obtener de Azure Portal
$StorageAccountName = "primaxbackups2024"       # Crear si no existe
$ContainerName = "backups"

# PASO 2: Ejecutar backup
.\02_azure_backup.ps1 `
    -ResourceGroupName $ResourceGroupName `
    -ServerName "persqlmotorpromocprd" `
    -DatabaseName "persqldbmotorpromocprd" `
    -StorageAccountName $StorageAccountName `
    -ContainerName $ContainerName `
    -AdminLogin "u_yairpanqueva" `
    -AdminPassword "0x2E0403602967FDD263E5"
```

### Método 2: Bash + Azure CLI (Linux/macOS)

```bash
# PASO 1: Editar variables en el script
nano scripts/backup/04_backup_azure_cli.sh

# Actualizar estas líneas:
RESOURCE_GROUP="TU_RESOURCE_GROUP"              # Obtener de Azure Portal
STORAGE_ACCOUNT="primaxbackups2024"             # Crear si no existe

# PASO 2: Ejecutar backup
./scripts/backup/04_backup_azure_cli.sh
```

### Método 3: Azure CLI Manual

```bash
# Backup directo
az sql db export \
    --resource-group "your-resource-group" \
    --server "persqlmotorpromocprd" \
    --name "persqldbmotorpromocprd" \
    --storage-key "your-storage-key" \
    --storage-key-type StorageAccessKey \
    --storage-uri "https://yourstorageaccount.blob.core.windows.net/backups/backup.bacpac" \
    --admin-user "u_yairpanqueva" \
    --admin-password "0x2E0403602967FDD263E5"
```

## 🔄 Métodos de Restore

### Método 1: PowerShell + Azure CLI (Recomendado)

```powershell
# PASO 1: Configurar variables
$ResourceGroupName = "TU_RESOURCE_GROUP"        # El mismo del backup
$StorageAccountName = "primaxbackups2024"       # El mismo del backup
$BackupFileName = "persqldbmotorpromocprd_backup_20251010_180000.bacpac"  # Nombre del archivo de backup

# PASO 2: Ejecutar restore
.\03_restore_database.ps1 `
    -ResourceGroupName $ResourceGroupName `
    -ServerName "persqlmotorpromocprd" `
    -NewDatabaseName "persqldbmotorpromocprd_restored" `
    -StorageAccountName $StorageAccountName `
    -ContainerName "backups" `
    -BackupFileName $BackupFileName `
    -AdminLogin "u_yairpanqueva" `
    -AdminPassword "0x2E0403602967FDD263E5" `
    -ServiceTier "HS_Gen5_12"
```

### Método 2: Azure CLI Manual

```bash
# PASO 1: Configurar variables
RESOURCE_GROUP="TU_RESOURCE_GROUP"
STORAGE_ACCOUNT="primaxbackups2024"
BACKUP_FILE="persqldbmotorpromocprd_backup_20251010_180000.bacpac"

# PASO 2: Obtener storage key
STORAGE_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "[0].value" --output tsv)

# PASO 3: Ejecutar restore
az sql db import \
    --resource-group $RESOURCE_GROUP \
    --server "persqlmotorpromocprd" \
    --name "persqldbmotorpromocprd_test" \
    --storage-key $STORAGE_KEY \
    --storage-key-type StorageAccessKey \
    --storage-uri "https://$STORAGE_ACCOUNT.blob.core.windows.net/backups/$BACKUP_FILE" \
    --admin-user "u_yairpanqueva" \
    --admin-password "0x2E0403602967FDD263E5" \
    --service-objective "HS_Gen5_12"
```

## 📋 Proceso Completo de Backup

### 1. Pre-Backup (Análisis)
```bash
# Ejecutar análisis pre-backup
/opt/mssql-tools/bin/sqlcmd \
    -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd \
    -U u_yairpanqueva \
    -P 0x2E0403602967FDD263E5 \
    -i scripts/backup/01_full_backup.sql \
    -o reports/pre_backup_analysis.txt \
    -t 300
```

### 2. Backup Principal
```powershell
# ACTUALIZAR ESTAS VARIABLES PRIMERO:
$ResourceGroupName = "TU_RESOURCE_GROUP"     # Obtener de Azure Portal
$StorageAccountName = "primaxbackups2024"    # Crear si no existe

# Ejecutar backup
.\scripts\backup\02_azure_backup.ps1 `
    -ResourceGroupName $ResourceGroupName `
    -ServerName "persqlmotorpromocprd" `
    -DatabaseName "persqldbmotorpromocprd" `
    -StorageAccountName $StorageAccountName `
    -ContainerName "backups" `
    -AdminLogin "u_yairpanqueva" `
    -AdminPassword "0x2E0403602967FDD263E5"
```

### 3. Verificación Post-Backup
```bash
# Verificar integridad
/opt/mssql-tools/bin/sqlcmd \
    -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd \
    -U u_yairpanqueva \
    -P 0x2E0403602967FDD263E5 \
    -i scripts/backup/05_verify_backup_restore.sql \
    -o reports/post_backup_verification.txt \
    -t 300
```

## 🔄 Proceso Completo de Restore

### 1. Restore Principal
```powershell
# Ejecutar restore
.\03_restore_database.ps1 -ResourceGroupName "myRG" -ServerName "persqlmotorpromocprd" -NewDatabaseName "persqldbmotorpromocprd_test" -StorageAccountName "mystorage" -ContainerName "backups" -BackupFileName "backup.bacpac" -AdminLogin "u_yairpanqueva" -AdminPassword "0x2E0403602967FDD263E5"
```

### 2. Verificación Post-Restore
```sql
-- Verificar base de datos restaurada
sqlcmd -S persqlmotorpromocprd.database.windows.net \
       -d persqldbmotorpromocprd_test \
       -U u_yairpanqueva \
       -P 0x2E0403602967FDD263E5 \
       -i 05_verify_backup_restore.sql \
       -o post_restore_verification.txt
```

## ⚙️ Configuración Requerida

### 1. Azure CLI
```bash
# Instalar Azure CLI (si no está instalado)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login con tenant específico
az logout
az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"

# Verificar suscripción
az account show
```

### 2. Obtener Resource Group
```bash
# Método 1: Buscar el servidor SQL
az sql server list --query "[?contains(name, 'persqlmotorpromocprd')]" --output table

# Método 2: Ver todos los resource groups
az group list --output table

# Método 3: Usar Azure Portal (más fácil)
# 1. Ve a https://portal.azure.com
# 2. Busca "persqlmotorpromocprd"
# 3. Anota el Resource Group mostrado
```

### 3. Crear/Verificar Storage Account
```bash
# Ver storage accounts existentes
az storage account list --output table

# Crear nuevo storage account (si no existe)
az storage account create \
    --name primaxbackups2024 \
    --resource-group [TU_RESOURCE_GROUP] \
    --location eastus \
    --sku Standard_LRS \
    --kind StorageV2

# Crear contenedor para backups
az storage container create \
    --name backups \
    --account-name primaxbackups2024
```

### 4. Permisos Requeridos
- **SQL Database Contributor** en la base de datos
- **Storage Blob Data Contributor** en el storage account
- **Reader** en el resource group

### 5. Información de tu Entorno
- **Subscription ID:** 617fad55-504d-42d2-ba0e-267e8472a399
- **Subscription Name:** suscription azure devops
- **Tenant ID:** d98b231e-79bb-4aff-b916-0157f4cdc5bc
- **Servidor SQL:** persqlmotorpromocprd.database.windows.net

## 📊 Información de la Base de Datos

### Tamaños Estimados:
- **CuponesDigitales:** ~13.5 GB (45M registros)
- **CuponesFisicoCorreccion:** ~13.6 GB (12M registros)
- **Otras tablas:** ~1 GB
- **Total estimado:** ~28 GB

### Tiempos Estimados:
- **Backup:** 30-60 minutos
- **Restore:** 45-90 minutos
- **Verificación:** 5-10 minutos

## 🎯 Estrategias de Backup

### 1. Backup Diario Automatizado
```bash
# Cron job para backup diario a las 2:00 AM
0 2 * * * /path/to/04_backup_azure_cli.sh >> /var/log/sql_backup.log 2>&1
```

### 2. Backup Semanal Completo
```powershell
# Task Scheduler para backup semanal
.\02_azure_backup.ps1 -ResourceGroupName "prod-rg" -ServerName "persqlmotorpromocprd" -DatabaseName "persqldbmotorpromocprd" -StorageAccountName "prodbackups" -ContainerName "weekly" -AdminLogin "u_yairpanqueva" -AdminPassword "0x2E0403602967FDD263E5"
```

### 3. Backup Pre-Mantenimiento
```sql
-- Antes de mantenimiento crítico
sqlcmd -i 01_full_backup.sql -o pre_maintenance_analysis.txt
```

## 🚨 Consideraciones Importantes

### Limitaciones de SQL Azure:
- **No soporta** `BACKUP TO DISK` tradicional
- **Requiere** Azure Storage para BACPAC
- **Tiempo de export** proporcional al tamaño
- **Costo** de storage y transferencia

### Mejores Prácticas:
- **Probar restore** regularmente
- **Monitorear** espacio de storage
- **Documentar** ubicaciones de backup
- **Verificar integridad** post-restore
- **Mantener** múltiples copias
- **Automatizar** proceso cuando sea posible

### Seguridad:
- **Encriptar** archivos BACPAC
- **Rotar** claves de storage
- **Limitar** acceso a containers
- **Auditar** operaciones de backup/restore

## 📈 Monitoreo y Alertas

### 1. Verificar Estado de Export/Import
```bash
# Monitorear operación
az sql db export-status show --operation-id "operation-id" --resource-group "rg" --server "server"
```

### 2. Alertas de Storage
```bash
# Configurar alertas de espacio
az monitor metrics alert create \
    --name "Storage Space Alert" \
    --resource-group "rg" \
    --scopes "/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/storage" \
    --condition "avg UsedCapacity > 80000000000"
```

## 🔧 Troubleshooting

### Errores Comunes:

1. **"Login failed for user 'u_yairpanqueva'"**
   ```bash
   # Verificar credenciales y firewall
   /opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net -U u_yairpanqueva -P 0x2E0403602967FDD263E5 -Q "SELECT 1"
   ```

2. **"Storage account not found"**
   ```bash
   # Verificar que existe
   az storage account show --name primaxbackups2024 --resource-group [TU_RESOURCE_GROUP]
   
   # Crear si no existe
   az storage account create --name primaxbackups2024 --resource-group [TU_RESOURCE_GROUP] --location eastus --sku Standard_LRS
   ```

3. **"AADSTS70008: Authorization code expired"**
   ```bash
   # Re-login en Azure CLI
   az logout
   az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"
   ```

4. **"Export timeout"**
   ```bash
   # La BD es grande (~30GB), el export puede tomar 60-90 minutos
   # Verificar estado:
   az sql db export-status show --operation-id [OPERATION_ID] --resource-group [RG] --server persqlmotorpromocprd
   ```

5. **"Insufficient permissions"**
   ```bash
   # Verificar roles en Azure Portal:
   # - SQL Database Contributor
   # - Storage Blob Data Contributor
   ```

### Comandos de Diagnóstico:
```bash
# Verificar conexión a SQL
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net -U u_yairpanqueva -P 0x2E0403602967FDD263E5 -Q "SELECT DB_NAME(), GETDATE()"

# Verificar Azure CLI
az account show

# Verificar storage account
az storage account list --output table

# Ver operaciones de export/import recientes
az sql db list-export-import-status --server persqlmotorpromocprd --resource-group [TU_RESOURCE_GROUP]
```

### Logs y Monitoreo:
```bash
# Ver logs detallados de Azure CLI
az configure --defaults group=[TU_RESOURCE_GROUP]
az sql db export --debug

# Monitorear progreso de backup
watch -n 30 'az sql db export-status show --operation-id [OPERATION_ID] --resource-group [RG] --server persqlmotorpromocprd'
```

## 📞 Soporte

Para problemas:
1. Verificar logs de Azure CLI
2. Revisar permisos y configuración
3. Consultar documentación de Azure SQL
4. Contactar soporte de Azure si es necesario

---

**Versión:** 1.0  
**Última actualización:** 2025-01-10  
**Compatibilidad:** SQL Azure Database, Azure CLI 2.0+
