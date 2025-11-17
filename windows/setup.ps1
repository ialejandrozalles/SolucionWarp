#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script de configuración inicial para Warp Terminal Docker en Windows

.DESCRIPTION
    Descarga e instala Warp Terminal para Windows y prepara el entorno Docker
#>

param(
    [switch]$SkipInstaller
)

# Colores para output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "Cyan",
        [string]$Prefix = ""
    )
    
    $colorMap = @{
        "Green" = "Green"
        "Cyan" = "Cyan"
        "Yellow" = "Yellow"
        "Red" = "Red"
    }
    
    if ($Prefix) {
        Write-Host "[$Prefix] " -ForegroundColor $colorMap[$Color] -NoNewline
    }
    Write-Host $Message
}

function Log {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Cyan" -Prefix "SETUP"
}

function Success {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Green" -Prefix "SUCCESS"
}

function Warning {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Yellow" -Prefix "WARNING"
}

function Error {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Red" -Prefix "ERROR"
}

$Script:SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:INSTALLER_NAME = "warp-terminal-installer.exe"
$Script:DOWNLOAD_URL = "https://app.warp.dev/download?package=exe"

function Test-Prerequisites {
    Write-Host ""
    Log "🔍 Verificando prerrequisitos..."
    
    # Verificar Windows 10/11
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Error "Se requiere Windows 10 o superior"
        exit 1
    }
    
    # Verificar PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Error "Se requiere PowerShell 5.0 o superior"
        exit 1
    }
    
    Success "Sistema operativo compatible: Windows $($osVersion.Major).$($osVersion.Minor)"
    
    # Verificar Docker Desktop
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Success "Docker Desktop detectado"
        
        try {
            docker ps 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Success "Docker Desktop está ejecutándose"
            } else {
                Warning "Docker Desktop está instalado pero no está ejecutándose"
                Log "Por favor inicia Docker Desktop antes de continuar"
            }
        } catch {
            Warning "Docker Desktop está instalado pero no está ejecutándose"
        }
        
        # Verificar WSL2
        $dockerInfo = docker info 2>&1 | Out-String
        if ($dockerInfo -match "WSL") {
            Success "Docker Desktop está usando WSL2"
        } else {
            Warning "Docker Desktop no está usando WSL2"
            Log "Se recomienda configurar WSL2 como backend de Docker Desktop"
        }
    } else {
        Warning "Docker Desktop no está instalado"
        Log "Docker Desktop es necesario para ejecutar Warp Terminal"
        Log "Descárgalo desde: https://www.docker.com/products/docker-desktop"
        
        $response = Read-Host "¿Deseas continuar de todos modos? (s/n)"
        if ($response -notmatch '^[sS]') {
            exit 0
        }
    }
    
    # Verificar WSL2
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        $wslVersion = wsl --status 2>&1 | Out-String
        if ($wslVersion -match "WSL 2") {
            Success "WSL2 está instalado"
        } else {
            Warning "WSL2 no está instalado"
            Log "WSL2 es necesario para Docker Desktop"
            Log "Instalalo con: wsl --install"
        }
    } else {
        Warning "WSL no está disponible"
        Log "WSL2 es necesario para Docker Desktop en Windows"
    }
    
    Write-Host ""
}

function Get-WarpInstaller {
    Write-Host ""
    Log "📥 Descargando Warp Terminal..."
    
    $installerPath = Join-Path $Script:SCRIPT_DIR $Script:INSTALLER_NAME
    
    # Verificar si ya existe
    if (Test-Path $installerPath) {
        $fileSize = (Get-Item $installerPath).Length
        Success "Instalador ya existe ($([math]::Round($fileSize / 1MB, 2)) MB)"
        
        $response = Read-Host "¿Deseas descargarlo nuevamente? (s/n)"
        if ($response -notmatch '^[sS]') {
            return $installerPath
        }
    }
    
    # Descargar
    try {
        Log "Descargando desde: $Script:DOWNLOAD_URL"
        Log "Esto puede tomar varios minutos..."
        
        # Usar WebClient para mostrar progreso
        $webClient = New-Object System.Net.WebClient
        
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action {
            $progress = $EventArgs.ProgressPercentage
            Write-Progress -Activity "Descargando Warp Terminal" -Status "$progress% completado" -PercentComplete $progress
        } | Out-Null
        
        $webClient.DownloadFile($Script:DOWNLOAD_URL, $installerPath)
        
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged -ErrorAction SilentlyContinue
        Write-Progress -Activity "Descargando Warp Terminal" -Completed
        
        $webClient.Dispose()
        
        # Verificar descarga
        if (Test-Path $installerPath) {
            $fileSize = (Get-Item $installerPath).Length
            Success "Descarga completada ($([math]::Round($fileSize / 1MB, 2)) MB)"
            return $installerPath
        } else {
            throw "El archivo no se descargó correctamente"
        }
    } catch {
        Error "Error al descargar: $($_.Exception.Message)"
        
        # Intentar con Invoke-WebRequest como fallback
        try {
            Log "Intentando método alternativo de descarga..."
            Invoke-WebRequest -Uri $Script:DOWNLOAD_URL -OutFile $installerPath -UseBasicParsing
            
            if (Test-Path $installerPath) {
                Success "Descarga completada"
                return $installerPath
            }
        } catch {
            Error "Fallo el método alternativo: $($_.Exception.Message)"
            exit 1
        }
    }
}

function Install-WarpTerminal {
    param([string]$InstallerPath)
    
    Write-Host ""
    Log "🚀 Instalación de Warp Terminal"
    Write-Host ""
    
    Warning "NOTA: Warp Terminal se instalará para uso NATIVO en Windows"
    Warning "El Docker image usará una imagen base de Ubuntu con Warp Terminal"
    Write-Host ""
    
    $response = Read-Host "¿Deseas ejecutar el instalador ahora? (s/n)"
    if ($response -match '^[sS]') {
        Log "Ejecutando instalador..."
        Start-Process -FilePath $InstallerPath -Wait
        Success "Instalador ejecutado"
    } else {
        Log "Puedes ejecutar el instalador manualmente:"
        Log "  $InstallerPath"
    }
}

function Initialize-DockerEnvironment {
    Write-Host ""
    Log "🐳 Preparando entorno Docker..."
    
    # Verificar que build.ps1 existe
    $buildScript = Join-Path $Script:SCRIPT_DIR "build.ps1"
    if (-not (Test-Path $buildScript)) {
        Warning "No se encontró build.ps1"
        Log "Asegúrate de que todos los archivos estén presentes"
        return
    }
    
    # Verificar Dockerfile
    $dockerfile = Join-Path $Script:SCRIPT_DIR "Dockerfile"
    if (-not (Test-Path $dockerfile)) {
        Warning "No se encontró Dockerfile"
        Log "Asegúrate de que todos los archivos estén presentes"
        return
    }
    
    Success "Archivos de Docker encontrados"
    
    $response = Read-Host "¿Deseas construir la imagen Docker ahora? (s/n)"
    if ($response -match '^[sS]') {
        & $buildScript
    } else {
        Log "Puedes construir la imagen más tarde con:"
        Log "  .\warp.ps1 build"
    }
}

function Show-NextSteps {
    Write-Host ""
    Write-Host "✅ Configuración completada!" -ForegroundColor Green
    Write-Host ""
    Log "📋 Próximos pasos:"
    Write-Host ""
    Write-Host "  1. Asegúrate de que Docker Desktop esté ejecutándose"
    Write-Host "  2. Ejecuta: .\warp.ps1"
    Write-Host ""
    Log "Comandos útiles:"
    Write-Host "  .\warp.ps1          - Abre una nueva instancia de Warp Terminal"
    Write-Host "  .\warp.ps1 list     - Lista instancias activas"
    Write-Host "  .\warp.ps1 help     - Muestra ayuda completa"
    Write-Host ""
    Log "Para más información, consulta README.md"
    Write-Host ""
}

# Main
function Invoke-Setup {
    Write-Host ""
    Write-Host "🚀 Configuración inicial de Warp Terminal Docker para Windows" -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    
    Test-Prerequisites
    
    if (-not $SkipInstaller) {
        $installerPath = Get-WarpInstaller
        Install-WarpTerminal -InstallerPath $installerPath
    } else {
        Log "Omitiendo descarga del instalador"
    }
    
    Initialize-DockerEnvironment
    Show-NextSteps
}

Invoke-Setup
