#!/bin/bash

# =====================================================
# ROLLBACK DE EMERGENCIA
# Restaura desde backup más reciente
# =====================================================

# Configuración (valores actualizados para el entorno real)
RESOURCE_GROUP="PERRSGRPYPRMTCLLYP"
STORAGE_ACCOUNT="perstgmotorbackprd"
CONTAINER_NAME="backups"
USERNAME="u_yairpanqueva"
PASSWORD="0x2E0403602967FDD263E5"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "🚨 ROLLBACK DE EMERGENCIA"
echo "========================="

# Verificar configuración
if [ "$RESOURCE_GROUP" = "TU_RESOURCE_GROUP" ]; then
    error "DEBE ACTUALIZAR LA VARIABLE RESOURCE_GROUP en el script"
    exit 1
fi

# Verificar PowerShell
if command -v pwsh &> /dev/null; then
    POWERSHELL_CMD="pwsh"
elif command -v powershell &> /dev/null; then
    POWERSHELL_CMD="powershell"
else
    error "PowerShell no está disponible"
    exit 1
fi

# Solicitar archivo de backup
echo ""
log "📁 Archivos de backup disponibles:"
az storage blob list --container-name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --query "[?contains(name, 'persqldbmotorpromocprd_backup')].{Name:name, Size:properties.contentLength, Modified:properties.lastModified}" --output table 2>/dev/null

echo ""
read -p "Ingrese el nombre del archivo de backup (ej: persqldbmotorpromocprd_backup_20251010_180000.bacpac): " BACKUP_FILE

if [ -z "$BACKUP_FILE" ]; then
    error "Nombre de archivo requerido"
    exit 1
fi

# Solicitar nombre de BD de destino
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEFAULT_DB_NAME="persqldbmotorpromocprd_rollback_$TIMESTAMP"
read -p "Nombre de BD de destino [$DEFAULT_DB_NAME]: " NEW_DB_NAME
NEW_DB_NAME=${NEW_DB_NAME:-$DEFAULT_DB_NAME}

# Confirmación
echo ""
warning "CONFIRMACIÓN DE ROLLBACK:"
log "Archivo de backup: $BACKUP_FILE"
log "Nueva BD: $NEW_DB_NAME"
log "Tiempo estimado: 60-120 minutos"
echo ""
read -p "¿Continuar con rollback? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Rollback cancelado por el usuario"
    exit 0
fi

# Ejecutar rollback
log "🔄 Iniciando rollback..."

$POWERSHELL_CMD -File "$(dirname "$0")/../backup/03_restore_database.ps1" \
    -ResourceGroupName "$RESOURCE_GROUP" \
    -ServerName "persqlmotorpromocprd" \
    -NewDatabaseName "$NEW_DB_NAME" \
    -StorageAccountName "$STORAGE_ACCOUNT" \
    -ContainerName "$CONTAINER_NAME" \
    -BackupFileName "$BACKUP_FILE" \
    -AdminLogin "$USERNAME" \
    -AdminPassword "$PASSWORD" \
    -ServiceTier "HS_Gen5_12"

if [ $? -eq 0 ]; then
    success "🎉 ROLLBACK COMPLETADO EXITOSAMENTE"
    echo "=================================="
    log "Base de datos restaurada: $NEW_DB_NAME"
    log "Servidor: persqlmotorpromocprd.database.windows.net"
    echo ""
    log "💡 PRÓXIMOS PASOS:"
    log "1. Actualizar cadenas de conexión a: $NEW_DB_NAME"
    log "2. Probar funcionalidad crítica"
    log "3. Una vez validado, renombrar BD si es necesario"
    log "4. Eliminar BD problemática original"
else
    error "❌ ERROR DURANTE ROLLBACK"
    log "Contacte al administrador de base de datos"
fi
