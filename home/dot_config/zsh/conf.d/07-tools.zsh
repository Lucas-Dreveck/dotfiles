[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

() {
  local d v
  if [[ -r "$NVM_DIR/alias/default" ]]; then
    v="$(<"$NVM_DIR/alias/default")"
    [[ -d "$NVM_DIR/versions/node/$v/bin" ]]  && d="$NVM_DIR/versions/node/$v/bin"
    [[ -z "$d" && -d "$NVM_DIR/versions/node/v$v/bin" ]] && d="$NVM_DIR/versions/node/v$v/bin"
  fi
  if [[ -z "$d" ]]; then
    local -a c=("$NVM_DIR"/versions/node/*/bin(N/n))
    (( $#c )) && d="${c[-1]}"
  fi
  [[ -n "$d" ]] && path=("$d" $path)
}

_nvm_load() {
  unfunction nvm 2>/dev/null
  [[ -t 2 ]] && print -u2 -n -P "%F{yellow}carregando nvm…%f"
  [[ -r /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh
  [[ -t 2 ]] && print -u2 -n $'\r\e[K'
}

nvm() { _nvm_load; nvm "$@" }
