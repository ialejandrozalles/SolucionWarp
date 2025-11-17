#!/bin/bash

# Warp Terminal Docker Entrypoint - Windows/WSL2 Edition
# Configura automÃ¡ticamente el entorno WSLg y lanza aplicaciones
# Compatible con Docker Desktop en Windows 10/11

set -e

# FunciÃ³n de logging
log() {
    echo "[WARP-DOCKER-WSL2] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# FunciÃ³n para verificar WSLg
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
        log "WARNING: /mnt/wslg no estÃ¡ montado"
        log "AsegÃºrate de ejecutar con: -v /mnt/wslg:/mnt/wslg"
    fi
    
    # Verificar DISPLAY
    if [ -z "$DISPLAY" ]; then
        log "WARNING: Variable DISPLAY no estÃ¡ configurada"
        export DISPLAY=:0
    fi
    
    log "DISPLAY=$DISPLAY"
    log "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
}

# FunciÃ³n para verificar conexiÃ³n X11/Wayland
check_display() {
    log "Verificando conexiÃ³n de display..."
    
    # Intentar con Wayland primero (preferido en WSLg)
    if [ -n "$WAYLAND_DISPLAY" ] && [ -e "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]; then
        log "Wayland disponible: ${WAYLAND_DISPLAY}"
        return 0
    fi
    
    # Intentar con X11
    if [ -n "$DISPLAY" ]; then
        if timeout 3 xset q &>/dev/null 2>&1; then
            log "ConexiÃ³n X11 exitosa en $DISPLAY"
            return 0
        else
            log "WARNING: No se puede conectar a X11 en $DISPLAY"
        fi
    fi
    
    log "Continuando sin verificaciÃ³n de display..."
    return 1
}

# FunciÃ³n para configurar el entorno grÃ¡fico
setup_graphics() {
    log "Configurando entorno grÃ¡fico..."
    
    # Crear directorio temporal para X11 si no existe
    mkdir -p /tmp/.X11-unix 2>/dev/null || true
    
    # Configurar autorizaciÃ³n X11 si existe
    if [ -f "/tmp/.X11-auth" ]; then
        cp /tmp/.X11-auth ~/.Xauthority 2>/dev/null || true
        chmod 600 ~/.Xauthority 2>/dev/null || true
        log "Archivo .Xauthority configurado"
    fi
    
    # Variables para aplicaciones grÃ¡ficas
    export QT_X11_NO_MITSHM=1
    export _X11_NO_MITSHM=1
    export _MITSHM=0
    export XLIB_SKIP_ARGB_VISUALS=1
    
    # Configuraciones adicionales para WSLg
    export GDK_BACKEND=x11,wayland
    export QT_QPA_PLATFORM=xcb
    export SDL_VIDEODRIVER=x11
    
    log "Variables de entorno grÃ¡fico configuradas"
}

# FunciÃ³n para inicializar servicios
init_services() {
    log "Inicializando servicios..."
    
    # Iniciar D-Bus si no estÃ¡ ejecutÃ¡ndose
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

# FunciÃ³n para verificar dependencias
check_dependencies() {
    log "Verificando dependencias..."
    
    # Verificar que Warp Terminal estÃ© instalado
    if ! command -v warp-terminal &> /dev/null; then
        log "ERROR: Warp Terminal no estÃ¡ instalado"
        exit 1
    fi
    
    log "Warp Terminal encontrado: $(which warp-terminal)"
}

# FunciÃ³n para mostrar informaciÃ³n del sistema
show_system_info() {
    log "=== InformaciÃ³n del Sistema ==="
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

# FunciÃ³n de limpieza
cleanup() {
    log "Ejecutando limpieza..."
    
    # Limpiar archivos temporales
    rm -f ~/.Xauthority 2>/dev/null || true
    
    log "Limpieza completada"
}

# Configurar trap para limpieza
trap cleanup EXIT INT TERM

# FunciÃ³n principal
main() {
    log "=== Iniciando Warp Terminal en Docker (Windows/WSL2) ==="
    
    show_system_info
    
    # Verificar dependencias
    check_dependencies
    
    # Configurar WSLg
    check_wslg
    
    # Configurar entorno grÃ¡fico
    setup_graphics
    
    # Inicializar servicios
    init_services
    
    # Verificar conexiÃ³n de display
    check_display || log "WARNING: Display no verificado, intentando ejecutar de todos modos..."
    
    # Ejecutar comando solicitado
    if [ $# -eq 0 ] || [ "$1" = "warp-terminal" ]; then
        log "Ejecutando Warp Terminal..."
        log "Si Warp no inicia, verifica que WSLg estÃ© habilitado en Windows"
        exec warp-terminal
    else
        log "Ejecutando comando personalizado: $*"
        exec "$@"
    fi
}

# Ejecutar funciÃ³n principal
main "$@"
