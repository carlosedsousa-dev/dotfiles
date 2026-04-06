#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"
ZSH_COMPLETIONS_DIR="$HOME/.zsh/completions"

# Lista de pacotes para o Zypper
# O padrão 'devel_basis' garante o linker (cc) e ferramentas de build
PACKAGES=(
    zsh
    stow
    curl
    git
    pavucontrol
    kitty
    wofi
    openssl
    ca-certificates
    libopenssl-devel
    jetbrains-mono-fonts
    google-roboto-fonts
    swww
    cargo
)

STOW_MODULES=(
    zsh
    mise
    niri
    waybar
    kitty
    wofi
    matugen
    scripts
)

CLEANUP_LIST=(
    .config/antidote
    .zshrc
    .zsh_plugins.txt
    .aliases
    .bindkeys
    .config/kitty
    .config/niri/
    .config/waybar/
    .config/wofi/
)

CREATE_LIST=(
    "$HOME/Imagens/Wallpapers"
    "$HOME/Imagens/Screenshots"
    "$ZSH_COMPLETIONS_DIR"
)

# FUNÇÃO DE DETECÇÃO PARA ZYPPER
is_installed() {
    local pkg=$1
    rpm -q "$pkg" &>/dev/null
}

echo "Iniciando setup para openSUSE..."

# Verificação e Instalação
MISSING_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "Instalando pacotes ausentes via Zypper: ${MISSING_PACKAGES[*]}"
    sudo zypper install -y "${MISSING_PACKAGES[@]}"
    [ -x "$(command -v fc-cache)" ] && fc-cache -fv
else
    echo "Todos os pacotes base já estão instalados."
fi

# Limpeza e Pastas
echo "Limpando conflitos e criando pastas..."
for item in "${CLEANUP_LIST[@]}"; do rm -rf "$HOME/$item"; done
for item in "${CREATE_LIST[@]}"; do mkdir -p "$item"; done

# Mise (Gerenciador de Runtime)
if ! command -v mise &> /dev/null; then
    echo "Instalando Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/share/mise/bin:$HOME/.local/bin:$PATH"
fi
[ -d "$HOME/.local/share/mise/bin" ] && export PATH="$HOME/.local/share/mise/bin:$PATH"
command -v mise &> /dev/null && mise completion zsh > "$ZSH_COMPLETIONS_DIR/_mise"

# Antidote (Zsh Plugins)
if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "Instalando Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

# Rust e Matugen (Compilação)
if ! command -v matugen &> /dev/null; then
    echo "Compilando Matugen (isso pode demorar)..."
    cargo install matugen
fi

# Mise Provisioning
echo "Instalando ferramentas do Mise..."
mise install -y || (mise self-update && mise install -y)

# Shell padrão
[ "$(basename "$SHELL")" != "zsh" ] && sudo chsh -s "$(which zsh)" "$USER"

# Wallpaper e Cores Iniciais
echo "Configurando tema inicial..."
WALL_PATH="$HOME/Imagens/Wallpapers/gargantua-black.jpg"
if [ ! -f "$WALL_PATH" ]; then
    curl -L -A "Mozilla/5.0" "https://4kwallpapers.com/images/wallpapers/gargantua-black-3840x2160-11475.jpg" -o "$WALL_PATH"
fi

if command -v matugen &> /dev/null; then
    matugen image "$WALL_PATH" > /dev/null 2>&1
fi

if command -v swww &> /dev/null; then
    swww-daemon & sleep 1
    swww img "$WALL_PATH" --transition-type center > /dev/null 2>&1 || true
fi

# Stow
echo "Aplicando Dotfiles com Stow..."
cd "$DOTFILES_DIR" || exit
for module in "${STOW_MODULES[@]}"; do stow "$module"; done

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
echo "Setup openSUSE concluído com sucesso!"
