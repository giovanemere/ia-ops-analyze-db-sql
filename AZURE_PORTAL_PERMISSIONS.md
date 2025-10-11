# 🔐 Otorgar Permisos desde Azure Portal

## 🎯 Objetivo
Otorgar permisos VIEW DEFINITION y db_datawriter al usuario `u_yairpanqueva` para permitir exports BACPAC.

## 📋 Pasos en Azure Portal

### 1. Acceder al SQL Server
1. Ve a **Azure Portal** (portal.azure.com)
2. Busca **"persqlmotorpromocprd"**
3. Selecciona el **SQL server** (no la base de datos)

### 2. Acceder al Query Editor
1. En el SQL server, ve a **"Databases"**
2. Selecciona **"persqldbmotorpromocprd"**
3. En el menú izquierdo, busca **"Query editor (preview)"**
4. Haz clic en **"Query editor (preview)"**

### 3. Autenticarse
1. Selecciona **"SQL server authentication"**
2. **Login:** `adminbpm`
3. **Password:** [Contraseña del administrador]
4. Clic en **"OK"**

### 4. Ejecutar Script de Permisos
Copia y pega este script en el Query Editor:

```sql
-- Otorgar permisos necesarios para BACPAC export
USE [persqldbmotorpromocprd];

-- Otorgar VIEW DEFINITION (crítico para export)
GRANT VIEW DEFINITION TO [u_yairpanqueva];

-- Agregar a rol db_datawriter (recomendado para export completo)
ALTER ROLE db_datawriter ADD MEMBER [u_yairpanqueva];

-- Verificar permisos otorgados
SELECT 
    'VERIFICATION' as Status,
    'VIEW DEFINITION' as Permission,
    CASE WHEN HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION', 'u_yairpanqueva') = 1 
         THEN 'GRANTED' ELSE 'NOT GRANTED' END as Result
UNION ALL
SELECT 
    'VERIFICATION',
    'db_datawriter',
    CASE WHEN IS_ROLEMEMBER('db_datawriter', 'u_yairpanqueva') = 1 
         THEN 'GRANTED' ELSE 'NOT GRANTED' END;

-- Mostrar todos los permisos del usuario
SELECT 
    'USER_PERMISSIONS' as Category,
    p.permission_name,
    p.state_desc,
    p.class_desc
FROM sys.database_permissions p
JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id
WHERE pr.name = 'u_yairpanqueva';
```

### 5. Ejecutar y Verificar
1. Clic en **"Run"**
2. Verificar que aparezcan mensajes de éxito
3. Confirmar que la verificación muestre **"GRANTED"**

## 🔄 Alternativa: Usar Azure CLI

Si prefieres usar Azure CLI desde tu terminal:

```bash
# Ejecutar script SQL directamente
az sql db execute \
    --server persqlmotorpromocprd \
    --database persqldbmotorpromocprd \
    --resource-group PERRSGRPYPRMTCLLYP \
    --admin-user adminbpm \
    --admin-password "[PASSWORD_ADMINBPM]" \
    --query "
    GRANT VIEW DEFINITION TO [u_yairpanqueva];
    ALTER ROLE db_datawriter ADD MEMBER [u_yairpanqueva];
    SELECT 'Permisos otorgados exitosamente' as Result;
    "
```

## ✅ Verificación Post-Configuración

Después de otorgar permisos, ejecuta esto para verificar:

```bash
cd /home/giovanemere/periferia/primax/sql-analysis-project

# Verificar permisos
/opt/mssql-tools/bin/sqlcmd -S persqlmotorpromocprd.database.windows.net \
    -d persqldbmotorpromocprd -U u_yairpanqueva -P 0x2E0403602967FDD263E5 \
    -Q "SELECT 
        'VIEW_DEFINITION' as Permission,
        CASE WHEN HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') = 1 
             THEN 'YES' ELSE 'NO' END as HasPermission
        UNION ALL
        SELECT 'db_datawriter', 
               CASE WHEN IS_ROLEMEMBER('db_datawriter') = 1 THEN 'YES' ELSE 'NO' END"
```

## 🚀 Reintentar Backup

Una vez otorgados los permisos:

```bash
# Reintentar backup
./scripts/tasks/task_2_1_backup_complete.sh
```

## 🚨 Troubleshooting

### Si no tienes la contraseña de adminbpm:
1. En Azure Portal, ve al SQL Server
2. Selecciona **"Reset password"**
3. Establece nueva contraseña
4. Usa la nueva contraseña en Query Editor

### Si Query Editor no funciona:
1. Usar Azure Cloud Shell
2. Instalar Azure Data Studio
3. Conectar desde SQL Server Management Studio (SSMS)

---

**Nota:** Estos permisos son necesarios para que el usuario pueda realizar exports BACPAC completos de la base de datos.
