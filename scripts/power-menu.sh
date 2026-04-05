#!/bin/bash

opcoes="  Desligar\n󰑐  Reiniciar\n󰤄  Suspender\n󰗼  Sair"

# Adicionei GDK_BACKEND aqui
escolha=$(echo -e "$opcoes" | GDK_BACKEND=wayland wofi --dmenu --prompt "Sistema" --width 400 --height 350)

case $escolha in
    *Desligar) systemctl poweroff ;;
    *Reiniciar) systemctl reboot ;;
    *Suspender) systemctl suspend ;;
    *Sair) niri msg action quit ;;
esac