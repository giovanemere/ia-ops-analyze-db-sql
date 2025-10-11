# 📊 Diccionario Completo de Base de Datos

## 🎯 Objetivo

Generar documentación completa y detallada de todos los objetos y componentes de la base de datos, incluyendo:

- **Estructura de tablas** y columnas
- **Objetos programables** (vistas, procedimientos, funciones)
- **Seguridad y permisos**
- **Estadísticas de rendimiento**
- **Índices y fragmentación**
- **Relaciones y restricciones**

## 📁 Estructura de Archivos

```
scripts/dictionary/
├── 01_complete_database_dictionary.sql    # Estructura básica de BD
├── 02_programmable_objects.sql            # Vistas, procedimientos, funciones
├── 03_security_permissions.sql            # Usuarios, roles, permisos
├── 04_statistics_performance.sql          # Rendimiento y estadísticas
├── 05_generate_markdown_documentation.sql # Generador de Markdown
├── run_complete_dictionary.sql            # Script principal
├── generate_dictionary.ps1                # Automatización PowerShell
└── README_DICTIONARY.md                   # Esta guía
```

## 🚀 Métodos de Ejecución

### Método 1: Ejecución Automática (Recomendado)

```powershell
# PowerShell - Ejecución completa automatizada
.\generate_dictionary.ps1 `
    -ServerName "persqlmotorpromocprd.database.windows.net" `
    -DatabaseName "persqldbmotorpromocprd" `
    -Username "u_yairpanqueva" `
    -Password "0x2E0403602967FDD263E5" `
    -OutputPath "./reports/dictionary"
```

### Método 2: Ejecución Manual por Partes

```bash
# 1. Estructura básica
sqlcmd -S persqlmotorpromocprd.database.windows.net \
       -d persqldbmotorpromocprd \
       -U u_yairpanqueva \
       -P 0x2E0403602967FDD263E5 \
       -i 01_complete_database_dictionary.sql \
       -o ../reports/01_database_structure.txt

# 2. Objetos programables
sqlcmd -S persqlmotorpromocprd.database.windows.net \
       -d persqldbmotorpromocprd \
       -U u_yairpanqueva \
       -P 0x2E0403602967FDD263E5 \
       -i 02_programmable_objects.sql \
       -o ../reports/02_programmable_objects.txt

# 3. Seguridad y permisos
sqlcmd -S persqlmotorpromocprd.database.windows.net \
       -d persqldbmotorpromocprd \
       -U u_yairpanqueva \
       -P 0x2E0403602967FDD263E5 \
       -i 03_security_permissions.sql \
       -o ../reports/03_security_permissions.txt

# 4. Estadísticas de rendimiento
sqlcmd -S persqlmotorpromocprd.database.windows.net \
       -d persqldbmotorpromocprd \
       -U u_yairpanqueva \
       -P 0x2E0403602967FDD263E5 \
       -i 04_statistics_performance.sql \
       -o ../reports/04_performance_stats.txt
```

### Método 3: Script Principal Completo

```bash
# Ejecutar todo en una sola operación
sqlcmd -S persqlmotorpromocprd.database.windows.net \
       -d persqldbmotorpromocprd \
       -U u_yairpanqueva \
       -P 0x2E0403602967FDD263E5 \
       -i run_complete_dictionary.sql \
       -o ../reports/complete_dictionary.txt
```

## 📋 Información Extraída

### 1. Estructura Básica (`01_complete_database_dictionary.sql`)

- ✅ **Información general** de la base de datos
- ✅ **Tablas** con propiedades y estadísticas de espacio
- ✅ **Columnas** detalladas con tipos de datos
- ✅ **Claves primarias** y sus propiedades
- ✅ **Claves foráneas** y relaciones
- ✅ **Índices** con configuración completa
- ✅ **Restricciones CHECK**
- ✅ **Triggers** y su estado

### 2. Objetos Programables (`02_programmable_objects.sql`)

- ✅ **Vistas** y sus columnas
- ✅ **Procedimientos almacenados** con parámetros
- ✅ **Funciones** (escalares y de tabla)
- ✅ **Tipos de datos** definidos por usuario
- ✅ **Sinónimos**

### 3. Seguridad y Permisos (`03_security_permissions.sql`)

- ✅ **Usuarios** de base de datos
- ✅ **Roles** y membresías
- ✅ **Permisos explícitos**
- ✅ **Esquemas** y propietarios
- ✅ **Certificados** y claves de seguridad

### 4. Rendimiento y Estadísticas (`04_statistics_performance.sql`)

- ✅ **Estadísticas** de tablas y columnas
- ✅ **Fragmentación** de índices
- ✅ **Uso de espacio** detallado
- ✅ **Índices faltantes** (sugerencias)
- ✅ **Índices no utilizados**
- ✅ **Consultas más costosas**
- ✅ **Estadísticas de esperas**

## 📊 Formatos de Salida

### 1. Archivos de Texto (.txt)
- Resultados tabulares con separadores
- Fácil importación a Excel/CSV
- Ideal para análisis programático

### 2. Documentación Markdown (.md)
- Formato legible y profesional
- Tablas formateadas automáticamente
- Compatible con GitHub/GitLab
- Incluye recomendaciones

### 3. Reportes HTML (opcional)
- Visualización web interactiva
- Gráficos y estadísticas visuales
- Navegación por secciones

## 🎯 Casos de Uso

### Para DBAs:
- **Auditoría completa** de base de datos
- **Documentación** para compliance
- **Análisis de seguridad** y permisos
- **Identificación** de problemas de rendimiento

### Para Desarrolladores:
- **Referencia rápida** de estructura
- **Documentación** de APIs (procedimientos/funciones)
- **Análisis** de dependencias
- **Optimización** de consultas

### Para Arquitectos:
- **Documentación** de arquitectura de datos
- **Análisis** de relaciones y dependencias
- **Planificación** de migraciones
- **Evaluación** de complejidad

## ⚡ Optimizaciones y Recomendaciones

### Ejecución Rápida:
```sql
-- Solo información crítica (5-10 minutos)
SELECT 'QUICK_ANALYSIS' as mode;
:r 01_complete_database_dictionary.sql
```

### Análisis Completo:
```sql
-- Análisis exhaustivo (15-30 minutos)
SELECT 'FULL_ANALYSIS' as mode;
:r run_complete_dictionary.sql
```

### Análisis de Rendimiento:
```sql
-- Solo estadísticas de rendimiento (2-5 minutos)
SELECT 'PERFORMANCE_ONLY' as mode;
:r 04_statistics_performance.sql
```

## 🔧 Personalización

### Filtros por Esquema:
```sql
-- Modificar en scripts para filtrar esquemas específicos
WHERE SCHEMA_NAME(t.schema_id) IN ('dbo', 'app', 'reporting')
```

### Límites de Resultados:
```sql
-- Agregar TOP N para limitar resultados
SELECT TOP 100 * FROM ...
```

### Formato de Salida:
```bash
# CSV format
sqlcmd ... -s "," -o output.csv

# Tab-delimited
sqlcmd ... -s "\t" -o output.tsv

# Fixed width
sqlcmd ... -o output.txt
```

## 📈 Métricas de Éxito

### Completitud:
- ✅ **100%** de tablas documentadas
- ✅ **100%** de objetos programables catalogados
- ✅ **100%** de permisos mapeados

### Calidad:
- ✅ **Descripciones** completas cuando disponibles
- ✅ **Relaciones** correctamente identificadas
- ✅ **Estadísticas** actualizadas

### Utilidad:
- ✅ **Formato** legible y profesional
- ✅ **Navegación** fácil por secciones
- ✅ **Recomendaciones** accionables

## 🚨 Consideraciones Importantes

### Rendimiento:
- Los scripts pueden tardar **15-30 minutos** en bases de datos grandes
- Ejecutar preferiblemente en **horarios de baja actividad**
- Considerar **límites de tiempo** en conexiones

### Permisos:
- Requiere permisos de **lectura** en vistas del sistema
- Algunos análisis requieren permisos **VIEW SERVER STATE**
- Verificar acceso antes de ejecutar

### Espacio:
- Los reportes pueden generar archivos de **varios MB**
- Asegurar espacio suficiente en disco
- Considerar **compresión** para archivos grandes

## 📞 Soporte

Para problemas o mejoras:
1. Verificar permisos de base de datos
2. Revisar logs de errores en archivos de salida
3. Ajustar timeouts si es necesario
4. Contactar al equipo de DBA para asistencia

---

**Generado por:** Sistema de Documentación Automática  
**Versión:** 1.0  
**Última actualización:** 2025-01-10
