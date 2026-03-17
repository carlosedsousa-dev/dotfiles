# History
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Ativar o Mise-en-place
# O comando 'activate' configura o PATH e hooks do shell automaticamente
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
fi

# Compinit (Autocomplete)
autoload -Uz compinit
compinit

# Inicializar o Antidote
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh

# Carregar plugins a partir do arquivo txt
antidote load

# Carregar arquivos extras
[[ -f ~/.bindkeys.zsh ]] && source ~/.bindkeys.zsh
[[ -f ~/.aliases.zsh ]] && source ~/.aliases.zsh