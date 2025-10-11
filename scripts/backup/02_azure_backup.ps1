# =====================================================
# BACKUP DE SQL AZURE DATABASE USANDO AZURE CLI
# Exporta BACPAC a Azure Storage
# =====================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFileName = "",
    
    [Parameter(Mandatory=$true)]
    [string]$AdminLogin,
    
    [Parameter(Mandatory=$true)]
    [string]$AdminPassword
)

# Configuración
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
if ($BackupFileName -eq "") {
    $BackupFileName = "$DatabaseName`_backup_$Timestamp.bacpac"
}

$StorageUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BackupFileName"

Write-Host "🚀 INICIANDO BACKUP DE SQL AZURE DATABASE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Servidor: $ServerName" -ForegroundColor Yellow
Write-Host "Base de Datos: $DatabaseName" -ForegroundColor Yellow
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Yellow
Write-Host "Archivo de Backup: $BackupFileName" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

try {
    # Verificar que Azure CLI esté instalado
    Write-Host "🔍 Verificando Azure CLI..." -ForegroundColor White
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI no está instalado. Instale desde: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    }
    Write-Host "✅ Azure CLI verificado" -ForegroundColor Green

    # Login a Azure (si no está logueado)
    Write-Host "🔐 Verificando autenticación de Azure..." -ForegroundColor White
    $account = az account show 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  No está autenticado. Ejecutando az login..." -ForegroundColor Yellow
        az login
        if ($LASTEXITCODE -ne 0) {
            throw "Error en autenticación de Azure"
        }
    }
    Write-Host "✅ Autenticación verificada: $($account.user.name)" -ForegroundColor Green

    # Verificar que el storage account existe
    Write-Host "🗄️  Verificando Storage Account..." -ForegroundColor White
    $storageAccount = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Storage Account '$StorageAccountName' no encontrado en el grupo de recursos '$ResourceGroupName'"
    }
    Write-Host "✅ Storage Account verificado" -ForegroundColor Green

    # Obtener la clave del storage account
    Write-Host "🔑 Obteniendo clave del Storage Account..." -ForegroundColor White
    $storageKey = az storage account keys list --account-name $StorageAccountName --resource-group $ResourceGroupName --query "[0].value" --output tsv
    if ($LASTEXITCODE -ne 0) {
        throw "Error obteniendo la clave del Storage Account"
    }
    Write-Host "✅ Clave obtenida exitosamente" -ForegroundColor Green

    # Crear el contenedor si no existe
    Write-Host "📦 Verificando/creando contenedor..." -ForegroundColor White
    az storage container create --name $ContainerName --account-name $StorageAccountName --account-key $storageKey --public-access off 2>$null
    Write-Host "✅ Contenedor verificado/creado" -ForegroundColor Green

    # Ejecutar el export de la base de datos
    Write-Host "💾 Iniciando export de la base de datos..." -ForegroundColor White
    Write-Host "   Esto puede tomar varios minutos dependiendo del tamaño de la BD..." -ForegroundColor Gray
    
    $exportResult = az sql db export `
        --resource-group $ResourceGroupName `
        --server $ServerName `
        --name $DatabaseName `
        --storage-key $storageKey `
        --storage-key-type StorageAccessKey `
        --storage-uri $StorageUri `
        --admin-user $AdminLogin `
        --admin-password $AdminPassword `
        --output json

    if ($LASTEXITCODE -ne 0) {
        throw "Error durante el export de la base de datos"
    }

    $export = $exportResult | ConvertFrom-Json
    Write-Host "✅ Export iniciado exitosamente" -ForegroundColor Green
    Write-Host "   Operation ID: $($export.name)" -ForegroundColor Gray

    # Monitorear el progreso del export
    Write-Host "⏳ Monitoreando progreso del export..." -ForegroundColor White
    
    do {
        Start-Sleep -Seconds 30
        $status = az sql db export-status show --operation-id $export.name --resource-group $ResourceGroupName --server $ServerName --output json | ConvertFrom-Json
        
        Write-Host "   Estado: $($status.status) - $($status.statusMessage)" -ForegroundColor Gray
        
        if ($status.status -eq "Failed") {
            throw "Export falló: $($status.errorMessage)"
        }
        
    } while ($status.status -eq "InProgress" -or $status.status -eq "Running")

    if ($status.status -eq "Succeeded") {
        Write-Host "🎉 BACKUP COMPLETADO EXITOSAMENTE" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host "Archivo: $BackupFileName" -ForegroundColor Yellow
        Write-Host "Ubicación: $StorageUri" -ForegroundColor Yellow
        Write-Host "Tamaño: Verificar en Azure Portal" -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Green

        # Verificar que el archivo existe en el storage
        Write-Host "🔍 Verificando archivo de backup..." -ForegroundColor White
        $blobInfo = az storage blob show --container-name $ContainerName --name $BackupFileName --account-name $StorageAccountName --account-key $storageKey --output json | ConvertFrom-Json
        
        if ($blobInfo) {
            $sizeGB = [math]::Round($blobInfo.properties.contentLength / 1GB, 2)
            Write-Host "✅ Archivo verificado - Tamaño: $sizeGB GB" -ForegroundColor Green
        }

    } else {
        throw "Export terminó con estado: $($status.status)"
    }

} catch {
    Write-Host "❌ ERROR DURANTE EL BACKUP" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 INFORMACIÓN DEL BACKUP:" -ForegroundColor Cyan
Write-Host "- Archivo: $BackupFileName" -ForegroundColor White
Write-Host "- URI: $StorageUri" -ForegroundColor White
Write-Host "- Fecha: $(Get-Date)" -ForegroundColor White
Write-Host ""
Write-Host "💡 PRÓXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "1. Verificar el archivo en Azure Portal" -ForegroundColor White
Write-Host "2. Documentar la ubicación del backup" -ForegroundColor White
Write-Host "3. Probar el restore en ambiente de prueba" -ForegroundColor White

# Ejemplo de uso:
Write-Host ""
Write-Host "💡 EJEMPLO DE USO:" -ForegroundColor Cyan
Write-Host ".\02_azure_backup.ps1 -ResourceGroupName 'myRG' -ServerName 'myserver' -DatabaseName 'mydb' -StorageAccountName 'mystorage' -ContainerName 'backups' -AdminLogin 'admin' -AdminPassword 'password'" -ForegroundColor Gray
