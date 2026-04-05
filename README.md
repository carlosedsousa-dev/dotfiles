# 🚀 Dotfiles: Server Architecture (Minimal)

Perfil enxuto e otimizado para servidores, homelabs e ambientes via SSH, focado em performance, estabilidade e redução de pegada de memória.

## 🛠️ Stack Tecnológica (Minimalista)

| Ferramenta | Função |
| :--- | :--- |
| **[GNU Stow](https://www.gnu.org/software/stow/)** | Orquestração de links simbólicos para manter o `$HOME` limpo. |
| **[Antidote](https://getantidote.github.io/)** | Gerenciador de plugins Zsh focado em performance (estático). |
| **Zsh** | Shell principal com aliases otimizados para navegação em servidores. |

## 🌿 Por que usar o perfil Server?

Ao contrário da branch `core`, este perfil **não instala gerenciadores de runtime (Mise)** ou ferramentas pesadas de desenvolvimento. O objetivo é fornecer um shell produtivo e familiar sem poluir o sistema de produção.

## ⚙️ Instalação Inteligente

O script `install.sh` opera de forma segura e idempotente:

1.  **Detecção de PM:** Suporte nativo para `APT`, `DNF`, `Zypper` e `PKG` (Termux).
2.  **Verificação de Estado:** Utiliza `dpkg` e `rpm` para validar pacotes existentes antes de qualquer comando de escrita.
3.  **Bootstrap Silencioso:** Provisiona o `Antidote` e aplica as configurações via `Stow` automaticamente.
4.  **Troca de Shell:** Configura o `zsh` como shell padrão para o usuário de forma automatizada.

## ⚡ Aliases & Ferramentas

Os aliases em `zsh/.aliases.zsh` neste perfil são focados em:
*   **Monitoramento:** Atalhos rápidos para visualização de logs e recursos do sistema.
*   **Gestão de Arquivos:** Comandos básicos e navegação rápida entre diretórios de configuração.
*   **Git:** Status e log simplificados para verificações rápidas em ambiente remoto.

---
*Para o perfil completo de desenvolvimento, utilize a branch **core**.*
