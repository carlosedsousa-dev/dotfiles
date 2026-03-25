#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"
ZSH_COMPLETIONS_DIR="$HOME/.zsh/completions"

# Pacotes comuns a todos os sistemas
COMMON_PACKAGES=(zsh stow curl git openssl ca-certificates)

# Pacotes específicos por gestor
APT_SPECIFIC=(libssl-dev)
DNF_SPECIFIC=(openssl-devel)
PKG_SPECIFIC=() # O Termux já inclui o necessário nos pacotes base

echo "Detectando sistema..."

if [ -n "$TERMUX_VERSION" ] || command -v pkg &> /dev/null; then
    PM="pkg"
    FINAL_PACKAGES=("${COMMON_PACKAGES[@]}" "${PKG_SPECIFIC[@]}")
elif command -v apt-get &> /dev/null; then
    PM="apt"
    FINAL_PACKAGES=("${COMMON_PACKAGES[@]}" "${APT_SPECIFIC[@]}")
elif command -v dnf &> /dev/null; then
    PM="dnf"
    FINAL_PACKAGES=("${COMMON_PACKAGES[@]}" "${DNF_SPECIFIC[@]}")
fi

echo "Instalando via $PM..."

if [ "$PM" == "pkg" ]; then
    pkg update && pkg install -y "${FINAL_PACKAGES[@]}"
elif [ "$PM" == "apt" ]; then
    sudo apt-get update -y && sudo apt-get install -y "${FINAL_PACKAGES[@]}"
    sudo update-ca-certificates
elif [ "$PM" == "dnf" ]; then
    sudo dnf install -y "${FINAL_PACKAGES[@]}"
    sudo update-ca-trust
fi

# Instalação do Mise
if ! command -v mise &> /dev/null; then
    echo "Instalando Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/share/mise/bin:$HOME/.local/bin:$PATH"
fi

# Autocomplete
mkdir -p "$ZSH_COMPLETIONS_DIR"
mise completion zsh > "$ZSH_COMPLETIONS_DIR/_mise"

# Instalação de Ferramentas
echo "Instalando ferramentas globais..."
# No Termux, se o Sigstore ainda falhar devido ao Kernel, 
# o script tentará instalar normalmente.
if ! mise install -y; then
    echo "Erro de verificação detetado. Tentando self-update..."
    mise self-update
    mise install -y
fi

# Antidote e Dotfiles
if [ ! -d "$ANTIDOTE_DIR" ]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

echo "Limpando conflitos e aplicando Stow..."
CLEANUP=(.config/antidote .zshrc .zsh_plugins.txt .aliases .bindkeys)
for item in "${CLEANUP[@]}"; do rm -rf "$HOME/$item"; done

cd "$DOTFILES_DIR" || exit
stow zsh
stow mise

# Troca de Shell
if [ "$(basename "$SHELL")" != "zsh" ]; then
    if [ "$PM" == "pkg" ]; then
        chsh -s zsh
    else
        sudo chsh -s "$(which zsh)" "$USER"
    fi
fi

echo "Setup concluído!"