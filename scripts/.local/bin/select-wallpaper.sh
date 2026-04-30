#!/bin/bash
WALL_DIR="$HOME/Imagens/Wallpapers"
THUMB_DIR="/tmp/wallpaper_thumbs"
mkdir -p "$THUMB_DIR"

# Garante que o script encontre o matugen, awww e outros binários do cargo/local
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Garante apenas uma instância da seleção de wallpaper (compartilhado com power-menu.sh)
LOCKFILE="/tmp/modal-menu.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    exit 0
fi

# Função para gerar a lista com ícones para o Rofi
gerar_lista() {
    find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | while read -r img; do
        nome=$(basename "$img")
        thumb="$THUMB_DIR/${nome}.png"
        
        # Gera miniatura se não existir (240x150 para um grid 3x3 perfeito)
        if [ ! -f "$thumb" ]; then
            if command -v magick &> /dev/null; then
                magick "$img" -strip -resize 240x150^ -gravity center -extent 240x150 "$thumb" 2>/dev/null
            elif command -v convert &> /dev/null; then
                convert "$img" -strip -resize 240x150^ -gravity center -extent 240x150 "$thumb" 2>/dev/null
            fi
        fi
        
        # O formato é: NomeExibido\0icon\x1fCaminhoDoIcone
        echo -en "$nome\0icon\x1f$thumb\n"
    done
}

# Seleção via Rofi - Usa o tema dedicado wallpaper.rasi
escolha=$(gerar_lista | rofi -dmenu -p "" -theme "$HOME/.config/rofi/wallpaper.rasi")

if [ -n "$escolha" ]; then
    # Reconstrói o caminho completo do arquivo
    WALLPATH="$WALL_DIR/$escolha"

    # Inicia a transição do wallpaper
    awww img "$WALLPATH" --transition-type center --transition-step 60 --transition-fps 60 &

    # Gera as cores com o Matugen
    matugen image "$WALLPATH" > /dev/null 2>&1

    # Pequena pausa para garantir que o sistema de arquivos registrou a escrita
    sleep 0.1

    # Recarrega o Kitty (Sinal USR1 faz o kitty ler o colors.conf sem fechar)
    pkill -USR1 kitty

    # Recarrega o estilo do Waybar
    touch "$HOME/.config/waybar/colors.css"
fi
