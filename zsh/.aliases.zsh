# Meus Aliases Personalizados
# Localização original: ~/dotfiles/zsh/.aliases

# Status e Adição
alias gst='git status'
alias ga='git add'
alias gaa='git add --all'

# Commit e Push/Pull
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'

# Branch e Navegação
alias gb='git branch'
alias gch='git checkout'
alias gchb='git checkout -b'

# Logs e Diff
alias gd='git diff'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Gestão de Dotfiles
alias dotup="cd ~/dotfiles && git pull && ./update.sh && source ~/.zshrc"
alias dot='cd ~/dotfiles'
alias edot='$EDITOR ~/dotfiles/zsh/.zshrc'
alias szsh='source ~/.zshrc'

# Substitudo do ls moderno
alias ls="eza"
