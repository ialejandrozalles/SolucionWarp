#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Warp Terminal Docker Launcher - Multi-Instance Edition for Windows

.DESCRIPTION
    Script de PowerShell para ejecutar Warp Terminal en Docker Desktop con WSL2.
    Soporta múltiples instancias simultáneas, gestión de contenedores, y configuración automática.

.PARAMETER Command
    Comando a ejecutar (new, build, rebuild, shell, list, kill, kill-all, logs, clean, cleanup-all, help)

.PARAMETER Id
    ID o nombre de la instancia para comandos kill o logs

.EXAMPLE
    .\warp.ps1
    Abre una nueva instancia de Warp Terminal

.EXAMPLE
    .\warp.ps1 list
    Lista todas las instancias activas

.EXAMPLE
    .\warp.ps1 kill warp-terminal-123
    Cierra una instancia específica
#>

param(
    [Parameter(Position = 0)]
    [string]$Command = "new",
    
    [Parameter(Position = 1)]
    [string]$Id = ""
)

# Configuración
$Script:VERSION = "2.1.0-Windows"
$Script:IMAGE_NAME = "warp-terminal"
$Script:IMAGE_TAG = "latest"
$Script:BASE_CONTAINER_NAME = "warp-terminal"
$Script:SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Colores para output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [string]$Prefix = ""
    )
    
    $colors = @{
        "Green"  = "Green"
        "Blue"   = "Cyan"
        "Yellow" = "Yellow"
        "Red"    = "Red"
    }
    
    if ($Prefix) {
        Write-Host "[$Prefix] " -ForegroundColor $colors[$Color] -NoNewline
    }
    Write-Host $Message
}

function Log {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Blue" -Prefix "INFO"
}

function Success {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Green" -Prefix "SUCCESS"
}

function Warning {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Yellow" -Prefix "WARNING"
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Color "Red" -Prefix "ERROR"
}

# Verificar Docker Desktop
function Test-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-ErrorMessage "Docker no está instalado o no está en el PATH"
        Log "Por favor instala Docker Desktop para Windows desde: https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    try {
        $null = docker ps 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw
        }
    } catch {
        Write-ErrorMessage "Docker Desktop no está ejecutándose"
        Log "Por favor inicia Docker Desktop e intenta nuevamente"
        exit 1
    }
    
    # Verificar WSL2
    $dockerInfo = docker info 2>&1 | Out-String
    if ($dockerInfo -notmatch "WSL") {
        Warning "Docker Desktop no está usando WSL2 como backend"
        Warning "Se recomienda usar WSL2 para mejor rendimiento"
    }
}

# Generar nombre único para el contenedor
function Get-UniqueContainerName {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $random = Get-Random -Minimum 1000 -Maximum 9999
    return "$Script:BASE_CONTAINER_NAME-$timestamp-$random"
}

# Verificar si la imagen existe
function Test-ImageExists {
    $images = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
    return $images -contains "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
}

# Construir imagen si no existe
function Build-ImageIfNeeded {
    param([bool]$Force = $false)
    
    if ($Force -or -not (Test-ImageExists)) {
        if ($Force) {
            Log "Reconstruyendo imagen..."
        } else {
            Log "Imagen no encontrada. Construyendo..."
        }
        
        $buildScript = Join-Path $Script:SCRIPT_DIR "build.ps1"
        if (Test-Path $buildScript) {
            & $buildScript
            if ($LASTEXITCODE -ne 0) {
                Write-ErrorMessage "Error al construir la imagen"
                exit 1
            }
        } else {
            Write-ErrorMessage "No se encontró build.ps1"
            exit 1
        }
    }
}

# Configurar WSLg / X11
function Initialize-Display {
    # WSLg en Windows 11 maneja automáticamente el display
    # Para Windows 10, se necesitaría VcXsrv o similar
    
    $env:WSL_DISPLAY = ":0"
    
    # Verificar si estamos en WSL
    if ($env:WSL_DISTRO_NAME) {
        Log "Detectado WSL: $env:WSL_DISTRO_NAME"
        $env:DISPLAY = $env:WSL_DISPLAY
    }
}

# Ejecutar nueva instancia
function Start-NewInstance {
    Test-Docker
    Build-ImageIfNeeded
    Initialize-Display
    
    $containerName = Get-UniqueContainerName
    
    Log "Iniciando nueva instancia: $containerName"
    
    $dockerArgs = @(
        "run"
        "--rm"
        "-it"
        "--name"
        $containerName
        "--network"
        "host"
        "--cap-add=SYS_ADMIN"
        "-e"
        "DISPLAY=${env:WSL_DISPLAY}"
        "-e"
        "WAYLAND_DISPLAY=wayland-0"
        "-e"
        "XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir"
        "-e"
        "PULSE_SERVER=/mnt/wslg/PulseServer"
        "-e"
        "WARP_INSTANCE_NAME=$containerName"
        "-v"
        "/tmp/.X11-unix:/tmp/.X11-unix"
        "-v"
        "/mnt/wslg:/mnt/wslg"
        "-v"
        "/run/user:/run/user"
    )

    # Sesiones persistentes controladas por variables de entorno (compatibles con Linux)
    $sessionName = $env:WARP_SESSION_NAME
    $resetSession = $env:WARP_SESSION_RESET
    $hostHome = $env:HOME
    $currentUser = $env:USER

    if (-not [string]::IsNullOrWhiteSpace($sessionName)) {
        $sessionsRoot = Join-Path $hostHome ".warp-multi/sessions"
        $sessionPath = Join-Path $sessionsRoot $sessionName

        if ($resetSession -and (Test-Path $sessionPath)) {
            Log "Reiniciando sesión persistente '$sessionName' (borrando datos previos)..."
            Remove-Item -Recurse -Force $sessionPath
        }

        if (-not (Test-Path $sessionPath)) {
            New-Item -ItemType Directory -Path $sessionPath -Force | Out-Null
        }

        Log "Usando sesión persistente '$sessionName' en $sessionPath"
        $dockerArgs += @(
            "-v"
            "${sessionPath}:/home/$currentUser"
        )
    } else {
        Log "Sesión efímera (sin persistencia en disco host)"
    }

    $dockerArgs += "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    
    & docker $dockerArgs
}

# Listar instancias activas
function Get-ActiveInstances {
    Test-Docker
    
    $containers = docker ps --filter "name=$Script:BASE_CONTAINER_NAME-" --format "table {{.Names}}\t{{.Status}}\t{{.ID}}" 2>$null
    
    if ([string]::IsNullOrWhiteSpace($containers) -or $containers -match "^NAMES") {
        Log "No hay instancias activas"
    } else {
        Write-Host ""
        Write-Host "Instancias activas de Warp Terminal:" -ForegroundColor Cyan
        Write-Host $containers
        Write-Host ""
    }
}

# Detener todas las instancias
function Stop-AllInstances {
    Test-Docker
    
    $containers = docker ps -q --filter "name=$Script:BASE_CONTAINER_NAME-" 2>$null
    
    if ([string]::IsNullOrWhiteSpace($containers)) {
        Log "No hay instancias activas para detener"
        return
    }
    
    Log "Deteniendo todas las instancias..."
    
    foreach ($container in $containers) {
        docker stop $container 2>$null | Out-Null
        docker rm -f $container 2>$null | Out-Null
    }
    
    Success "Todas las instancias han sido detenidas"
}

# Detener instancia específica
function Stop-Instance {
    param([string]$InstanceId)
    
    if ([string]::IsNullOrWhiteSpace($InstanceId)) {
        Write-ErrorMessage "Debes especificar el ID o nombre de la instancia"
        Log "Uso: .\warp.ps1 kill <instance-id>"
        exit 1
    }
    
    Test-Docker
    
    # Verificar que el contenedor existe y es de warp-terminal
    $container = docker ps -q --filter "name=$InstanceId" 2>$null
    
    if ([string]::IsNullOrWhiteSpace($container)) {
        Write-ErrorMessage "No se encontró la instancia: $InstanceId"
        exit 1
    }
    
    Log "Deteniendo instancia: $InstanceId"
    docker stop $container 2>$null | Out-Null
    docker rm -f $container 2>$null | Out-Null
    Success "Instancia detenida: $InstanceId"
}

# Ver logs de una instancia
function Show-InstanceLogs {
    param([string]$InstanceId)
    
    if ([string]::IsNullOrWhiteSpace($InstanceId)) {
        Write-ErrorMessage "Debes especificar el ID o nombre de la instancia"
        Log "Uso: .\warp.ps1 logs <instance-id>"
        exit 1
    }
    
    Test-Docker
    docker logs -f $InstanceId
}

# Limpiar contenedores detenidos
function Clear-StoppedContainers {
    Test-Docker
    
    Log "Limpiando contenedores detenidos..."
    
    $stoppedContainers = docker ps -aq --filter "name=$Script:BASE_CONTAINER_NAME-" --filter "status=exited" 2>$null
    
    if ([string]::IsNullOrWhiteSpace($stoppedContainers)) {
        Log "No hay contenedores detenidos para limpiar"
    } else {
        docker rm $stoppedContainers 2>$null | Out-Null
        Success "Contenedores detenidos eliminados"
    }
}

# Limpiar todo
function Clear-All {
    Clear-StoppedContainers
    
    Log "Limpiando recursos de Docker..."
    docker system prune -f 2>$null | Out-Null
    Success "Limpieza completa finalizada"
}

# Abrir shell en nueva instancia
function Start-ShellInstance {
    Test-Docker
    Build-ImageIfNeeded
    
    $containerName = Get-UniqueContainerName
    
    Log "Abriendo shell en nueva instancia: $containerName"
    
    docker run --rm -it `
        --name $containerName `
        --network host `
        "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}" `
        /bin/bash
}

# Mostrar ayuda
function Show-Help {
    Write-Host @"

Warp Terminal Docker - Multi-Instance Edition v$Script:VERSION (Windows)
========================================================================

Uso: .\warp.ps1 [comando] [argumentos]

COMANDOS PRINCIPALES:

  (sin comando)    Abre una nueva instancia de Warp Terminal
  new             Abre una nueva instancia (alias del comportamiento por defecto)
  
  build           Construye la imagen Docker
  rebuild         Reconstruye la imagen Docker (sin caché)
  
  shell, bash     Abre un shell bash en una nueva instancia
  
GESTIÓN DE INSTANCIAS:

  list, ls        Lista todas las instancias activas
  
  kill-all        Detiene y elimina TODAS las instancias
  killall         (alias de kill-all)
  
  kill <ID>       Detiene y elimina una instancia específica
  stop <ID>       (alias de kill)
  
  logs <ID>       Muestra los logs de una instancia específica
  log <ID>        (alias de logs)

LIMPIEZA:

  clean           Limpia contenedores detenidos
  cleanup-all     Limpieza completa (contenedores + system prune)
  clean-all       (alias de cleanup-all)

AYUDA:

  help            Muestra esta ayuda
  --help, -h      (alias de help)

EJEMPLOS:

  # Abrir una nueva instancia
  .\warp.ps1
  
  # Abrir múltiples instancias (ejecuta en diferentes terminales)
  .\warp.ps1
  Start-Process pwsh -ArgumentList "-NoExit", "-File", ".\warp.ps1"
  
  # Ver instancias activas
  .\warp.ps1 list
  
  # Cerrar todas las instancias
  .\warp.ps1 kill-all
  
  # Cerrar una instancia específica
  .\warp.ps1 kill warp-terminal-20240117-123456-7890
  
  # Ver logs de una instancia
  .\warp.ps1 logs warp-terminal-20240117-123456-7890

REQUISITOS:

  - Windows 10/11
  - Docker Desktop con WSL2
  - WSLg (Windows 11 22H2+) o VcXsrv (Windows 10)

Para más información, consulta README.md

"@
}

# Comando principal
function Invoke-Main {
    param(
        [string]$Cmd,
        [string]$Arg
    )
    
    switch ($Cmd.ToLower()) {
        "" { Start-NewInstance }
        "new" { Start-NewInstance }
        "run" { Start-NewInstance }
        
        "build" { Build-ImageIfNeeded -Force $false }
        "rebuild" { Build-ImageIfNeeded -Force $true }
        
        "shell" { Start-ShellInstance }
        "bash" { Start-ShellInstance }
        
        "list" { Get-ActiveInstances }
        "ls" { Get-ActiveInstances }
        
        "kill-all" { Stop-AllInstances }
        "killall" { Stop-AllInstances }
        
        "kill" { Stop-Instance -InstanceId $Arg }
        "stop" { Stop-Instance -InstanceId $Arg }
        
        "logs" { Show-InstanceLogs -InstanceId $Arg }
        "log" { Show-InstanceLogs -InstanceId $Arg }
        
        "clean" { Clear-StoppedContainers }
        "cleanup-all" { Clear-All }
        "clean-all" { Clear-All }
        
        "help" { Show-Help }
        "--help" { Show-Help }
        "-h" { Show-Help }
        
        default {
            Write-ErrorMessage "Comando desconocido: $Cmd"
            Log "Usa '.\warp.ps1 help' para ver los comandos disponibles"
            exit 1
        }
    }
}

# Ejecutar
Invoke-Main -Cmd $Command -Arg $Id
