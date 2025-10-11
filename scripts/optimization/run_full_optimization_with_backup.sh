#!/bin/bash

# =====================================================
# OPTIMIZACIÓN COMPLETA CON BACKUP Y ROLLBACK
# Proceso seguro integrado
# =====================================================

# Configuración
SERVER="persqlmotorpromocprd.database.windows.net"
DATABASE="persqldbmotorpromocprd"
USERNAME="u_yairpanqueva"
PASSWORD="0x2E0403602967FDD263E5"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/../../reports/optimization"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Variables de Azure (valores actualizados para el entorno real)
RESOURCE_GROUP="PERRSGRPYPRMTCLLYP"
STORAGE_ACCOUNT="perstgmotorbackprd"
CONTAINER_NAME="backups"

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

# Crear directorio de reportes
mkdir -p "$REPORTS_DIR"

log "🚀 OPTIMIZACIÓN COMPLETA CON BACKUP Y ROLLBACK"
echo "=============================================="
log "Servidor: $SERVER"
log "Base de Datos: $DATABASE"
log "Timestamp: $TIMESTAMP"
echo "=============================================="

# Verificar configuración de Azure
if [ "$RESOURCE_GROUP" = "TU_RESOURCE_GROUP" ]; then
    error "DEBE ACTUALIZAR LA VARIABLE RESOURCE_GROUP en el script"
    echo "Edite el archivo y cambie RESOURCE_GROUP por su valor real"
    exit 1
fi

# FASE 1: BACKUP PRE-OPTIMIZACIÓN
log "💾 FASE 1: BACKUP PRE-OPTIMIZACIÓN"
echo "=================================="

warning "Esta fase puede tomar 60-90 minutos para ~30GB"
read -p "¿Continuar con backup pre-optimización? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    log "Ejecutando backup..."
    
    # Verificar que PowerShell esté disponible
    if command -v pwsh &> /dev/null; then
        POWERSHELL_CMD="pwsh"
    elif command -v powershell &> /dev/null; then
        POWERSHELL_CMD="powershell"
    else
        error "PowerShell no está disponible. Instale PowerShell Core."
        exit 1
    fi
    
    # Ejecutar backup
    $POWERSHELL_CMD -File "$SCRIPT_DIR/../backup/02_azure_backup.ps1" \
        -ResourceGroupName "$RESOURCE_GROUP" \
        -ServerName "persqlmotorpromocprd" \
        -DatabaseName "$DATABASE" \
        -StorageAccountName "$STORAGE_ACCOUNT" \
        -ContainerName "$CONTAINER_NAME" \
        -AdminLogin "$USERNAME" \
        -AdminPassword "$PASSWORD"
    
    if [ $? -eq 0 ]; then
        success "Backup completado exitosamente"
        BACKUP_FILE="${DATABASE}_backup_${TIMESTAMP}.bacpac"
        log "Archivo de backup: $BACKUP_FILE"
    else
        error "Error durante el backup. Abortando optimización."
        exit 1
    fi
else
    warning "Backup omitido. RIESGO: No hay punto de rollback."
    read -p "¿Está seguro de continuar sin backup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Proceso abortado por el usuario"
        exit 0
    fi
fi

# FASE 2: ANÁLISIS PRE-OPTIMIZACIÓN
log "🔍 FASE 2: ANÁLISIS PRE-OPTIMIZACIÓN"
echo "===================================="

/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/01_performance_analysis.sql" \
    -o "$REPORTS_DIR/pre_optimization_analysis_$TIMESTAMP.txt" \
    -t 300 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    success "Análisis pre-optimización completado"
    log "Revise: $REPORTS_DIR/pre_optimization_analysis_$TIMESTAMP.txt"
else
    error "Error en análisis pre-optimización"
fi

# Mostrar resumen del análisis
log "📊 Mostrando fragmentación crítica..."
grep "FRAGMENTATION_ANALYSIS" "$REPORTS_DIR/pre_optimization_analysis_$TIMESTAMP.txt" | head -10

# FASE 3: CONFIRMACIÓN PARA CONTINUAR
echo ""
warning "PUNTO DE DECISIÓN: ¿Continuar con optimización completa?"
log "Esto incluirá:"
log "- Creación de índices (30 min, online)"
log "- Mantenimiento urgente (2-4 horas, downtime)"
log "- Optimización adicional (20 min)"
echo ""
read -p "¿Continuar con optimización completa? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # FASE 4: OPTIMIZACIÓN COMPLETA
    log "⚡ FASE 4: EJECUTANDO OPTIMIZACIÓN COMPLETA"
    echo "=========================================="
    
    "$SCRIPT_DIR/run_optimization.sh"
    
    if [ $? -eq 0 ]; then
        success "Optimización completa finalizada"
    else
        error "Error durante optimización"
        
        # Ofrecer rollback
        echo ""
        warning "¿Desea ejecutar rollback desde backup?"
        read -p "¿Ejecutar rollback? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]] && [ ! -z "$BACKUP_FILE" ]; then
            log "🔄 Ejecutando rollback..."
            
            $POWERSHELL_CMD -File "$SCRIPT_DIR/../backup/03_restore_database.ps1" \
                -ResourceGroupName "$RESOURCE_GROUP" \
                -ServerName "persqlmotorpromocprd" \
                -NewDatabaseName "${DATABASE}_rollback_${TIMESTAMP}" \
                -StorageAccountName "$STORAGE_ACCOUNT" \
                -ContainerName "$CONTAINER_NAME" \
                -BackupFileName "$BACKUP_FILE" \
                -AdminLogin "$USERNAME" \
                -AdminPassword "$PASSWORD"
            
            if [ $? -eq 0 ]; then
                success "Rollback completado. BD restaurada como: ${DATABASE}_rollback_${TIMESTAMP}"
            else
                error "Error durante rollback. Contacte al administrador."
            fi
        fi
    fi
else
    log "Optimización completa cancelada por el usuario"
fi

# FASE 5: ANÁLISIS POST-OPTIMIZACIÓN
log "📈 FASE 5: ANÁLISIS POST-OPTIMIZACIÓN"
echo "====================================="

/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/01_performance_analysis.sql" \
    -o "$REPORTS_DIR/post_optimization_analysis_$TIMESTAMP.txt" \
    -t 300 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    success "Análisis post-optimización completado"
    
    # Comparar resultados
    log "📊 Comparando resultados..."
    echo "ANTES DE OPTIMIZACIÓN:"
    grep "FRAGMENTATION_ANALYSIS" "$REPORTS_DIR/pre_optimization_analysis_$TIMESTAMP.txt" | head -5
    echo ""
    echo "DESPUÉS DE OPTIMIZACIÓN:"
    grep "FRAGMENTATION_ANALYSIS" "$REPORTS_DIR/post_optimization_analysis_$TIMESTAMP.txt" | head -5
fi

# Generar reporte final
log "📝 Generando reporte final..."
final_report="$REPORTS_DIR/optimization_final_report_$TIMESTAMP.md"

cat > "$final_report" << EOF
# 🎯 Reporte Final de Optimización

**Generado:** $(date)
**Base de Datos:** $DATABASE
**Backup:** ${BACKUP_FILE:-"No realizado"}

## 📊 Archivos Generados

- **Pre-análisis:** pre_optimization_analysis_$TIMESTAMP.txt
- **Post-análisis:** post_optimization_analysis_$TIMESTAMP.txt
- **Logs completos:** Revisar directorio reports/optimization/

## 🔄 Plan de Rollback

Si es necesario hacer rollback:

\`\`\`bash
# Restore desde backup
./scripts/backup/03_restore_database.ps1 \\
    -ResourceGroupName "$RESOURCE_GROUP" \\
    -ServerName "persqlmotorpromocprd" \\
    -NewDatabaseName "${DATABASE}_rollback" \\
    -StorageAccountName "$STORAGE_ACCOUNT" \\
    -ContainerName "$CONTAINER_NAME" \\
    -BackupFileName "${BACKUP_FILE:-"BACKUP_FILE.bacpac"}" \\
    -AdminLogin "$USERNAME" \\
    -AdminPassword "[PASSWORD]"
\`\`\`

## 📋 Próximos Pasos

1. Monitorear rendimiento durante 24-48 horas
2. Validar funcionalidad de aplicaciones
3. Documentar cambios realizados
4. Programar mantenimiento automático

---
*Proceso completado el $(date)*
EOF

success "Reporte final creado: $(basename "$final_report")"

# Resumen final
echo ""
log "🎉 PROCESO COMPLETO FINALIZADO"
echo "=============================="
success "Optimización con backup completada"
log "Reportes en: $REPORTS_DIR"
log "Backup: ${BACKUP_FILE:-"No realizado"}"

echo ""
log "💡 RECOMENDACIONES POST-OPTIMIZACIÓN:"
log "1. Monitorear rendimiento las próximas 24-48 horas"
log "2. Probar funcionalidad crítica de aplicaciones"
log "3. Mantener el backup por al menos 1 semana"
log "4. Programar mantenimiento automático semanal"
