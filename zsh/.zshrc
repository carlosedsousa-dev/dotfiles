# Histórico e Fpath
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
fpath=(~/.zsh/completions $fpath)

# Antidote com Cache Estático
# Carrega instantaneamente se o cache existir e estiver atualizado
_antidote_dir=${ZDOTDIR:-$HOME}/.antidote
_antidote_plugins_txt=${ZDOTDIR:-$HOME}/.zsh_plugins.txt
_antidote_static=${ZDOTDIR:-$HOME}/.zsh_plugins.zsh

source $_antidote_dir/antidote.zsh

if [[ ! -f $_antidote_static || $_antidote_plugins_txt -nt $_antidote_static ]]; then
  antidote bundle < $_antidote_plugins_txt > $_antidote_static
fi
source $_antidote_static

# Lazy Load para o Compinit
# Ativa apenas no primeiro Tab
autoload -Uz compinit
compinit_lazy() {
    unfunction compinit_lazy
    compinit
}
zle -N expand-or-complete compinit_lazy

# Carregamento Diferido para o Mise
# Ativa hooks após o prompt sem travar o startup
load_mise() {
    if command -v mise &> /dev/null; then
        eval "$(mise activate zsh)"
    fi
    add-zsh-hook -d precmd load_mise
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd load_mise

# Path
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Arquivos extras
[[ -f ~/.bindkeys.zsh ]] && source ~/.bindkeys.zsh
[[ -f ~/.aliases.zsh ]] && source ~/.aliases.zsh
