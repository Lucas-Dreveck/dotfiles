_cached_init() {
  local bin=$commands[$1]
  [[ -n $bin ]] || return 0
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init-$1.zsh"
  if [[ ! -s $cache || $bin -nt $cache || $bin -ot $cache ]]; then
    mkdir -p "${cache:h}"
    "$bin" "${@:2}" >| "$cache.tmp" || { rm -f "$cache.tmp"; return 1 }
    mv -f "$cache.tmp" "$cache"
    touch -r "$bin" "$cache"
    zcompile "$cache"
  fi
  source "$cache"
}

_cached_init starship init zsh --print-full-init
_cached_init zoxide init zsh

unfunction _cached_init
