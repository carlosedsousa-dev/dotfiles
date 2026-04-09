#!/bin/bash

# Garante o PATH
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Lock compartilhado
LOCKFILE="/tmp/modal-menu.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    exit 0
fi

# Pasta para miniaturas
THUMB_DIR="/tmp/cliphist_thumbs"
mkdir -p "$THUMB_DIR"

# Limpa miniaturas órfãs para não dar conflito após um 'wipe'
find "$THUMB_DIR" -type f -mmin +60 -delete 2>/dev/null

# Função para gerar a lista para o Rofi
gerar_lista() {
    # Opção especial para limpar tudo
    echo -en "󰃢  LIMPAR TODO O HISTÓRICO\0icon\x1fedit-clear-all\n"
    
    cliphist list | while read -r line; do
        id=$(echo "$line" | cut -f1)
        content=$(echo "$line" | cut -f2-)
        
        if [ -z "$id" ]; then continue; fi

        if [[ "$content" == *"[[ binary data"* ]]; then
            thumb="$THUMB_DIR/${id}.png"
            if [ ! -f "$thumb" ]; then
                if command -v magick &> /dev/null; then
                    cliphist decode "$id" | magick - -resize 64x64 "$thumb" 2>/dev/null
                elif command -v convert &> /dev/null; then
                    cliphist decode "$id" | convert - -resize 64x64 "$thumb" 2>/dev/null
                fi
            fi
            
            if [ -f "$thumb" ]; then
                echo -en "Imagem ($content)\0icon\x1f$thumb\n"
            else
                echo -en "Imagem ($content)\0icon\x1fimage-x-generic\n"
            fi
        else
            echo -en "$content\n"
        fi
    done
}

# Executa o Rofi
escolha=$(gerar_lista | rofi -dmenu -p "󰅌 Histórico" -i \
    -theme-str 'window {width: 800px; height: 600px;} listview {columns: 1; lines: 10;}')

if [ -n "$escolha" ]; then
    if [[ "$escolha" == "󰃢  LIMPAR TODO O HISTÓRICO" ]]; then
        cliphist wipe
        rm -rf "$THUMB_DIR"/*
        notify-send "Clipboard" "Histórico limpo com sucesso!"
        exit 0
    fi

    if [[ "$escolha" == "Imagem ("* ]]; then
        busca=$(echo "$escolha" | sed 's/Imagem (\(.*\))/\1/')
        cliphist list | grep -F "$busca" | head -n 1 | cliphist decode | wl-copy
    else
        cliphist list | grep -F "$escolha" | head -n 1 | cliphist decode | wl-copy
    fi
fi
