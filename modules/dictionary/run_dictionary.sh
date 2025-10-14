#!/bin/bash

# =====================================================
# GENERADOR AUTOMÁTICO DE DICCIONARIO DE DATOS
# Ejecuta todos los scripts y genera reportes completos
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
REPORTS_DIR="$SCRIPT_DIR/../../reports/dictionary"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Iniciar logging
start_logging "run_dictionary.sh" "Generación de diccionario completo de datos"

# Crear directorio de reportes
mkdir -p "$REPORTS_DIR"

# Verificar que sqlcmd esté disponible
if ! command -v /opt/mssql-tools/bin/sqlcmd &> /dev/null; then
    log_error "sqlcmd no está instalado"
    end_logging "run_dictionary.sh" "ERROR"
    exit 1
fi

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
    end_logging "run_dictionary.sh" "ERROR"
    exit 1
fi

log_success "Conexión establecida exitosamente"

# Función para ejecutar script SQL con logging
execute_sql_script() {
    local script_file="$1"
    local output_file="$2"
    local description="$3"
    
    log_info "📋 $description..."
    
    if [ ! -f "$SCRIPT_DIR/$script_file" ]; then
        log_error "No se encontró el archivo: $script_file"
        return 1
    fi
    
    local start_time=$SECONDS
    
    $SQLCMD -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
            -i "$SCRIPT_DIR/$script_file" -o "$output_file" \
            -t $TIMEOUT -s "|" -W -h -1 2>/dev/null
    
    local duration=$((SECONDS - start_time))
    
    if [ $? -eq 0 ]; then
        log_success "$description completado"
        if [ -f "$output_file" ]; then
            local size=$(du -h "$output_file" | cut -f1)
            log_info "  📄 Archivo generado: $(basename "$output_file") ($size)"
        fi
        log_sql_execution "$SCRIPT_DIR/$script_file" "$output_file" "$duration" "SUCCESS"
        return 0
    else
        log_error "Error ejecutando: $description"
        log_sql_execution "$SCRIPT_DIR/$script_file" "$output_file" "$duration" "ERROR"
        return 1
    fi
}

# Array de scripts a ejecutar
declare -a scripts=(
    "01_complete_database_dictionary.sql|01_database_structure_$TIMESTAMP.txt|Analizando estructura de base de datos"
    "02_programmable_objects.sql|02_programmable_objects_$TIMESTAMP.txt|Analizando objetos programables"
    "03_security_permissions.sql|03_security_permissions_$TIMESTAMP.txt|Analizando seguridad y permisos"
    "04_statistics_performance.sql|04_performance_stats_$TIMESTAMP.txt|Analizando estadísticas de rendimiento"
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

# Ejecutar script completo
log_info "📊 Generando reporte completo de diccionario..."
complete_report="$REPORTS_DIR/complete_dictionary_$TIMESTAMP.txt"
execute_sql_script "run_complete_dictionary.sql" "$complete_report" "Generando reporte completo"

# Generar documentación Markdown
log_info "📝 Generando documentación Markdown..."
markdown_report="$REPORTS_DIR/Database_Dictionary_$TIMESTAMP.md"
execute_sql_script "05_generate_markdown_documentation.sql" "$markdown_report" "Generando documentación Markdown"

# Crear índice de archivos generados
index_file="$REPORTS_DIR/INDEX_$TIMESTAMP.md"
cat > "$index_file" << EOF
# 📊 Índice de Diccionario de Datos

**Generado:** $(date)
**Base de Datos:** $DATABASE
**Servidor:** $SERVER

## 📁 Archivos Generados

EOF

for file in "$REPORTS_DIR"/*"$TIMESTAMP"*; do
    if [ -f "$file" ] && [ "$file" != "$index_file" ]; then
        filename=$(basename "$file")
        size=$(du -h "$file" | cut -f1)
        echo "- **$filename** ($size)" >> "$index_file"
    fi
done

cat >> "$index_file" << EOF

## 🎯 Descripción de Archivos

- **01_database_structure**: Estructura completa de tablas, columnas, índices y relaciones
- **02_programmable_objects**: Vistas, procedimientos almacenados, funciones y tipos de usuario
- **03_security_permissions**: Usuarios, roles, permisos y configuración de seguridad
- **04_performance_stats**: Estadísticas de rendimiento, fragmentación e índices
- **complete_dictionary**: Reporte completo consolidado
- **Database_Dictionary**: Documentación en formato Markdown

---
*Generado automáticamente por el sistema de documentación de base de datos*
EOF

log_success "Índice creado: $(basename "$index_file")"

# Resumen final
log_info "🎯 RESUMEN DE GENERACIÓN DE DICCIONARIO"
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
    log_success "🎉 DICCIONARIO COMPLETO GENERADO EXITOSAMENTE"
    end_logging "run_dictionary.sh" "SUCCESS"
else
    log_warning "⚠️  DICCIONARIO GENERADO CON ADVERTENCIAS"
    end_logging "run_dictionary.sh" "WARNING"
fi

log_info "✅ Proceso completado. Revise los archivos en: $REPORTS_DIR"
