# 🚀 Dotfiles: Core Architecture

Um ecossistema automatizado para provisionamento de ambientes Unix-like, focado em produtividade e consistência através de diferentes distribuições Linux e Termux.

## 🛠️ Stack Tecnológica

| Ferramenta | Função |
| :--- | :--- |
| **[Mise](https://mise.jdx.dev/)** | Polyglot runtime manager (alternativa moderna ao asdf). Gerencia versões de Node, Python, Go, etc. |
| **[Chezmoi](https://www.chezmoi.io/)** | Gerenciador de dotfiles com template, criptografia e idempotência nativa. |
| **[Antidote](https://getantidote.github.io/)** | Gerenciador de plugins Zsh ultra-rápido baseado em clones nativos. |
| **[Eza](https://github.com/eza-community/eza)** | Substituto moderno e colorido para o comando `ls`. |
| **Zsh** | Shell principal com integração de plugins e aliases otimizados. |

## ⚙️ Instalação Inteligente

O `run_once_install.sh` (chezmoi) opera com detecção dinâmica de ambiente e gerenciamento de estado:

1.  **Detecção de PM:** Suporte nativo para `APT` (Debian/Ubuntu), `DNF` (Fedora), `Zypper` (OpenSUSE) e `PKG` (Termux).
2.  **Idempotência:** Antes de cada instalação, o script verifica via `dpkg`, `rpm` ou `pkg list` se o pacote já existe, evitando chamadas desnecessárias ao sudo e consumo de banda.
3.  **Bootstrap Automático:** Instala automaticamente o `Mise` e `Antidote` caso não estejam presentes.
4.  **Aplicação via Chezmoi:** O Chezmoi gerencia os dotfiles, aplicando templates, resolvendo conflitos e garantindo idempotência com `chezmoi apply`.
5.  **Provisionamento Global:** Após o setup base, o `Mise` provisiona todas as ferramentas definidas no `mise.toml`.

## 📂 Organização Chezmoi

As configurações seguem a convenção de prefixos do Chezmoi:

*   `dot_zshrc` → `~/.zshrc`
*   `dot_aliases.zsh` → `~/.aliases.zsh`
*   `dot_bindkeys.zsh` → `~/.bindkeys.zsh`
*   `dot_zsh_plugins.txt` → `~/.zsh_plugins.txt`
*   `dot_config/mise/mise.toml` → `~/.config/mise/mise.toml`
*   `dot_config/xdg-desktop-portal/niri-portals.conf` → `~/.config/xdg-desktop-portal/niri-portals.conf`
*   `dot_config/environment.d/90-wayland.conf` → `~/.config/environment.d/90-wayland.conf`
*   `dot_config/env/private_secrets.env.tmpl` → `~/.config/env/secrets.env` (gerado)
*   `dot_config/systemd/user/gnome-keyring-daemon.service.d/override.conf` → override do GNOME Keyring
*   `dot_ssh/modify_config` → aplicado como modify do `~/.ssh/config`
*   `run_once_install.sh` → executado uma vez na primeira aplicação
*   `run_onchange_after_restart-portal.sh.tmpl` → reinicia o portal de desktop quando o config do niri muda

## 🔐 Segredos e Variáveis de Ambiente

Os segredos vivem apenas em `~/.config/chezmoi/chezmoi.toml` (fora do git, modo 600). Na primeira execução de `chezmoi init`, o `.chezmoi.toml.tmpl` pergunta pelas chaves; depois `chezmoi edit-config` para alterar valores e `chezmoi apply` para regenerar `~/.config/env/secrets.env`, que é carregado automaticamente pelo `.zshrc`.

Variáveis de sessão (Wayland/Qt/GTK/SDL etc.) ficam em `~/.config/environment.d/90-wayland.conf`, lidas pelo `systemd --user`.

## 🧰 Scripts Executados pelo Chezmoi

- `run_once_install.sh`: detecta o gerenciador de pacotes, instala pacotes base, Mise, Antidote, aplica os dotfiles e provisiona ferramentas.
- `run_once_system-setup.sh`: overrides Flatpak globais, `xdg-terminal-exec` (kitty) e seleção de terminal do Cinnamon.
- `run_onchange_after_restart-portal.sh.tmpl`: reinicia os portais de desktop quando `niri-portals.conf` muda (checksum na ordem de execução).

## ⚡ Produtividade (Aliases)

Os aliases principais em `dot_aliases.zsh` incluem:
*   `dot`: Navegação rápida para o diretório de dotfiles.
*   `edot`: Edição rápida das configurações.
*   `szsh`: Recarregamento instantâneo do contexto do shell.
*   Workflow Git simplificado (status, commits, logs).

## 🪟 Fix do Seletor de Arquivo em Wayland/niri

Em sessões `niri`, o `xdg-desktop-portal` encaminha o `FileChooser` pro backend GNOME, que delega pro **Nautilus** (não instalado) → nenhum seletor abre. A correção:

1. `~/.config/xdg-desktop-portal/niri-portals.conf` define `FileChooser=gtk` (backend GTK nativo), mantendo `default=gnome` para screencast/screenshot.
2. `run_onchange_after_restart-portal.sh` reinicia o portal apenas quando o config muda (via checksum no template).
3. `run_once_install.sh` instala `xdg-desktop-portal-gtk` (APT/DNF/Zypper) em máquinas novas.
