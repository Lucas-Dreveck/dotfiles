zinit ice blockf
zinit light zsh-users/zsh-completions

autoload -Uz compinit
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
unset _zcompdump

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
