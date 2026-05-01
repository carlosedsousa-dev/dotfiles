#!/usr/bin/env bash

# Verifica se o cliphist está instalado
if ! command -v cliphist &> /dev/null; then
    notify-send "Erro" "cliphist não está instalado."
    exit 1
fi

MODE="$1"
SELECTION="$2"

case "$MODE" in
    text)
        if [ -z "$SELECTION" ]; then
            # Lista textos, remove IDs e ignora qualquer coisa que comece com [[ binary
            # O grep -a garante que trate tudo como texto, -v inverte para pegar apenas o que NÃO é imagem
            LIST=$(cliphist list | grep -a -vE '^[0-9]+[[:space:]]+\[\[[[:space:]]*binary' | sed 's/^[0-9]*[[:space:]]*//')
            if [ -z "$LIST" ]; then
                echo "󱄽 Clipboard de texto vazio..."
            else
                echo "$LIST"
            fi
        else
            # Busca a linha original que termina com o conteúdo selecionado após um espaço/tab
            cliphist list | grep -a -m 1 -F "$SELECTION" | cliphist decode | wl-copy
            notify-send "Clipboard" "Texto copiado."
        fi
        ;;
    img)
        THUMB_DIR="/tmp/cliphist_thumbs"
        mkdir -p "$THUMB_DIR"
        if [ -z "$SELECTION" ]; then
            # Lista apenas o que for marcado como binary, gera miniatura e formata para o Rofi
            cliphist list | grep -a -E '^[0-9]+[[:space:]]+\[\[[[:space:]]*binary' | while read -r line; do
                id=$(echo "$line" | awk '{print $1}')
                desc=$(echo "$line" | sed 's/^[0-9]*[[:space:]]*//')
                thumb="$THUMB_DIR/${id}.png"
                
                # Gera miniatura se não existir
                if [ ! -f "$thumb" ]; then
                    echo "$line" | cliphist decode | magick - -strip -resize 300x200^ -gravity center -extent 300x200 "$thumb" 2>/dev/null
                fi
                
                # Formato Rofi: Descrição\0icon\x1fCaminho
                echo -en "$desc\0icon\x1f$thumb\n"
            done
        else
            # Recupera e decodifica a imagem
            # Busca pela string de descrição da imagem (ex: [[ binary data... ]])
            cliphist list | grep -a -m 1 -F "$SELECTION" | cliphist decode | wl-copy
            notify-send "Clipboard" "Imagem copiada."
        fi
        ;;
esac
