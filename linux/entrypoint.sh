#!/bin/bash

# Warp Terminal Docker Entrypoint - Professional Portable Edition
# Automatically configures X11 environment and launches applications
# Compatible with any user and system configuration

set -e

# Función de logging
log() {
    echo "[WARP-DOCKER] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Función para verificar conexión X11
check_x11() {
    log "Verificando conexión X11..."
    
    if [ -z "$DISPLAY" ]; then
        log "ERROR: Variable DISPLAY no está configurada"
        exit 1
    fi
    
    # Intentar conectar al servidor X
    if ! timeout 5 xset q &>/dev/null; then
        log "WARNING: No se puede conectar al servidor X11 en $DISPLAY"
        log "Asegúrate de que X11 forwarding esté habilitado en el host"
        return 1
    fi
    
    log "Conexión X11 exitosa en $DISPLAY"
    return 0
}

# Función para configurar el entorno gráfico
setup_graphics() {
    log "Configurando entorno gráfico..."
    
    # Crear directorio temporal para X11 si no existe
    mkdir -p /tmp/.X11-unix
    
    # Configurar permisos para el socket X11
    if [ -S "/tmp/.X11-unix/X${DISPLAY#*:}" ]; then
        log "Socket X11 detectado: /tmp/.X11-unix/X${DISPLAY#*:}"
    fi
    
    # Configurar autorización X11 si existe .Xauthority
    if [ -f "/tmp/.X11-auth" ]; then
        cp /tmp/.X11-auth ~/.Xauthority 2>/dev/null || true
        chmod 600 ~/.Xauthority 2>/dev/null || true
        log "Archivo .Xauthority configurado"
    fi
    
    # Configurar variables adicionales para aplicaciones gráficas
    export QT_X11_NO_MITSHM=1
    export _X11_NO_MITSHM=1
    export _MITSHM=0
    export XLIB_SKIP_ARGB_VISUALS=1
}

# Función para inicializar servicios necesarios
init_services() {
    log "Inicializando servicios..."
    
    # Iniciar D-Bus si no está ejecutándose
    if ! pgrep -x "dbus-daemon" > /dev/null; then
        log "Iniciando D-Bus..."
        dbus-daemon --session --fork --print-pid > /tmp/dbus.pid 2>/dev/null || true
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session"
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

# Función para limpiar al salir
cleanup() {
    log "Ejecutando limpieza..."
    
    # Terminar D-Bus si lo iniciamos
    if [ -f /tmp/dbus.pid ]; then
        kill $(cat /tmp/dbus.pid) 2>/dev/null || true
        rm -f /tmp/dbus.pid
    fi
    
    # Limpiar archivos temporales
    rm -f ~/.Xauthority 2>/dev/null || true
    
    log "Limpieza completada"
}

# Configurar trap para limpieza al salir
trap cleanup EXIT INT TERM

# Función principal
main() {
    log "=== Iniciando Warp Terminal en Docker ==="
    log "Usuario: $(whoami)"
    log "Home: $HOME"
    log "Display: $DISPLAY"
    log "Argumentos: $*"
    
    # Verificar dependencias
    check_dependencies
    
    # Configurar entorno gráfico
    setup_graphics
    
    # Inicializar servicios
    init_services
    
    # Verificar conexión X11
    if check_x11; then
        log "Sistema listo para aplicaciones gráficas"
    else
        log "Continuando sin verificación X11..."
    fi
    
    # Ejecutar comando solicitado
    if [ $# -eq 0 ] || [ "$1" = "warp-terminal" ]; then
        log "Ejecutando Warp Terminal..."
        exec warp-terminal
    else
        log "Ejecutando comando personalizado: $*"
        exec "$@"
    fi
}

# Ejecutar función principal con todos los argumentos
main "$@"
