# Script PowerShell para conectar y ejecutar análisis
param(
    [string]$ScriptPath = ""
)

$ServerName = "persqlmotorpromocprd.database.windows.net"
$DatabaseName = "persqldbmotorpromocprd"
$Username = "u_yairpanqueva"
$Password = "0x2E0403602967FDD263E5"

# Crear string de conexión
$ConnectionString = "Server=$ServerName;Database=$DatabaseName;User Id=$Username;Password=$Password;Encrypt=True;TrustServerCertificate=False;"

try {
    # Importar módulo SqlServer si está disponible
    Import-Module SqlServer -ErrorAction SilentlyContinue
    
    if ($ScriptPath -ne "") {
        Write-Host "Ejecutando script: $ScriptPath"
        Invoke-Sqlcmd -ConnectionString $ConnectionString -InputFile $ScriptPath
    } else {
        Write-Host "Conexión establecida exitosamente a $DatabaseName"
        Write-Host "Usar parámetro -ScriptPath para ejecutar un script específico"
    }
} catch {
    Write-Error "Error de conexión: $($_.Exception.Message)"
}

# Ejemplo de uso:
# .\connect.ps1 -ScriptPath ".\scripts\edr\01_table_structure.sql"
