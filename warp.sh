#!/bin/bash

# Warp Terminal Docker - Professional Portable Edition
# Universal launcher with automatic configuration
# Compatible with any Linux system with Docker

set -e

# Global Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly IMAGE_NAME="warp-terminal"
readonly IMAGE_TAG="latest"
readonly CONTAINER_NAME="warp-terminal"
readonly PROJECT_VERSION="2.0.0"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[WARP-AUTO]${NC} $(date '+%H:%M:%S') - $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') - $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%H:%M:%S') - $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%H:%M:%S') - $1"
}

# Función para mostrar ayuda rápida
show_help() {
    cat << EOF
🚀 Warp Terminal - Automatización Docker

USO:
  $0              # Ejecutar Warp Terminal automáticamente
  $0 build        # Construir imagen primero, luego ejecutar
  $0 rebuild      # Reconstruir imagen forzadamente, luego ejecutar
  $0 clean        # Limpiar contenedores y ejecutar
  $0 shell        # Ejecutar shell bash en lugar de Warp Terminal
  $0 --help       # Mostrar ayuda completa

CARACTERÍSTICAS:
✓ Auto-configuración de X11
✓ Manejo de permisos automático
✓ Limpieza inteligente de contenedores
✓ Verificaciones de integridad
✓ Inicio en un solo comando

EOF
}

# Auto-configurar X11 de forma segura
auto_setup_x11() {
    log "Configurando X11 automáticamente..."
    
    # Configurar DISPLAY si no está establecido
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=:0
        log "DISPLAY configurado a :0"
    fi
    
    # Generar .Xauthority si no existe
    if [ ! -f "$HOME/.Xauthority" ]; then
        touch "$HOME/.Xauthority"
        xauth generate $DISPLAY . trusted 2>/dev/null || true
        log "Archivo .Xauthority creado"
    fi
    
    # Permitir conexiones locales temporalmente
    xhost +local: &>/dev/null || warning "No se pudo configurar xhost (normal en algunos sistemas)"
    
    success "X11 configurado correctamente"
}

# Verificar y construir imagen si es necesario
check_and_build_image() {
    local force_build=$1
    
    if [ "$force_build" = "true" ] || ! docker image inspect "$IMAGE_NAME:$IMAGE_TAG" &>/dev/null; then
        log "Construyendo imagen Docker..."
        
        if [ ! -f "$SCRIPT_DIR/build.sh" ]; then
            error "Script build.sh no encontrado"
            exit 1
        fi
        
        # Ejecutar construcción
        if [ "$force_build" = "true" ]; then
            bash "$SCRIPT_DIR/build.sh" --force --clean
        else
            bash "$SCRIPT_DIR/build.sh" --clean
        fi
        
        success "Imagen construida exitosamente"
    else
        log "Imagen $IMAGE_NAME:$IMAGE_TAG ya existe"
    fi
}

# Limpiar contenedores anteriores
cleanup_containers() {
    log "Limpiando contenedores anteriores..."
    
    # Limpiar contenedor específico
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        docker rm -f "$CONTAINER_NAME" &>/dev/null || true
        log "Contenedor $CONTAINER_NAME eliminado"
    fi
    
    # Limpiar contenedores warp-terminal antiguos
    local old_containers=$(docker ps -aq -f name="warp-terminal" 2>/dev/null || true)
    if [ -n "$old_containers" ]; then
        echo "$old_containers" | xargs docker rm -f &>/dev/null || true
        log "Contenedores warp-terminal antiguos eliminados"
    fi
}

# Ejecutar Warp Terminal con configuración optimizada
run_warp_terminal() {
    local command="${1:-}"
    
    log "Iniciando Warp Terminal en Docker..."
    
    # Preparar comando base
    local docker_cmd="docker run --rm -it"
    
    # Nombre del contenedor
    docker_cmd="$docker_cmd --name $CONTAINER_NAME"
    
    # Configuración de red
    docker_cmd="$docker_cmd --network host"
    
    # Capacidades necesarias
    docker_cmd="$docker_cmd --cap-add=SYS_ADMIN"
    
    # Acceso a GPU/DRI si está disponible
    if [ -d "/dev/dri" ]; then
        docker_cmd="$docker_cmd --device=/dev/dri"
    fi
    
    # Variables de entorno (dinámicas para portabilidad)
    local current_user=$(whoami)
    docker_cmd="$docker_cmd -e DISPLAY=$DISPLAY"
    docker_cmd="$docker_cmd -e XAUTHORITY=/tmp/.X11-auth"
    docker_cmd="$docker_cmd -e HOME=/home/$current_user"
    docker_cmd="$docker_cmd -e USER=$current_user"
    
    # Optimizaciones gráficas
    docker_cmd="$docker_cmd -e QT_X11_NO_MITSHM=1"
    docker_cmd="$docker_cmd -e _X11_NO_MITSHM=1"
    docker_cmd="$docker_cmd -e XLIB_SKIP_ARGB_VISUALS=1"
    
    # Montajes esenciales
    docker_cmd="$docker_cmd -v /tmp/.X11-unix:/tmp/.X11-unix:rw"
    docker_cmd="$docker_cmd -v $HOME/.Xauthority:/tmp/.X11-auth:ro"
    docker_cmd="$docker_cmd -v /dev/shm:/dev/shm"
    docker_cmd="$docker_cmd -v /etc/localtime:/etc/localtime:ro"
    
    # Directorio de trabajo (dinámico para portabilidad)
    docker_cmd="$docker_cmd --workdir /home/$current_user"
    
    # Imagen
    docker_cmd="$docker_cmd $IMAGE_NAME:$IMAGE_TAG"
    
    # Comando específico
    if [ -n "$command" ]; then
        docker_cmd="$docker_cmd $command"
    fi
    
    log "Ejecutando: Warp Terminal"
    success "¡Listo! Warp Terminal debería aparecer en unos segundos..."
    
    # Ejecutar comando
    eval "$docker_cmd"
}

# Función de limpieza al salir
cleanup_on_exit() {
    log "Ejecutando limpieza final..."
    
    # Restaurar xhost
    xhost -local: &>/dev/null || true
    
    # Opcional: limpiar contenedores huérfanos
    docker container prune -f &>/dev/null || true
    
    success "Limpieza completada"
}

# Función principal
main() {
    trap cleanup_on_exit EXIT
    
    echo
    log "🚀 Iniciando Warp Terminal Automático"
    echo
    
    case "${1:-run}" in
        "build")
            log "Modo: Construir y ejecutar"
            auto_setup_x11
            check_and_build_image false
            cleanup_containers
            run_warp_terminal
            ;;
        "rebuild")
            log "Modo: Reconstruir forzadamente y ejecutar"
            auto_setup_x11
            check_and_build_image true
            cleanup_containers
            run_warp_terminal
            ;;
        "clean")
            log "Modo: Limpiar y ejecutar"
            auto_setup_x11
            cleanup_containers
            docker system prune -f &>/dev/null || true
            check_and_build_image false
            run_warp_terminal
            ;;
        "shell"|"bash")
            log "Modo: Shell bash"
            auto_setup_x11
            check_and_build_image false
            cleanup_containers
            run_warp_terminal "bash"
            ;;
        "help"|"--help"|"-h")
            show_help
            exit 0
            ;;
        "run"|"")
            log "Modo: Ejecutar directo"
            auto_setup_x11
            check_and_build_image false
            cleanup_containers
            run_warp_terminal
            ;;
        *)
            error "Comando desconocido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Verificación rápida de Docker
if ! command -v docker &>/dev/null; then
    error "Docker no está instalado"
    exit 1
fi

if ! docker info &>/dev/null; then
    error "Docker no está ejecutándose"
    exit 1
fi

# Ejecutar función principal
main "$@"
