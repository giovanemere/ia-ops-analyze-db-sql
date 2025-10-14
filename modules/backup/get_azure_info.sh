#!/bin/bash

# =====================================================
# OBTENER INFORMACIÓN DE AZURE
# Resource Group y Storage Account
# =====================================================

echo "🔍 OBTENIENDO INFORMACIÓN DE AZURE"
echo "=================================="

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI no está instalado"
    exit 1
fi

# Verificar login
if ! az account show &> /dev/null; then
    echo "⚠️  No está logueado. Ejecute: az login"
    exit 1
fi

echo "✅ Azure CLI verificado"
echo ""

# 1. INFORMACIÓN DE LA SUSCRIPCIÓN
echo "📋 INFORMACIÓN DE SUSCRIPCIÓN:"
echo "=============================="
az account show --query "{SubscriptionId:id, SubscriptionName:name, TenantId:tenantId}" --output table

echo ""

# 2. BUSCAR RESOURCE GROUPS
echo "📁 RESOURCE GROUPS DISPONIBLES:"
echo "==============================="
az group list --query "[].{Name:name, Location:location}" --output table

echo ""

# 3. BUSCAR EL SERVIDOR SQL
echo "🗄️  SERVIDORES SQL AZURE:"
echo "========================"
az sql server list --query "[].{ServerName:name, ResourceGroup:resourceGroup, Location:location}" --output table

echo ""

# 4. BUSCAR STORAGE ACCOUNTS
echo "💾 STORAGE ACCOUNTS DISPONIBLES:"
echo "==============================="
az storage account list --query "[].{StorageAccount:name, ResourceGroup:resourceGroup, Location:location, Tier:sku.tier}" --output table

echo ""

# 5. BUSCAR ESPECÍFICAMENTE EL SERVIDOR DE LA BD
echo "🎯 BUSCANDO SERVIDOR 'persqlmotorpromocprd':"
echo "==========================================="
SERVER_INFO=$(az sql server list --query "[?contains(name, 'persqlmotorpromocprd')]" --output json)

if [ "$SERVER_INFO" != "[]" ]; then
    echo "$SERVER_INFO" | jq -r '.[] | "Servidor: \(.name)\nResource Group: \(.resourceGroup)\nLocation: \(.location)"'
    
    # Extraer resource group
    RESOURCE_GROUP=$(echo "$SERVER_INFO" | jq -r '.[0].resourceGroup')
    echo ""
    echo "✅ RESOURCE GROUP ENCONTRADO: $RESOURCE_GROUP"
    
    # Buscar storage accounts en el mismo resource group
    echo ""
    echo "💾 STORAGE ACCOUNTS EN EL MISMO RESOURCE GROUP:"
    echo "=============================================="
    az storage account list --resource-group "$RESOURCE_GROUP" --query "[].{StorageAccount:name, Location:location, Tier:sku.tier}" --output table
    
else
    echo "❌ Servidor 'persqlmotorpromocprd' no encontrado"
    echo "   Verifique que tiene permisos o que el servidor existe"
fi

echo ""
echo "💡 COMANDOS PARA CREAR STORAGE ACCOUNT (si no existe):"
echo "====================================================="
echo "# Crear storage account"
echo "az storage account create \\"
echo "    --name mystorageaccount \\"
echo "    --resource-group [RESOURCE_GROUP] \\"
echo "    --location eastus \\"
echo "    --sku Standard_LRS"
echo ""
echo "# Crear contenedor para backups"
echo "az storage container create \\"
echo "    --name backups \\"
echo "    --account-name [STORAGE_ACCOUNT]"
