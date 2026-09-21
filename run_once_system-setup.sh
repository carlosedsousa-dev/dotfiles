#!/bin/bash
# Setup único de sistema: flatpak overrides + xdg-terminal-exec.
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
