#!/bin/bash

# Script de configuración inicial para Warp Terminal Docker
# Descarga el archivo .deb necesario automáticamente

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Información del archivo
DEB_FILE="warp-terminal.deb"
DOWNLOAD_URL="https://app.warp.dev/get_warp?package=deb"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    echo
    log "🚀 Configuración inicial de Warp Terminal Docker"
    echo
    
    # Verificar si el archivo ya existe
    if [ -f "$SCRIPT_DIR/$DEB_FILE" ]; then
        success "Archivo $DEB_FILE ya existe"
        echo
        log "¡Todo listo! Ejecuta: ./warp.sh"
        exit 0
    fi
    
    log "Descargando Warp Terminal..."
    log "URL: $DOWNLOAD_URL"
    
    # Verificar wget
    if ! command -v wget &> /dev/null; then
        error "wget no está instalado"
        log "Instalando wget..."
        sudo apt update && sudo apt install -y wget
    fi
    
    # Descargar archivo
    if wget -O "$SCRIPT_DIR/$DEB_FILE" "$DOWNLOAD_URL"; then
        success "Warp Terminal descargado exitosamente"
        
        # Verificar integridad del archivo
        if [ -f "$SCRIPT_DIR/$DEB_FILE" ] && [ -s "$SCRIPT_DIR/$DEB_FILE" ]; then
            local file_size=$(stat -c%s "$SCRIPT_DIR/$DEB_FILE")
            success "Archivo válido ($(numfmt --to=iec $file_size))"
        else
            error "El archivo descargado está corrupto"
            rm -f "$SCRIPT_DIR/$DEB_FILE"
            exit 1
        fi
    else
        error "Error al descargar Warp Terminal"
        exit 1
    fi
    
    echo
    success "✅ Configuración completada!"
    echo
    log "Próximos pasos:"
    log "1. Ejecutar: ./warp.sh"
    log "   - O para más control: ./build.sh && ./run.sh"
    echo
    log "Para ayuda detallada, consulta README.md"
    echo
}

main "$@"
