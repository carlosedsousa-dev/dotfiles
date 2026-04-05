# Dotfiles

Minhas configurações de ambiente automatizadas para Linux (Ubuntu/Debian, Fedora, OpenSUSE e derivados), agora com suporte a perfis de **Desktop** e **Server**.

> **Por que este repositório existe?** > Este projeto surgiu da necessidade de manter consistência e rapidez no setup ao transitar entre diferentes máquinas, garantindo que meu fluxo de trabalho seja idêntico em qualquer lugar, seja no meu laptop principal ou em um servidor remoto/homelab via SSH.

## 🌿 Escolha seu Perfil

Este repositório possui duas branches principais para atender diferentes cenários:

* **`core` (Desktop):** Setup completo com todas as ferramentas de desenvolvimento, além de conter tudo do server.
* **`server` (Minimal):** Versão enxuta focada em performance e estabilidade para servidores, contendo apenas o essencial.

## 🚀 Instalação

Para configurar seu ambiente, escolha a branch e rode o script:

### No Desktop (Perfil Completo)
```bash
git clone -b core https://github.com/carlosedsousa-dev/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### No Servidor (Perfil Minimalista)
```bash
git clone -b server https://github.com/carlosedsousa-dev/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

⚠️ **Atenção:** O script `install.sh` detecta automaticamente as dependências necessárias. No perfil `core`, ele instala gerenciadores de runtime (Mise) e plugins de shell. No perfil `server`, ele prioriza ferramentas leves.

## 🛠️ Como funciona

Este ecossistema utiliza ferramentas consagradas para manter a ordem:

* **[GNU Stow](https://www.gnu.org/software/stow/):** Gerencia os links simbólicos das configurações de forma não destrutiva.
* **[Mise en Place](https://mise.jdx.dev/):** Gerenciador de runtimes e ferramentas (focado em produtividade na `main`).
* **[Antidote](https://antidote.sh/):** Gerenciador de plugins Zsh de alta performance.
* **Detecção Inteligente:** Scripts que identificam o gerenciador de pacotes (APT/DNF/Zypper) e o ambiente para aplicar as configurações corretas.

## ⚡ Aliases Principais

Os atalhos de produtividade estão centralizados em `zsh/.aliases.zsh`:

* **Git Essentials:** Fluxo completo (status, commit, logs gráficos).
* **Dotfiles Management:** Atalhos `dot` (navegar), `edot` (editar) e `szsh` (recarregar).
* **Navegação & Server:** Atalhos rápidos para monitoramento de recursos e movimentação entre diretórios.

## 📂 Estrutura do Projeto

* `zsh/`: Configurações do shell, plugins e o arquivo `.aliases.zsh`.
* `install.sh`: Script de instalação inteligente.
