#!/bin/bash

# Garante que o script encontre o matugen, swww e outros binários do cargo/local
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Garante apenas uma instância do menu
LOCKFILE="/tmp/modal-menu.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    exit 0
fi

opcoes="  Desligar\n󰑐  Reiniciar\n󰤄  Suspender\n󰗼  Sair"

# Captura o uptime (formato amigável)
uptime_info=$(uptime | awk -F'up|ligado por' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ //g')

# Usando o tema simplificado (estilização centralizada no powermenu.rasi)
theme="$HOME/.config/rofi/powermenu.rasi"
escolha=$(echo -e "$opcoes" | rofi -dmenu -p "Sistema" -mesg "Uptime: $uptime_info" -theme "$theme")

case $escolha in
    *Desligar) systemctl poweroff ;;
    *Reiniciar) systemctl reboot ;;
    *Suspender) systemctl suspend ;;
    *Sair) niri msg action quit ;;
esac