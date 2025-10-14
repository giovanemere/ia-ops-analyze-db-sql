# =====================================================
# GENERADOR AUTOMÁTICO DE DICCIONARIO DE DATOS
# Ejecuta todos los scripts y genera reportes
# =====================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./reports/dictionary"
)

# Configuración
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ReportsPath = $OutputPath
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Crear directorio de reportes si no existe
if (!(Test-Path $ReportsPath)) {
    New-Item -ItemType Directory -Path $ReportsPath -Force
    Write-Host "✅ Directorio de reportes creado: $ReportsPath" -ForegroundColor Green
}

Write-Host "🚀 INICIANDO GENERACIÓN DE DICCIONARIO COMPLETO" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Servidor: $ServerName" -ForegroundColor Yellow
Write-Host "Base de Datos: $DatabaseName" -ForegroundColor Yellow
Write-Host "Usuario: $Username" -ForegroundColor Yellow
Write-Host "Ruta de Reportes: $ReportsPath" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

# Función para ejecutar SQL y guardar resultados
function Execute-SQLScript {
    param(
        [string]$ScriptFile,
        [string]$OutputFile,
        [string]$Description
    )
    
    Write-Host "📋 $Description..." -ForegroundColor White
    
    try {
        $FullScriptPath = Join-Path $ScriptPath $ScriptFile
        
        if (!(Test-Path $FullScriptPath)) {
            Write-Host "❌ Error: No se encontró el archivo $ScriptFile" -ForegroundColor Red
            return $false
        }
        
        # Ejecutar script SQL
        sqlcmd -S $ServerName -d $DatabaseName -U $Username -P $Password -i $FullScriptPath -o $OutputFile -s "|" -W
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $Description completado" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Error ejecutando $Description" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Excepción ejecutando $Description`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para generar reporte Markdown
function Generate-MarkdownReport {
    param(
        [string]$OutputFile
    )
    
    Write-Host "📝 Generando documentación Markdown..." -ForegroundColor White
    
    try {
        $MarkdownScript = Join-Path $ScriptPath "05_generate_markdown_documentation.sql"
        
        if (!(Test-Path $MarkdownScript)) {
            Write-Host "❌ Error: No se encontró el script de Markdown" -ForegroundColor Red
            return $false
        }
        
        # Ejecutar script de Markdown
        sqlcmd -S $ServerName -d $DatabaseName -U $Username -P $Password -i $MarkdownScript -o $OutputFile -h -1 -W
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Documentación Markdown generada" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Error generando documentación Markdown" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Excepción generando Markdown: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Ejecutar scripts individuales
$Scripts = @(
    @{
        File = "01_complete_database_dictionary.sql"
        Output = Join-Path $ReportsPath "01_database_structure_$Timestamp.txt"
        Description = "Analizando estructura de base de datos"
    },
    @{
        File = "02_programmable_objects.sql"
        Output = Join-Path $ReportsPath "02_programmable_objects_$Timestamp.txt"
        Description = "Analizando objetos programables"
    },
    @{
        File = "03_security_permissions.sql"
        Output = Join-Path $ReportsPath "03_security_permissions_$Timestamp.txt"
        Description = "Analizando seguridad y permisos"
    },
    @{
        File = "04_statistics_performance.sql"
        Output = Join-Path $ReportsPath "04_performance_stats_$Timestamp.txt"
        Description = "Analizando estadísticas de rendimiento"
    }
)

$SuccessCount = 0
$TotalScripts = $Scripts.Count

foreach ($Script in $Scripts) {
    if (Execute-SQLScript -ScriptFile $Script.File -OutputFile $Script.Output -Description $Script.Description) {
        $SuccessCount++
    }
    Start-Sleep -Seconds 2
}

# Generar reporte completo
Write-Host "📊 Generando reporte completo..." -ForegroundColor White
$CompleteReportPath = Join-Path $ReportsPath "complete_dictionary_$Timestamp.txt"
$CompleteScript = Join-Path $ScriptPath "run_complete_dictionary.sql"

if (Test-Path $CompleteScript) {
    Execute-SQLScript -ScriptFile "run_complete_dictionary.sql" -OutputFile $CompleteReportPath -Description "Generando reporte completo"
}

# Generar documentación Markdown
$MarkdownReportPath = Join-Path $ReportsPath "Database_Dictionary_$Timestamp.md"
Generate-MarkdownReport -OutputFile $MarkdownReportPath

# Resumen final
Write-Host ""
Write-Host "🎯 RESUMEN DE GENERACIÓN" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Scripts ejecutados exitosamente: $SuccessCount de $TotalScripts" -ForegroundColor $(if ($SuccessCount -eq $TotalScripts) { "Green" } else { "Yellow" })
Write-Host "Reportes generados en: $ReportsPath" -ForegroundColor Yellow

# Listar archivos generados
Write-Host ""
Write-Host "📁 ARCHIVOS GENERADOS:" -ForegroundColor White
Get-ChildItem -Path $ReportsPath -Filter "*$Timestamp*" | ForEach-Object {
    $SizeKB = [math]::Round($_.Length / 1KB, 2)
    Write-Host "  📄 $($_.Name) ($SizeKB KB)" -ForegroundColor Gray
}

Write-Host ""
if ($SuccessCount -eq $TotalScripts) {
    Write-Host "🎉 DICCIONARIO COMPLETO GENERADO EXITOSAMENTE" -ForegroundColor Green
} else {
    Write-Host "⚠️  DICCIONARIO GENERADO CON ADVERTENCIAS" -ForegroundColor Yellow
}

Write-Host "================================================" -ForegroundColor Cyan

# Ejemplo de uso
Write-Host ""
Write-Host "💡 EJEMPLO DE USO:" -ForegroundColor Cyan
Write-Host ".\generate_dictionary.ps1 -ServerName 'servidor.database.windows.net' -DatabaseName 'mibd' -Username 'usuario' -Password '0x2E0403602967FDD263E5' -OutputPath './reports/dictionary'" -ForegroundColor Gray
