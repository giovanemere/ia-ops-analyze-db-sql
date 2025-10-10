# 🚀 Guía de Ejecución - Ventana de Mantenimiento

## ⏰ Cronograma de Ejecución

### **FASE 1: Mantenimiento Urgente** (2-4 horas)
```bash
# Ejecutar en ventana de mantenimiento
sqlcmd -S persqlmotorpromocprd.database.windows.net -d persqldbmotorpromocprd -U u_yairpanqueva -P "0x2E0403602967FDD263E5" -C -i scripts/maintenance/mantenimiento_urgente.sql
```

**⚠️ IMPORTANTE:**
- Requiere **DOWNTIME** (ONLINE = OFF para REBUILD)
- Tiempo estimado: **2-4 horas**
- Ejecutar en horario de menor actividad

### **FASE 2: Optimización Adicional** (1-2 horas)
```bash
# Puede ejecutarse con sistema activo (ONLINE = ON)
sqlcmd -S persqlmotorpromocprd.database.windows.net -d persqldbmotorpromocprd -U u_yairpanqueva -P "0x2E0403602967FDD263E5" -C -i scripts/maintenance/optimizacion_adicional.sql
```

**✅ VENTAJA:**
- Se ejecuta **ONLINE** (sin downtime)
- Mejoras adicionales del 20-30%

### **FASE 3: Validación** (15 minutos)
```bash
# Verificar que todo funcionó correctamente
sqlcmd -S persqlmotorpromocprd.database.windows.net -d persqldbmotorpromocprd -U u_yairpanqueva -P "0x2E0403602967FDD263E5" -C -i scripts/maintenance/validacion_post_mantenimiento.sql
```

## 📋 Checklist Pre-Ejecución

### Antes de Comenzar:
- [ ] **Backup completo** de la base de datos
- [ ] Verificar **espacio libre** en disco (mínimo 50% adicional)
- [ ] Coordinar **ventana de mantenimiento** con usuarios
- [ ] Tener **plan de rollback** preparado
- [ ] Monitorear **CPU y memoria** disponibles

### Recursos Necesarios:
- **CPU**: 4 cores disponibles (MAXDOP = 4)
- **Memoria**: Mínimo 8GB RAM libre
- **Disco**: 50% espacio adicional temporal
- **Tiempo**: 3-6 horas total

## 🎯 Resultados Esperados

### Antes del Mantenimiento:
```
❌ Fragmentación: 92-99% (crítica)
❌ Consulta típica: 15-45 segundos
❌ CPU promedio: 75-85%
❌ Timeouts frecuentes
```

### Después del Mantenimiento:
```
✅ Fragmentación: <10% (óptima)
✅ Consulta típica: 2-5 segundos
✅ CPU promedio: 45-55%
✅ Sin timeouts
```

## 🚨 Plan de Contingencia

### Si algo sale mal:
1. **DETENER** ejecución inmediatamente
2. **RESTAURAR** desde backup
3. **CONTACTAR** al equipo de DBA
4. **DOCUMENTAR** el error para análisis

### Comandos de Emergencia:
```sql
-- Verificar procesos activos
SELECT * FROM sys.dm_exec_requests WHERE command LIKE '%INDEX%';

-- Cancelar operación si es necesario
KILL [session_id];

-- Verificar integridad después de problemas
DBCC CHECKDB('persqldbmotorpromocprd');
```

## 📊 Monitoreo Durante Ejecución

### Consultas de Monitoreo:
```sql
-- Ver progreso de REBUILD/REORGANIZE
SELECT 
    r.session_id,
    r.command,
    r.percent_complete,
    r.estimated_completion_time,
    CAST(r.estimated_completion_time/1000.0/60 AS DECIMAL(10,2)) AS minutos_restantes
FROM sys.dm_exec_requests r
WHERE r.command IN ('ALTER INDEX', 'UPDATE STATISTICS');

-- Verificar uso de recursos
SELECT 
    cpu_time,
    total_elapsed_time,
    logical_reads,
    writes
FROM sys.dm_exec_requests 
WHERE session_id = @@SPID;
```

## 📞 Contactos de Emergencia

- **DBA Principal**: [Tu contacto]
- **Equipo de Infraestructura**: [Contacto]
- **Responsable de Aplicación**: [Contacto]

## ✅ Post-Ejecución

### Verificar:
1. **Fragmentación** reducida (<10%)
2. **Consultas** más rápidas (80-90% mejora)
3. **Sin errores** en logs de SQL Server
4. **Aplicación** funcionando correctamente

### Documentar:
- Tiempo total de ejecución
- Mejoras observadas
- Problemas encontrados
- Próxima fecha de mantenimiento

---

**🎯 ¿Listo para ejecutar? Comienza con la Fase 1 en tu próxima ventana de mantenimiento.**
