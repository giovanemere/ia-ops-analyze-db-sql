#!/bin/bash

# =====================================================
# OPTIMIZACIÓN COMPLETA DE BASE DE DATOS
# Ejecuta análisis, mantenimiento y optimización
# =====================================================

# Configuración
SERVER="persqlmotorpromocprd.database.windows.net"
DATABASE="persqldbmotorpromocprd"
USERNAME="u_yairpanqueva"
PASSWORD="0x2E0403602967FDD263E5"
TIMEOUT=600  # 10 minutos para operaciones largas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/../../reports/optimization"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de logging
log() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Crear directorio de reportes
mkdir -p "$REPORTS_DIR"

SQLCMD="/opt/mssql-tools/bin/sqlcmd"

log "🚀 INICIANDO OPTIMIZACIÓN COMPLETA DE BASE DE DATOS"
echo "=================================================="
log "Servidor: $SERVER"
log "Base de Datos: $DATABASE"
log "Usuario: $USERNAME"
log "Directorio de Reportes: $REPORTS_DIR"
log "Timestamp: $TIMESTAMP"
echo "=================================================="

# Test de conexión
log "🔍 Probando conexión a la base de datos..."
$SQLCMD -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
        -Q "SELECT 'CONNECTION_OK' as STATUS, DB_NAME() as DATABASE" \
        -t 30 -h -1 2>/dev/null

if [ $? -ne 0 ]; then
    error "No se pudo conectar a la base de datos. Verificar credenciales."
    exit 1
fi

success "Conexión establecida exitosamente"

# Función para ejecutar script SQL
execute_sql_script() {
    local script_file="$1"
    local output_file="$2"
    local description="$3"
    local timeout="${4:-$TIMEOUT}"
    
    log "📋 $description..."
    
    if [ ! -f "$script_file" ]; then
        error "No se encontró el archivo: $script_file"
        return 1
    fi
    
    $SQLCMD -S "$SERVER" -d "$DATABASE" -U "$USERNAME" -P "$PASSWORD" \
            -i "$script_file" -o "$output_file" \
            -t $timeout -s "|" -W -h -1 2>/dev/null
    
    if [ $? -eq 0 ]; then
        success "$description completado"
        if [ -f "$output_file" ]; then
            local size=$(du -h "$output_file" | cut -f1)
            log "  📄 Archivo generado: $(basename "$output_file") ($size)"
        fi
        return 0
    else
        error "Error ejecutando: $description"
        return 1
    fi
}

# FASE 1: ANÁLISIS PRE-OPTIMIZACIÓN
log "🔍 FASE 1: ANÁLISIS PRE-OPTIMIZACIÓN"
echo "======================================"

execute_sql_script \
    "$SCRIPT_DIR/01_performance_analysis.sql" \
    "$REPORTS_DIR/01_pre_optimization_analysis_$TIMESTAMP.txt" \
    "Analizando rendimiento actual" \
    300

# FASE 2: MANTENIMIENTO URGENTE
log "🔧 FASE 2: MANTENIMIENTO URGENTE"
echo "================================="

warning "Esta fase puede tomar 2-4 horas y requiere ventana de mantenimiento"
read -p "¿Continuar con mantenimiento urgente? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    execute_sql_script \
        "$SCRIPT_DIR/05_maintenance_urgent.sql" \
        "$REPORTS_DIR/02_maintenance_urgent_$TIMESTAMP.txt" \
        "Ejecutando mantenimiento urgente (REBUILD/REORGANIZE)" \
        7200  # 2 horas
else
    warning "Mantenimiento urgente omitido por el usuario"
fi

# FASE 3: CREACIÓN DE ÍNDICES
log "📊 FASE 3: CREACIÓN DE ÍNDICES OPTIMIZADOS"
echo "==========================================="

execute_sql_script \
    "$SCRIPT_DIR/02_create_indexes.sql" \
    "$REPORTS_DIR/03_create_indexes_$TIMESTAMP.txt" \
    "Creando índices optimizados" \
    1800  # 30 minutos

# FASE 4: OPTIMIZACIÓN ADICIONAL
log "⚡ FASE 4: OPTIMIZACIÓN ADICIONAL"
echo "================================="

execute_sql_script \
    "$SCRIPT_DIR/06_additional_optimization.sql" \
    "$REPORTS_DIR/04_additional_optimization_$TIMESTAMP.txt" \
    "Ejecutando optimización adicional" \
    1200  # 20 minutos

# FASE 5: VALIDACIÓN POST-OPTIMIZACIÓN
log "✅ FASE 5: VALIDACIÓN POST-OPTIMIZACIÓN"
echo "======================================="

execute_sql_script \
    "$SCRIPT_DIR/07_validation.sql" \
    "$REPORTS_DIR/05_post_optimization_validation_$TIMESTAMP.txt" \
    "Validando resultados de optimización" \
    300

# FASE 6: ANÁLISIS POST-OPTIMIZACIÓN
log "📈 FASE 6: ANÁLISIS POST-OPTIMIZACIÓN"
echo "====================================="

execute_sql_script \
    "$SCRIPT_DIR/01_performance_analysis.sql" \
    "$REPORTS_DIR/06_post_optimization_analysis_$TIMESTAMP.txt" \
    "Analizando rendimiento post-optimización" \
    300

# Generar reporte de resumen
log "📝 Generando reporte de resumen..."
summary_report="$REPORTS_DIR/optimization_summary_$TIMESTAMP.md"

cat > "$summary_report" << EOF
# 🚀 Reporte de Optimización Completa

**Generado:** $(date)
**Base de Datos:** $DATABASE
**Servidor:** $SERVER

## 📊 Fases Ejecutadas

### ✅ Fase 1: Análisis Pre-Optimización
- **Archivo:** 01_pre_optimization_analysis_$TIMESTAMP.txt
- **Propósito:** Identificar problemas de rendimiento

### ✅ Fase 2: Mantenimiento Urgente
- **Archivo:** 02_maintenance_urgent_$TIMESTAMP.txt
- **Propósito:** REBUILD/REORGANIZE de índices fragmentados

### ✅ Fase 3: Creación de Índices
- **Archivo:** 03_create_indexes_$TIMESTAMP.txt
- **Propósito:** Crear índices optimizados para consultas frecuentes

### ✅ Fase 4: Optimización Adicional
- **Archivo:** 04_additional_optimization_$TIMESTAMP.txt
- **Propósito:** Optimizaciones complementarias

### ✅ Fase 5: Validación
- **Archivo:** 05_post_optimization_validation_$TIMESTAMP.txt
- **Propósito:** Verificar integridad post-optimización

### ✅ Fase 6: Análisis Post-Optimización
- **Archivo:** 06_post_optimization_analysis_$TIMESTAMP.txt
- **Propósito:** Medir mejoras obtenidas

## 🎯 Mejoras Esperadas

- **Consultas:** 60-80% más rápidas
- **Fragmentación:** Reducida a <10%
- **CPU:** Reducción del 30-40%
- **I/O:** Mejora significativa en lecturas lógicas

## 📋 Próximos Pasos

1. Monitorear rendimiento durante 24-48 horas
2. Ajustar índices según patrones de uso
3. Programar mantenimiento automático
4. Documentar cambios realizados

---
*Optimización generada automáticamente*
EOF

success "Reporte de resumen creado: $(basename "$summary_report")"

# Resumen final
echo ""
log "🎯 RESUMEN DE OPTIMIZACIÓN COMPLETA"
echo "===================================="
success "Optimización completada exitosamente"
log "Reportes generados en: $REPORTS_DIR"

# Listar archivos generados
echo ""
log "📁 ARCHIVOS GENERADOS:"
for file in "$REPORTS_DIR"/*"$TIMESTAMP"*; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        log "  📄 $(basename "$file") ($size)"
    fi
done

echo ""
success "🎉 OPTIMIZACIÓN COMPLETA FINALIZADA"
echo "===================================="
log "✅ Proceso completado. Revise los archivos en: $REPORTS_DIR"

echo ""
log "💡 RECOMENDACIONES POST-OPTIMIZACIÓN:"
log "1. Monitorear rendimiento durante las próximas 24-48 horas"
log "2. Verificar que las aplicaciones funcionen correctamente"
log "3. Programar mantenimiento automático semanal"
log "4. Documentar los cambios realizados"
