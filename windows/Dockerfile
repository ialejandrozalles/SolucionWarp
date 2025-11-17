# Warp Terminal Docker - Windows/WSL2 Edition
# Base: Ubuntu 22.04 LTS con soporte WSLg
FROM ubuntu:22.04

# Metadata
LABEL maintainer="WSL2/Windows User"
LABEL description="Warp Terminal en Docker con soporte WSLg para Windows"
LABEL version="2.1.0-Windows"

# Build arguments para usuario dinámico
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=user

# Variables de entorno
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    # Locales
    locales \
    tzdata \
    # X11 y gráficos (WSLg compatibility)
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxrandr2 \
    libxss1 \
    libxcursor1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxinerama1 \
    libxkbfile1 \
    # GTK y Wayland (para WSLg)
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libwayland-client0 \
    libwayland-egl1 \
    libwayland-server0 \
    # Fuentes
    fonts-liberation \
    fonts-dejavu-core \
    ttf-mscorefonts-installer \
    # Audio (PulseAudio para WSLg)
    pulseaudio-utils \
    libpulse0 \
    # Herramientas de red
    curl \
    wget \
    net-tools \
    iputils-ping \
    dnsutils \
    # SSH
    openssh-server \
    openssh-client \
    # Herramientas de desarrollo
    git \
    vim \
    nano \
    htop \
    strace \
    gdb \
    # Utilidades
    sudo \
    ca-certificates \
    xdg-utils \
    dbus-x11 \
    x11-xserver-utils \
    && rm -rf /var/lib/apt/lists/*

# Configurar locales
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Crear usuario no-root con el mismo UID/GID del host
RUN groupadd -g ${GROUP_ID} ${USERNAME} || groupmod -n ${USERNAME} $(getent group ${GROUP_ID} | cut -d: -f1) && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ${USERNAME} || usermod -l ${USERNAME} $(id -nu ${USER_ID}) && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Instalar Warp Terminal
# Nota: Para Windows, descargamos el .deb desde URL
RUN mkdir -p /opt/warp-terminal && \
    cd /opt/warp-terminal && \
    wget -O warp-terminal.deb "https://app.warp.dev/get_warp?package=deb" && \
    dpkg -i warp-terminal.deb || true && \
    apt-get update && apt-get install -f -y && \
    dpkg -i warp-terminal.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm warp-terminal.deb

# Configurar directorio X11
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

# Copiar entrypoint
COPY entrypoint.sh /usr/local/bin/warp-entrypoint.sh
RUN chmod +x /usr/local/bin/warp-entrypoint.sh

# Cambiar al usuario no-root
USER ${USERNAME}

# Configurar variables de entorno del usuario
ENV HOME=/home/${USERNAME} \
    USER=${USERNAME} \
    XDG_RUNTIME_DIR=/tmp/runtime-${USERNAME} \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    WAYLAND_DISPLAY=wayland-0 \
    PULSE_SERVER=/mnt/wslg/PulseServer

# Crear directorios de configuración
RUN mkdir -p ${XDG_CONFIG_HOME} ${XDG_DATA_HOME}

# Crear directorio runtime (como root, luego cambiar permisos)
USER root
RUN mkdir -p /tmp/runtime-${USERNAME} && \
    chmod 700 /tmp/runtime-${USERNAME} && \
    chown ${USER_ID}:${GROUP_ID} /tmp/runtime-${USERNAME}

# Volver al usuario no-root
USER ${USERNAME}

# Directorio de trabajo
WORKDIR /home/${USERNAME}

# Entrypoint
ENTRYPOINT ["/usr/local/bin/warp-entrypoint.sh"]

# Comando por defecto
CMD ["warp-terminal"]
