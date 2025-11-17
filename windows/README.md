# Warp Terminal Docker - Windows Edition

[![Version](https://img.shields.io/badge/version-2.1.0--Windows-blue.svg)](https://github.com/warpdotdev/warp)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue.svg)](https://www.microsoft.com/windows)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/products/docker-desktop)
[![WSL2](https://img.shields.io/badge/WSL2-required-blue.svg)](https://docs.microsoft.com/windows/wsl/)

Ejecuta Warp Terminal en Docker con soporte gráfico completo usando Docker Desktop y WSL2/WSLg en Windows 10/11.

## 🌟 Características

- ✅ **Múltiples instancias simultáneas** de Warp Terminal
- ✅ **Gestión avanzada de instancias** (listar, detener, logs)
- ✅ **Soporte WSLg** para gráficos nativos en Windows 11
- ✅ **Compatibilidad X11** para Windows 10 (con VcXsrv)
- ✅ **Audio PulseAudio** a través de WSLg
- ✅ **Cliente SSH** integrado para conexiones remotas
- ✅ **Herramientas de desarrollo** preinstaladas (git, vim, nano, htop, gdb)
- ✅ **Configuración automática** de usuario y permisos
- ✅ **Scripts PowerShell** nativos para Windows

## 📋 Requisitos del Sistema

### Sistema Operativo
- **Windows 11** (22H2 o superior, con WSLg) - Recomendado
- **Windows 10** (versión 2004 o superior, con WSL2 + VcXsrv)

### Software Requerido
- **Docker Desktop para Windows** (versión 4.0+) con backend WSL2
- **WSL2** (Windows Subsystem for Linux 2)
- **PowerShell** 5.1 o superior (incluido en Windows)

### Recursos Mínimos
- **RAM**: 4 GB (8 GB recomendado)
- **Disco**: 5 GB de espacio libre
- **CPU**: Procesador x86_64 compatible con virtualización

### Configuración Adicional para Windows 10
Si usas Windows 10, necesitarás instalar un servidor X11:
- **VcXsrv** o **Xming** para soporte X11
- Disponible en: https://sourceforge.net/projects/vcxsrv/

## 🚀 Inicio Rápido

### 1. Verificar Prerrequisitos

Abre PowerShell y verifica que Docker Desktop esté instalado y ejecutándose:

```powershell
docker --version
docker ps
```

### 2. Instalación Simple

```powershell
# Navegar al directorio del proyecto
cd path\to\SolucionWarp\windows

# Ejecutar configuración inicial
.\setup.ps1

# Construir y ejecutar
.\warp.ps1
```

### 3. Método Manual

Si prefieres control total:

```powershell
# 1. Construir la imagen Docker
.\build.ps1

# 2. Ejecutar Warp Terminal
.\warp.ps1
```

### 4. One-Liner

```powershell
.\warp.ps1 build
```

## 📖 Guía de Uso

### Comandos Principales

#### Abrir Nueva Instancia
```powershell
.\warp.ps1
# o
.\warp.ps1 new
```

#### Construir Imagen
```powershell
.\warp.ps1 build           # Construir imagen
.\warp.ps1 rebuild         # Reconstruir sin caché
```

#### Gestión de Múltiples Instancias

**Abrir múltiples instancias:**
```powershell
# Primera instancia
.\warp.ps1

# Segunda instancia (en otra ventana PowerShell)
.\warp.ps1

# O abrir en nueva ventana automáticamente
Start-Process pwsh -ArgumentList "-NoExit", "-File", ".\warp.ps1"
```

**Listar instancias activas:**
```powershell
.\warp.ps1 list
# o
.\warp.ps1 ls
```

**Detener instancias:**
```powershell
.\warp.ps1 kill-all                      # Detiene TODAS las instancias
.\warp.ps1 kill warp-terminal-123456     # Detiene una instancia específica
```

**Ver logs de una instancia:**
```powershell
.\warp.ps1 logs warp-terminal-123456
```

### Comandos Avanzados

#### Shell Bash
```powershell
.\warp.ps1 shell
# o
.\warp.ps1 bash
```

#### Limpieza
```powershell
.\warp.ps1 clean          # Limpia contenedores detenidos
.\warp.ps1 cleanup-all    # Limpieza completa + system prune
```

#### Ayuda
```powershell
.\warp.ps1 help
# o
.\warp.ps1 --help
```

## 🐳 Uso con Docker Desktop

### Configuración Recomendada de Docker Desktop

1. **Abrir Docker Desktop Settings**
2. **General**:
   - ✅ Use the WSL 2 based engine
   - ✅ Start Docker Desktop when you log in
   
3. **Resources > WSL Integration**:
   - ✅ Enable integration with my default WSL distro
   - ✅ Enable integration with additional distros (Ubuntu, etc.)

4. **Resources**:
   - Memory: Al menos 4 GB
   - CPUs: Al menos 2 cores
   - Disk: Al menos 20 GB

### Verificar WSL2

```powershell
# Ver versión de WSL
wsl --version

# Listar distribuciones instaladas
wsl --list --verbose

# Asegurarse de que la versión sea WSL 2
wsl --set-default-version 2
```

## 🖼️ Configuración de WSLg (Windows 11)

WSLg viene preinstalado en Windows 11 22H2 y superior. Verifica que esté funcionando:

```powershell
# Desde WSL (Ubuntu u otra distro)
wsl
echo $DISPLAY
echo $WAYLAND_DISPLAY

# Debería mostrar:
# DISPLAY=:0
# WAYLAND_DISPLAY=wayland-0
```

Si WSLg no funciona:
1. Actualiza Windows a la última versión
2. Actualiza WSL: `wsl --update`
3. Reinicia WSL: `wsl --shutdown`

## 🖥️ Configuración X11 para Windows 10

### Instalación de VcXsrv

1. Descarga VcXsrv: https://sourceforge.net/projects/vcxsrv/
2. Instala con opciones por defecto
3. Ejecuta XLaunch con estas configuraciones:
   - Display number: `0`
   - Start no client
   - ✅ Disable access control

### Configurar Firewall

Permite conexiones de WSL2 a VcXsrv:

```powershell
# Ejecutar como Administrador
New-NetFirewallRule -DisplayName "VcXsrv" -Direction Inbound -Program "C:\Program Files\VcXsrv\vcxsrv.exe" -Action Allow
```

### Configurar Variables de Entorno

Edita `warp.ps1` y agrega tu IP de WSL2:

```powershell
# Obtener IP del host desde WSL
wsl hostname -I

# En warp.ps1, actualiza DISPLAY:
$env:DISPLAY = "<TU_IP_WSL2>:0.0"
```

## 🔧 Configuración Avanzada

### Variables de Entorno

El contenedor usa estas variables:

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `DISPLAY` | `:0` | Display X11 |
| `WAYLAND_DISPLAY` | `wayland-0` | Display Wayland (WSLg) |
| `XDG_RUNTIME_DIR` | `/mnt/wslg/runtime-dir` | Runtime de WSLg |
| `PULSE_SERVER` | `/mnt/wslg/PulseServer` | Servidor de audio |
| `QT_X11_NO_MITSHM` | `1` | Fix para Qt apps |
| `WARP_INSTANCE_NAME` | `warp-terminal-<ID>` | Nombre de instancia |

### Volúmenes Montados

```powershell
/tmp/.X11-unix:/tmp/.X11-unix              # Socket X11
/mnt/wslg:/mnt/wslg                        # WSLg runtime
/run/user:/run/user                        # User runtime
```

### Personalizar Build

```powershell
# Build con nombre personalizado
$env:IMAGE_NAME = "mi-warp-terminal"
.\build.ps1

# Build verboso
.\build.ps1 -Verbose

# Build limpio
.\build.ps1 -Clean
```

### Volúmenes Persistentes

Para guardar configuraciones entre sesiones:

```powershell
# Crear volumen persistente
docker volume create warp-config

# Modificar warp.ps1 para montar volumen:
"-v", "warp-config:/home/$env:USERNAME/.config/warp-terminal"
```

## 🛠️ Troubleshooting

### Problema: "Docker no está instalado"

**Solución:**
```powershell
# Descargar Docker Desktop
# https://www.docker.com/products/docker-desktop
# Instalar y reiniciar Windows
```

### Problema: "Docker no está ejecutándose"

**Solución:**
```powershell
# Iniciar Docker Desktop desde el menú de inicio
# Esperar a que aparezca el ícono de Docker en la bandeja del sistema
```

### Problema: "WSL2 no está instalado"

**Solución:**
```powershell
# Instalar WSL2
wsl --install

# Reiniciar Windows
# Configurar usuario y contraseña en WSL
```

### Problema: Warp Terminal no se muestra

**Para Windows 11 (WSLg):**
```powershell
# Verificar WSLg
wsl
echo $DISPLAY
echo $WAYLAND_DISPLAY

# Actualizar WSL
wsl --update
wsl --shutdown

# Reintentar
.\warp.ps1
```

**Para Windows 10 (VcXsrv):**
```powershell
# Verificar que VcXsrv esté ejecutándose
Get-Process vcxsrv

# Si no está ejecutándose, inicia XLaunch
# Ejecuta .\warp.ps1 nuevamente
```

### Problema: "Error de permisos"

**Solución:**
```powershell
# Ejecutar PowerShell como Administrador
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Reintentar
.\warp.ps1
```

### Problema: Construcción falla por falta de espacio

**Solución:**
```powershell
# Limpiar Docker
docker system prune -a

# O desde warp.ps1
.\warp.ps1 cleanup-all
```

### Problema: No hay audio

**Solución para Windows 11:**
```powershell
# Verificar que el volumen WSLg esté montado
docker inspect <container_id> | Select-String "wslg"

# Reiniciar WSL
wsl --shutdown
```

### Debug Avanzado

```powershell
# Ver logs de una instancia
.\warp.ps1 logs <instance-id>

# Abrir shell en contenedor
.\warp.ps1 shell

# Verificar variables de entorno
docker exec -it <container_id> env

# Ver configuración de Docker
docker info
```

## 📁 Estructura del Proyecto

```
windows/
├── warp.ps1                    # Script principal de launcher
├── setup.ps1                   # Script de configuración inicial
├── build.ps1                   # Script de construcción de imagen
├── demo-multi-instance.ps1     # Script de demostración
├── Dockerfile                  # Definición de imagen Docker
├── entrypoint.sh              # Script de entrada del contenedor
└── README.md                  # Este archivo
```

### Descripción de Archivos

| Archivo | Propósito |
|---------|-----------|
| `warp.ps1` | Launcher principal con gestión de múltiples instancias |
| `setup.ps1` | Configuración inicial y descarga de dependencias |
| `build.ps1` | Construcción de imagen Docker con opciones |
| `demo-multi-instance.ps1` | Demostración de características |
| `Dockerfile` | Imagen Ubuntu 22.04 con Warp Terminal y WSLg |
| `entrypoint.sh` | Configuración de entorno y lanzamiento |

## 🔐 Seguridad

- ✅ Contenedor ejecuta como **usuario no-root**
- ✅ UID/GID mapeados al usuario del host
- ✅ Capabilities limitadas (solo SYS_ADMIN para X11)
- ✅ Filesystem aislado
- ✅ Autenticación X11 con Xauthority

## 📦 Tamaños

- **Imagen Docker**: ~1.2 GB
- **Descarga de Warp**: ~40 MB
- **Total en disco**: ~1.3 GB

## 🐛 Logs y Debugging

### Habilitar Logs Detallados

```powershell
# Ver logs en tiempo real
.\warp.ps1 logs <instance-id>

# Logs de construcción
.\build.ps1 -Verbose
```

### Inspeccionar Contenedor

```powershell
# Abrir shell bash
.\warp.ps1 shell

# Una vez dentro del contenedor:
env                    # Ver variables de entorno
ps aux                 # Ver procesos
netstat -tlnp          # Ver puertos
```

## 🚧 Limitaciones Conocidas

1. **Warp AI**: Puede requerir configuración adicional de red
2. **GPU Acceleration**: Limitada en WSL2
3. **Clipboard**: Puede no sincronizar automáticamente
4. **Performance**: Ligeramente menor que instalación nativa

## 🤝 Contribuir

Este proyecto es parte de una solución más amplia para ejecutar Warp Terminal en diferentes plataformas usando Docker.

## 📄 Licencia

MIT License - Ver archivo LICENSE para detalles

## 🙏 Agradecimientos

- [Warp Terminal](https://www.warp.dev/) - Por crear una terminal increíble
- [Docker](https://www.docker.com/) - Por la tecnología de contenedores
- [Microsoft WSL](https://docs.microsoft.com/windows/wsl/) - Por WSL2 y WSLg

## 📞 Soporte

Si encuentras problemas:

1. Revisa la sección de [Troubleshooting](#-troubleshooting)
2. Verifica que tu sistema cumpla los [Requisitos](#-requisitos-del-sistema)
3. Consulta los logs con `.\warp.ps1 logs <instance-id>`
4. Prueba ejecutar `.\warp.ps1 shell` para debug interactivo

---

**Versión**: 2.1.0-Windows  
**Última actualización**: 2024  
**Plataforma**: Windows 10/11 con Docker Desktop y WSL2
