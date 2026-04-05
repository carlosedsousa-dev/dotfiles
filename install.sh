#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"

# Lista de dependências universais para o sistema
PACKAGES=(
    zsh
    stow
    curl
    git
    openssl
    ca-certificates
)

# Lista de módulos do stow para aplicar (apenas essencial)
STOW_MODULES=(
    zsh
)

# Lista de arquivos/pastas para limpar antes do stow
CLEANUP_LIST=(
    .config/antidote
    .zshrc
    .zsh_plugins.txt
    .aliases
    .bindkeys
)

echo "Detectando gerenciador de pacotes..."

if [ -n "$TERMUX_VERSION" ] || command -v pkg &> /dev/null; then
    PM="pkg"
elif command -v apt-get &> /dev/null; then
    PM="apt"
elif command -v dnf &> /dev/null; then
    PM="dnf"
elif command -v zypper &> /dev/null; then
    PM="zypper"
fi

# Função de verificação de existência do pacote (idempotência)
is_installed() {
    local pkg=$1
    case "$PM" in
        pkg) pkg list-installed "$pkg" &>/dev/null ;;
        apt) dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" ;;
        dnf|zypper) rpm -q "$pkg" &>/dev/null ;;
    esac
}

echo "Verificando dependências via $PM..."
MISSING_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "Instalando pacotes ausentes: ${MISSING_PACKAGES[*]}"
    if [ "$PM" == "pkg" ]; then
        pkg update && pkg install -y "${MISSING_PACKAGES[@]}"
    elif [ "$PM" == "apt" ]; then
        sudo apt-get update -y && sudo apt-get install -y "${MISSING_PACKAGES[@]}"
        sudo update-ca-certificates
    elif [ "$PM" == "dnf" ]; then
        sudo dnf install -y "${MISSING_PACKAGES[@]}"
        sudo update-ca-trust
    elif [ "$PM" == "zypper" ]; then
        sudo zypper install -y "${MISSING_PACKAGES[@]}"
    fi
else
    echo "Todas as dependências do sistema já estão instaladas."
fi

# Configuração do Antidote (Plugin Manager)
if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "Provisionando Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

echo "Limpando conflitos de arquivos antigos..."
for item in "${CLEANUP_LIST[@]}"; do 
    rm -rf "$HOME/$item"
done

echo "Aplicando módulos do Stow..."
cd "$DOTFILES_DIR" || exit
for module in "${STOW_MODULES[@]}"; do 
    stow "$module"
done

# Troca de Shell para Zsh
if [ "$(basename "$SHELL")" != "zsh" ]; then
    echo "Alterando shell padrão para zsh..."
    if [ "$PM" == "pkg" ]; then
        chsh -s zsh
    else
        sudo chsh -s "$(which zsh)" "$USER"
    fi
fi

echo "Setup de servidor concluído com sucesso!"
