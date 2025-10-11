#!/bin/bash

# =====================================================
# TAREA 1.2: ANÁLISIS DE INFRAESTRUCTURA
# Duración: 10 minutos | Downtime: No
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Iniciar logging
start_logging "task_1_2_infrastructure_analysis.sh" "TAREA 1.2: Análisis de Infraestructura"

log_info "🎯 EJECUTANDO TAREA 1.2: ANÁLISIS DE INFRAESTRUCTURA"
log_info "Duración estimada: 10 minutos"
log_info "Downtime: No"

# Ejecutar análisis de infraestructura
log_info "🖥️ Ejecutando análisis de infraestructura..."
"$(dirname "$0")/../infrastructure/run_infrastructure.sh"

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 1.2 COMPLETADA EXITOSAMENTE"
    end_logging "task_1_2_infrastructure_analysis.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 1.2"
    end_logging "task_1_2_infrastructure_analysis.sh" "ERROR"
    exit 1
fi

log_info "🎯 PRÓXIMO PASO: Ejecutar Tarea 1.3 (Diccionario de Datos)"
log_info "Comando: ./scripts/tasks/task_1_3_dictionary_generation.sh"
