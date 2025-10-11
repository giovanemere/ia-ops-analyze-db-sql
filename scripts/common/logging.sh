#!/bin/bash

# =====================================================
# SISTEMA DE LOGGING CENTRALIZADO
# Funciones comunes para todos los scripts
# =====================================================

# Configuración de logging
LOG_DIR="/home/giovanemere/periferia/primax/sql-analysis-project/logs"
LOG_FILE="$LOG_DIR/sql_analysis_$(date +%Y%m%d).log"
ERROR_LOG="$LOG_DIR/errors_$(date +%Y%m%d).log"

# Crear directorio de logs si no existe
mkdir -p "$LOG_DIR"

# Colores para terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Función principal de logging
write_log() {
    local level="$1"
    local message="$2"
    local script_name="${3:-$(basename "$0")}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Escribir al archivo de log principal
    echo "[$timestamp] [$level] [$script_name] $message" >> "$LOG_FILE"
    
    # Si es error, también escribir al log de errores
    if [ "$level" = "ERROR" ]; then
        echo "[$timestamp] [$script_name] $message" >> "$ERROR_LOG"
    fi
}

# Funciones de logging con colores
log_info() {
    local message="$1"
    local script_name="${2:-$(basename "$0")}"
    echo -e "${CYAN}[$(date +'%H:%M:%S')] [INFO]${NC} $message"
    write_log "INFO" "$message" "$script_name"
}

log_success() {
    local message="$1"
    local script_name="${2:-$(basename "$0")}"
    echo -e "${GREEN}[$(date +'%H:%M:%S')] [SUCCESS]${NC} $message"
    write_log "SUCCESS" "$message" "$script_name"
}

log_warning() {
    local message="$1"
    local script_name="${2:-$(basename "$0")}"
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] [WARNING]${NC} $message"
    write_log "WARNING" "$message" "$script_name"
}

log_error() {
    local message="$1"
    local script_name="${2:-$(basename "$0")}"
    echo -e "${RED}[$(date +'%H:%M:%S')] [ERROR]${NC} $message"
    write_log "ERROR" "$message" "$script_name"
}

log_debug() {
    local message="$1"
    local script_name="${2:-$(basename "$0")}"
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${PURPLE}[$(date +'%H:%M:%S')] [DEBUG]${NC} $message"
        write_log "DEBUG" "$message" "$script_name"
    fi
}

# Función para iniciar logging de un script
start_logging() {
    local script_name="$1"
    local description="$2"
    
    log_info "=========================================="
    log_info "INICIANDO: $description"
    log_info "Script: $script_name"
    log_info "Usuario: $(whoami)"
    log_info "Fecha: $(date)"
    log_info "=========================================="
}

# Función para finalizar logging de un script
end_logging() {
    local script_name="$1"
    local status="${2:-SUCCESS}"
    
    log_info "=========================================="
    if [ "$status" = "SUCCESS" ]; then
        log_success "COMPLETADO: $script_name"
    else
        log_error "FALLIDO: $script_name"
    fi
    log_info "Duración: $SECONDS segundos"
    log_info "=========================================="
}

# Función para logging de comandos SQL
log_sql_execution() {
    local sql_file="$1"
    local output_file="$2"
    local duration="$3"
    local status="$4"
    
    if [ "$status" = "SUCCESS" ]; then
        log_success "SQL ejecutado: $(basename "$sql_file") -> $(basename "$output_file") (${duration}s)"
    else
        log_error "SQL falló: $(basename "$sql_file") (${duration}s)"
    fi
}

# Función para logging de backups
log_backup_operation() {
    local operation="$1"  # START, PROGRESS, SUCCESS, ERROR
    local details="$2"
    
    case "$operation" in
        "START")
            log_info "🔄 Iniciando backup: $details"
            ;;
        "PROGRESS")
            log_info "⏳ Progreso backup: $details"
            ;;
        "SUCCESS")
            log_success "✅ Backup completado: $details"
            ;;
        "ERROR")
            log_error "❌ Error en backup: $details"
            ;;
    esac
}

# Función para rotar logs (mantener solo últimos 7 días)
rotate_logs() {
    find "$LOG_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null
    log_info "Logs rotados - eliminados archivos > 7 días"
}

# Función para mostrar estadísticas de logs
show_log_stats() {
    local today=$(date +%Y%m%d)
    local log_file="$LOG_DIR/sql_analysis_$today.log"
    local error_file="$LOG_DIR/errors_$today.log"
    
    if [ -f "$log_file" ]; then
        local total_entries=$(wc -l < "$log_file")
        local errors=$(grep -c "ERROR" "$log_file" 2>/dev/null || echo "0")
        local warnings=$(grep -c "WARNING" "$log_file" 2>/dev/null || echo "0")
        local success=$(grep -c "SUCCESS" "$log_file" 2>/dev/null || echo "0")
        
        echo "📊 ESTADÍSTICAS DE LOGS (HOY):"
        echo "  Total entradas: $total_entries"
        echo "  Éxitos: $success"
        echo "  Advertencias: $warnings"
        echo "  Errores: $errors"
        echo "  Archivo: $log_file"
    else
        echo "📊 No hay logs para hoy"
    fi
}

# Función para buscar en logs
search_logs() {
    local pattern="$1"
    local days="${2:-1}"
    
    echo "🔍 Buscando '$pattern' en logs de últimos $days días:"
    find "$LOG_DIR" -name "*.log" -type f -mtime -"$days" -exec grep -l "$pattern" {} \; | while read file; do
        echo "📄 $(basename "$file"):"
        grep --color=always "$pattern" "$file" | tail -10
        echo ""
    done
}

# Exportar funciones para uso en otros scripts
export -f log_info log_success log_warning log_error log_debug
export -f start_logging end_logging log_sql_execution log_backup_operation
export -f rotate_logs show_log_stats search_logs write_log
