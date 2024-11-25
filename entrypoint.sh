#!/bin/bash

LOGFILE="/var/log/entrypoint.log"
exec &> >(tee -a "${LOGFILE}")

echo "======== Iniciando configuración del contenedor ========"

# Crear usuario si no existe
if ! id -u "$USER" &>/dev/null; then
    echo "Creando usuario $USER..."
    useradd -m -s /bin/bash "$USER"
    echo "$USER:$PASSWORD" | chpasswd
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# Configurar VNC
echo "Configurando VNC para ${USER}"
mkdir -p /home/${USER}/.vnc
echo "${VNCPASSWORD}" | vncpasswd -f > /home/${USER}/.vnc/passwd
chmod 600 /home/${USER}/.vnc/passwd
echo 'exec startxfce4' > /home/${USER}/.vnc/xstartup
chmod 755 /home/${USER}/.vnc/xstartup
chown -R ${USER}:${USER} /home/${USER}

# Crear y habilitar el servicio de VNC
cat > /etc/systemd/system/vncserver@.service <<EOF
[Unit]
Description=TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$USER
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -localhost no
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Enlace de aplicaciones en el escritorio
echo "Agregando accesos directos a aplicaciones en el escritorio"
APPLICATIONS=("google-chrome" "obs" "vlc")
mkdir -p /home/${USER}/Desktop
for APP in "${APPLICATIONS[@]}"; do
    [ -f "/usr/share/applications/${APP}.desktop" ] && cp "/usr/share/applications/${APP}.desktop" "/home/${USER}/Desktop/"
done
chown -R ${USER}:${USER} /home/${USER}/Desktop

echo "======== Configuración completada ========"

exec /sbin/init
