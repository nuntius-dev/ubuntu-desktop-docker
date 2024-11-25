#!/bin/bash

# Configuración de contraseña VNC
vncpassword="${vncpassword:-insecure}"
printf "$vncpassword\n$vncpassword\n\n" | vncserver :1

# Iniciar noVNC
/.novnc/utils/launch.sh --vnc localhost:5901 --listen 8080
