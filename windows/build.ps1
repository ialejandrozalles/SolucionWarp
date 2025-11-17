#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script de construcción de imagen Docker para Warp Terminal en Windows

.DESCRIPTION
    Construye la imagen Docker con soporte WSLg y configuración automática

.PARAMETER Force
    Forzar reconstrucción sin caché

.PARAMETER Clean
    Limpiar imágenes antiguas después de construir

.PARAMETER Verbose
    Mostrar output detallado de Docker build

.EXAMPLE
    .\build.ps1
    .\build.ps1 -Force
    .\build.ps1 -Clean -Verbose
#>

param(
    [switch]$Force,
    [switch]$Clean,
    [switch]$Verbose
)

# Configuración
$Script:IMAGE_NAME = "warp-terminal"
$Script:IMAGE_TAG = "latest"
$Script:SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:DOCKERFILE = Join-Path $Script:SCRIPT_DIR "Dockerfile"

# Colores
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
    Write-ColorOutput -Message $Message -Color "Cyan" -Prefix "BUILD"
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

# Verificar prerequisitos
function Test-Prerequisites {
    # Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Error "Docker no está instalado"
        Log "Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    try {
        docker ps 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw
        }
    } catch {
        Error "Docker Desktop no está ejecutándose"
        exit 1
    }
    
    # Dockerfile
    if (-not (Test-Path $Script:DOCKERFILE)) {
        Error "No se encontró Dockerfile en: $Script:DOCKERFILE"
        exit 1
    }
    
    # entrypoint.sh
    $entrypoint = Join-Path $Script:SCRIPT_DIR "entrypoint.sh"
    if (-not (Test-Path $entrypoint)) {
        Error "No se encontró entrypoint.sh"
        exit 1
    }
    
    Success "Prerrequisitos verificados"
}

# Construir imagen
function Build-DockerImage {
    Write-Host ""
    Log "🐳 Construyendo imagen Docker: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    Write-Host ""
    
    if ($Force) {
        Warning "Modo forzado: construyendo sin caché"
    }
    
    # Obtener usuario actual (para mapeo UID/GID)
    $currentUser = $env:USERNAME
    $userId = 1000  # Default para WSL
    $groupId = 1000
    
    # Build arguments
    $buildArgs = @(
        "build"
        "--build-arg", "USER_ID=$userId"
        "--build-arg", "GROUP_ID=$groupId"
        "--build-arg", "USERNAME=$currentUser"
        "-t", "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
        "-f", $Script:DOCKERFILE
    )
    
    if ($Force) {
        $buildArgs += "--no-cache"
    }
    
    if ($Verbose) {
        $buildArgs += "--progress=plain"
    }
    
    $buildArgs += $Script:SCRIPT_DIR
    
    Log "Ejecutando: docker $($buildArgs -join ' ')"
    Write-Host ""
    
    & docker $buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Error "Error al construir la imagen"
        exit 1
    }
    
    Write-Host ""
    Success "Imagen construida exitosamente!"
    
    # Mostrar información de la imagen
    $imageInfo = docker images "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}" --format "{{.ID}} {{.Size}}"
    if ($imageInfo) {
        $parts = $imageInfo -split ' '
        Log "Image ID: $($parts[0])"
        Log "Tamaño: $($parts[1])"
    }
}

# Limpiar imágenes antiguas
function Clear-OldImages {
    if (-not $Clean) {
        return
    }
    
    Write-Host ""
    Log "🧹 Limpiando imágenes antiguas..."
    
    # Remover imágenes dangling
    $danglingImages = docker images -f "dangling=true" -q 2>$null
    
    if ($danglingImages) {
        docker rmi $danglingImages 2>$null | Out-Null
        Success "Imágenes antiguas eliminadas"
    } else {
        Log "No hay imágenes antiguas para limpiar"
    }
}

# Mostrar instrucciones
function Show-Instructions {
    Write-Host ""
    Write-Host "✅ ¡Imagen lista para usar!" -ForegroundColor Green
    Write-Host ""
    Log "Para ejecutar Warp Terminal:"
    Write-Host ""
    Write-Host "  .\warp.ps1"
    Write-Host ""
    Log "O manualmente con Docker:"
    Write-Host ""
    Write-Host "  docker run --rm -it ``"
    Write-Host "    --name warp-terminal ``"
    Write-Host "    -e DISPLAY=:0 ``"
    Write-Host "    -v /tmp/.X11-unix:/tmp/.X11-unix ``"
    Write-Host "    -v /mnt/wslg:/mnt/wslg ``"
    Write-Host "    ${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    Write-Host ""
}

# Main
function Invoke-Build {
    Write-Host ""
    Write-Host "🚀 Warp Terminal Docker Build para Windows" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-Prerequisites
    Build-DockerImage
    Clear-OldImages
    Show-Instructions
}

Invoke-Build
