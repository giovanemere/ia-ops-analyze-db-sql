#!/bin/bash

# =====================================================
# TAREA 3.2: MANTENIMIENTO URGENTE
# Duración: 2-4 horas | Downtime: Sí (REBUILD)
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
start_logging "task_3_2_maintenance_urgent.sh" "TAREA 3.2: Mantenimiento Urgente"

mkdir -p "$REPORTS_DIR"

log_info "🎯 EJECUTANDO TAREA 3.2: MANTENIMIENTO URGENTE"
log_info "Duración estimada: 2-4 horas"
log_info "Downtime: SÍ (REBUILD completo)"
log_warning "⚠️  VENTANA DE MANTENIMIENTO CRÍTICA"

# Confirmación
read -p "¿CONFIRMAR MANTENIMIENTO URGENTE CON DOWNTIME? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Mantenimiento cancelado por el usuario"
    end_logging "task_3_2_maintenance_urgent.sh" "CANCELLED"
    exit 0
fi

# Ejecutar mantenimiento urgente
log_info "🔧 Ejecutando mantenimiento urgente (REBUILD/REORGANIZE)..."
/opt/mssql-tools/bin/sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
    -i "$SCRIPT_DIR/../optimization/05_maintenance_urgent.sql" \
    -o "$REPORTS_DIR/task_3_2_maintenance_urgent_$TIMESTAMP.txt" \
    -t 14400 -s "|" -W -h -1 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "✅ TAREA 3.2 COMPLETADA EXITOSAMENTE"
    log_info "📄 Reporte: task_3_2_maintenance_urgent_$TIMESTAMP.txt"
    end_logging "task_3_2_maintenance_urgent.sh" "SUCCESS"
else
    log_error "❌ ERROR EN TAREA 3.2"
    log_warning "💡 ROLLBACK: Verificar estado de índices"
    end_logging "task_3_2_maintenance_urgent.sh" "ERROR"
    exit 1
fi

log_info "🎯 PRÓXIMO PASO: Ejecutar Tarea 3.3 (Optimización Adicional)"
log_info "Comando: ./scripts/tasks/task_3_3_additional_optimization.sh"
