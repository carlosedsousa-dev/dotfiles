#!/usr/bin/env bash

# Caminhos dos temas e scripts
THEME_DISPATCH="$HOME/.config/rofi/clipboard-dispatcher.rasi"
THEME_TEXT="$HOME/.config/rofi/clipboard.rasi"
THEME_IMG="$HOME/.config/rofi/clipboard-img.rasi"
SCRIPT_CLIPBOARD="$HOME/.local/bin/clipboard-menu.sh"

# Menu de seleção estilizado
CHOICE=$(echo -e "󱄽 Textos\n󰋩 Imagens" | rofi -dmenu -p "" -theme "$THEME_DISPATCH")

case "$CHOICE" in
    *Textos)
        rofi -show text -modi "text:$SCRIPT_CLIPBOARD text" -theme "$THEME_TEXT"
        ;;
    *Imagens)
        rofi -show img -modi "img:$SCRIPT_CLIPBOARD img" -theme "$THEME_IMG"
        ;;
esac
