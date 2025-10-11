#!/bin/bash

# =====================================================
# TAREA 2.1: BACKUP COMPLETO
# Duración: 60-90 minutos | Downtime: No
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Iniciar logging
start_logging "task_2_1_backup_complete.sh" "TAREA 2.1: Backup Completo"

log_info "🎯 EJECUTANDO TAREA 2.1: BACKUP COMPLETO"
log_info "Duración estimada: 60-90 minutos"
log_info "Downtime: No"
log_info "Tamaño estimado: ~30 GB"

# Ejecutar backup
log_backup_operation "START" "Iniciando backup completo de persqldbmotorpromocprd"
"$(dirname "$0")/../backup/04_backup_azure_cli.sh"

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 2.1 COMPLETADA EXITOSAMENTE"
    log_backup_operation "SUCCESS" "Backup completo finalizado"
    end_logging "task_2_1_backup_complete.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 2.1"
    log_backup_operation "ERROR" "Falló backup completo"
    end_logging "task_2_1_backup_complete.sh" "ERROR"
    exit 1
fi

log_info "🎯 PRÓXIMO PASO: Ejecutar Tarea 2.2 (Verificación de Backup)"
log_info "Comando: ./scripts/tasks/task_2_2_backup_verification.sh"
