# 🚀 Dotfiles: Niri Architecture

Um ecossistema automatizado para provisionamento de ambientes Unix-like, focado em produtividade e consistência visual dinâmica, otimizado para o compositor Niri.

## 🛠️ Stack Tecnológica

| Ferramenta | Função |
| :--- | :--- |
| **[Niri](https://github.com/YaLTeR/niri)** | Compositor de janelas scroll-based (insensível a Tayloring tradicional). |
| **[Matugen](https://github.com/InSync/Matugen)** | Gerador de cores baseado em Material You para extração dinâmica de temas. |
| **[Mise](https://mise.jdx.dev/)** | Polyglot runtime manager. Gerencia versões de Node, Python, Rust e ferramentas CLI. |
| **[GNU Stow](https://www.gnu.org/software/stow/)** | Gerenciador de symlinks para persistência e modularidade dos arquivos de configuração. |
| **[Antidote](https://getantidote.github.io/)** | Gerenciador de plugins Zsh ultra-rápido baseado em carregamento estático. |
| **[SWWW](https://github.com/L_S_D/swww)** | Wallpaper daemon com suporte a transições animadas e alta performance. |

## 🏗️ Fluxo de Provisionamento (Bootstrap)

A arquitetura de instalação é projetada para ser executada em camadas, garantindo que o sistema base esteja pronto antes da configuração das aplicações.

**System Layer**
O script identifica o gerenciador de pacotes nativo (Somente Zypper por enquanto) e instala dependências de compilação, fontes e binários essenciais.

**Symlink Layer**
O GNU Stow mapeia os módulos do repositório para o `$HOME`. Esta camada é idempotente e permite que alterações nos dotfiles sejam refletidas instantaneamente no sistema.

**Runtime Layer**
O Mise provisiona as linguagens de programação e ferramentas globais sem interferir no gerenciador de pacotes do sistema operacional.

**Theming Layer**
O Matugen processa os templates de cores para Kitty, Waybar e Niri, criando uma identidade visual coesa baseada no wallpaper ativo.

## 📦 Gestão de Módulos (Stow)

As configurações são segmentadas em unidades lógicas. Cada módulo pode ser aplicado independentemente:

* `zsh/`: Core do shell, plugins e definições de aliases.
* `niri/`: Layout de janelas, binds de produtividade e regras de renderização.
* `waybar/`: Interface de status bar com suporte a recarregamento via sinal USR1.
* `kitty/`: Configurações de terminal com suporte a troca de cores em tempo real.
* `scripts/`: Automações de sistema, incluindo o seletor de wallpaper e atualizador.

## ⚡ Automação e Lifecycle

O ambiente conta com scripts de manutenção para garantir a evolução do setup sem a necessidade de re-instalação:

**install.sh**
Script de primeiro uso. Limpa conflitos, instala o Rust/Cargo, provisiona o Matugen e aplica os links iniciais. Possui travas de segurança e confirmação para processos longos de compilação.

**update.sh**
Sincroniza o repositório local com o remoto, utiliza `stow -R` para atualizar os links simbólicos e atualiza os runtimes via Mise, mantendo o sistema em dia com um único comando.

**select-wallpaper.sh**
Integra Wofi, SWWW e Matugen. Altera o fundo de tela com transições suaves e dispara sinais `SIGUSR1` para que a interface atualize as cores via CSS sem fechar as aplicações ou causar flickers.

## 🚀 Como Começar

```bash
git clone [https://github.com/seu-usuario/dotfiles.git](https://github.com/seu-usuario/dotfiles.git) ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```