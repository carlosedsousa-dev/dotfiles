#!/bin/bash
# Setup único de sistema: flatpak overrides + xdg-terminal-exec + Cinnamon terminal.
# Executado uma vez pelo chezmoi (run_once).

# --- Flatpak: overrides globais (GPU, áudio, Wayland) ---
if command -v flatpak &>/dev/null; then
    if [ ! -f "$HOME/.local/share/flatpak/overrides/global" ]; then
        echo "Aplicando overrides globais do Flatpak..."
        flatpak override --user \
            --device=dri \
            --socket=pulseaudio \
            --socket=wayland \
            --socket=fallback-x11
        echo "Overrides do Flatpak aplicados."
    else
        echo "Overrides globais do Flatpak já existem, ignorando."
    fi
else
    echo "Flatpak não encontrado, ignorando overrides."
fi

# --- xdg-terminal-exec: wrapper para kitty ---
TERMINAL_BIN="/usr/local/bin/xdg-terminal-exec"
if [ ! -f "$TERMINAL_BIN" ]; then
    echo "Instalando xdg-terminal-exec (kitty)..."
    sudo tee "$TERMINAL_BIN" > /dev/null <<'WRAPPER'
#!/bin/bash
[ "$1" = "--" ] && shift
DIR="${1:-.}"
shift 2>/dev/null
[ -d "$DIR" ] && DIR="$(cd "$DIR" && pwd)"
exec kitty --directory "$DIR" "$@"
WRAPPER
    sudo chmod +x "$TERMINAL_BIN"
    echo "xdg-terminal-exec instalado."
else
    echo "xdg-terminal-exec já existe, ignorando."
fi

# --- Cinnamon: aponta terminal para xdg-terminal-exec ---
if command -v gsettings &>/dev/null; then
    CINNAMON_EXEC=$(gsettings get org.cinnamon.desktop.default-applications.terminal exec 2>/dev/null)
    if [ "$CINNAMON_EXEC" = "'gnome-terminal'" ] || [ "$CINNAMON_EXEC" = "'cinnamon-terminal'" ]; then
        echo "Configurando terminal do Cinnamon para xdg-terminal-exec..."
        gsettings set org.cinnamon.desktop.default-applications.terminal exec 'xdg-terminal-exec'
        gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg '--'
        echo "Terminal do Cinnamon configurado."
    else
        echo "Terminal do Cinnamon já configurado: $CINNAMON_EXEC"
    fi
fi
