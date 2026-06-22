# Meus Bindkeys Personalizados
# Localização original: ~/dotfiles/zsh/.bindkeys

# Carrega o suporte ao banco de dados de terminais
zmodload zsh/terminfo

# Coloca o terminal em Application Mode para garantir sequências consistentes
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() { echoti smkx }
  function zle-line-finish() { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# Mapeia as funções apenas se a tecla existir no banco de dados do terminal atual
# Bind das setas para cima e para baixo
[[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
[[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down

# Ctrl + Seta para Esquerda e para Direita
[[ -n "${terminfo[kLFT5]}" ]] && bindkey "${terminfo[kLFT5]}" backward-word
[[ -n "${terminfo[kRIT5]}" ]] && bindkey "${terminfo[kRIT5]}" forward-word

# Ctrl + Delete
bindkey '^H' backward-kill-word

