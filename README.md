# 🗄️ SQL Analysis Project - Azure Database Management

Sistema completo de análisis, optimización y gestión para SQL Azure Database (Hyperscale).

## 🎯 Características Principales

- ✅ **Backup y Restore** automatizado con Azure Storage
- ✅ **Optimización completa** de rendimiento con análisis pre/post
- ✅ **Sistema de logging** centralizado con métricas automáticas
- ✅ **Análisis de infraestructura** (CPU, memoria, I/O, sesiones)
- ✅ **Generación de diccionario** de datos completo
- ✅ **Rollback de emergencia** integrado

## 🏗️ Arquitectura

```
sql-analysis-project/
├── scripts/
│   ├── backup/                    # 💾 Backup y restore completo
│   ├── common/                    # 📝 Sistema de logging centralizado
│   ├── dictionary/                # 📚 Generación de diccionario de datos
│   ├── infrastructure/            # 🖥️ Análisis de infraestructura
│   └── optimization/              # ⚡ Optimización completa integrada
├── logs/                          # 📋 Logs centralizados
└── reports/                       # 📊 Reportes generados
```

## 🚀 Inicio Rápido

### 1. Configuración Inicial

```bash
# Clonar repositorio
git clone git@github.com:giovanemere/ia-ops-analyze-db-sql.git
cd ia-ops-analyze-db-sql

# Configurar permisos
chmod +x scripts/**/*.sh
```

### 2. Configurar Azure (Requerido para backups)

```bash
# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"

# Crear storage account (si no existe)
az storage account create \
    --name primaxbackups2024 \
    --resource-group [TU_RESOURCE_GROUP] \
    --location eastus \
    --sku Standard_LRS
```

### 3. Ejecución

#### Análisis Completo (Recomendado)
```bash
# Proceso completo con backup y optimización
./scripts/optimization/run_full_optimization_with_backup.sh
```

#### Por Módulos
```bash
# Solo backup
./scripts/backup/04_backup_azure_cli.sh

# Solo diccionario de datos
./scripts/dictionary/run_dictionary.sh

# Solo análisis de infraestructura
./scripts/infrastructure/run_infrastructure.sh

# Solo optimización
./scripts/optimization/run_optimization.sh
```

## 📊 Base de Datos Objetivo

- **Servidor:** persqlmotorpromocprd.database.windows.net
- **Base de Datos:** persqldbmotorpromocprd
- **Edición:** Hyperscale HS_Gen5_12
- **Tamaño:** ~30 GB (58M registros)
- **Tablas principales:** CuponesDigitales (45M), CuponesFisicoCorreccion (12M)

## 🛠️ Funcionalidades Detalladas

### 💾 Backup y Restore
- **Backup completo** a Azure Storage (BACPAC)
- **Restore automatizado** con validación
- **Rollback de emergencia** en caso de problemas
- **Verificación de integridad** post-operación

### ⚡ Optimización de Rendimiento
- **Análisis de fragmentación** y consultas costosas
- **Creación de índices** optimizados para consultas frecuentes
- **Mantenimiento urgente** (REBUILD/REORGANIZE)
- **Validación post-optimización** con métricas

### 🖥️ Análisis de Infraestructura
- **Monitoreo de CPU y memoria** en tiempo real
- **Análisis de sesiones** activas y bloqueos
- **Estadísticas de I/O** y latencia de almacenamiento
- **Reportes ejecutivos** automatizados

### 📚 Diccionario de Datos
- **Estructura completa** de tablas, columnas e índices
- **Objetos programables** (vistas, procedimientos, funciones)
- **Seguridad y permisos** detallados
- **Documentación Markdown** automática

### 📝 Sistema de Logging
- **Logging centralizado** con niveles (INFO, SUCCESS, WARNING, ERROR)
- **Métricas automáticas** de rendimiento y duración
- **Rotación automática** de logs (7 días activos, 30 días backup)
- **Herramientas de análisis** y búsqueda

## 📈 Métricas y Monitoreo

### Estadísticas de Rendimiento
```bash
# Ver estadísticas de logs
./scripts/common/log_manager.sh stats

# Analizar rendimiento
./scripts/common/log_manager.sh performance 7

# Buscar errores
./scripts/common/log_manager.sh errors 1
```

### Mejoras Esperadas
- **Consultas:** 60-80% más rápidas
- **Fragmentación:** <10% (desde 99%)
- **CPU:** Reducción 30-40%
- **I/O:** Mejora significativa en lecturas lógicas

## 🚨 Consideraciones Importantes

### Tiempos de Ejecución
- **Backup completo:** 60-90 minutos
- **Optimización completa:** 4-6 horas
- **Análisis de infraestructura:** 15 minutos
- **Diccionario de datos:** 10 minutos

### Requisitos de Sistema
- **Azure CLI** instalado y configurado
- **PowerShell Core** (para scripts .ps1)
- **SQL Server Tools** (sqlcmd)
- **Acceso a Azure Storage** para backups

### Seguridad
- **Passwords encriptados** en scripts
- **Conexiones seguras** (TLS/SSL)
- **Logs sin información sensible**
- **Backups encriptados** en Azure Storage

## 🔧 Troubleshooting

### Problemas Comunes

1. **Error de conexión:**
   ```bash
   # Verificar conectividad
   /opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
       -U u_yairpanqueva -P 0x2E0403602967FDD263E5 -Q "SELECT 1"
   ```

2. **Azure CLI no autenticado:**
   ```bash
   az logout
   az login --tenant "d98b231e-79bb-4aff-b916-0157f4cdc5bc"
   ```

3. **Storage Account no encontrado:**
   ```bash
   # Verificar que existe
   az storage account show --name primaxbackups2024 --resource-group [RG]
   ```

## 📞 Soporte

- **Logs:** `/logs/sql_analysis_YYYYMMDD.log`
- **Errores:** `/logs/errors_YYYYMMDD.log`
- **Documentación:** Cada módulo tiene su README específico

## 🏷️ Versiones

- **v2.0.0** - Sistema completo con logging, backup y optimización integrada
- **v1.0.0** - Versión inicial con scripts básicos

## 📄 Licencia

Este proyecto está diseñado específicamente para el entorno de Primax y SQL Azure Database.

---

**Desarrollado para SQL Azure Database (Hyperscale) - Optimizado para producción**
