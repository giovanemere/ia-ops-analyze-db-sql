#!/bin/bash

# =====================================================
# EJECUTOR MAESTRO DE TAREAS
# Ejecuta todas las tareas en secuencia controlada
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Iniciar logging
start_logging "run_all_tasks.sh" "Ejecutor Maestro de Tareas"

log_info "🚀 PLAN DE EJECUCIÓN POR TAREAS SEPARADAS"
log_info "=========================================="

# Función para ejecutar tarea con confirmación
execute_task() {
    local task_script="$1"
    local task_name="$2"
    local duration="$3"
    local downtime="$4"
    
    echo ""
    log_info "📋 PRÓXIMA TAREA: $task_name"
    log_info "Duración estimada: $duration"
    log_info "Downtime: $downtime"
    
    read -p "¿Ejecutar esta tarea? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "▶️  Ejecutando: $task_name"
        "$SCRIPT_DIR/$task_script"
        
        if [ $? -eq 0 ]; then
            log_success "✅ $task_name - COMPLETADA"
        else
            log_error "❌ $task_name - FALLÓ"
            log_warning "🛑 Deteniendo ejecución por error"
            return 1
        fi
    else
        log_warning "⏭️  $task_name - OMITIDA"
    fi
    
    return 0
}

# FASE 1: ANÁLISIS INICIAL
log_info ""
log_info "🔍 FASE 1: ANÁLISIS INICIAL (Sin Downtime)"
log_info "==========================================="

execute_task "task_1_1_performance_analysis.sh" "Análisis de Rendimiento" "15 min" "No" || exit 1
execute_task "task_1_2_infrastructure_analysis.sh" "Análisis de Infraestructura" "10 min" "No" || exit 1
execute_task "task_1_3_dictionary_generation.sh" "Diccionario de Datos" "10 min" "No" || exit 1

# FASE 2: BACKUP DE SEGURIDAD
log_info ""
log_info "💾 FASE 2: BACKUP DE SEGURIDAD (Crítico)"
log_info "========================================"

execute_task "task_2_1_backup_complete.sh" "Backup Completo" "60-90 min" "No" || exit 1
execute_task "task_2_2_backup_verification.sh" "Verificación de Backup" "5 min" "No" || exit 1

# FASE 3: OPTIMIZACIÓN (Ventana de Mantenimiento)
log_info ""
log_warning "⚠️  FASE 3: OPTIMIZACIÓN (Ventana de Mantenimiento)"
log_warning "================================================="
log_warning "ATENCIÓN: Las siguientes tareas requieren ventana de mantenimiento"
log_warning "Tiempo total estimado: 4-5 horas"

execute_task "task_3_1_create_indexes.sh" "Creación de Índices" "30 min" "Parcial" || exit 1
execute_task "task_3_2_maintenance_urgent.sh" "Mantenimiento Urgente" "2-4 horas" "Sí" || exit 1
execute_task "task_3_3_additional_optimization.sh" "Optimización Adicional" "20 min" "Mínimo" || exit 1

# FASE 4: VALIDACIÓN
log_info ""
log_info "✅ FASE 4: VALIDACIÓN POST-OPTIMIZACIÓN"
log_info "======================================"

execute_task "task_4_1_validation.sh" "Validación de Integridad" "15 min" "No" || exit 1
execute_task "task_4_2_post_analysis.sh" "Análisis Post-Optimización" "15 min" "No" || exit 1

# Resumen final
log_info ""
log_success "🎉 TODAS LAS TAREAS COMPLETADAS EXITOSAMENTE"
log_info "============================================"
log_info "📊 Revisar reportes en: reports/tasks/"
log_info "📝 Logs completos en: logs/"

# Mostrar estadísticas finales
log_info ""
log_info "📈 ESTADÍSTICAS FINALES:"
./scripts/common/log_manager.sh stats

end_logging "run_all_tasks.sh" "SUCCESS"

log_info ""
log_info "💡 PRÓXIMOS PASOS:"
log_info "1. Monitorear rendimiento durante 24-48 horas"
log_info "2. Validar funcionalidad de aplicaciones"
log_info "3. Documentar mejoras obtenidas"
log_info "4. Programar mantenimiento automático"
