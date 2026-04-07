#!/bin/bash
WALL_DIR="$HOME/Imagens/Wallpapers"

# Garante que o script encontre o matugen, swww e outros binários do cargo/local
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Seleção via Wofi - Apenas texto (sem miniatura) e mesma largura do Mod+D (500)
# Listamos apenas o nome do arquivo (%f) para ficar mais limpo
escolha=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) -printf "%f\n" | \
    GDK_BACKEND=wayland wofi --dmenu --prompt "Escolher Wallpaper" --width 500 --height 600)

if [ -n "$escolha" ]; then
    # Reconstrói o caminho completo do arquivo
    WALLPATH="$WALL_DIR/$escolha"

    # Inicia a transição do wallpaper
    swww img "$WALLPATH" --transition-type center --transition-step 60 --transition-fps 60 &

    # Gera as cores com o Matugen
    matugen image "$WALLPATH" > /dev/null 2>&1

    # Pequena pausa para garantir que o sistema de arquivos registrou a escrita
    sleep 0.1

    # Recarrega o Kitty (Sinal USR1 faz o kitty ler o colors.conf sem fechar)
    pkill -USR1 kitty

    # Recarrega o estilo do Waybar
    touch "$HOME/.config/waybar/colors.css"
fi
