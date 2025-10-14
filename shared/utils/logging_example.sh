#!/bin/bash

# =====================================================
# EJEMPLO DE USO DEL SISTEMA DE LOGGING
# Muestra cómo integrar logging en scripts
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/logging.sh"

# Iniciar logging del script
start_logging "logging_example.sh" "Ejemplo de sistema de logging"

# Ejemplos de diferentes tipos de log
log_info "Este es un mensaje informativo"
log_success "Operación completada exitosamente"
log_warning "Esta es una advertencia"
log_error "Este es un mensaje de error"
log_debug "Este es un mensaje de debug (solo visible con DEBUG=1)"

# Ejemplo de logging de operación SQL
log_sql_execution "ejemplo.sql" "resultado.txt" "15" "SUCCESS"

# Ejemplo de logging de backup
log_backup_operation "START" "Iniciando backup de ejemplo"
sleep 2
log_backup_operation "PROGRESS" "50% completado"
sleep 2
log_backup_operation "SUCCESS" "Backup completado - archivo: ejemplo.bacpac"

# Mostrar estadísticas
echo ""
show_log_stats

# Finalizar logging
end_logging "logging_example.sh" "SUCCESS"
