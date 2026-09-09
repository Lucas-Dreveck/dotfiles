# eza
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias lt='eza --tree --level=2'
alias lta='eza --tree --level=2 -a'
alias llg='eza -l --git'

# fd
alias fdf='fd -t f'
alias fdd='fd -t d'

# fzf
ff() {
  fd -t f | fzf \
    --preview 'bat --color=always --style=numbers --line-range=:200 {}'
}

rff() {
  local query="$1"

  [[ -z "$query" ]] && {
    echo "Usage: rff <search>"
    return 1
  }

  rg -l "$query" | fzf \
    --preview "rg -n --passthru --color=always --colors 'match:none' --colors 'match:bg:220' --colors 'match:fg:0' --colors 'match:style:bold' '$query' {}"
}

# Git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gsw='git switch'
alias glog='git log --oneline --graph --decorate --all'

alias lg='lazygit'


# Docker
alias d='docker'
alias dc='docker compose'

alias dcu='docker compose up'
alias dcub='docker compose up --build'
alias dcubf='docker compose up --build --force-recreate'

alias dcd='docker compose down'
alias dcdv='docker compose down -v'

alias dcp='docker compose pull'

alias dcl='docker compose logs'
alias dclf='docker compose logs -f'

rdclf() {
  local query="$1"

  [[ -z "$query" ]] && {
    echo "Usage: rdclf <pattern>"
    return 1
  }

  docker compose logs -f 2>&1 | rg -n --color=always "$query"
}

alias dps='docker ps'
alias dpsa='docker ps -a'

alias di='docker images'

alias dv='docker volume'
alias dvls='docker volume ls'

alias dexec='docker exec -it'