# Histórico e Fpath
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Fpath para automatic complements
fpath=(~/.zsh/completions $fpath)

# Antidote (Carregamento estático é mais rápido)
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh
antidote load

# Lazy Load para o Compinit
autoload -Uz compinit
compinit_lazy() {
    unfunction compinit_lazy
    compinit
}
zle -N expand-or-complete compinit_lazy

# Lazy Load para o Mise
mise() {
    unfunction mise
    eval "$(command mise activate zsh)"
    mise "$@"
}

# Arquivos extras
[[ -f ~/.bindkeys.zsh ]] && source ~/.bindkeys.zsh
[[ -f ~/.aliases.zsh ]] && source ~/.aliases.zsh
