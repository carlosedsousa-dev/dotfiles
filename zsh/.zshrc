# History
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Comp
autoload -Uz compinit
compinit

# Inicializar o Antidote
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh

# Carregar plugins a partir do arquivo txt
antidote load

# Bind das setas para cima e para baixo
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Aliases
alias dotup="cd ~/dotfiles && git pull && ./install.sh && source ~/.zshrc"
