#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"

# Lista de dependências para o sistema
PACKAGES=(
    zsh
    stow
    curl
    git
)

# Lista de arquivos/pastas para limpar antes do stow
CLEANUP_LIST=(
    "$HOME/.config/antidote"
    "$HOME/.zshrc"
    "$HOME/.zsh_plugins.txt"
    "$HOME/.aliases"
    "$HOME/.bindkeys"
)

# Lista de módulos do stow
STOW_MODULES=(
    zsh
)

echo "Verificando dependências do sistema..."

MISSING_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "Instalando pacotes ausentes: ${MISSING_PACKAGES[*]}"
    if command -v pkg &> /dev/null; then
        pkg update && pkg install -y "${MISSING_PACKAGES[@]}"
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "${MISSING_PACKAGES[@]}"
    fi
else
    echo "Todas as dependências do sistema já estão instaladas."
fi

# Configuração do Antidote
if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "Clonando Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

echo "Limpando arquivos antigos para evitar conflitos..."
for item in "${CLEANUP_LIST[@]}"; do
    rm -rf "$item"
done

echo "Aplicando módulos do Stow..."
cd "$DOTFILES_DIR" || exit
for module in "${STOW_MODULES[@]}"; do
    stow "$module"
done

# Troca de Shell
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo "Alterando shell padrão para ZSH..."
    if [ -n "$TERMUX_VERSION" ]; then
        chsh -s zsh
    else
        sudo chsh -s "$(which zsh)" "$USER"
    fi
    echo "Shell alterado. Por favor, reinicie o terminal após o término."
fi

echo "Configuração concluída com sucesso!"
