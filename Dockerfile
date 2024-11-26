# syntax=docker/dockerfile:1
FROM ubuntu:22.04
LABEL maintainer="hola@nuntius.dev"

# Configuración básica
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota \
    LANG=es_ES.UTF-8 \
    USER=root

# Claves manejados de forma más segura
ARG VNCPASSWORD=insecure
ARG PASSWORD=root

EXPOSE 22 5901 8080 3389

# Actualización e instalación de dependencias
RUN apt-get update && \
    apt-get install -y \
    locales xfce4 xauth xfce4-terminal novnc tightvncserver websockify wget curl \
    chromium-browser firefox openssh-client git gedit vim apt-utils \
    tigervnc-standalone-server tigervnc-xorg-extension xorg dbus-x11 \
    sudo nano tmux ffmpeg htop vlc python3.10 python3.10-venv python3.10-dev python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar websockify via pip
RUN pip3 install websockify

# Comienza el bloque de instrucciones RUN
RUN arch=$(uname -m) && \
    if [[ "$arch" == "arm"* || "$arch" == "aarch64" ]]; then \
        echo "arquitectura arm detectada: $arch. instalando pi-apps..."; \
        wget -qo- https://raw.githubusercontent.com/botspot/pi-apps/master/install | bash; \
    else \
        echo "arquitectura no arm detectada: $arch. saltando instalación de pi-apps."; \
    fi

#se crea .Xauthority
RUN touch /root/.Xauthority && \
    chmod 600 /root/.Xauthority

# Configuración de locales
RUN localedef -i es_ES -c -f UTF-8 -A /usr/share/locale/locale.alias es_ES.UTF-8

# Configuración del sistema y permisos del usuario root
RUN echo "root:root" | chpasswd && \
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configuración de VNC y entorno gráfico
RUN mkdir -p /root/.vnc && \
    echo "insecure" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    echo '#!/bin/bash\nstartxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Configuración de noVNC
RUN mkdir -p /opt/novnc && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.5.0.tar.gz | \
    tar xz --strip 1 -C /opt/novnc && \
    mkdir -p /opt/novnc/utils/websockify && \
    wget -qO- https://github.com/novnc/websockify/archive/v0.12.0.tar.gz | \
    tar xz --strip 1 -C /opt/novnc/utils/websockify

# Crear el directorio /root/Desktop/ si no existe y crear start.sh
RUN mkdir -p /root/Desktop && \
    echo '#!/bin/bash\n\
set -e\n\
\n\
# Iniciar servidor VNC\n\
vncserver :1 -geometry 1920x1080 -localhost no -SecurityTypes VncAuth\n\
\n\
# Iniciar noVNC con websockify\n\
/opt/novnc/utils/websockify/websockify.py --web=/opt/novnc 8080 localhost:5901 &\n\
\n\
# Mantener el contenedor en ejecución\n\
tail -f /dev/null' > /root/Desktop/start.sh && \
    chmod +x /root/Desktop/start.sh

# Configuración inicial y lanzamiento
CMD ["/root/Desktop/start.sh"]

VOLUME ["/root/.vnc", "/root/Desktop"]
