# 📝 Sistema de Logging Centralizado

## 🎯 Objetivo

Proporcionar un sistema de logging unificado para todos los scripts del proyecto, con análisis, rotación automática y herramientas de gestión.

## 📁 Estructura

```
scripts/common/
├── logging.sh              # Sistema de logging principal
├── log_manager.sh          # Gestor y herramientas de análisis
├── logging_example.sh      # Ejemplo de uso
└── README_LOGGING.md       # Esta guía

logs/
├── sql_analysis_YYYYMMDD.log    # Log principal diario
├── errors_YYYYMMDD.log          # Log de errores diario
└── backup/                      # Respaldos de logs
```

## 🚀 Uso Básico

### En tus scripts:

```bash
#!/bin/bash

# Cargar sistema de logging
source "$(dirname "$0")/../common/logging.sh"

# Iniciar logging del script
start_logging "mi_script.sh" "Descripción del script"

# Usar funciones de logging
log_info "Mensaje informativo"
log_success "Operación exitosa"
log_warning "Advertencia"
log_error "Error ocurrido"
log_debug "Debug (solo con DEBUG=1)"

# Logging específico para SQL
log_sql_execution "archivo.sql" "resultado.txt" "30" "SUCCESS"

# Logging específico para backups
log_backup_operation "START" "Iniciando backup"
log_backup_operation "SUCCESS" "Backup completado"

# Finalizar logging
end_logging "mi_script.sh" "SUCCESS"
```

## 🛠️ Herramientas de Gestión

### Gestor de Logs:

```bash
# Mostrar estadísticas
./scripts/common/log_manager.sh stats

# Buscar en logs
./scripts/common/log_manager.sh search "ERROR" 3

# Ver errores recientes
./scripts/common/log_manager.sh errors 1

# Seguir logs en tiempo real
./scripts/common/log_manager.sh tail

# Limpiar logs antiguos
./scripts/common/log_manager.sh clean 30

# Crear backup de logs
./scripts/common/log_manager.sh backup

# Listar archivos de log
./scripts/common/log_manager.sh list

# Analizar rendimiento
./scripts/common/log_manager.sh performance 7
```

## 📊 Tipos de Log

### Niveles disponibles:
- **INFO** - Información general
- **SUCCESS** - Operaciones exitosas
- **WARNING** - Advertencias
- **ERROR** - Errores
- **DEBUG** - Información de depuración

### Logs especializados:
- **SQL** - Ejecución de scripts SQL
- **BACKUP** - Operaciones de backup/restore
- **PERFORMANCE** - Métricas de rendimiento

## 🔧 Configuración

### Variables de entorno:

```bash
# Habilitar logs de debug
export DEBUG=1

# Cambiar directorio de logs (opcional)
export LOG_DIR="/ruta/personalizada/logs"
```

### Rotación automática:
- Los logs se rotan automáticamente cada 7 días
- Se mantienen backups por 30 días por defecto

## 📈 Análisis y Monitoreo

### Estadísticas automáticas:
- Conteo de operaciones por tipo
- Tiempos de ejecución promedio
- Detección de errores frecuentes
- Análisis de rendimiento

### Alertas (futuro):
- Notificaciones por errores críticos
- Alertas por rendimiento degradado
- Reportes automáticos

## 🎯 Integración con Scripts Existentes

### Scripts ya integrados:
- ✅ `optimization/run_optimization.sh`
- ✅ `optimization/run_full_optimization_with_backup.sh`
- ✅ `optimization/emergency_rollback.sh`

### Para integrar en otros scripts:

1. **Agregar al inicio:**
   ```bash
   source "$(dirname "$0")/../common/logging.sh"
   start_logging "$(basename "$0")" "Descripción"
   ```

2. **Reemplazar echo/printf:**
   ```bash
   # Antes
   echo "Mensaje informativo"
   
   # Después
   log_info "Mensaje informativo"
   ```

3. **Agregar al final:**
   ```bash
   end_logging "$(basename "$0")" "SUCCESS"
   ```

## 📋 Ejemplos Prácticos

### Ejemplo 1: Script de backup
```bash
source "$(dirname "$0")/../common/logging.sh"
start_logging "backup.sh" "Backup de base de datos"

log_backup_operation "START" "Iniciando backup de $DATABASE"
# ... código de backup ...
log_backup_operation "SUCCESS" "Backup completado: $BACKUP_FILE"

end_logging "backup.sh" "SUCCESS"
```

### Ejemplo 2: Script de optimización
```bash
source "$(dirname "$0")/../common/logging.sh"
start_logging "optimize.sh" "Optimización de índices"

log_info "Analizando fragmentación..."
# ... ejecutar SQL ...
log_sql_execution "analyze.sql" "results.txt" "$duration" "SUCCESS"

log_success "Optimización completada"
end_logging "optimize.sh" "SUCCESS"
```

## 🚨 Troubleshooting

### Problemas comunes:

1. **"Permission denied" en logs:**
   ```bash
   chmod 755 /home/giovanemere/periferia/primax/sql-analysis-project/logs
   ```

2. **Logs no aparecen:**
   ```bash
   # Verificar que el directorio existe
   ls -la /home/giovanemere/periferia/primax/sql-analysis-project/logs
   
   # Verificar permisos
   ./scripts/common/log_manager.sh list
   ```

3. **Logs muy grandes:**
   ```bash
   # Limpiar logs antiguos
   ./scripts/common/log_manager.sh clean 7
   
   # Crear backup antes de limpiar
   ./scripts/common/log_manager.sh backup
   ```

## 📊 Estado Actual

### ✅ Implementado:
- ✅ Sistema de logging centralizado
- ✅ Rotación automática de logs
- ✅ Herramientas de análisis
- ✅ Logging especializado (SQL, backup)
- ✅ Colores en terminal
- ✅ Gestión de errores

### 🔄 En progreso:
- ⏳ Integración en todos los scripts
- ⏳ Alertas automáticas
- ⏳ Dashboard web (futuro)

### 📈 Métricas:
- **Archivos de log:** Diarios con rotación
- **Retención:** 7 días activos, 30 días backup
- **Tamaño promedio:** ~1-5MB por día
- **Rendimiento:** <1ms overhead por log
