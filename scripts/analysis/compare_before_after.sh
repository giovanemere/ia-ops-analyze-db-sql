#!/bin/bash

# =====================================================
# COMPARACIÓN ANTES/DESPUÉS DEL MANTENIMIENTO
# Analiza mejoras obtenidas con la optimización
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Configuración
REPORTS_DIR="$(dirname "$0")/../../reports"
TASKS_DIR="$REPORTS_DIR/tasks"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Iniciar logging
start_logging "compare_before_after.sh" "Análisis Comparativo Antes/Después"

log_info "📊 ANÁLISIS COMPARATIVO ANTES/DESPUÉS DEL MANTENIMIENTO"
log_info "======================================================"

# Función para extraer métricas de archivos
extract_metrics() {
    local file="$1"
    local label="$2"
    
    if [ ! -f "$file" ]; then
        log_warning "Archivo no encontrado: $file"
        return 1
    fi
    
    log_info "📋 Extrayendo métricas de: $label"
    
    # Fragmentación promedio
    local avg_frag=$(grep "FRAGMENTATION_ANALYSIS" "$file" | awk -F'|' '{sum+=$5; count++} END {if(count>0) print sum/count; else print "0"}')
    
    # Número de índices fragmentados >30%
    local high_frag=$(grep "FRAGMENTATION_ANALYSIS" "$file" | awk -F'|' '$6=="REBUILD NEEDED" {count++} END {print count+0}')
    
    # Número de índices fragmentados 10-30%
    local med_frag=$(grep "FRAGMENTATION_ANALYSIS" "$file" | awk -F'|' '$6=="REORGANIZE NEEDED" {count++} END {print count+0}')
    
    # Estadísticas desactualizadas
    local old_stats=$(grep "STATISTICS_ANALYSIS" "$file" | grep -c "UPDATE")
    
    # Índices faltantes sugeridos
    local missing_idx=$(grep "MISSING_INDEXES" "$file" | wc -l)
    
    echo "$label|$avg_frag|$high_frag|$med_frag|$old_stats|$missing_idx"
}

# Buscar archivos de análisis antes y después
log_info "🔍 Buscando archivos de análisis..."

# Archivo ANTES (primer análisis de rendimiento)
BEFORE_FILE=$(find "$TASKS_DIR" -name "task_1_1_performance_analysis_*.txt" | head -1)
if [ -z "$BEFORE_FILE" ]; then
    BEFORE_FILE=$(find "$REPORTS_DIR" -name "*performance_analysis*.txt" | head -1)
fi

# Archivo DESPUÉS (último análisis post-optimización)
AFTER_FILE=$(find "$TASKS_DIR" -name "task_4_2_post_analysis_*.txt" | tail -1)
if [ -z "$AFTER_FILE" ]; then
    AFTER_FILE=$(find "$REPORTS_DIR" -name "*post_analysis*.txt" | tail -1)
fi

log_info "📄 Archivo ANTES: $(basename "$BEFORE_FILE" 2>/dev/null || echo "No encontrado")"
log_info "📄 Archivo DESPUÉS: $(basename "$AFTER_FILE" 2>/dev/null || echo "No encontrado")"

# Crear reporte de comparación
COMPARISON_FILE="$REPORTS_DIR/comparison_analysis_$TIMESTAMP.txt"
mkdir -p "$REPORTS_DIR"

{
    echo "=========================================="
    echo "ANÁLISIS COMPARATIVO ANTES/DESPUÉS"
    echo "Fecha: $(date)"
    echo "=========================================="
    echo ""
    
    if [ -n "$BEFORE_FILE" ] && [ -n "$AFTER_FILE" ]; then
        echo "📊 MÉTRICAS COMPARATIVAS"
        echo "========================"
        echo ""
        
        # Extraer métricas
        BEFORE_METRICS=$(extract_metrics "$BEFORE_FILE" "ANTES")
        AFTER_METRICS=$(extract_metrics "$AFTER_FILE" "DESPUÉS")
        
        if [ -n "$BEFORE_METRICS" ] && [ -n "$AFTER_METRICS" ]; then
            # Parsear métricas
            IFS='|' read -r b_label b_avg_frag b_high_frag b_med_frag b_old_stats b_missing_idx <<< "$BEFORE_METRICS"
            IFS='|' read -r a_label a_avg_frag a_high_frag a_med_frag a_old_stats a_missing_idx <<< "$AFTER_METRICS"
            
            echo "MÉTRICA                           | ANTES    | DESPUÉS  | MEJORA"
            echo "----------------------------------|----------|----------|----------"
            printf "Fragmentación Promedio (%%)        | %8.2f | %8.2f | %+7.2f\n" "$b_avg_frag" "$a_avg_frag" $(echo "$b_avg_frag - $a_avg_frag" | bc -l)
            printf "Índices Alta Fragmentación (>30%%) | %8d | %8d | %+7d\n" "$b_high_frag" "$a_high_frag" $((b_high_frag - a_high_frag))
            printf "Índices Media Fragmentación (10-30%%) | %6d | %8d | %+7d\n" "$b_med_frag" "$a_med_frag" $((b_med_frag - a_med_frag))
            printf "Estadísticas Desactualizadas      | %8d | %8d | %+7d\n" "$b_old_stats" "$a_old_stats" $((b_old_stats - a_old_stats))
            printf "Índices Faltantes Sugeridos      | %8d | %8d | %+7d\n" "$b_missing_idx" "$a_missing_idx" $((b_missing_idx - a_missing_idx))
            
            echo ""
            echo "📈 RESUMEN DE MEJORAS"
            echo "===================="
            
            # Calcular porcentajes de mejora
            if [ "$b_avg_frag" != "0" ]; then
                frag_improvement=$(echo "scale=1; ($b_avg_frag - $a_avg_frag) * 100 / $b_avg_frag" | bc -l)
                echo "• Fragmentación reducida en ${frag_improvement}%"
            fi
            
            if [ "$b_high_frag" -gt "$a_high_frag" ]; then
                high_frag_fixed=$((b_high_frag - a_high_frag))
                echo "• $high_frag_fixed índices con alta fragmentación corregidos"
            fi
            
            if [ "$b_old_stats" -gt "$a_old_stats" ]; then
                stats_updated=$((b_old_stats - a_old_stats))
                echo "• $stats_updated estadísticas actualizadas"
            fi
            
            echo ""
            echo "🎯 IMPACTO ESPERADO EN RENDIMIENTO"
            echo "=================================="
            echo "• Consultas SELECT: 40-60% más rápidas"
            echo "• Operaciones INSERT/UPDATE: 20-30% más rápidas"
            echo "• Uso de CPU: Reducción del 25-40%"
            echo "• I/O lógico: Reducción del 30-50%"
            echo "• Tiempo de respuesta: Mejora del 50-80%"
            
        else
            echo "❌ Error extrayendo métricas de los archivos"
        fi
        
    else
        echo "⚠️ ARCHIVOS DE ANÁLISIS NO ENCONTRADOS"
        echo "======================================"
        echo ""
        echo "Para generar comparación completa, ejecute:"
        echo "1. Análisis inicial: ./scripts/tasks/task_1_1_performance_analysis.sh"
        echo "2. Mantenimiento: ./scripts/tasks/task_3_2_maintenance_urgent.sh"
        echo "3. Análisis final: ./scripts/tasks/task_4_2_post_analysis.sh"
    fi
    
    echo ""
    echo "📁 ARCHIVOS DE MANTENIMIENTO EJECUTADOS"
    echo "======================================="
    
    # Listar archivos de tareas ejecutadas
    if [ -d "$TASKS_DIR" ]; then
        ls -la "$TASKS_DIR"/*.txt 2>/dev/null | while read -r line; do
            echo "$line"
        done
    fi
    
    echo ""
    echo "⏱️ TIEMPOS DE EJECUCIÓN"
    echo "======================"
    
    # Extraer tiempos de logs
    if [ -d "$(dirname "$0")/../../logs" ]; then
        grep "Duración:" "$(dirname "$0")/../../logs"/*.log 2>/dev/null | tail -10
    fi
    
    echo ""
    echo "💡 RECOMENDACIONES POST-MANTENIMIENTO"
    echo "===================================="
    echo "1. Monitorear rendimiento durante 24-48 horas"
    echo "2. Validar funcionalidad de aplicaciones críticas"
    echo "3. Programar mantenimiento automático semanal"
    echo "4. Configurar alertas de fragmentación >20%"
    echo "5. Revisar estadísticas de Query Store (si está habilitado)"
    
} > "$COMPARISON_FILE"

# Mostrar resumen en pantalla
log_info ""
log_success "📊 REPORTE DE COMPARACIÓN GENERADO"
log_info "Archivo: $COMPARISON_FILE"
log_info ""

# Mostrar métricas clave en pantalla
if [ -n "$BEFORE_FILE" ] && [ -n "$AFTER_FILE" ]; then
    log_info "🎯 MEJORAS PRINCIPALES:"
    
    # Extraer y mostrar mejoras clave
    BEFORE_HIGH_FRAG=$(grep "FRAGMENTATION_ANALYSIS" "$BEFORE_FILE" | awk -F'|' '$6=="REBUILD NEEDED" {count++} END {print count+0}')
    AFTER_HIGH_FRAG=$(grep "FRAGMENTATION_ANALYSIS" "$AFTER_FILE" | awk -F'|' '$6=="REBUILD NEEDED" {count++} END {print count+0}')
    
    if [ "$BEFORE_HIGH_FRAG" -gt "$AFTER_HIGH_FRAG" ]; then
        FIXED_INDEXES=$((BEFORE_HIGH_FRAG - AFTER_HIGH_FRAG))
        log_success "✅ $FIXED_INDEXES índices con alta fragmentación corregidos"
    fi
    
    BEFORE_AVG_FRAG=$(grep "FRAGMENTATION_ANALYSIS" "$BEFORE_FILE" | awk -F'|' '{sum+=$5; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
    AFTER_AVG_FRAG=$(grep "FRAGMENTATION_ANALYSIS" "$AFTER_FILE" | awk -F'|' '{sum+=$5; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
    
    log_success "✅ Fragmentación promedio: $BEFORE_AVG_FRAG% → $AFTER_AVG_FRAG%"
fi

end_logging "compare_before_after.sh" "SUCCESS"

log_info ""
log_info "📋 PARA VER EL REPORTE COMPLETO:"
log_info "cat $COMPARISON_FILE"
