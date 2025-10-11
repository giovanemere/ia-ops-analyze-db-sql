# 📋 Plan de Ejecución por Tareas Separadas

## 🎯 Objetivo
Ejecutar análisis y optimización de la base de datos SQL Azure en tareas independientes y controladas.

## 📊 Información del Entorno
- **Servidor:** persqlmotorpromocprd.database.windows.net
- **Base de Datos:** persqldbmotorpromocprd (Hyperscale HS_Gen5_12)
- **Tamaño:** ~30 GB (58M registros)
- **Resource Group:** PERRSGRPYPRMTCLLYP
- **Storage Account:** perstgmotorbackprd

---

## 🚀 FASE 1: ANÁLISIS INICIAL (Sin Downtime)

### Tarea 1.1: Análisis de Rendimiento
```bash
# Duración: 15 minutos | Downtime: No
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -i scripts/optimization/01_performance_analysis.sql \
    -o reports/01_performance_analysis.txt -t 300
```

### Tarea 1.2: Análisis de Infraestructura
```bash
# Duración: 10 minutos | Downtime: No
./scripts/infrastructure/run_infrastructure.sh
```

### Tarea 1.3: Generación de Diccionario
```bash
# Duración: 10 minutos | Downtime: No
./scripts/dictionary/run_dictionary.sh
```

**✅ Resultado Fase 1:** Reportes de análisis completos sin afectar producción

---

## 💾 FASE 2: BACKUP DE SEGURIDAD (Crítico)

### Tarea 2.1: Backup Completo
```bash
# Duración: 60-90 minutos | Downtime: No
./scripts/backup/04_backup_azure_cli.sh
```

### Tarea 2.2: Verificación de Backup
```bash
# Duración: 5 minutos | Downtime: No
az storage blob show --container-name backups --account-name perstgmotorbackprd \
    --name "persqldbmotorpromocprd_backup_$(date +%Y%m%d)*.bacpac" --output table
```

**✅ Resultado Fase 2:** Backup verificado y disponible para rollback

---

## ⚡ FASE 3: OPTIMIZACIÓN (Ventana de Mantenimiento)

### Tarea 3.1: Creación de Índices
```bash
# Duración: 30 minutos | Downtime: Parcial (ONLINE=ON)
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -i scripts/optimization/02_create_indexes.sql \
    -o reports/02_create_indexes.txt -t 1800
```

### Tarea 3.2: Mantenimiento Urgente
```bash
# Duración: 2-4 horas | Downtime: Sí (REBUILD)
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -i scripts/optimization/05_maintenance_urgent.sql \
    -o reports/05_maintenance_urgent.txt -t 14400
```

### Tarea 3.3: Optimización Adicional
```bash
# Duración: 20 minutos | Downtime: Mínimo
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -i scripts/optimization/06_additional_optimization.sql \
    -o reports/06_additional_optimization.txt -t 1200
```

**✅ Resultado Fase 3:** Base de datos optimizada con mejoras de 60-80%

---

## ✅ FASE 4: VALIDACIÓN POST-OPTIMIZACIÓN

### Tarea 4.1: Validación de Integridad
```bash
# Duración: 15 minutos | Downtime: No
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -i scripts/optimization/07_validation.sql \
    -o reports/07_validation.txt -t 900
```

### Tarea 4.2: Análisis Post-Optimización
```bash
# Duración: 15 minutos | Downtime: No
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -i scripts/optimization/01_performance_analysis.sql \
    -o reports/01_performance_analysis_post.txt -t 300
```

**✅ Resultado Fase 4:** Validación completa y métricas de mejora

---

## 🚨 PLAN DE ROLLBACK (Si es necesario)

### Rollback Rápido: Eliminar Índices Problemáticos
```sql
-- Solo si hay problemas con índices nuevos
DROP INDEX IF EXISTS IX_CuponesDigitales_FechaCreacion ON CuponesDigitales;
DROP INDEX IF EXISTS IX_CuponesDigitales_Campanna_Estado ON CuponesDigitales;
DROP INDEX IF EXISTS IX_CuponesFisicoCorreccion_FechaCreacion ON CuponesFisicoCorreccion;
```

### Rollback Completo: Restore desde Backup
```bash
# Duración: 60-120 minutos | Downtime: Sí
./scripts/optimization/emergency_rollback.sh
```

---

## 📅 CRONOGRAMA RECOMENDADO

### **Día 1: Análisis (Horario Normal)**
- ✅ 09:00 - 09:15: Tarea 1.1 (Análisis de Rendimiento)
- ✅ 09:15 - 09:25: Tarea 1.2 (Análisis de Infraestructura)
- ✅ 09:25 - 09:35: Tarea 1.3 (Diccionario de Datos)
- ✅ 09:35 - 10:00: Revisión de resultados y planificación

### **Día 2: Backup (Horario Normal)**
- ✅ 14:00 - 15:30: Tarea 2.1 (Backup Completo)
- ✅ 15:30 - 15:35: Tarea 2.2 (Verificación de Backup)

### **Día 3: Optimización (Ventana de Mantenimiento)**
- ⚠️ 02:00 - 02:30: Tarea 3.1 (Creación de Índices)
- ⚠️ 02:30 - 06:30: Tarea 3.2 (Mantenimiento Urgente)
- ⚠️ 06:30 - 06:50: Tarea 3.3 (Optimización Adicional)
- ✅ 06:50 - 07:05: Tarea 4.1 (Validación)
- ✅ 07:05 - 07:20: Tarea 4.2 (Análisis Post-Optimización)

---

## 📊 CHECKLIST DE EJECUCIÓN

### Pre-Ejecución
- [ ] Azure CLI autenticado (`az login`)
- [ ] Conexión a BD verificada
- [ ] Espacio suficiente en storage account
- [ ] Notificación a usuarios (para Fase 3)
- [ ] Plan de rollback documentado

### Durante Ejecución
- [ ] Monitorear logs en tiempo real
- [ ] Verificar progreso de cada tarea
- [ ] Documentar cualquier error
- [ ] Mantener comunicación con stakeholders

### Post-Ejecución
- [ ] Validar integridad de datos
- [ ] Probar funcionalidad crítica
- [ ] Comparar métricas pre/post
- [ ] Documentar resultados
- [ ] Programar monitoreo continuo

---

## 🔧 COMANDOS DE MONITOREO

### Ver Logs en Tiempo Real
```bash
./scripts/common/log_manager.sh tail
```

### Verificar Estado de Operaciones
```bash
./scripts/common/log_manager.sh stats
```

### Buscar Errores
```bash
./scripts/common/log_manager.sh errors 1
```

---

## 📞 CONTACTOS DE EMERGENCIA

- **DBA Principal:** [Contacto]
- **Administrador Azure:** [Contacto]
- **Responsable Aplicación:** [Contacto]

---

**Tiempo Total Estimado:** 6-8 horas (distribuido en 3 días)
**Downtime Requerido:** 4-5 horas (solo Fase 3)
**Mejoras Esperadas:** 60-80% en rendimiento de consultas
