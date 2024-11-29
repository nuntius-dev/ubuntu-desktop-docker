# Usar una imagen base oficial de Debian
FROM debian:12.8-slim

# Establecer variables de entorno necesarias
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    DISPLAY=:1 \
    VNC_PORT=5901 \
    NOVNC_PORT=8080

# Actualizar e instalar dependencias necesarias
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    locales \
    kde-plasma-desktop \
    tigervnc-standalone-server \
    novnc websockify \
    xfonts-base x11-xserver-utils \
    wget curl nano sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configurar locales
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Crear usuario para el entorno gráfico y otorgar permisos sudo
RUN useradd -m -s /bin/bash docker && \
    echo "docker:docker" | chpasswd && \
    usermod -aG sudo docker

# Verificar y opcionalmente instalar pi-apps si la arquitectura es ARM
RUN /bin/bash -c ' \
    if dpkg --print-architecture | grep -qE "arm|aarch64|arm64"; then \
        echo "Instalando pi-apps para arquitectura ARM..."; \
        wget -qO- https://raw.githubusercontent.com/botspot/pi-apps/master/install | bash; \
    else \
        echo "Arquitectura no ARM detectada. Saltando instalación de pi-apps."; \
    fi'

# Crear directorios persistentes para VNC y Desktop
VOLUME /docker/.vnc
VOLUME /docker/Desktop

# Configurar TigerVNC
RUN mkdir -p /docker/.vnc && \
    echo "docker" | vncpasswd -f > /docker/.vnc/passwd && \
    chmod 600 /docker/.vnc/passwd

# Crear el script de inicio
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Iniciar servidor VNC\n\
vncserver -kill $DISPLAY || true\n\
vncserver $DISPLAY -geometry 1280x720 -depth 24\n\
\n\
# Iniciar noVNC\n\
websockify --web=/usr/share/novnc/ --cert=/docker/.vnc/self.pem $NOVNC_PORT localhost:$VNC_PORT &\n\
echo "noVNC iniciado en http://localhost:$NOVNC_PORT/vnc.html"\n\
\n\
# Mantener el contenedor activo\n\
tail -f /dev/null' > /docker/start.sh && \
    chmod +x /docker/start.sh

# Exponer puertos para VNC y noVNC
EXPOSE 5901 8080

# Comando para iniciar el contenedor
CMD ["/bin/bash", "/docker/start.sh"]
