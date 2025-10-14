#!/bin/bash

# =====================================================
# GESTOR DE LOGS
# Herramientas para gestionar y analizar logs
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/logging.sh"

# Función de ayuda
show_help() {
    echo "📋 GESTOR DE LOGS - Herramientas de análisis"
    echo "============================================"
    echo ""
    echo "Uso: $0 [comando] [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo "  stats                    - Mostrar estadísticas de logs"
    echo "  search <patrón> [días]   - Buscar patrón en logs"
    echo "  errors [días]            - Mostrar errores recientes"
    echo "  tail [archivo]           - Seguir logs en tiempo real"
    echo "  rotate                   - Rotar logs antiguos"
    echo "  clean                    - Limpiar logs antiguos"
    echo "  backup                   - Respaldar logs"
    echo "  list                     - Listar archivos de log"
    echo ""
    echo "Ejemplos:"
    echo "  $0 stats"
    echo "  $0 search 'ERROR' 3"
    echo "  $0 errors 1"
    echo "  $0 tail"
}

# Función para mostrar errores recientes
show_recent_errors() {
    local days="${1:-1}"
    local error_count=0
    
    echo "🚨 ERRORES RECIENTES (últimos $days días):"
    echo "=========================================="
    
    find "$LOG_DIR" -name "errors_*.log" -type f -mtime -"$days" | while read error_file; do
        if [ -f "$error_file" ] && [ -s "$error_file" ]; then
            echo ""
            echo "📄 $(basename "$error_file"):"
            echo "$(wc -l < "$error_file") errores encontrados"
            echo ""
            tail -20 "$error_file" | while read line; do
                echo "  $line"
                ((error_count++))
            done
        fi
    done
    
    if [ $error_count -eq 0 ]; then
        echo "✅ No se encontraron errores recientes"
    fi
}

# Función para seguir logs en tiempo real
tail_logs() {
    local log_file="${1:-$LOG_FILE}"
    
    if [ ! -f "$log_file" ]; then
        log_file="$LOG_FILE"
    fi
    
    echo "👁️  Siguiendo logs en tiempo real: $(basename "$log_file")"
    echo "Presione Ctrl+C para salir"
    echo "=========================================="
    
    tail -f "$log_file" | while read line; do
        # Colorear según el nivel
        if [[ "$line" == *"[ERROR]"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" == *"[WARNING]"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ "$line" == *"[SUCCESS]"* ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ "$line" == *"[INFO]"* ]]; then
            echo -e "${CYAN}$line${NC}"
        else
            echo "$line"
        fi
    done
}

# Función para limpiar logs antiguos
clean_old_logs() {
    local days="${1:-30}"
    
    echo "🧹 Limpiando logs anteriores a $days días..."
    
    local deleted_count=$(find "$LOG_DIR" -name "*.log" -type f -mtime +$days -print | wc -l)
    
    if [ $deleted_count -gt 0 ]; then
        find "$LOG_DIR" -name "*.log" -type f -mtime +$days -delete
        log_success "Eliminados $deleted_count archivos de log antiguos"
    else
        log_info "No hay logs antiguos para eliminar"
    fi
}

# Función para respaldar logs
backup_logs() {
    local backup_dir="$LOG_DIR/backup"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/logs_backup_$timestamp.tar.gz"
    
    mkdir -p "$backup_dir"
    
    echo "💾 Creando respaldo de logs..."
    
    tar -czf "$backup_file" -C "$LOG_DIR" --exclude="backup" *.log 2>/dev/null
    
    if [ $? -eq 0 ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "Backup creado: $(basename "$backup_file") ($size)"
    else
        log_error "Error creando backup de logs"
    fi
}

# Función para listar archivos de log
list_logs() {
    echo "📁 ARCHIVOS DE LOG DISPONIBLES:"
    echo "==============================="
    
    if [ -d "$LOG_DIR" ]; then
        ls -lah "$LOG_DIR"/*.log 2>/dev/null | while read line; do
            echo "  $line"
        done
        
        echo ""
        echo "📊 Resumen:"
        local total_files=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
        local total_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
        echo "  Total archivos: $total_files"
        echo "  Tamaño total: $total_size"
    else
        echo "❌ Directorio de logs no existe: $LOG_DIR"
    fi
}

# Función para analizar rendimiento
analyze_performance() {
    local days="${1:-7}"
    
    echo "📈 ANÁLISIS DE RENDIMIENTO (últimos $days días):"
    echo "==============================================="
    
    # Buscar operaciones SQL y sus tiempos
    find "$LOG_DIR" -name "*.log" -type f -mtime -"$days" -exec grep -h "SQL ejecutado" {} \; | \
    sed 's/.*(\([0-9]*\)s).*/\1/' | \
    awk '{
        sum += $1
        count++
        if ($1 > max) max = $1
        if (min == 0 || $1 < min) min = $1
    }
    END {
        if (count > 0) {
            print "  Operaciones SQL: " count
            print "  Tiempo promedio: " sum/count "s"
            print "  Tiempo mínimo: " min "s"
            print "  Tiempo máximo: " max "s"
        } else {
            print "  No se encontraron operaciones SQL"
        }
    }'
    
    # Contar tipos de operaciones
    echo ""
    echo "📊 Tipos de operaciones:"
    find "$LOG_DIR" -name "*.log" -type f -mtime -"$days" -exec grep -h "\[SUCCESS\]" {} \; | \
    grep -o "backup\|optimization\|analysis\|dictionary\|infrastructure" | \
    sort | uniq -c | while read count operation; do
        echo "  $operation: $count"
    done
}

# Procesar argumentos
case "${1:-help}" in
    "stats")
        show_log_stats
        ;;
    "search")
        if [ -z "$2" ]; then
            echo "❌ Patrón de búsqueda requerido"
            echo "Uso: $0 search <patrón> [días]"
            exit 1
        fi
        search_logs "$2" "${3:-1}"
        ;;
    "errors")
        show_recent_errors "${2:-1}"
        ;;
    "tail")
        tail_logs "$2"
        ;;
    "rotate")
        rotate_logs
        ;;
    "clean")
        clean_old_logs "${2:-30}"
        ;;
    "backup")
        backup_logs
        ;;
    "list")
        list_logs
        ;;
    "performance")
        analyze_performance "${2:-7}"
        ;;
    "help"|*)
        show_help
        ;;
esac
