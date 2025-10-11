#!/bin/bash

# =====================================================
# TAREA 1.1: ANÁLISIS DE RENDIMIENTO
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
start_logging "task_1_1_performance_analysis.sh" "TAREA 1.1: Análisis de Rendimiento"

# Crear directorio de reportes
mkdir -p "$REPORTS_DIR"

log_info "🎯 EJECUTANDO TAREA 1.1: ANÁLISIS DE RENDIMIENTO"
log_info "Duración estimada: 15 minutos"
log_info "Downtime: No"

# Ejecutar análisis
log_info "📊 Ejecutando análisis de rendimiento..."
/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/../optimization/01_performance_analysis.sql" \
    -o "$REPORTS_DIR/task_1_1_performance_analysis_$TIMESTAMP.txt" \
    -t 300 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 1.1 COMPLETADA EXITOSAMENTE"
    log_info "📄 Reporte: task_1_1_performance_analysis_$TIMESTAMP.txt"
    
    # Mostrar resumen
    log_info "📋 RESUMEN DE FRAGMENTACIÓN:"
    grep "FRAGMENTATION_ANALYSIS" "$REPORTS_DIR/task_1_1_performance_analysis_$TIMESTAMP.txt" | head -5
    
    end_logging "task_1_1_performance_analysis.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 1.1"
    end_logging "task_1_1_performance_analysis.sh" "ERROR"
    exit 1
fi

log_info "🎯 PRÓXIMO PASO: Ejecutar Tarea 1.2 (Análisis de Infraestructura)"
log_info "Comando: ./scripts/tasks/task_1_2_infrastructure_analysis.sh"
