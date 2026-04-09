#!/bin/bash

# Caminhos
DOTFILES_DIR="$HOME/dotfiles"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.local/share/mise/bin:$PATH"

echo "Iniciando Atualização de Dotfiles"

# Sincronizar Repositório
echo "Puxando mudanças do Git..."
cd "$DOTFILES_DIR" || exit
git pull origin $(git branch --show-current)

# Atualizar Módulos do Stow
echo "Recriando links simbólicos (Restow)..."
STOW_MODULES=(zsh mise niri waybar kitty rofi matugen scripts)
for module in "${STOW_MODULES[@]}"; do 
    stow -R "$module"
done

# Atualizar Ferramentas do Mise
if command -v mise &> /dev/null; then
    echo "Atualizando ferramentas do Mise..."
    mise upgrade
    mise install -y
fi

# Atualizar Plugins do Zsh (Antidote)
if [ -f "$HOME/.zsh_plugins.txt" ]; then
    echo "Atualizando plugins do Zsh..."
    # Se você usa antidote, ele geralmente atualiza ao carregar o shell, 
    # mas você pode forçar aqui se quiser.
fi

# Atualizar Matugen (Opcional - demora no Celeron)
read -p "Deseja verificar atualizações para o Matugen/Cargo? (s/N): " up_cargo
if [[ "$up_cargo" =~ ^[Ss]$ ]]; then
    echo "Atualizando Matugen..."
    cargo install matugen # O cargo reinstala apenas se houver versão nova
fi

echo "Atualização concluída com sucesso!"