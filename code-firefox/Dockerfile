# Usar una imagen base oficial de Ubuntu
FROM ubuntu:22.04

# Establecer variables de entorno necesarias
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=es_ES.UTF-8 \
    LANGUAGE=es_ES:en \
    LC_ALL=es_ES.UTF-8 \
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
RUN apt-get -y purge xfce4-power-manager && \
    rm -rf /home/nuntius/.config/xfce4/power-manager
# Configurar locales
RUN locale-gen es_ES.UTF-8 && \
    update-locale LANG=es_ES.UTF-8
# Instalar Firefox:
run /bin/bash -c ' \
    arquitecturas=$(dpkg --print-architecture) && \
    echo "Arquitectura detectada: $arquitecturas" && \
    if [[ "$arquitecturas" == "arm" || "$arquitecturas" == "aarch64" || "$arquitecturas" == "arm64" ]]; then \
        echo "Arquitectura ARM detectada. Instalando Firefox..." && \
        firefox-nightly || echo "Error al instalar Firefox." ; \
    else \
        echo "Arquitectura no ARM detectada. Instalando versión estándar de Firefox..." && \
        apt-get install -y firefox || echo "Error al instalar la versión estándar de Firefox."; \
    fi'
# Instalar Visual Studio Code:
run /bin/bash -c ' \
    arquitecturas=$(dpkg --print-architecture) && \
    echo "Arquitectura detectada: $arquitecturas" && \
    if [[ "$arquitecturas" == "arm" || "$arquitecturas" == "aarch64" || "$arquitecturas" == "arm64" ]]; then \
        echo "Arquitectura ARM detectada. Instalando Visual Studio Code..." && \
        curl -L -o code_arm64.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-arm64-deb && \
        sudo apt install ./code_arm64.deb || echo "Error al instalar Visual Studio Code en ARM."; \
    else \
        echo "Arquitectura no ARM detectada. Instalando versión estándar de Visual Studio Code..." && \
        curl -L -o code_amd64.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-x64-deb && \
        sudo apt install ./code_amd64.deb || echo "Error al instalar la versión de Visual Studio Code."; \
    fi'
# Crear directorios persistentes para VNC y Desktop
VOLUME /root/.vnc
VOLUME /root/Desktop

# Crear y configurar el archivo de contraseña de VNC
RUN mkdir -p /root/.vnc && \
    echo "docker" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    chown -R nuntius:nuntius /root/.vnc

# Crear el script de inicio
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Montar el directorio
mount --bind /usr/local/share/applications /usr/share/applications/usr-local-temporary || true\n\
\n\
# Iniciar servidor VNC\n\
echo "Iniciando servidor VNC..." && \
vncserver -kill $DISPLAY || true && \
vncserver $DISPLAY -geometry 1280x720 -depth 24 && \
echo "Servidor VNC iniciado."\n\
\n\
# Iniciar noVNC\n\
echo "Iniciando noVNC..." && \
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
