# Dotfiles

Minhas configurações de ambiente, automatizadas para Linux (Ubuntu/Debian e Fedora e seus derivados).

## 🚀 Instalação

Para configurar seu ambiente do zero, basta rodar o script de instalação na raiz do repositório:

```bash
git clone https://github.com/carlosedsousa/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## 🛠️ Como funciona

Este repositório utiliza:

* **GNU Stow:** Para gerenciar os links simbólicos das configurações.
* **Antidote:** Gerenciador de plugins para Zsh (leve e rápido).
* **Scripts de Automação:** Instaladores inteligentes que detectam o gerenciador de pacotes (APT/DNF) e preparam o ambiente.

## 🔄 Atualização

Sempre que fizer alterações no repositório, basta rodar o script de atualização no seu terminal:

```bash
dotup
```

## 📂 Estrutura

* `zsh/`: Configurações do Zsh (`.zshrc`, plugins).
* `install.sh`: Script de instalação automática.
* `update.sh`: Script de atualização.

---
