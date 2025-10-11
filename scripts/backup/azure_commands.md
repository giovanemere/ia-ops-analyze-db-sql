# 🔍 Comandos para Obtener Información de Azure

## 1. Login en Azure CLI

```bash
# Logout primero (limpiar sesión)
az logout

# Login con tu tenant específico
az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"
```

## 2. Obtener Resource Group

```bash
# Ver todos los resource groups
az group list --output table

# Buscar el servidor SQL específico
az sql server list --query "[?contains(name, 'persqlmotorpromocprd')]" --output table

# Si encuentras el servidor, obtener su resource group
az sql server show --name persqlmotorpromocprd --resource-group [RESOURCE_GROUP_NAME] --output table
```

## 3. Obtener Storage Accounts

```bash
# Ver todos los storage accounts
az storage account list --output table

# Ver storage accounts en un resource group específico
az storage account list --resource-group [RESOURCE_GROUP_NAME] --output table
```

## 4. Crear Storage Account (si no existe)

```bash
# Crear storage account
az storage account create \
    --name primax2024storage \
    --resource-group [RESOURCE_GROUP_NAME] \
    --location eastus \
    --sku Standard_LRS \
    --kind StorageV2

# Crear contenedor para backups
az storage container create \
    --name backups \
    --account-name primax2024storage
```

## 5. Comandos Alternativos (si no tienes acceso completo)

### Opción A: Usar Azure Portal
1. Ir a https://portal.azure.com
2. Buscar "persqlmotorpromocprd" 
3. Ver el Resource Group en la página del servidor
4. Ir a Storage Accounts para ver los disponibles

### Opción B: Usar información de conexión
```bash
# El servidor ya lo conoces: persqlmotorpromocprd.database.windows.net
# Esto sugiere que el resource group podría ser algo como:
# - primax-prod-rg
# - persql-rg  
# - motor-promo-rg
```

## 6. Valores Típicos para Primax

Basándome en el nombre del servidor, probablemente:

```bash
# Posibles resource groups
RESOURCE_GROUP="primax-prod-rg"
# o
RESOURCE_GROUP="persql-motor-promo-rg"

# Storage account sugerido
STORAGE_ACCOUNT="primaxbackupstorage"
# o
STORAGE_ACCOUNT="persqlbackups2024"
```

## 7. Script de Prueba Rápida

```bash
# Probar diferentes nombres comunes
for rg in "primax-prod-rg" "persql-rg" "motor-promo-rg" "primax-rg"; do
    echo "Probando resource group: $rg"
    az sql server show --name persqlmotorpromocprd --resource-group "$rg" 2>/dev/null && echo "✅ Encontrado en: $rg" && break
done
```

## 8. Información de tu Suscripción

Ya tienes:
- **Subscription ID:** 617fad55-504d-42d2-ba0e-267e8472a399
- **Subscription Name:** suscription azure devops  
- **Tenant ID:** d98b231e-79bb-4aff-b916-0157f4cdc5bc
