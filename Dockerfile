# Warp Terminal Docker - Multi-Instance Edition
# Base: Ubuntu 22.04 LTS con soporte X11
FROM ubuntu:22.04

# Metadata
LABEL maintainer="Container User"
LABEL description="Warp Terminal en contenedor Docker con soporte X11 - Multi-Instance"
LABEL version="2.1.0"

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
    # X11 y gráficos
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
    # GTK y Wayland
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libwayland-client0 \
    libwayland-egl1 \
    libwayland-server0 \
    # Librerías multimedia y sonido
    libasound2 \
    libasound2-plugins \
    libpulse0 \
    pulseaudio-utils \
    # Fuentes
    fonts-liberation \
    fonts-dejavu-core \
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
# Descargar el .deb desde la página oficial
RUN mkdir -p /opt/warp-terminal && \
    cd /opt/warp-terminal && \
    wget -O warp-terminal.deb "https://app.warp.dev/download?package=deb" && \
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
    XDG_DATA_HOME=/home/${USERNAME}/.local/share

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
