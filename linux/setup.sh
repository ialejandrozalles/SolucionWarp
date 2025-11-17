#!/bin/bash

# Script de configuración inicial para Warp Terminal Docker
# Ya no requiere descargar el .deb manualmente

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    echo
    log "🚀 Configuración inicial de Warp Terminal Docker"
    echo
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado"
        log "Por favor instala Docker desde: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    success "Docker encontrado: $(docker --version)"
    
    # Verificar que Docker esté ejecutándose
    if ! docker ps &> /dev/null; then
        error "Docker no está ejecutándose"
        log "Por favor inicia el servicio Docker"
        exit 1
    fi
    
    success "Docker está ejecutándose"
    
    # Verificar X11
    if [ -z "$DISPLAY" ]; then
        warning "Variable DISPLAY no está configurada"
        log "Es posible que X11 no esté disponible"
    else
        success "X11 detectado: DISPLAY=$DISPLAY"
    fi
    
    echo
    success "✅ Configuración completada!"
    echo
    log "📋 Próximos pasos:"
    echo
    echo "  1. Construir la imagen Docker:"
    echo "     ./build.sh"
    echo
    echo "  2. Ejecutar Warp Terminal:"
    echo "     ./warp.sh"
    echo
    echo "  O usa el comando todo-en-uno:"
    echo "     ./warp.sh build"
    echo
    log "ℹ️  Nota: El archivo .deb se descarga automáticamente durante el build"
    log "   Ya no es necesario descargarlo manualmente"
    echo
    log "Para más información, consulta README.md"
    echo
}

main "$@"
