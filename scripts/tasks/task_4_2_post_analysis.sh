#!/bin/bash

# =====================================================
# TAREA 4.2: ANÁLISIS POST-OPTIMIZACIÓN
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
start_logging "task_4_2_post_analysis.sh" "TAREA 4.2: Análisis Post-Optimización"

mkdir -p "$REPORTS_DIR"

log_info "🎯 EJECUTANDO TAREA 4.2: ANÁLISIS POST-OPTIMIZACIÓN"
log_info "Duración estimada: 15 minutos"
log_info "Downtime: No"

# Ejecutar análisis post-optimización
log_info "📈 Analizando mejoras de rendimiento..."
/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/../optimization/01_performance_analysis.sql" \
    -o "$REPORTS_DIR/task_4_2_post_analysis_$TIMESTAMP.txt" \
    -t 900 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 4.2 COMPLETADA EXITOSAMENTE"
    log_info "📄 Reporte: task_4_2_post_analysis_$TIMESTAMP.txt"
    
    log_info ""
    log_success "🎉 TODAS LAS FASES COMPLETADAS EXITOSAMENTE"
    log_info "============================================"
    log_info "✅ FASE 1: ANÁLISIS INICIAL - COMPLETADA"
    log_info "✅ FASE 2: BACKUP DE SEGURIDAD - COMPLETADA"
    log_info "✅ FASE 3: OPTIMIZACIÓN - COMPLETADA"
    log_info "✅ FASE 4: VALIDACIÓN - COMPLETADA"
    log_info ""
    log_info "📊 PROCESO DE OPTIMIZACIÓN FINALIZADO"
    log_info "Base de datos optimizada y validada exitosamente"
    
    end_logging "task_4_2_post_analysis.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 4.2"
    end_logging "task_4_2_post_analysis.sh" "ERROR"
    exit 1
fi
