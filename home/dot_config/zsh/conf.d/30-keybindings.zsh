bindkey -e

setopt NO_BEEP

WORDCHARS="${WORDCHARS//-}"

if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  autoload -Uz add-zle-hook-widget
  _zle_app_start() { echoti smkx }
  _zle_app_stop()  { echoti rmkx }
  add-zle-hook-widget -Uz zle-line-init   _zle_app_start
  add-zle-hook-widget -Uz zle-line-finish _zle_app_stop
fi

[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line   # Home
[[ -n "${terminfo[kend]}"  ]] && bindkey "${terminfo[kend]}"  end-of-line         # End

bindkey '^[[H'  beginning-of-line                 # Home
bindkey '^[[F'  end-of-line                       # End
bindkey '^[OH'  beginning-of-line                 # Home (application mode)
bindkey '^[OF'  end-of-line                       # End (application mode)
bindkey '^[[1~' beginning-of-line                 # Home
bindkey '^[[4~' end-of-line                       # End

[[ -n "${terminfo[kdch1]}" ]] && bindkey "${terminfo[kdch1]}" delete-char         # Delete

bindkey '^[[3~' delete-char                       # Delete
bindkey '^[[2~' overwrite-mode                    # Insert

bindkey '^[[1;5C' forward-word                    # Ctrl+Right
bindkey '^[[1;5D' backward-word                   # Ctrl+Left

bindkey '^[[3;5~' kill-word                       # Ctrl+Delete
bindkey '^H'      backward-kill-word              # Ctrl+Backspace

[[ -n "${terminfo[kpp]}" ]] && bindkey "${terminfo[kpp]}" up-line-or-history      # PageUp
[[ -n "${terminfo[knp]}" ]] && bindkey "${terminfo[knp]}" down-line-or-history    # PageDown
