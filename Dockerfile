# usar una imagen base oficial de ubuntu
FROM ubuntu:22.04

# establecer variables de entorno necesarias
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=es_ES.UTF-8 \
    LANGUAGE=es_ES:en \
    LC_ALL=es_ES.UTF-8 \
    DISPLAY=:1 \
    VNC_PORT=5901 \
    NOVNC_PORT=8080

# actualizar e instalar dependencias necesarias
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    xfonts-base x11-xserver-utils \
    wget curl nano locales sudo xfce4-panel-profiles gdebi software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# crear el usuario 'nuntius' y agregarlo al grupo sudo
RUN useradd -m -s /bin/bash nuntius && \
    echo "nuntius ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# cambiar al usuario 'nuntius' temporalmente para ejecutar el script
USER nuntius

# cambiar de nuevo al usuario 'root'
USER root

# purgar el gestor de energía
RUN apt-get -y purge xfce4-power-manager && \
    rm -rf /home/nuntius/.config/xfce4/power-manager

# configurar locales
RUN locale-gen es_ES.UTF-8 && \
    update-locale LANG=es_ES.UTF-8

# crear el directorio de escritorio antes de ejecutar el instalador
RUN mkdir -p /root/Desktop

# crear directorios persistentes para vnc y desktop
VOLUME /root/.vnc
VOLUME /root/Desktop

# crear y configurar el archivo de contraseña de vnc
RUN mkdir -p /root/.vnc && \
    echo "docker" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    chown -R nuntius:nuntius /root/.vnc

# crear el script de inicio
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# montar el directorio
mount --bind /usr/local/share/applications /usr/share/applications/usr-local-temporary || true\n\
\n\
# iniciar servidor vnc\n\
echo "iniciando servidor vnc..." && \
vncserver -kill $DISPLAY || true && \
vncserver $DISPLAY -geometry 1280x720 -depth 24 && \
echo "servidor vnc iniciado."\n\
\n\
# iniciar novnc\n\
echo "iniciando novnc..." && \
websockify --web=/usr/share/novnc/ --cert=/root/.vnc/self.pem $NOVNC_PORT localhost:$VNC_PORT &\n\
echo "novnc iniciado en http://localhost:$NOVNC_PORT/vnc.html"\n\
\n\
# mantener el contenedor activo\n\
tail -f /dev/null' > /root/start.sh && \
    chmod +x /root/start.sh

# puertos expuestos para vnc y novnc
EXPOSE 5901 8080

# comando para iniciar el contenedor
CMD ["/bin/bash", "/root/start.sh"]
