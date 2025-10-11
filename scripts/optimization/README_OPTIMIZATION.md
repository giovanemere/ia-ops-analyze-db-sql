# ⚡ Optimización Completa de Base de Datos

## 🎯 Objetivo

Implementar optimización completa de la base de datos `persqldbmotorpromocprd` con backup, análisis, mantenimiento y rollback integrados.

## 📋 Orden de Ejecución Recomendado

### 🔄 **PROCESO COMPLETO CON BACKUP Y ROLLBACK**

```bash
# PASO 1: BACKUP PRE-OPTIMIZACIÓN (CRÍTICO)
./scripts/backup/02_azure_backup.ps1 -ResourceGroupName "[TU_RG]" -ServerName "persqlmotorpromocprd" -DatabaseName "persqldbmotorpromocprd" -StorageAccountName "primaxbackups2024" -ContainerName "backups" -AdminLogin "u_yairpanqueva" -AdminPassword "0x2E0403602967FDD263E5"

# PASO 2: ANÁLISIS PRE-OPTIMIZACIÓN
./scripts/optimization/run_optimization.sh
# Responder "N" al mantenimiento urgente (solo análisis)

# PASO 3: PLANIFICAR VENTANA DE MANTENIMIENTO
# - Revisar resultados del análisis
# - Programar ventana de 4-6 horas
# - Notificar usuarios

# PASO 4: OPTIMIZACIÓN COMPLETA (VENTANA DE MANTENIMIENTO)
./scripts/optimization/run_optimization.sh
# Responder "Y" al mantenimiento urgente

# PASO 5: VALIDACIÓN POST-OPTIMIZACIÓN
# - Verificar rendimiento
# - Probar aplicaciones
# - Monitorear 24-48 horas
```

## 🚨 Plan de Rollback

### **Si algo falla durante la optimización:**

```bash
# ROLLBACK OPCIÓN 1: Restore desde BACPAC
./scripts/backup/03_restore_database.ps1 \
    -ResourceGroupName "[TU_RG]" \
    -ServerName "persqlmotorpromocprd" \
    -NewDatabaseName "persqldbmotorpromocprd_rollback" \
    -StorageAccountName "primaxbackups2024" \
    -ContainerName "backups" \
    -BackupFileName "[BACKUP_FILE].bacpac" \
    -AdminLogin "u_yairpanqueva" \
    -AdminPassword "0x2E0403602967FDD263E5"

# ROLLBACK OPCIÓN 2: Eliminar índices problemáticos
DROP INDEX IF EXISTS IX_CuponesDigitales_FechaCreacion ON CuponesDigitales;
DROP INDEX IF EXISTS IX_CuponesDigitales_Campanna_Estado ON CuponesDigitales;
# ... otros índices según sea necesario
```

## 📁 Estructura Integrada

```
scripts/
├── backup/                           # Scripts de backup y restore
│   ├── 02_azure_backup.ps1          # Backup principal
│   ├── 03_restore_database.ps1      # Restore/rollback
│   └── README_BACKUP_RESTORE.md     # Guía de backup
├── optimization/                     # Scripts de optimización
│   ├── 01_performance_analysis.sql  # Análisis de rendimiento
│   ├── 02_create_indexes.sql        # Índices optimizados
│   ├── 05_maintenance_urgent.sql    # Mantenimiento urgente
│   ├── 06_additional_optimization.sql # Optimización adicional
│   ├── 07_validation.sql            # Validación
│   ├── run_optimization.sql         # Script SQL principal
│   ├── run_optimization.sh          # Script bash automatizado
│   └── README_OPTIMIZATION.md       # Esta guía
```

## 🔄 Métodos de Ejecución Seguros

### **Método 1: Proceso Completo Automatizado (Recomendado)**

```bash
# 1. Backup automático
cd /home/giovanemere/periferia/primax/sql-analysis-project
./scripts/backup/02_azure_backup.ps1 \
    -ResourceGroupName "[TU_RESOURCE_GROUP]" \
    -ServerName "persqlmotorpromocprd" \
    -DatabaseName "persqldbmotorpromocprd" \
    -StorageAccountName "primaxbackups2024" \
    -ContainerName "backups" \
    -AdminLogin "u_yairpanqueva" \
    -AdminPassword "0x2E0403602967FDD263E5"

# 2. Optimización con análisis previo
./scripts/optimization/run_optimization.sh
```

### **Método 2: Paso a Paso con Validación**

```bash
# FASE 1: BACKUP (60-90 min)
./scripts/backup/02_azure_backup.ps1 [parámetros]

# FASE 2: ANÁLISIS INICIAL (15 min, sin downtime)
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -i scripts/optimization/01_performance_analysis.sql \
    -o reports/pre_optimization_analysis.txt

# FASE 3: CREAR ÍNDICES (30 min, online)
/opt/mssql-tools/bin/sqlcmd [...] \
    -i scripts/optimization/02_create_indexes.sql \
    -o reports/create_indexes.txt

# FASE 4: MANTENIMIENTO URGENTE (2-4 horas, downtime)
/opt/mssql-tools/bin/sqlcmd [...] \
    -i scripts/optimization/05_maintenance_urgent.sql \
    -o reports/maintenance_urgent.txt -t 7200

# FASE 5: VALIDACIÓN (15 min)
/opt/mssql-tools/bin/sqlcmd [...] \
    -i scripts/optimization/07_validation.sql \
    -o reports/validation.txt
```

## ⚠️ Consideraciones Críticas

### **Tiempos Estimados:**
- **Backup:** 60-90 minutos (~30GB)
- **Análisis:** 15 minutos
- **Índices:** 30 minutos (online)
- **Mantenimiento:** 2-4 horas (downtime)
- **Rollback:** 60-120 minutos (si es necesario)

### **Requisitos de Espacio:**
- **Backup BACPAC:** ~30GB en Azure Storage
- **Espacio temporal:** 20-30% adicional durante optimización
- **Rollback:** Espacio para BD temporal

### **Puntos de No Retorno:**
1. **Antes del mantenimiento:** Rollback fácil (solo eliminar índices)
2. **Durante REBUILD:** Rollback complejo (requiere restore)
3. **Después de validación:** Rollback desde backup

## 🚨 Plan de Contingencia

### **Escenario 1: Falla durante creación de índices**
```sql
-- Eliminar índices problemáticos
DROP INDEX IF EXISTS IX_CuponesDigitales_FechaCreacion ON CuponesDigitales;
-- Continuar con el resto del proceso
```

### **Escenario 2: Falla durante mantenimiento urgente**
```bash
# Restore completo desde backup
./scripts/backup/03_restore_database.ps1 \
    -NewDatabaseName "persqldbmotorpromocprd_restored" \
    [otros parámetros]
```

### **Escenario 3: Rendimiento degradado post-optimización**
```sql
-- Revertir estadísticas
UPDATE STATISTICS CuponesDigitales WITH SAMPLE 10 PERCENT;
-- O restore completo si es crítico
```

## 📊 Checklist Pre-Optimización

### ✅ **Antes de Ejecutar:**
- [ ] Backup completado y verificado
- [ ] Ventana de mantenimiento programada
- [ ] Usuarios notificados
- [ ] Espacio suficiente en Azure Storage
- [ ] Plan de rollback documentado
- [ ] Monitoreo preparado

### ✅ **Durante la Ejecución:**
- [ ] Monitorear progreso de cada fase
- [ ] Verificar logs por errores
- [ ] Validar cada paso antes de continuar
- [ ] Mantener comunicación con usuarios

### ✅ **Post-Optimización:**
- [ ] Validar integridad de datos
- [ ] Probar funcionalidad crítica
- [ ] Monitorear rendimiento 24-48h
- [ ] Documentar cambios realizados
- [ ] Programar mantenimiento automático

## ⚡ Mejoras Esperadas

### Con Optimization Completa:
- **Consultas:** 60-80% más rápidas
- **Fragmentación:** <10% (desde 99%)
- **CPU:** Reducción 30-40%
- **I/O:** Mejora significativa
- **Espacio:** Optimización 20-30%

### Solo con Maintenance:
- **Consultas:** 40-60% más rápidas
- **Fragmentación:** <10%
- **CPU:** Reducción 20-30%
- **Sin índices nuevos**

## 🚨 Consideraciones Importantes

### Downtime Requerido:
- **Análisis:** Sin downtime
- **Mantenimiento:** 2-4 horas downtime
- **Índices:** Parcial (ONLINE = ON)
- **Validación:** Sin downtime

### Recursos Necesarios:
- **CPU:** Uso intensivo durante optimización
- **I/O:** Alto durante REBUILD
- **Espacio:** 20-30% adicional temporal
- **Memoria:** Uso elevado

## 💡 Decisión Final

**RECOMENDACIÓN:** Usar `/scripts/optimization/` con el siguiente plan:

1. **Ejecutar análisis** sin mantenimiento (30 min)
2. **Revisar resultados** y planificar ventana
3. **Ejecutar optimización completa** en ventana de mantenimiento
4. **Monitorear** resultados 24-48 horas
5. **Ajustar** según sea necesario

Esto te dará la mejor optimización posible con análisis completo y validación de resultados.
