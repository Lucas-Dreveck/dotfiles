zinit ice blockf
zinit light zsh-users/zsh-completions

autoload -Uz compinit
() {
  local dump="${ZDOTDIR:-$HOME}/.zcompdump" d stale=0
  [[ -s $dump ]] || stale=1
  for d in $fpath; do
    [[ $d -nt $dump ]] && { stale=1; break }
  done
  if (( stale )); then
    compinit -d "$dump"
    touch "$dump"
  else
    compinit -C -d "$dump"
  fi
  [[ $dump.zwc -nt $dump ]] || zcompile "$dump"
}

zinit ice wait'0' lucid
zinit light Aloxaf/fzf-tab

if [[ -r /usr/share/fzf/completion.zsh ]]; then
  zinit ice wait'0' lucid
  zinit snippet /usr/share/fzf/completion.zsh
fi

if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  zinit ice wait'0' lucid
  zinit snippet /usr/share/fzf/key-bindings.zsh
fi
