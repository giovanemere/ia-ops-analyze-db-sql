#!/bin/bash

# =====================================================
# TAREA 3.1: CREACIÓN DE ÍNDICES OPTIMIZADOS
# Duración: 30 minutos | Downtime: Parcial (ONLINE=ON)
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
start_logging "task_3_1_create_indexes.sh" "TAREA 3.1: Creación de Índices Optimizados"

mkdir -p "$REPORTS_DIR"

log_info "🎯 EJECUTANDO TAREA 3.1: CREACIÓN DE ÍNDICES"
log_info "Duración estimada: 30 minutos"
log_info "Downtime: Parcial (ONLINE=ON)"
log_warning "⚠️  VENTANA DE MANTENIMIENTO REQUERIDA"

# Confirmación
read -p "¿Continuar con creación de índices? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Tarea cancelada por el usuario"
    end_logging "task_3_1_create_indexes.sh" "CANCELLED"
    exit 0
fi

# Ejecutar creación de índices
log_info "📊 Creando índices optimizados..."
/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/../optimization/02_create_indexes.sql" \
    -o "$REPORTS_DIR/task_3_1_create_indexes_$TIMESTAMP.txt" \
    -t 1800 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 3.1 COMPLETADA EXITOSAMENTE"
    log_info "📄 Reporte: task_3_1_create_indexes_$TIMESTAMP.txt"
    end_logging "task_3_1_create_indexes.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 3.1"
    log_warning "💡 ROLLBACK: Eliminar índices problemáticos si es necesario"
    end_logging "task_3_1_create_indexes.sh" "ERROR"
    exit 1
fi

log_info "🎯 PRÓXIMO PASO: Ejecutar Tarea 3.2 (Mantenimiento Urgente)"
log_info "Comando: ./scripts/tasks/task_3_2_maintenance_urgent.sh"
log_warning "⚠️  ATENCIÓN: La siguiente tarea requiere DOWNTIME COMPLETO (2-4 horas)"
