FROM ubuntu:22.04
MAINTAINER hola@nuntius.dev

# Configuración básica
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota
ENV LANG es_ES.UTF-8
ENV USER=root
ENV TZ=America/Bogota
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=dummy

EXPOSE 22 5901 8080 3389 5901

# Actualización e instalación de dependencias
RUN apt-get update && \
    apt-get install -y \
    apt full-upgrade -y \
    locales xfce4 xfce4-terminal novnc tightvncserver websockify wget curl \
    chromium-browser firefox openssh-client git gedit vim apt-utils\
    tigervnc-standalone-server tigervnc-xorg-extension xorg dbus-x11 \
    sudo nano tmux ffmpeg htop vlc snapd python3.10 python3.10-venv python3.10-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configuración de locales
RUN localedef -i es_ES -c -f UTF-8 -A /usr/share/locale/locale.alias es_ES.UTF-8

# Configuración del entorno gráfico
COPY start.sh /start.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /start.sh /entrypoint.sh
# instalar apps
wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash
# Configuración de noVNC
RUN mkdir -p /.novnc/utils/websockify && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.5.0.tar.gz | tar xz --strip 1 -C /.novnc && \
    wget -qO- https://github.com/novnc/websockify/archive/v0.12.0.tar.gz | tar xz --strip 1 -C /.novnc/utils/websockify && \
    ln -s /.novnc/vnc.html /.novnc/index.html

# Configuración del sistema
RUN systemctl enable ssh.service

CMD ["sh", "/start.sh"]
