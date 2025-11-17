#!/bin/bash

# Warp Terminal Docker Entrypoint - Windows/WSL2 Edition
# Configura automáticamente el entorno WSLg y lanza aplicaciones
# Compatible con Docker Desktop en Windows 10/11

set -e

# Función de logging
log() {
    echo "[WARP-DOCKER-WSL2] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Función para verificar WSLg
check_wslg() {
    log "Verificando entorno WSLg..."
    
    # Verificar montajes de WSLg
    if [ -d "/mnt/wslg" ]; then
        log "WSLg detectado: /mnt/wslg disponible"
        export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
        export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/mnt/wslg/runtime-dir}
        
        # Verificar PulseAudio
        if [ -e "/mnt/wslg/PulseServer" ]; then
            export PULSE_SERVER=/mnt/wslg/PulseServer
            log "PulseAudio configurado: /mnt/wslg/PulseServer"
        fi
    else
        log "WARNING: /mnt/wslg no está montado"
        log "Asegúrate de ejecutar con: -v /mnt/wslg:/mnt/wslg"
    fi
    
    # Verificar DISPLAY
    if [ -z "$DISPLAY" ]; then
        log "WARNING: Variable DISPLAY no está configurada"
        export DISPLAY=:0
    fi
    
    log "DISPLAY=$DISPLAY"
    log "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
}

# Función para verificar conexión X11/Wayland
check_display() {
    log "Verificando conexión de display..."
    
    # Intentar con Wayland primero (preferido en WSLg)
    if [ -n "$WAYLAND_DISPLAY" ] && [ -e "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]; then
        log "Wayland disponible: ${WAYLAND_DISPLAY}"
        return 0
    fi
    
    # Intentar con X11
    if [ -n "$DISPLAY" ]; then
        if timeout 3 xset q &>/dev/null 2>&1; then
            log "Conexión X11 exitosa en $DISPLAY"
            return 0
        else
            log "WARNING: No se puede conectar a X11 en $DISPLAY"
        fi
    fi
    
    log "Continuando sin verificación de display..."
    return 1
}

# Función para configurar el entorno gráfico
setup_graphics() {
    log "Configurando entorno gráfico..."
    
    # Crear directorio temporal para X11 si no existe
    mkdir -p /tmp/.X11-unix 2>/dev/null || true
    
    # Configurar autorización X11 si existe
    if [ -f "/tmp/.X11-auth" ]; then
        cp /tmp/.X11-auth ~/.Xauthority 2>/dev/null || true
        chmod 600 ~/.Xauthority 2>/dev/null || true
        log "Archivo .Xauthority configurado"
    fi
    
    # Variables para aplicaciones gráficas
    export QT_X11_NO_MITSHM=1
    export _X11_NO_MITSHM=1
    export _MITSHM=0
    export XLIB_SKIP_ARGB_VISUALS=1
    
    # Configuraciones adicionales para WSLg
    export GDK_BACKEND=x11,wayland
    export QT_QPA_PLATFORM=xcb
    export SDL_VIDEODRIVER=x11
    
    log "Variables de entorno gráfico configuradas"
}

# Función para inicializar servicios
init_services() {
    log "Inicializando servicios..."
    
    # Iniciar D-Bus si no está ejecutándose
    if ! pgrep -x "dbus-daemon" > /dev/null 2>&1; then
        log "Iniciando D-Bus..."
        dbus-daemon --session --fork 2>/dev/null || true
    fi
    
    # Configurar PulseAudio client para WSLg
    if [ -n "$PULSE_SERVER" ]; then
        mkdir -p ~/.config/pulse 2>/dev/null || true
        echo "default-server = $PULSE_SERVER" > ~/.config/pulse/client.conf
        log "PulseAudio client configurado"
    fi
}

# Función para verificar dependencias
check_dependencies() {
    log "Verificando dependencias..."
    
    # Verificar que Warp Terminal esté instalado
    if ! command -v warp-terminal &> /dev/null; then
        log "ERROR: Warp Terminal no está instalado"
        exit 1
    fi
    
    log "Warp Terminal encontrado: $(which warp-terminal)"
}

# Función para mostrar información del sistema
show_system_info() {
    log "=== Información del Sistema ==="
    log "Usuario: $(whoami)"
    log "Home: $HOME"
    log "Display: $DISPLAY"
    log "Wayland Display: $WAYLAND_DISPLAY"
    log "XDG Runtime Dir: $XDG_RUNTIME_DIR"
    log "Pulse Server: $PULSE_SERVER"
    
    if [ -n "$WARP_INSTANCE_NAME" ]; then
        log "Instancia: $WARP_INSTANCE_NAME"
    fi
    
    log "=============================="
}

# Función de limpieza
cleanup() {
    log "Ejecutando limpieza..."
    
    # Limpiar archivos temporales
    rm -f ~/.Xauthority 2>/dev/null || true
    
    log "Limpieza completada"
}

# Configurar trap para limpieza
trap cleanup EXIT INT TERM

# Función principal
main() {
    log "=== Iniciando Warp Terminal en Docker (Windows/WSL2) ==="
    
    show_system_info
    
    # Verificar dependencias
    check_dependencies
    
    # Configurar WSLg
    check_wslg
    
    # Configurar entorno gráfico
    setup_graphics
    
    # Inicializar servicios
    init_services
    
    # Verificar conexión de display
    check_display || log "WARNING: Display no verificado, intentando ejecutar de todos modos..."
    
    # Ejecutar comando solicitado
    if [ $# -eq 0 ] || [ "$1" = "warp-terminal" ]; then
        log "Ejecutando Warp Terminal..."
        log "Si Warp no inicia, verifica que WSLg esté habilitado en Windows"
        exec warp-terminal
    else
        log "Ejecutando comando personalizado: $*"
        exec "$@"
    fi
}

# Ejecutar función principal
main "$@"
