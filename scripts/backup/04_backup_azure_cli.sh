#!/bin/bash

# =====================================================
# BACKUP DE SQL AZURE DATABASE USANDO AZURE CLI
# Script bash para Linux/macOS
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Configuración (modificar según sus valores)
RESOURCE_GROUP="PERRSGRPYPRMTCLLYP"
SERVER_NAME="persqlmotorpromocprd"
DATABASE_NAME="persqldbmotorpromocprd"
STORAGE_ACCOUNT="perstgmotorbackprd"
CONTAINER_NAME="backups"
ADMIN_LOGIN="u_yairpanqueva"
ADMIN_PASSWORD="0x2E0403602967FDD263E5"

# Generar nombre de archivo con timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${DATABASE_NAME}_backup_${TIMESTAMP}.bacpac"
STORAGE_URI="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER_NAME}/${BACKUP_FILENAME}"

# Iniciar logging
start_logging "04_backup_azure_cli.sh" "Backup de SQL Azure Database"

log_info "Servidor: $SERVER_NAME"
log_info "Base de Datos: $DATABASE_NAME"
log_info "Storage Account: $STORAGE_ACCOUNT"
log_info "Archivo de Backup: $BACKUP_FILENAME"

# Verificar Azure CLI
log_info "🔍 Verificando Azure CLI..."
if ! command -v az &> /dev/null; then
    log_error "Azure CLI no está instalado. Instale desde: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    end_logging "04_backup_azure_cli.sh" "ERROR"
    exit 1
fi
log_success "Azure CLI verificado"

# Verificar autenticación
log_info "🔐 Verificando autenticación de Azure..."
if ! az account show &> /dev/null; then
    log_warning "No está autenticado. Ejecutando az login..."
    az login
    if [ $? -ne 0 ]; then
        log_error "Error en autenticación de Azure"
        end_logging "04_backup_azure_cli.sh" "ERROR"
        exit 1
    fi
fi

ACCOUNT_NAME=$(az account show --query "user.name" --output tsv)
log_success "Autenticación verificada: $ACCOUNT_NAME"

# Verificar Storage Account
log_info "🗄️  Verificando Storage Account..."
if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    log_error "Storage Account '$STORAGE_ACCOUNT' no encontrado en el grupo de recursos '$RESOURCE_GROUP'"
    end_logging "04_backup_azure_cli.sh" "ERROR"
    exit 1
fi
log_success "Storage Account verificado"

# Obtener clave del storage account
log_info "🔑 Obteniendo clave del Storage Account..."
STORAGE_KEY=$(az storage account keys list --account-name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query "[0].value" --output tsv)
if [ $? -ne 0 ]; then
    log_error "Error obteniendo la clave del Storage Account"
    end_logging "04_backup_azure_cli.sh" "ERROR"
    exit 1
fi
log_success "Clave obtenida exitosamente"

# Crear contenedor si no existe
log_info "📦 Verificando/creando contenedor..."
az storage container create --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --account-key "$STORAGE_KEY" --public-access off &> /dev/null
log_success "Contenedor verificado/creado"

# Ejecutar export
log_backup_operation "START" "Iniciando export de $DATABASE_NAME"
log_info "   Esto puede tomar varios minutos dependiendo del tamaño de la BD..."

EXPORT_RESULT=$(az sql db export \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SERVER_NAME" \
    --name "$DATABASE_NAME" \
    --storage-key "$STORAGE_KEY" \
    --storage-key-type StorageAccessKey \
    --storage-uri "$STORAGE_URI" \
    --admin-user "$ADMIN_LOGIN" \
    --admin-password "$ADMIN_PASSWORD" \
    --output json)

if [ $? -ne 0 ]; then
    log_error "Error durante el export de la base de datos"
    log_backup_operation "ERROR" "Falló export de $DATABASE_NAME"
    end_logging "04_backup_azure_cli.sh" "ERROR"
    exit 1
fi

OPERATION_ID=$(echo "$EXPORT_RESULT" | jq -r '.name')
log_success "Export iniciado exitosamente"
log_info "   Operation ID: $OPERATION_ID"

# Monitorear progreso
log_info "⏳ Monitoreando progreso del export..."

while true; do
    sleep 30
    
    STATUS_RESULT=$(az sql db show-operation \
        --operation-id "$OPERATION_ID" \
        --resource-group "$RESOURCE_GROUP" \
        --server "$SERVER_NAME" \
        --output json)
    
    STATUS=$(echo "$STATUS_RESULT" | jq -r '.status')
    STATUS_MESSAGE=$(echo "$STATUS_RESULT" | jq -r '.statusMessage')
    
    log_backup_operation "PROGRESS" "$STATUS - $STATUS_MESSAGE"
    
    if [ "$STATUS" = "Failed" ]; then
        ERROR_MESSAGE=$(echo "$STATUS_RESULT" | jq -r '.errorMessage')
        log_error "Export falló: $ERROR_MESSAGE"
        log_backup_operation "ERROR" "Export falló: $ERROR_MESSAGE"
        end_logging "04_backup_azure_cli.sh" "ERROR"
        exit 1
    fi
    
    if [ "$STATUS" = "Succeeded" ]; then
        break
    fi
    
    if [ "$STATUS" != "InProgress" ] && [ "$STATUS" != "Running" ]; then
        log_error "Export terminó con estado inesperado: $STATUS"
        log_backup_operation "ERROR" "Estado inesperado: $STATUS"
        end_logging "04_backup_azure_cli.sh" "ERROR"
        exit 1
    fi
done

log_backup_operation "SUCCESS" "Backup completado: $BACKUP_FILENAME"
log_info "Archivo: $BACKUP_FILENAME"
log_info "Ubicación: $STORAGE_URI"

# Verificar archivo
log_info "🔍 Verificando archivo de backup..."
BLOB_INFO=$(az storage blob show \
    --container-name "$CONTAINER_NAME" \
    --name "$BACKUP_FILENAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$STORAGE_KEY" \
    --output json)

if [ $? -eq 0 ]; then
    SIZE_BYTES=$(echo "$BLOB_INFO" | jq -r '.properties.contentLength')
    SIZE_GB=$(echo "scale=2; $SIZE_BYTES / 1024 / 1024 / 1024" | bc)
    log_success "Archivo verificado - Tamaño: ${SIZE_GB} GB"
else
    log_warning "No se pudo verificar el archivo de backup"
fi

log_info "📋 INFORMACIÓN DEL BACKUP:"
log_info "- Archivo: $BACKUP_FILENAME"
log_info "- URI: $STORAGE_URI"
log_info "- Fecha: $(date)"

log_info "💡 PRÓXIMOS PASOS:"
log_info "1. Verificar el archivo en Azure Portal"
log_info "2. Documentar la ubicación del backup"
log_info "3. Probar el restore en ambiente de prueba"

end_logging "04_backup_azure_cli.sh" "SUCCESS"
