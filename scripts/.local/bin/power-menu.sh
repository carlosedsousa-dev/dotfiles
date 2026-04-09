#!/bin/bash

# Garante que o script encontre o matugen, swww e outros binários do cargo/local
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Garante apenas uma instância do menu (compartilhado com select-wallpaper.sh)
LOCKFILE="/tmp/modal-menu.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    exit 0
fi

opcoes="  Desligar\n󰑐  Reiniciar\n󰤄  Suspender\n󰗼  Sair"

# Usando o tema simplificado
theme="$HOME/.config/rofi/powermenu.rasi"
escolha=$(echo -e "$opcoes" | rofi -dmenu -p "Sistema" -theme "$theme")

case $escolha in
    *Desligar) systemctl poweroff ;;
    *Reiniciar) systemctl reboot ;;
    *Suspender) systemctl suspend ;;
    *Sair) niri msg action quit ;;
esac