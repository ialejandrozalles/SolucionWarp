#!/bin/bash

# Warp Terminal Docker Builder - Professional Edition
# Builds portable Docker image with automatic user configuration
# Compatible with any Linux system and user

set -e

# Global Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly IMAGE_NAME="warp-terminal"
readonly IMAGE_TAG="latest"
readonly DOCKERFILE_PATH="$SCRIPT_DIR/Dockerfile"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de logging con colores
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} ${timestamp} - $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message"
            ;;
        *)
            echo "[$level] ${timestamp} - $message"
            ;;
    esac
}

# Función para mostrar ayuda
show_help() {
    cat << EOF
Uso: $0 [OPCIONES]

Construye la imagen Docker de Warp Terminal con soporte X11.

OPCIONES:
    -n, --name NAME     Nombre de la imagen (default: $IMAGE_NAME)
    -t, --tag TAG       Tag de la imagen (default: $IMAGE_TAG)
    -f, --force         Forzar reconstrucción (--no-cache)
    -c, --clean         Limpiar imágenes sin etiquetar después de la construcción
    -v, --verbose       Modo verboso
    -h, --help          Mostrar esta ayuda

EJEMPLOS:
    $0                           # Construcción estándar
    $0 -f                        # Construcción sin caché
    $0 -n mi-warp -t v1.0        # Nombre y tag personalizados
    $0 -c                        # Construcción y limpieza automática

EOF
}

# Función para verificar prerequisitos
check_prerequisites() {
    log "INFO" "Verificando prerequisitos..."
    
    # Verificar Docker/Podman
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker no está instalado"
        exit 1
    fi
    
    # Detectar si estamos usando Podman
    if docker --version 2>&1 | grep -q "podman"; then
        log "INFO" "Detectado Podman emulando Docker"
        # Crear archivo para silenciar warnings
        sudo mkdir -p /etc/containers 2>/dev/null || true
        sudo touch /etc/containers/nodocker 2>/dev/null || true
    fi
    
    # Verificar que Docker esté ejecutándose
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker no está ejecutándose"
        exit 1
    fi
    
    # Verificar Dockerfile
    if [ ! -f "$DOCKERFILE_PATH" ]; then
        log "ERROR" "Dockerfile no encontrado en: $DOCKERFILE_PATH"
        exit 1
    fi
    
    # Verificar archivo .deb (cualquier nombre)
    local deb_files=("$SCRIPT_DIR"/*.deb)
    if [ ! -f "${deb_files[0]}" ]; then
        log "ERROR" "Archivo .deb no encontrado en: $SCRIPT_DIR"
        log "INFO" "Ejecuta primero: ./setup.sh"
        log "INFO" "O descarga manualmente con: wget -O warp-terminal.deb 'https://app.warp.dev/get_warp?package=deb'"
        exit 1
    else
        log "SUCCESS" "Archivo .deb encontrado: $(basename "${deb_files[0]}")"
    fi
    
    # Verificar entrypoint.sh
    if [ ! -f "$SCRIPT_DIR/entrypoint.sh" ]; then
        log "ERROR" "Script entrypoint.sh no encontrado: $SCRIPT_DIR/entrypoint.sh"
        exit 1
    fi
    
    log "SUCCESS" "Todos los prerequisitos verificados"
}

# Función para obtener información del usuario actual
get_user_info() {
    local user_id=$(id -u)
    local group_id=$(id -g)
    local username=$(whoami)
    
    echo "$user_id:$group_id:$username"
}

# Función principal de construcción
build_image() {
    local no_cache=""
    local verbose=""
    
    if [ "$FORCE_BUILD" = "true" ]; then
        no_cache="--no-cache"
        log "INFO" "Construcción forzada activada (sin caché)"
    fi
    
    if [ "$VERBOSE" = "true" ]; then
        verbose="--progress=plain"
        log "INFO" "Modo verboso activado"
    fi
    
    # Obtener información del usuario
    local user_info=$(get_user_info)
    IFS=':' read -r user_id group_id username <<<"$user_info"
    
    log "INFO" "Información del usuario:"
    log "INFO" "  - Usuario: $username"
    log "INFO" "  - UID: $user_id"
    log "INFO" "  - GID: $group_id"
    
    log "INFO" "Iniciando construcción de imagen Docker..."
    log "INFO" "Imagen: $IMAGE_NAME:$IMAGE_TAG"
    log "INFO" "Contexto: $SCRIPT_DIR"
    
    # Comando de construcción
    local build_cmd="docker build $no_cache $verbose --build-arg USER_ID=$user_id --build-arg GROUP_ID=$group_id --build-arg USERNAME=$username -t $IMAGE_NAME:$IMAGE_TAG -f $DOCKERFILE_PATH $SCRIPT_DIR"
    
    log "INFO" "Ejecutando: $build_cmd"
    
    if eval $build_cmd; then
        log "SUCCESS" "Imagen construida exitosamente: $IMAGE_NAME:$IMAGE_TAG"
        
        # Mostrar información de la imagen
        local image_size=$(docker images --format "table {{.Size}}" $IMAGE_NAME:$IMAGE_TAG | tail -n +2)
        local image_id=$(docker images --format "table {{.ID}}" $IMAGE_NAME:$IMAGE_TAG | tail -n +2)
        
        log "INFO" "Información de la imagen:"
        log "INFO" "  - ID: $image_id"
        log "INFO" "  - Tamaño: $image_size"
        
    else
        log "ERROR" "Falló la construcción de la imagen"
        exit 1
    fi
}

# Función para limpiar imágenes huérfanas
clean_dangling_images() {
    log "INFO" "Limpiando imágenes sin etiquetar..."
    
    local dangling_images=$(docker images -f "dangling=true" -q)
    
    if [ -n "$dangling_images" ]; then
        docker rmi $dangling_images
        log "SUCCESS" "Imágenes huérfanas eliminadas"
    else
        log "INFO" "No hay imágenes huérfanas para limpiar"
    fi
}

# Función para mostrar instrucciones de uso
show_usage_instructions() {
    log "SUCCESS" "=== CONSTRUCCIÓN COMPLETADA ==="
    echo
    log "INFO" "Para ejecutar Warp Terminal, usa:"
    echo "  ./run.sh"
    echo
    log "INFO" "O manualmente:"
    echo "  docker run --rm -it \\"
    echo "    --name warp-terminal \\"
    echo "    -e DISPLAY=\$DISPLAY \\"
    echo "    -v /tmp/.X11-unix:/tmp/.X11-unix \\"
    echo "    -v \$HOME/.Xauthority:/tmp/.X11-auth:ro \\"
    echo "    $IMAGE_NAME:$IMAGE_TAG"
    echo
    log "INFO" "Para más opciones, consulta el README.md"
}

# Función principal
main() {
    # Variables por defecto
    FORCE_BUILD=false
    CLEAN=false
    VERBOSE=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_BUILD=true
                shift
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log "INFO" "=== INICIANDO CONSTRUCCIÓN DE WARP TERMINAL DOCKER ==="
    
    # Verificar prerequisitos
    check_prerequisites
    
    # Construir imagen
    build_image
    
    # Limpiar si se solicita
    if [ "$CLEAN" = "true" ]; then
        clean_dangling_images
    fi
    
    # Mostrar instrucciones de uso
    show_usage_instructions
}

# Ejecutar función principal con todos los argumentos
main "$@"
