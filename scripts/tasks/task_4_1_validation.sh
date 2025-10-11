#!/bin/bash

# =====================================================
# TAREA 4.1: VALIDACIÓN DE INTEGRIDAD
# Duración: 15 minutos | Downtime: No
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Configuración
SERVER="persqlmotorpromocprd.database.windows.net"
DATABASE="persqldbmotorpromocprd"
USERNAME="u_yairpanqueva"
PASSWORD="0x2E0403602967FDD263E5"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/../../reports/tasks"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Iniciar logging
start_logging "task_4_1_validation.sh" "TAREA 4.1: Validación de Integridad"

mkdir -p "$REPORTS_DIR"

log_info "🎯 EJECUTANDO TAREA 4.1: VALIDACIÓN DE INTEGRIDAD"
log_info "Duración estimada: 15 minutos"
log_info "Downtime: No"

# Ejecutar validación
log_info "🔍 Validando integridad post-optimización..."
/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/../optimization/07_validation.sql" \
    -o "$REPORTS_DIR/task_4_1_validation_$TIMESTAMP.txt" \
    -t 900 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 4.1 COMPLETADA EXITOSAMENTE"
    log_info "📄 Reporte: task_4_1_validation_$TIMESTAMP.txt"
    end_logging "task_4_1_validation.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 4.1"
    end_logging "task_4_1_validation.sh" "ERROR"
    exit 1
fi

log_info "🎯 PRÓXIMO PASO: Ejecutar Tarea 4.2 (Análisis Post-Optimización)"
log_info "Comando: ./scripts/tasks/task_4_2_post_analysis.sh"
