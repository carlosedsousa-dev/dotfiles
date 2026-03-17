# Dotfiles

Minhas configurações de ambiente, automatizadas para Linux (Ubuntu/Debian e Fedora e seus derivados).

## 🚀 Instalação

Para configurar seu ambiente do zero, basta rodar o script de instalação na raiz do repositório:

```bash
git clone https://github.com/carlosedsousa-dev/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## 🛠️ Como funciona

Este repositório utiliza:

* **[GNU Stow](https://www.gnu.org/software/stow/):** Para gerenciar os links simbólicos das configurações.
* **[Antidote](https://antidote.sh/):** Gerenciador de plugins para Zsh (leve e rápido).
* **[Mise en Place](https://mise.jdx.dev/):** Gerenciador de runtimes e ferramentas (instalado via script).
* **Scripts de Automação:** Instaladores inteligentes que detectam o gerenciador de pacotes (APT/DNF) e preparam o ambiente.

## ⚡ Aliases Principais

Os atalhos de produtividade estão centralizados em [zsh/.aliases.zsh](./zsh/.aliases.zsh). Eles cobrem:

* **Git Essentials:** Fluxo completo de status, add, commit, push/pull e logs gráficos.
* **Dotfiles Management:** Atalhos dot (navegar), edot (editar) e szsh (recarregar as configurações).
* **Navegação:** Atalhos rápidos para movimentação entre diretórios frequentes.

## 🔄 Atualização

Sempre que fizer alterações no repositório, basta rodar o script de atualização no seu terminal:

```bash
dotup
```

## 📂 Estrutura

* `zsh/`: Configurações do Zsh (`.zshrc`, plugins).
    * `.aliases.zsh`: Todos os meus atalhos e funções.
* `install.sh`: Script de instalação automática (inclui setup do Mise).
* `update.sh`: Script de atualização.
