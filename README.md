# 🚀 Dotfiles: Core Architecture

Um ecossistema automatizado para provisionamento de ambientes Unix-like, focado em produtividade e consistência através de diferentes distribuições Linux e Termux.

## 🛠️ Stack Tecnológica

| Ferramenta | Função |
| :--- | :--- |
| **[Mise](https://mise.jdx.dev/)** | Polyglot runtime manager (alternativa moderna ao asdf). Gerencia versões de Node, Python, Go, etc. |
| **[GNU Stow](https://www.gnu.org/software/stow/)** | Gerenciador de symlinks para arquivos de configuração (dotfiles). |
| **[Antidote](https://getantidote.github.io/)** | Gerenciador de plugins Zsh ultra-rápido baseado em clones nativos. |
| **[Eza](https://github.com/eza-community/eza)** | Substituto moderno e colorido para o comando `ls`. |
| **Zsh** | Shell principal com integração de plugins e aliases otimizados. |

## 🌿 Estrutura de Branches

*   **`core` (Desktop/Dev):** Setup completo. Inclui gerenciadores de runtime (Mise), plugins visuais e ferramentas de desenvolvimento.
*   **`server` (Minimal/SSH):** Versão enxuta. Focada em performance e estabilidade para ambientes de servidor, contendo apenas o essencial para navegação e edição.

## ⚙️ Instalação Inteligente

O script `install.sh` opera com detecção dinâmica de ambiente e gerenciamento de estado:

1.  **Detecção de PM:** Suporte nativo para `APT` (Debian/Ubuntu), `DNF` (Fedora), `Zypper` (OpenSUSE) e `PKG` (Termux).
2.  **Idempotência:** Antes de cada instalação, o script verifica via `dpkg`, `rpm` ou `pkg list` se o pacote já existe, evitando chamadas desnecessárias ao sudo e consumo de banda.
3.  **Bootstrap Automático:** Instala automaticamente o `Mise`, `Antidote` e `Stow` caso não estejam presentes.
4.  **Gestão de Conflitos:** Limpa links simbólicos ou arquivos órfãos antes de aplicar os novos módulos via Stow.
5.  **Provisionamento Global:** Após o setup base, o `Mise` provisiona todas as ferramentas definidas no `mise.toml`.

## 📂 Organização de Módulos

As configurações são organizadas em pastas compatíveis com o `Stow`:

*   `zsh/`: `.zshrc`, `.zsh_plugins.txt`, `.aliases.zsh`, `.bindkeys.zsh`.
*   `mise/`: `.config/mise/mise.toml`.

## ⚡ Produtividade (Aliases)

Os aliases principais em `zsh/.aliases.zsh` incluem:
*   `dot`: Navegação rápida para o diretório de dotfiles.
*   `edot`: Edição rápida das configurações.
*   `szsh`: Recarregamento instantâneo do contexto do shell.
*   Workflow Git simplificado (status, commits, logs).
