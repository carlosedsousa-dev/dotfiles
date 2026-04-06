#!/bin/bash
WALL_DIR="$HOME/Imagens/Wallpapers"

# Garante que o script encontre o matugen, swww e outros binários do cargo/local
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Seleção via Wofi (GDK_BACKEND forçado para evitar erros de X11 no Wayland)
escolha=$(ls "$WALL_DIR" | GDK_BACKEND=wayland wofi --dmenu --prompt "Escolher Wallpaper")

if [ -n "$escolha" ]; then
    WALLPATH="$WALL_DIR/$escolha"

    # Inicia a transição do wallpaper (rodando em background para não travar o script)
    swww img "$WALLPATH" --transition-type center --transition-step 60 --transition-fps 60 &

    # Gera as cores com o Matugen
    # É importante que isso rode antes do reload da barra
    matugen image "$WALLPATH" > /dev/null 2>&1

    # Pequena pausa para garantir que o sistema de arquivos registrou a escrita
    sleep 0.1

    # Recarrega o Kitty (Sinal USR1 faz o kitty ler o colors.conf sem fechar)
    pkill -USR1 kitty

    # Recarrega o estilo do Waybar
    # Se "reload_style_on_change": true estiver no config.jsonc, o touch abaixo basta
    touch home/carlos/.config/waybar/colors.css
fi