# Dockerfile para Warp Terminal con soporte X11
# Base: Ubuntu 22.04 LTS para compatibilidad óptima
FROM ubuntu:22.04

# Información del mantenedor
LABEL maintainer="ialejandrozalles"
LABEL description="Warp Terminal en contenedor Docker con soporte X11"
LABEL version="1.0"

# Variables de entorno para instalación no interactiva
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Actualización del sistema e instalación de dependencias base
RUN apt-get update && apt-get install -y \
    # Dependencias del sistema
    ca-certificates \
    wget \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    # Dependencias gráficas X11
    xorg \
    x11-apps \
    x11-utils \
    x11-xserver-utils \
    # Dependencias de librerías gráficas
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxrandr2 \
    libxss1 \
    libgconf-2-4 \
    libasound2 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    # Dependencias adicionales para aplicaciones modernas
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxinerama1 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    libappindicator3-1 \
    libnss3 \
    libdrm2 \
    libxkbcommon0 \
    libwayland-client0 \
    # Utilidades del sistema
    dbus-x11 \
    fonts-liberation \
    fonts-dejavu-core \
    fontconfig \
    # Herramientas de depuración
    strace \
    gdb \
    # Herramientas de red y conectividad
    openssh-client \
    openssh-server \
    net-tools \
    iputils-ping \
    telnet \
    netcat \
    rsync \
    git \
    vim \
    nano \
    htop \
    tree \
    zip \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user matching host user (portable)
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=user

RUN groupadd -g ${GROUP_ID} ${USERNAME} \
    && useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Crear directorio de trabajo y copiar el archivo .deb
WORKDIR /opt/warp-terminal
COPY warp-terminal.deb /opt/warp-terminal/

# Instalar Warp Terminal
RUN dpkg -i warp-terminal.deb || true \
    && apt-get update \
    && apt-get install -f -y \
    && dpkg -i warp-terminal.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm warp-terminal.deb

# Configurar el entorno gráfico
RUN mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix \
    && chown root:root /tmp/.X11-unix

# Cambiar al usuario creado
USER ${USERNAME}

# Configurar directorio home del usuario
WORKDIR /home/${USERNAME}

# Crear directorio para configuraciones de aplicación
RUN mkdir -p /home/${USERNAME}/.config \
    && mkdir -p /home/${USERNAME}/.local/share

# Script de entrada universal
COPY entrypoint.sh /usr/local/bin/warp-entrypoint.sh
RUN chmod +x /usr/local/bin/warp-entrypoint.sh

# Configuración de variables de entorno para el usuario
ENV HOME=/home/${USERNAME}
ENV USER=${USERNAME}
ENV XDG_RUNTIME_DIR=/tmp/runtime-${USERNAME}
ENV XDG_CONFIG_HOME=/home/${USERNAME}/.config
ENV XDG_DATA_HOME=/home/${USERNAME}/.local/share

# Crear directorio runtime
USER root
RUN mkdir -p /tmp/runtime-${USERNAME} \
    && chown ${USERNAME}:${USERNAME} /tmp/runtime-${USERNAME} \
    && chmod 700 /tmp/runtime-${USERNAME}

# Volver al usuario no-root
USER ${USERNAME}

# Punto de entrada universal
ENTRYPOINT ["/usr/local/bin/warp-entrypoint.sh"]

# Comando por defecto (arrancar Warp Terminal)
CMD ["warp-terminal"]
