#!/bin/bash

# =====================================================
# TAREA 3.3: OPTIMIZACIÓN ADICIONAL
# Duración: 20 minutos | Downtime: Mínimo
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
start_logging "task_3_3_additional_optimization.sh" "TAREA 3.3: Optimización Adicional"

mkdir -p "$REPORTS_DIR"

log_info "🎯 EJECUTANDO TAREA 3.3: OPTIMIZACIÓN ADICIONAL"
log_info "Duración estimada: 20 minutos"
log_info "Downtime: Mínimo"

# Ejecutar optimización adicional
log_info "⚡ Ejecutando optimización adicional..."
/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/../optimization/06_additional_optimization.sql" \
    -o "$REPORTS_DIR/task_3_3_additional_optimization_$TIMESTAMP.txt" \
    -t 1200 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 3.3 COMPLETADA EXITOSAMENTE"
    log_info "📄 Reporte: task_3_3_additional_optimization_$TIMESTAMP.txt"
    
    log_info ""
    log_success "🎉 FASE 3 COMPLETADA - OPTIMIZACIÓN FINALIZADA"
    log_info "=============================================="
    log_info "✅ 3.1 Creación de Índices - COMPLETADO"
    log_info "✅ 3.2 Mantenimiento Urgente - COMPLETADO"
    log_info "✅ 3.3 Optimización Adicional - COMPLETADO"
    log_info ""
    log_info "🎯 PRÓXIMA FASE: FASE 4 - VALIDACIÓN"
    log_info "Comando: ./scripts/tasks/task_4_1_validation.sh"
    
    end_logging "task_3_3_additional_optimization.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 3.3"
    end_logging "task_3_3_additional_optimization.sh" "ERROR"
    exit 1
fi
