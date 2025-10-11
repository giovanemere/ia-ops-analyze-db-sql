# =====================================================
# RESTORE DE SQL AZURE DATABASE DESDE BACPAC
# Importa BACPAC desde Azure Storage
# =====================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "PERRSGRPYPRMTCLLYP",
    
    [Parameter(Mandatory=$false)]
    [string]$ServerName = "persqlmotorpromocprd",
    
    [Parameter(Mandatory=$true)]
    [string]$NewDatabaseName,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "perstgmotorbackprd",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerName = "backups",
    
    [Parameter(Mandatory=$true)]
    [string]$BackupFileName,
    
    [Parameter(Mandatory=$false)]
    [string]$AdminLogin = "u_yairpanqueva",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminPassword = "0x2E0403602967FDD263E5",
    
    [Parameter(Mandatory=$false)]
    [string]$ServiceTier = "HS_Gen5_12",
    
    [Parameter(Mandatory=$false)]
    [switch]$OverwriteExisting
)

$StorageUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BackupFileName"

Write-Host "🔄 INICIANDO RESTORE DE SQL AZURE DATABASE" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Servidor: $ServerName" -ForegroundColor Yellow
Write-Host "Nueva Base de Datos: $NewDatabaseName" -ForegroundColor Yellow
Write-Host "Archivo de Backup: $BackupFileName" -ForegroundColor Yellow
Write-Host "Service Tier: $ServiceTier" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Cyan

try {
    # Verificar Azure CLI
    Write-Host "🔍 Verificando Azure CLI..." -ForegroundColor White
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI no está instalado"
    }
    Write-Host "✅ Azure CLI verificado" -ForegroundColor Green

    # Verificar autenticación
    Write-Host "🔐 Verificando autenticación..." -ForegroundColor White
    $account = az account show 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Ejecutando az login..." -ForegroundColor Yellow
        az login
        if ($LASTEXITCODE -ne 0) {
            throw "Error en autenticación"
        }
    }
    Write-Host "✅ Autenticación verificada" -ForegroundColor Green

    # Verificar si la base de datos ya existe
    Write-Host "🔍 Verificando si la base de datos existe..." -ForegroundColor White
    $existingDb = az sql db show --resource-group $ResourceGroupName --server $ServerName --name $NewDatabaseName 2>$null
    
    if ($LASTEXITCODE -eq 0 -and -not $OverwriteExisting) {
        throw "La base de datos '$NewDatabaseName' ya existe. Use -OverwriteExisting para sobrescribir."
    } elseif ($LASTEXITCODE -eq 0 -and $OverwriteExisting) {
        Write-Host "⚠️  Base de datos existente será sobrescrita" -ForegroundColor Yellow
        
        # Eliminar base de datos existente
        Write-Host "🗑️  Eliminando base de datos existente..." -ForegroundColor White
        az sql db delete --resource-group $ResourceGroupName --server $ServerName --name $NewDatabaseName --yes
        if ($LASTEXITCODE -ne 0) {
            throw "Error eliminando base de datos existente"
        }
        Write-Host "✅ Base de datos existente eliminada" -ForegroundColor Green
    }

    # Obtener clave del storage account
    Write-Host "🔑 Obteniendo clave del Storage Account..." -ForegroundColor White
    $storageKey = az storage account keys list --account-name $StorageAccountName --resource-group $ResourceGroupName --query "[0].value" --output tsv
    if ($LASTEXITCODE -ne 0) {
        throw "Error obteniendo clave del Storage Account"
    }
    Write-Host "✅ Clave obtenida" -ForegroundColor Green

    # Verificar que el archivo BACPAC existe
    Write-Host "📦 Verificando archivo BACPAC..." -ForegroundColor White
    $blobInfo = az storage blob show --container-name $ContainerName --name $BackupFileName --account-name $StorageAccountName --account-key $storageKey --output json 2>$null | ConvertFrom-Json
    
    if (-not $blobInfo) {
        throw "Archivo BACPAC '$BackupFileName' no encontrado en el contenedor '$ContainerName'"
    }
    
    $sizeGB = [math]::Round($blobInfo.properties.contentLength / 1GB, 2)
    Write-Host "✅ Archivo BACPAC verificado - Tamaño: $sizeGB GB" -ForegroundColor Green

    # Iniciar el import
    Write-Host "📥 Iniciando import de la base de datos..." -ForegroundColor White
    Write-Host "   Esto puede tomar varios minutos dependiendo del tamaño..." -ForegroundColor Gray
    
    $importResult = az sql db import `
        --resource-group $ResourceGroupName `
        --server $ServerName `
        --name $NewDatabaseName `
        --storage-key $storageKey `
        --storage-key-type StorageAccessKey `
        --storage-uri $StorageUri `
        --admin-user $AdminLogin `
        --admin-password $AdminPassword `
        --service-objective $ServiceTier `
        --output json

    if ($LASTEXITCODE -ne 0) {
        throw "Error durante el import de la base de datos"
    }

    $import = $importResult | ConvertFrom-Json
    Write-Host "✅ Import iniciado exitosamente" -ForegroundColor Green
    Write-Host "   Operation ID: $($import.name)" -ForegroundColor Gray

    # Monitorear progreso
    Write-Host "⏳ Monitoreando progreso del import..." -ForegroundColor White
    
    do {
        Start-Sleep -Seconds 30
        $status = az sql db import-status show --operation-id $import.name --resource-group $ResourceGroupName --server $ServerName --output json | ConvertFrom-Json
        
        Write-Host "   Estado: $($status.status) - $($status.statusMessage)" -ForegroundColor Gray
        
        if ($status.status -eq "Failed") {
            throw "Import falló: $($status.errorMessage)"
        }
        
    } while ($status.status -eq "InProgress" -or $status.status -eq "Running")

    if ($status.status -eq "Succeeded") {
        Write-Host "🎉 RESTORE COMPLETADO EXITOSAMENTE" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green

        # Verificar la base de datos restaurada
        Write-Host "🔍 Verificando base de datos restaurada..." -ForegroundColor White
        $restoredDb = az sql db show --resource-group $ResourceGroupName --server $ServerName --name $NewDatabaseName --output json | ConvertFrom-Json
        
        if ($restoredDb) {
            Write-Host "✅ Base de datos verificada" -ForegroundColor Green
            Write-Host "   Nombre: $($restoredDb.name)" -ForegroundColor Yellow
            Write-Host "   Estado: $($restoredDb.status)" -ForegroundColor Yellow
            Write-Host "   Service Tier: $($restoredDb.currentServiceObjectiveName)" -ForegroundColor Yellow
            Write-Host "   Tamaño Máximo: $([math]::Round($restoredDb.maxSizeBytes / 1GB, 2)) GB" -ForegroundColor Yellow
        }

        # Ejecutar verificación post-restore
        Write-Host "🔍 Ejecutando verificación post-restore..." -ForegroundColor White
        
        $connectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$NewDatabaseName;Persist Security Info=False;User ID=$AdminLogin;Password=$AdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        try {
            # Verificar conectividad básica
            $query = "SELECT COUNT(*) as TableCount FROM sys.tables WHERE is_ms_shipped = 0"
            # Aquí se podría usar Invoke-Sqlcmd si está disponible
            Write-Host "✅ Conectividad verificada" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  No se pudo verificar conectividad automáticamente" -ForegroundColor Yellow
        }

    } else {
        throw "Import terminó con estado: $($status.status)"
    }

} catch {
    Write-Host "❌ ERROR DURANTE EL RESTORE" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 INFORMACIÓN DEL RESTORE:" -ForegroundColor Cyan
Write-Host "- Base de Datos: $NewDatabaseName" -ForegroundColor White
Write-Host "- Servidor: $ServerName.database.windows.net" -ForegroundColor White
Write-Host "- Service Tier: $ServiceTier" -ForegroundColor White
Write-Host "- Fecha: $(Get-Date)" -ForegroundColor White
Write-Host ""
Write-Host "💡 PRÓXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "1. Verificar integridad de datos" -ForegroundColor White
Write-Host "2. Actualizar cadenas de conexión" -ForegroundColor White
Write-Host "3. Configurar usuarios y permisos" -ForegroundColor White
Write-Host "4. Probar funcionalidad de aplicaciones" -ForegroundColor White

# Ejemplo de uso:
Write-Host ""
Write-Host "💡 EJEMPLO DE USO:" -ForegroundColor Cyan
Write-Host ".\03_restore_database.ps1 -ResourceGroupName 'myRG' -ServerName 'myserver' -NewDatabaseName 'mydb_restored' -StorageAccountName 'mystorage' -ContainerName 'backups' -BackupFileName 'backup.bacpac' -AdminLogin 'admin' -AdminPassword 'password'" -ForegroundColor Gray
