#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"

# Lista de dependências para o sistema
PACKAGES=(
    zsh
    stow
)

# Lista de arquivos/pastas para limpar antes do stow
CLEANUP_LIST=(
    "$HOME/.zshrc"
    "$HOME/.config/antidote"
)

# Lista de módulos do stow
STOW_MODULES=(
    zsh
)

echo "Verificando dependências..."

MISSING_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "Instalando pacotes ausentes: ${MISSING_PACKAGES[*]}"
    # Suporte a Termux, APT e DNF
    if command -v pkg &> /dev/null; then
        pkg update && pkg install -y "${MISSING_PACKAGES[@]}"
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "${MISSING_PACKAGES[@]}"
    fi
else
    echo "Todas as dependências já estão instaladas."
fi

if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "Clonando Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

echo "Limpando arquivos antigos para evitar conflitos..."
for item in "${CLEANUP_LIST[@]}"; do
    rm -rf "$item"
done

echo "Aplicando módulos do Stow..."
cd "$DOTFILES_DIR"
for module in "${STOW_MODULES[@]}"; do
    stow "$module"
done

# Checagem do shell padrão e alteração para zsh caso necessário
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    if [ -n "$TERMUX_VERSION" ]; then
        echo "Configurando ZSH no Termux..."
        echo "chsh -s zsh"
        chsh -s zsh
    else
        echo "Alterando shell padrão..."
        sudo chsh -s "$(which zsh)" "$USER"
    fi
    echo "Por favor, reinicie o terminal."
fi

echo "Configuração concluída!"
