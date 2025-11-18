#!/bin/bash

# Warp Terminal Docker - Multi-Instance Edition
# Universal launcher with support for multiple simultaneous instances
# Compatible with any Linux system with Docker

set -e

# Global Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly IMAGE_NAME="warp-terminal"
readonly IMAGE_TAG="latest"
readonly BASE_CONTAINER_NAME="warp-terminal"
readonly PROJECT_VERSION="2.1.0"
readonly SESSIONS_DIR="$HOME/.warp-multi/sessions"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[WARP-MULTI]${NC} $(date '+%H:%M:%S') - $1"
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

info() {
    echo -e "${CYAN}[INFO]${NC} $(date '+%H:%M:%S') - $1"
}

# Función para generar nombre único de contenedor
generate_container_name() {
    local timestamp=$(date +%s)
    local random=$(shuf -i 100-999 -n 1)
    echo "${BASE_CONTAINER_NAME}-${timestamp}-${random}"
}

# Función para mostrar ayuda completa
show_help() {
    cat << EOF
🚀 Warp Terminal Docker - Multi-Instance Edition v${PROJECT_VERSION}

USO BÁSICO:
  $0              # Ejecutar nueva instancia de Warp Terminal
  $0 new          # Crear nueva instancia (mismo que sin argumentos)
  $0 build        # Construir imagen y ejecutar nueva instancia
  $0 rebuild      # Reconstruir imagen forzadamente y ejecutar
  $0 shell        # Ejecutar shell bash en nueva instancia

GESTIÓN DE MÚLTIPLES INSTANCIAS:
  $0 list         # Listar todas las instancias activas
  $0 kill-all     # Cerrar todas las instancias de Warp
  $0 kill <ID>    # Cerrar instancia específica por ID
  $0 logs <ID>    # Ver logs de una instancia específica

MANTENIMIENTO:
  $0 clean        # Limpiar contenedores muertos y ejecutar nueva instancia
  $0 cleanup-all  # Limpiar todo (contenedores, imágenes no usadas)
  $0 --help       # Mostrar esta ayuda

CARACTERÍSTICAS:
✓ Múltiples instancias simultáneas
✓ Auto-configuración de X11
✓ Nombres únicos de contenedor
✓ Gestión inteligente de instancias
✓ Limpieza automática
✓ Verificaciones de integridad

EJEMPLOS:
  $0                    # Abrir primera instancia
  $0 & $0 & $0         # Abrir 3 instancias simultáneas
  $0 list              # Ver todas las instancias
  $0 kill-all          # Cerrar todas

EOF
}

# Auto-configurar X11 de forma segura
auto_setup_x11() {
    log "Configurando X11 para múltiples instancias..."
    
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
    
    success "X11 configurado para múltiples instancias"
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

# Listar instancias activas
list_instances() {
    echo
    info "📋 Instancias de Warp Terminal activas:"
    echo
    
    local containers=$(docker ps --filter "name=${BASE_CONTAINER_NAME}-" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.CreatedAt}}" 2>/dev/null || true)
    
    if [ -z "$containers" ] || [ "$(echo "$containers" | wc -l)" -eq 1 ]; then
        warning "No hay instancias activas de Warp Terminal"
        echo
        info "Usa '$0' para crear una nueva instancia"
        return
    fi
    
    echo "$containers"
    echo
    local count=$(($(echo "$containers" | wc -l) - 1))
    info "Total de instancias: $count"
    echo
    info "Comandos útiles:"
    info "  $0 kill <CONTAINER_ID>  # Cerrar instancia específica"
    info "  $0 logs <CONTAINER_ID>  # Ver logs"
    info "  $0 kill-all            # Cerrar todas las instancias"
}

# Cerrar todas las instancias
kill_all_instances() {
    log "Cerrando todas las instancias de Warp Terminal..."
    
    local containers=$(docker ps -q --filter "name=${BASE_CONTAINER_NAME}-" 2>/dev/null || true)
    
    if [ -z "$containers" ]; then
        warning "No hay instancias activas para cerrar"
        return
    fi
    
    local count=$(echo "$containers" | wc -l)
    echo "$containers" | xargs docker stop &>/dev/null || true
    echo "$containers" | xargs docker rm &>/dev/null || true
    
    success "$count instancia(s) cerrada(s) exitosamente"
}

# Cerrar instancia específica
kill_instance() {
    local container_id="$1"
    
    if [ -z "$container_id" ]; then
        error "Debes especificar el ID del contenedor"
        error "Usa '$0 list' para ver las instancias activas"
        exit 1
    fi
    
    log "Cerrando instancia: $container_id"
    
    if docker ps -q --filter "id=$container_id" --filter "name=${BASE_CONTAINER_NAME}-" | grep -q .; then
        docker stop "$container_id" &>/dev/null || true
        docker rm "$container_id" &>/dev/null || true
        success "Instancia $container_id cerrada exitosamente"
    else
        error "Instancia $container_id no encontrada o no es una instancia de Warp"
        info "Usa '$0 list' para ver las instancias activas"
        exit 1
    fi
}

# Ver logs de una instancia
show_logs() {
    local container_id="$1"
    
    if [ -z "$container_id" ]; then
        error "Debes especificar el ID del contenedor"
        error "Usa '$0 list' para ver las instancias activas"
        exit 1
    fi
    
    log "Mostrando logs de la instancia: $container_id"
    docker logs -f "$container_id" 2>/dev/null || {
        error "No se pudieron obtener los logs de $container_id"
        error "Verifica que la instancia existe con '$0 list'"
        exit 1
    }
}

# Limpiar solo contenedores muertos
cleanup_dead_containers() {
    log "Limpiando contenedores muertos..."
    
    # Eliminar solo contenedores que no están ejecutándose
    local dead_containers=$(docker ps -aq --filter "name=${BASE_CONTAINER_NAME}-" --filter "status=exited" 2>/dev/null || true)
    
    if [ -n "$dead_containers" ]; then
        echo "$dead_containers" | xargs docker rm &>/dev/null || true
        log "Contenedores muertos eliminados"
    else
        log "No hay contenedores muertos para limpiar"
    fi
}

# Limpieza completa del sistema
cleanup_all() {
    log "Realizando limpieza completa del sistema..."
    
    # Cerrar todas las instancias
    kill_all_instances
    
    # Limpiar contenedores muertos
    cleanup_dead_containers
    
    # Limpiar sistema Docker
    docker system prune -f &>/dev/null || true
    
    success "Limpieza completa realizada"
}

# Ejecutar nueva instancia de Warp Terminal
run_warp_terminal() {
    local command="${1:-}"
    local container_name=$(generate_container_name)
    
    log "Iniciando nueva instancia de Warp Terminal..."
    info "Nombre del contenedor: $container_name"
    
    # Preparar comando base
    local docker_cmd="docker run --rm -it"
    
    # Nombre único del contenedor
    docker_cmd="$docker_cmd --name $container_name"
    
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
    
    # Variable para identificar la instancia
    docker_cmd="$docker_cmd -e WARP_INSTANCE_NAME=$container_name"
    
    # Montajes esenciales
    docker_cmd="$docker_cmd -v /tmp/.X11-unix:/tmp/.X11-unix:rw"
    docker_cmd="$docker_cmd -v $HOME/.Xauthority:/tmp/.X11-auth:ro"
    docker_cmd="$docker_cmd -v /dev/shm:/dev/shm"
    docker_cmd="$docker_cmd -v /etc/localtime:/etc/localtime:ro"
    
    # Soporte de sesiones persistentes basadas en variables de entorno
    local session_name="${WARP_SESSION_NAME:-}"
    local reset_session="${WARP_SESSION_RESET:-0}"
    local host_home="$HOME"
    local container_home="/home/$current_user"

    if [ -n "$session_name" ]; then
        local session_path="$SESSIONS_DIR/$session_name"

        if [ "$reset_session" != "0" ] && [ -d "$session_path" ]; then
            log "Reiniciando sesión persistente '$session_name' (borrando datos previos)..."
            rm -rf "$session_path"
        fi

        mkdir -p "$session_path"
        log "Usando sesión persistente '$session_name' en $session_path"

        # Montar el directorio de sesión como HOME dentro del contenedor
        docker_cmd="$docker_cmd -v $session_path:$container_home"
    else
        log "Sesión efímera (sin persistencia en disco host)"
    fi
    
    # Directorio de trabajo (dinámico para portabilidad)
    docker_cmd="$docker_cmd --workdir /home/$current_user"
    
    # Imagen
    docker_cmd="$docker_cmd $IMAGE_NAME:$IMAGE_TAG"
    
    # Comando específico
    if [ -n "$command" ]; then
        docker_cmd="$docker_cmd $command"
    fi
    
    info "Ejecutando nueva instancia de Warp Terminal"
    success "¡Nueva instancia iniciada! Contenedor: $container_name"
    
    # Ejecutar comando
    eval "$docker_cmd"
}

# Función de limpieza al salir (solo limpia contenedores muertos)
cleanup_on_exit() {
    log "Ejecutando limpieza final..."
    
    # Restaurar xhost
    xhost -local: &>/dev/null || true
    
    # Solo limpiar contenedores muertos, no los activos
    cleanup_dead_containers
    
    success "Limpieza completada"
}

# Función principal
main() {
    # Solo configurar trap si no es un comando de gestión
    case "${1:-run}" in
        "list"|"kill-all"|"kill"|"logs"|"help"|"--help"|"-h")
            # No configurar trap para comandos de gestión
            ;;
        *)
            trap cleanup_on_exit EXIT
            ;;
    esac
    
    echo
    log "🚀 Warp Terminal Multi-Instance v${PROJECT_VERSION}"
    echo
    
    case "${1:-run}" in
        "new"|"run"|"")
            log "Modo: Nueva instancia"
            auto_setup_x11
            check_and_build_image false
            cleanup_dead_containers
            run_warp_terminal
            ;;
        "build")
            log "Modo: Construir y ejecutar nueva instancia"
            auto_setup_x11
            check_and_build_image false
            cleanup_dead_containers
            run_warp_terminal
            ;;
        "rebuild")
            log "Modo: Reconstruir forzadamente y ejecutar nueva instancia"
            auto_setup_x11
            check_and_build_image true
            cleanup_dead_containers
            run_warp_terminal
            ;;
        "shell"|"bash")
            log "Modo: Shell bash en nueva instancia"
            auto_setup_x11
            check_and_build_image false
            cleanup_dead_containers
            run_warp_terminal "bash"
            ;;
        "list"|"ls")
            list_instances
            ;;
        "kill-all"|"killall")
            kill_all_instances
            ;;
        "kill"|"stop")
            kill_instance "$2"
            ;;
        "logs"|"log")
            show_logs "$2"
            ;;
        "clean")
            log "Modo: Limpiar contenedores muertos y ejecutar nueva instancia"
            auto_setup_x11
            cleanup_dead_containers
            check_and_build_image false
            run_warp_terminal
            ;;
        "cleanup-all"|"clean-all")
            cleanup_all
            ;;
        "help"|"--help"|"-h")
            show_help
            exit 0
            ;;
        *)
            error "Comando desconocido: $1"
            echo
            info "Comandos disponibles: new, list, kill-all, kill <ID>, logs <ID>, clean, help"
            info "Usa '$0 --help' para ver la ayuda completa"
            exit 1
            ;;
    esac
}

# Verificación rápida de Docker/Podman
if ! command -v docker &> /dev/null; then
    error "Docker no está instalado"
    exit 1
fi

# Detectar si estamos usando Podman
if docker --version 2>&1 | grep -q "podman"; then
    log "Detectado Podman emulando Docker"
    # Crear archivo para silenciar warnings
    sudo mkdir -p /etc/containers 2>/dev/null || true
    sudo touch /etc/containers/nodocker 2>/dev/null || true
fi

if ! docker info &> /dev/null; then
    error "Docker no está ejecutándose"
    exit 1
fi

# Ejecutar función principal
main "$@"
