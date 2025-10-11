#!/bin/bash

# =====================================================
# ANÁLISIS COMPLETO DE INFRAESTRUCTURA DE BASE DE DATOS
# CPU, Memoria, I/O, Sesiones, Almacenamiento
# =====================================================

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Configuración
SERVER="persqlmotorpromocprd.database.windows.net"
DATABASE="persqldbmotorpromocprd"
USERNAME="u_yairpanqueva"
PASSWORD="0x2E0403602967FDD263E5"
TIMEOUT=300
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/../../reports/infrastructure"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Iniciar logging
start_logging "run_infrastructure.sh" "Análisis completo de infraestructura de base de datos"

# Crear directorio de reportes
mkdir -p "$REPORTS_DIR"

SQLCMD="/opt/mssql-tools/bin/sqlcmd"

log_info "Servidor: $SERVER"
log_info "Base de Datos: $DATABASE"
log_info "Usuario: $USERNAME"
log_info "Directorio de Reportes: $REPORTS_DIR"
log_info "Timestamp: $TIMESTAMP"

# Test de conexión
log_info "🔍 Probando conexión a la base de datos..."
$SQLCMD -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
        -Q "SELECT 'CONNECTION_OK' as STATUS, @@SERVERNAME as SERVER, DB_NAME() as DATABASE" \
        -t 30 -h -1 2>/dev/null

if [ $? -ne 0 ]; then
    log_error "No se pudo conectar a la base de datos. Verificar credenciales."
    end_logging "run_infrastructure.sh" "ERROR"
    exit 1
fi

log_success "Conexión establecida exitosamente"

# Función para ejecutar script SQL con logging
execute_sql_script() {
    local script_file="$1"
    local output_file="$2"
    local description="$3"
    
    log_info "📋 $description..."
    
    if [ ! -f "$script_file" ]; then
        log_error "No se encontró el archivo: $script_file"
        return 1
    fi
    
    local start_time=$SECONDS
    
    $SQLCMD -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
            -i "$script_file" -o "$output_file" \
            -t $TIMEOUT -s "|" -W -h -1 2>/dev/null
    
    local duration=$((SECONDS - start_time))
    
    if [ $? -eq 0 ]; then
        log_success "$description completado"
        if [ -f "$output_file" ]; then
            local size=$(du -h "$output_file" | cut -f1)
            log_info "  📄 Archivo generado: $(basename "$output_file") ($size)"
        fi
        log_sql_execution "$script_file" "$output_file" "$duration" "SUCCESS"
        return 0
    else
        log_error "Error ejecutando: $description"
        log_sql_execution "$script_file" "$output_file" "$duration" "ERROR"
        return 1
    fi
}

# Array de scripts a ejecutar
declare -a scripts=(
    "$SCRIPT_DIR/01_system_resources.sql|01_system_resources_$TIMESTAMP.txt|Analizando recursos del sistema (CPU, Memoria)"
    "$SCRIPT_DIR/02_sessions_connections.sql|02_sessions_connections_$TIMESTAMP.txt|Analizando sesiones y conexiones activas"
    "$SCRIPT_DIR/03_storage_io_analysis.sql|03_storage_io_analysis_$TIMESTAMP.txt|Analizando almacenamiento y I/O"
)

# Ejecutar scripts individuales
success_count=0
total_scripts=${#scripts[@]}

for script_info in "${scripts[@]}"; do
    IFS='|' read -r script_file output_file description <<< "$script_info"
    
    if execute_sql_script "$script_file" "$REPORTS_DIR/$output_file" "$description"; then
        ((success_count++))
    fi
    
    sleep 2
done

# Ejecutar análisis completo
log_info "📊 Generando reporte completo de infraestructura..."
complete_report="$REPORTS_DIR/complete_infrastructure_$TIMESTAMP.txt"
execute_sql_script "$SCRIPT_DIR/run_infrastructure_analysis.sql" "$complete_report" "Generando reporte completo"

# Generar reporte ejecutivo
log_info "📝 Generando reporte ejecutivo..."
executive_report="$REPORTS_DIR/executive_summary_$TIMESTAMP.txt"

cat > "$executive_report" << EOF
# 🏗️ REPORTE EJECUTIVO DE INFRAESTRUCTURA

**Generado:** $(date)
**Servidor:** $SERVER
**Base de Datos:** $DATABASE
**Análisis:** Infraestructura completa

## 📊 Resumen de Análisis

### ✅ Componentes Analizados:
- **Recursos del Sistema:** CPU, Memoria, Configuración
- **Sesiones Activas:** Conexiones, Bloqueos, Procesos
- **Almacenamiento:** I/O, Latencia, Espacio en Disco
- **Rendimiento:** Contadores, Estadísticas, Buffer Pool

### 📁 Archivos Generados:
EOF

for file in "$REPORTS_DIR"/*"$TIMESTAMP"*; do
    if [ -f "$file" ] && [ "$file" != "$executive_report" ]; then
        filename=$(basename "$file")
        size=$(du -h "$file" | cut -f1)
        echo "- **$filename** ($size)" >> "$executive_report"
    fi
done

cat >> "$executive_report" << EOF

## 🎯 Próximos Pasos:

1. **Revisar recursos del sistema** para identificar cuellos de botella
2. **Analizar sesiones activas** para optimizar conexiones
3. **Evaluar I/O y almacenamiento** para mejorar rendimiento
4. **Implementar recomendaciones** basadas en los hallazgos

---
*Análisis generado automáticamente*
EOF

# Resumen final
log_info "🎯 RESUMEN DE ANÁLISIS DE INFRAESTRUCTURA"
if [ $success_count -eq $total_scripts ]; then
    log_success "Scripts ejecutados exitosamente: $success_count de $total_scripts"
else
    log_warning "Scripts ejecutados: $success_count de $total_scripts (algunos fallaron)"
fi

log_info "Reportes generados en: $REPORTS_DIR"

# Listar archivos generados
log_info "📁 ARCHIVOS GENERADOS:"
for file in "$REPORTS_DIR"/*"$TIMESTAMP"*; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        log_info "  📄 $(basename "$file") ($size)"
    fi
done

if [ $success_count -eq $total_scripts ]; then
    log_success "🎉 ANÁLISIS DE INFRAESTRUCTURA COMPLETADO EXITOSAMENTE"
    end_logging "run_infrastructure.sh" "SUCCESS"
else
    log_warning "⚠️  ANÁLISIS COMPLETADO CON ADVERTENCIAS"
    end_logging "run_infrastructure.sh" "WARNING"
fi

log_info "✅ Proceso completado. Revise los archivos en: $REPORTS_DIR"

log_info "💡 RECOMENDACIONES RÁPIDAS:"
log_info "1. Revisar CPU y memoria en 01_system_resources"
log_info "2. Verificar sesiones bloqueadas en 02_sessions_connections"
log_info "3. Analizar latencia de I/O en 03_storage_io_analysis"
log_info "4. Consultar reporte ejecutivo para resumen completo"
