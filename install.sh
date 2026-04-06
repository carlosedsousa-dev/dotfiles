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
    openssl
    ca-certificates
)

# Pacotes específico do DNF (Fedora)
DNF_SPECIFIC=(
    @development-tools
    openssl-devel
    jetbrains-mono-fonts
    google-roboto-fonts
    symbols-only-nerd-fonts
    dnf-plugins-core
)

# Pacotes específico do Zypper (openSUSE)
ZYPPER_SPECIFIC=(
    -t pattern devel_basis
    libopenssl-devel
    jetbrains-mono-fonts
    google-roboto-fonts
    swww
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

if command -v dnf &> /dev/null; then
    PM="dnf"
    FINAL_PACKAGES=("${PACKAGES[@]}" "${DNF_SPECIFIC[@]}")
elif command -v zypper &> /dev/null; then
    PM="zypper"
    FINAL_PACKAGES=("${PACKAGES[@]}" "${ZYPPER_SPECIFIC[@]}")
else
    echo "Sistema não suportado (apenas Fedora ou openSUSE)."
    exit 1
fi

# Função de verificação de existência do pacote
is_installed() {
    local pkg=$1
    # Ignora padrões do zypper na checagem simples de RPM
    [[ "$pkg" == "-t"* ]] && return 1
    rpm -q "$pkg" &>/dev/null
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
    if [ "$PM" == "dnf" ]; then
        sudo dnf install -y "${MISSING_PACKAGES[@]}"
        
        # Instalação do swww via COPR no Fedora
        sudo dnf copr enable -y solopasha/hyprland
        sudo dnf install -y swww
        
        sudo update-ca-trust
    elif [ "$PM" == "zypper" ]; then
        sudo zypper install -y "${MISSING_PACKAGES[@]}"
    fi
    
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

# Instalação do Mise
if ! command -v mise &> /dev/null; then
    echo "Instalando Mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/share/mise/bin:$HOME/.local/bin:$PATH"
fi

if command -v mise &> /dev/null; then
    mise completion zsh > "$ZSH_COMPLETIONS_DIR/_mise"
fi

# Antidote
if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "Instalando Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

if ! command -v cargo &> /dev/null || ! command -v matugen &> /dev/null; then
    echo "Atenção: A instalação do Rust, Matugen e swww exige compilação."
    read -p "Deseja continuar com a instalação agora? (s/N): " confirmacao
fi

if [[ "$confirmacao" =~ ^[Ss]$ ]]; then
    if ! command -v cargo &> /dev/null; then
        echo "Instalando Rust/Cargo..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env"
    fi

    if ! command -v matugen &> /dev/null; then
        echo "Instalando Matugen via Cargo..."
        cargo install matugen
    fi
fi

[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

echo "Provisionando ferramentas globais via Mise..."
if ! mise install -y; then
    mise self-update && mise install -y
fi

if [ "$(basename "$SHELL")" != "zsh" ]; then
    echo "Alterando shell padrão para zsh..."
    sudo chsh -s "$(which zsh)" "$USER"
fi

echo "Configurando cores iniciais..."
if [ -z "$(ls -A "$HOME/Imagens/Wallpapers")" ]; then
    echo "Baixando wallpaper padrão..."
    curl -L -A "Mozilla/5.0" "https://4kwallpapers.com/images/wallpapers/gargantua-black-3840x2160-11475.jpg" -o "$HOME/Imagens/Wallpapers/gargantua-black.jpg"
fi

if [ -f "$HOME/Imagens/Wallpapers/gargantua-black.jpg" ] && command -v matugen &> /dev/null; then
    matugen image "$HOME/Imagens/Wallpapers/gargantua-black.jpg" > /dev/null 2>&1
fi

if command -v swww &> /dev/null; then
    swww img "$HOME/Imagens/Wallpapers/gargantua-black.jpg" > /dev/null 2>&1 || true
fi

echo "Aplicando módulos do Stow..."
cd "$DOTFILES_DIR" || exit
for module in "${STOW_MODULES[@]}"; do 
    stow "$module"
done

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
echo "Setup concluído com sucesso!"
