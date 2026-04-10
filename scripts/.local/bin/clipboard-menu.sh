#!/bin/bash

# Garante o PATH
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Pasta para miniaturas
THUMB_DIR="/tmp/cliphist_thumbs"
mkdir -p "$THUMB_DIR"

# Função para limpar tudo (Texto e Imagem)
limpar_tudo() {
    cliphist wipe
    rm -rf "$THUMB_DIR"/*
    notify-send "Clipboard" "Histórico de texto e imagem limpo!"
}

# Lógica de execução baseada nos argumentos do Rofi
case "$1" in
    --text)
        # Tema igual ao launcher (Mod+D) - Força reset do tamanho dos ícones e padding
        echo -en "\0theme\x1fwindow { width: 800px; height: 500px; } mainbox { children: [ \"inputbar\", \"mode-switcher\", \"listview\" ]; } listview { columns: 1; lines: 8; spacing: 5px; scrollbar: false; } element { children: [ \"element-icon\", \"element-text\" ]; orientation: horizontal; padding: 8px; } element-icon { size: 24px; expand: false; } element-text { enabled: true; horizontal-align: 0.0; }\n"
        if [ -n "$2" ]; then
            if [[ "$2" == *"Limpar Tudo"* ]]; then
                limpar_tudo
            else
                cliphist list | grep -v "\[\[ binary data" | grep -F "$2" | head -n 1 | cliphist decode | wl-copy
            fi
            exit 0
        fi
        cliphist list | grep -v "\[\[ binary data" | cut -f2-
        echo -en "󰃢  Limpar Tudo\0icon\x1fedit-clear-all\n"
        ;;

    --image)
        # Tema com largura de 800px e miniaturas ampliadas para 360px
        echo -en "\0theme\x1fwindow { width: 800px; height: 600px; } mainbox { children: [ \"inputbar\", \"mode-switcher\", \"listview\", \"message\" ]; } listview { columns: 2; lines: 3; spacing: 20px; scrollbar: false; } element { children: [ \"element-icon\" ]; padding: 10px; } element-icon { size: 360px; border-radius: 12px; horizontal-align: 0.5; vertical-align: 0.5; expand: true; } element-text { enabled: false; }\n"
        if [ -n "$2" ]; then
            if [[ "$2" == *"Limpar Tudo"* ]]; then
                limpar_tudo
            else
                # Busca pelo conteúdo exato
                cliphist list | grep "\[\[ binary data" | grep -F "$2" | head -n 1 | cliphist decode | wl-copy
            fi
            exit 0
        fi
        cliphist list | grep "\[\[ binary data" | while read -r line; do
            id=$(echo "$line" | cut -f1)
            content=$(echo "$line" | cut -f2-)
            
            thumb="$THUMB_DIR/${id}.png"
            if [ ! -f "$thumb" ]; then
                cliphist decode "$id" | magick - -strip -resize 280x150^ -gravity center -extent 280x150 "$thumb" 2>/dev/null
            fi
            echo -en "$content\0icon\x1f$thumb\n"
        done
        echo -en "󰃢  Limpar Tudo\0icon\x1fedit-clear-all\n"
        ;;

    --clear)
        # Menu de limpeza - Força estilo de texto simples
        echo -en "\0theme\x1fwindow { width: 800px; height: 250px; } mainbox { children: [ \"inputbar\", \"mode-switcher\", \"listview\" ]; } listview { columns: 1; lines: 1; } element { children: [ \"element-icon\", \"element-text\" ]; padding: 8px; } element-icon { size: 24px; expand: false; } element-text { enabled: true; horizontal-align: 0.5; }\n"
        if [ -n "$2" ]; then
            limpar_tudo
            exit 0
        fi
        echo -en "󰃢  CONFIRMAR LIMPEZA TOTAL\0icon\x1fedit-clear-all\n"
        ;;

    *)
        # Execução inicial: Define os 3 modos (Texto, Imagem, Limpar)
        # kb-row-last "Shift+Down" faz o Shift+Seta Baixo ir direto para o "Limpar Tudo" no fim da lista
        exec rofi -show "Texto 󰅍" \
            -modi "Texto 󰅍:$0 --text,Imagens 󰏆:$0 --image,Limpar 󰃢:$0 --clear" \
            -kb-row-last "Shift+Down" \
            -mesg "󰃢  Shift+Down para selecionar Limpar Tudo" \
            -theme "$HOME/.config/rofi/launcher.rasi" \
            -theme-str '
                message { margin: 10px 0px 0px 0px; padding: 10px; border: 2px; border-radius: 12px; border-color: @border-colour; background-color: @alternate-background; }
                textbox { text-color: @foreground-colour; horizontal-align: 0.5; }
                textbox-prompt-colon { str: "󰅍"; }'
        ;;
esac
