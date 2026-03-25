# Histórico
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Fpath e Plugins
fpath=(~/.zsh/completions $fpath)
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh
antidote load

# Inicializar completações após carregar plugins
autoload -Uz compinit && compinit

# Mise-en-place
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi

# Arquivos extras
[[ -f ~/.bindkeys.zsh ]] && source ~/.bindkeys.zsh
[[ -f ~/.aliases.zsh ]] && source ~/.aliases.zsh
