# Dotfiles

Minhas configurações de ambiente automatizadas para Linux (Ubuntu/Debian, Fedora, OpenSUSE e derivados), com suporte a perfis de **Desktop** e **Server**.

> **Por que este repositório existe?**
> Este projeto surgiu da necessidade de manter consistência e rapidez no setup ao transitar entre diferentes máquinas, garantindo que meu fluxo de trabalho seja idêntico em qualquer lugar, seja no meu laptop principal ou em um servidor remoto/homelab via SSH.

## 🌿 Escolha seu Perfil

Este repositório possui três branches principais para atender diferentes cenários:

* **`niri` (Wayland Desktop):** Configuração otimizada para o compositor Niri, gerenciada de forma moderna via **chezmoi**.
* **`core` (Desktop):** Setup completo com todas as ferramentas de desenvolvimento, gerenciado via **GNU Stow**.
* **`server` (Minimal):** Versão enxuta focada em performance e estabilidade para servidores, gerenciada via **GNU Stow**.

## 🚀 Instalação

Para configurar seu ambiente, escolha o método correspondente à branch desejada:

### 🌌 No Desktop (Compositor Niri — via chezmoi)
Certifique-se de ter o `chezmoi` instalado e execute:
```bash
chezmoi init --apply --branch niri carlosedsousa-dev

```

### 💻 No Desktop (Perfil Completo / Outros WMs — via Stow)

```bash
git clone -b core [https://github.com/carlosedsousa-dev/dotfiles.git](https://github.com/carlosedsousa-dev/dotfiles.git) ~/dotfiles
cd ~/dotfiles
./install.sh

```

### 🌐 No Servidor (Perfil Minimalista — via Stow)

```bash
git clone -b server [https://github.com/carlosedsousa-dev/dotfiles.git](https://github.com/carlosedsousa-dev/dotfiles.git) ~/dotfiles
cd ~/dotfiles
./install.sh

```

⚠️ **Atenção:** Os scripts de instalação e automações detectam o gerenciador de pacotes (APT/DNF/Zypper) para aplicar as configurações corretas. Na branch `niri`, utilize os scripts nativos do chezmoi (`run_once_*`) para pós-instalação.

## 🛠️ Como funciona

Este ecossistema utiliza ferramentas consagradas para manter a ordem:

* **[chezmoi](https://www.chezmoi.io/):** Gerencia os dotfiles de forma declarativa (exclusivo da branch `niri`).
* **[GNU Stow](https://www.gnu.org/software/stow/):** Gerencia os links simbólicos de forma tradicional nas branches `core` e `server`.
* **[Mise en Place](https://mise.jdx.dev/):** Gerenciador de runtimes e ferramentas.
* **[Antidote](https://antidote.sh/):** Gerenciador de plugins Zsh de alta performance.

## ⚡ Aliases Principais

Os atalhos de produtividade estão centralizados em `zsh/.aliases.zsh` (ou gerenciados via chezmoi na branch correspondente):

* **Git Essentials:** Fluxo completo (status, commit, logs gráficos).
* **Dotfiles Management:** Atalhos `dot`/`edot` (para Stow) ou comandos `chezmoi` dependendo do perfil ativo.
* **Navegação & Server:** Atalhos rápidos para monitoramento de recursos e movimentação entre diretórios.
