# Usar una imagen base oficial de Ubuntu
FROM ubuntu:22.04

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
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    xfonts-base x11-xserver-utils \
    wget curl nano locales sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# comienza el bloque de instrucciones run

# Crear el usuario 'nuntius' y agregarlo al grupo sudo
RUN useradd -m -s /bin/bash nuntius && \
    echo "nuntius ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Cambiar temporalmente al usuario 'nuntius' para ejecutar el script
USER nuntius

RUN /bin/bash -c ' \
    arquitecturas=$(dpkg --print-architecture) && \
    echo "arquitectura detectada: $arquitecturas" && \
    if [[ "$arquitecturas" == "arm" || "$arquitecturas" == "aarch64" || "$arquitecturas" == "arm64" ]]; then \
        echo "arquitectura arm detectada. instalando pi-apps..." && \
        wget -qO- https://raw.githubusercontent.com/botspot/pi-apps/master/install | bash; \
    else \
        echo "arquitectura no arm detectada. saltando instalación de pi-apps."; \
    fi'

# Cambiar de nuevo al usuario 'root' (opcional)
USER root

# Configurar locales
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Crear usuario para ejecutar el entorno gráfico
RUN useradd -m -s /bin/bash docker && \
    echo "docker:docker" | chpasswd && \
    usermod -aG sudo docker

# Crear directorios persistentes para VNC y Desktop
VOLUME /root/.vnc
VOLUME /root/Desktop

# Configurar TigerVNC
RUN mkdir -p /root/.vnc && \
    echo "docker" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Crear el script de inicio
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Iniciar servidor VNC\n\
vncserver -kill $DISPLAY || true\n\
vncserver $DISPLAY -geometry 1280x720 -depth 24\n\
\n\
# Iniciar noVNC\n\
websockify --web=/usr/share/novnc/ --cert=/root/.vnc/self.pem $NOVNC_PORT localhost:$VNC_PORT &\n\
echo "noVNC iniciado en http://localhost:$NOVNC_PORT/vnc.html"\n\
\n\
# Mantener el contenedor activo\n\
tail -f /dev/null' > /root/start.sh && \
    chmod +x /root/start.sh

# Puertos expuestos para VNC y noVNC
EXPOSE 5901 8080

# Comando para iniciar el contenedor
CMD ["/bin/bash", "/root/start.sh"]
