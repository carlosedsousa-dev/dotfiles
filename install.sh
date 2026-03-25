#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"
ZSH_COMPLETIONS_DIR="$HOME/.zsh/completions"

# Configuração de Listas (Modularidade)
# Pacotes universais
PACKAGES=(
    zsh
    stow
    curl
    git
    openssl
    ca-certificates
    eza
)

# Pacotes específico do APT
APT_SPECIFIC=(
    libssl-dev
)

# Pacotes específico do DNF
DNF_SPECIFIC=(
    openssl-devel
)

# Lista de módulos do Stow para aplicar
STOW_MODULES=(
    zsh
    mise
)

# Lista de arquivos para limpar antes do Stow
CLEANUP_LIST=(
    .config/antidote 
    .zshrc 
    .zsh_plugins.txt 
    .aliases 
    .bindkeys
)

echo "Detectando sistema..."

if [ -n "$TERMUX_VERSION" ] || command -v pkg &> /dev/null; then
    PM="pkg"
    FINAL_PACKAGES=("${PACKAGES[@]}")
elif command -v apt-get &> /dev/null; then
    PM="apt"
    FINAL_PACKAGES=("${PACKAGES[@]}" "${APT_SPECIFIC[@]}")
elif command -v dnf &> /dev/null; then
    PM="dnf"
    FINAL_PACKAGES=("${PACKAGES[@]}" "${DNF_SPECIFIC[@]}")
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
if command -v mise &> /dev/null; then
    mise completion zsh > "$ZSH_COMPLETIONS_DIR/_mise"
fi
# Antidote
if [ ! -d "$ANTIDOTE_DIR" ]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

echo "Limpando conflitos..."
for item in "${CLEANUP_LIST[@]}"; do 
    rm -rf "$HOME/$item"
done

echo "Aplicando módulos do Stow..."
cd "$DOTFILES_DIR" || exit
for module in "${STOW_MODULES[@]}"; do 
    stow "$module"
done

# Instalação de Ferramentas
echo "Instalando ferramentas globais..."
if ! mise install -y; then
    echo "Erro de verificação detetado. Tentando self-update..."
    mise self-update && mise install -y
fi

# Troca de Shell
if [ "$(basename "$SHELL")" != "zsh" ]; then
    if [ "$PM" == "pkg" ]; then
        chsh -s zsh
    else
        sudo chsh -s "$(which zsh)" "$USER"
    fi
fi

echo "Setup concluído com sucesso!"
