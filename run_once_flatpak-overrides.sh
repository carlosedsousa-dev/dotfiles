#!/bin/bash

# Aplica overrides globais para flatpaks terem acesso a GPU, áudio e Wayland.
# Executado uma vez pelo chezmoi (run_once).
# Câmera vai pelo portal (PermissionStore), não por override.

if ! command -v flatpak &>/dev/null; then
    echo "Flatpak não encontrado, ignorando overrides."
    exit 0
fi

if [ -f "$HOME/.local/share/flatpak/overrides/global" ]; then
    echo "Overrides globais do Flatpak já existem, ignorando."
    exit 0
fi

echo "Aplicando overrides globais do Flatpak..."
flatpak override --user \
    --device=dri \
    --socket=pulseaudio \
    --socket=wayland \
    --socket=fallback-x11

echo "Overrides do Flatpak aplicados com sucesso."
