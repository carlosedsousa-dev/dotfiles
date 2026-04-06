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
    pavucontrol
    kitty
    wofi

    # Adição de compatibilidades com tipos de chaves SSH usadas pelo Mise
    openssl
    ca-certificates
)

# Pacotes específico do APT
APT_SPECIFIC=(
    build-essential
    libssl-dev
    fonts-jetbrains-mono
    fonts-roboto
)

# Pacotes específico do DNF
DNF_SPECIFIC=(
    @development-tools
    openssl-devel
    jetbrains-mono-fonts
    google-roboto-fonts
    symbols-only-nerd-fonts
)

# Pacotes específico do Zypper
ZYPPER_SPECIFIC=(
    -t pattern devel_basis
    libopenssl-devel
    jetbrains-mono-fonts
    google-roboto-fonts
)

# Lista de módulos do Stow para aplicar
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

# Lista de arquivos para limpar antes do Stow
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
    $HOME/Imagens/Wallpapers
    $HOME/Imagens/Screenshots
    $ZSH_COMPLETIONS_DIR
)

echo "Detectando sistema..."

if command -v apt-get &> /dev/null; then
    PM="apt"
    FINAL_PACKAGES=("${PACKAGES[@]}" "${APT_SPECIFIC[@]}")
elif command -v dnf &> /dev/null; then
    PM="dnf"
    FINAL_PACKAGES=("${PACKAGES[@]}" "${DNF_SPECIFIC[@]}")
elif command -v zypper &> /dev/null; then
    PM="zypper"
    FINAL_PACKAGES=("${PACKAGES[@]}" "${ZYPPER_SPECIFIC[@]}")
fi

# Função de verificação de existência do pacote
is_installed() {
    local pkg=$1
    case "$PM" in
        apt) dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" ;;
        dnf|zypper) rpm -q "$pkg" &>/dev/null ;;
    esac
}

echo "Verificando pacotes necessários via $PM..."
MISSING_PACKAGES=()
for pkg in "${FINAL_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "Instalando pacotes ausentes: ${MISSING_PACKAGES[*]}"
    if [ "$PM" == "apt" ]; then
        sudo apt-get update -y && sudo apt-get install -y "${MISSING_PACKAGES[@]}"
        sudo update-ca-certificates
    elif [ "$PM" == "dnf" ]; then
        sudo dnf install -y "${MISSING_PACKAGES[@]}"
        sudo update-ca-trust
    elif [ "$PM" == "zypper" ]; then
        sudo zypper install -y "${MISSING_PACKAGES[@]}"
    fi
    
    # Atualiza o cache de fontes caso novas fontes tenham sido instaladas
    if command -v fc-cache &> /dev/null; then
        echo "Atualizando cache de fontes..."
        fc-cache -fv
    fi
else
    echo "Todos os pacotes base já estão instalados."
fi

echo "Limpando conflitos de arquivos antigos..."
for item in "${CLEANUP_LIST[@]}"; do 
    rm -rf "$HOME/$item"
done

echo "Criando pastas necessárias..."
for item in "${CREATE_LIST[@]}"; do 
    mkdir -p "$item"
done

# Instalação do Mise (Gerenciador de Runtime)
if ! command -v mise &> /dev/null; then
    echo "Instalando Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/share/mise/bin:$HOME/.local/bin:$PATH"
fi

if command -v mise &> /dev/null; then
    mise completion zsh > "$ZSH_COMPLETIONS_DIR/_mise"
fi

# Antidote (Gerenciador de Plugins Zsh)
if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "Instalando Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

echo "Atenção: A instalação do Rust e do Matugen exige compilação e pode demorar de 5 a 15 minutos no seu hardware."
read -p "Deseja continuar com a instalação agora? (s/N): " confirmacao

if [[ "$confirmacao" =~ ^[Ss]$ ]]; then
    # Instalando cargo
    if ! command -v cargo &> /dev/null; then
        echo "Instalando Rust/Cargo..."
        # Adicionado --no-modify-path para evitar a criação do .zshenv
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env"
    fi

    # Instalando matugen
    if ! command -v matugen &> /dev/null; then
        echo "Instalando Matugen via Cargo (Compilando...)..."
        cargo install matugen
    fi
else
    echo "Instalação do Rust/Matugen pulada pelo usuário."
fi

echo "Aplicando módulos do Stow..."
cd "$DOTFILES_DIR" || exit
for module in "${STOW_MODULES[@]}"; do 
    stow "$module"
done

# Instalação de Ferramentas via Mise (conforme mise.toml)
echo "Provisionando ferramentas globais via Mise..."
if ! mise install -y; then
    echo "Erro de verificação detectado. Tentando self-update..."
    mise self-update && mise install -y
fi

# Troca de Shell para Zsh
if [ "$(basename "$SHELL")" != "zsh" ]; then
    echo "Alterando shell padrão para zsh..."
    sudo chsh -s "$(which zsh)" "$USER"
fi

# Garante que o ambiente do Cargo esteja ativo para a sessão atual
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Garante que os binários locais estejam no PATH
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

echo "Setup concluído com sucesso!"
