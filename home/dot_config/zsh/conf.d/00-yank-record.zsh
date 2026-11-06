: ${YANK_DIR:="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/yank"}
zmodload zsh/datetime 2>/dev/null

_yank_should_record() {
  [[ -o interactive ]]          || return 1
  [[ -t 0 && -t 1 ]]            || return 1
  [[ -z "$YANK_DISABLE" ]]      || return 1
  command -v script >/dev/null  || return 1
  [[ -n "$_YANK_REC" && "$_YANK_TTY" == "$TTY" ]] && return 1
  return 0
}

if [[ -n "$_YANK_REC" && -z "$_YANK_TTY" ]]; then
  export _YANK_TTY=$TTY
elif _yank_should_record; then
  mkdir -p "$YANK_DIR"
  () {
    local f pid
    local -a dead
    if [[ -d /proc/self ]]; then
      for f in "$YANK_DIR"/sess-*.log(N); do
        pid=${${f:t}#sess-}; pid=${pid%%-*}
        [[ -r /proc/$pid/cmdline && "$(</proc/$pid/cmdline)" == *${f:t}* ]] || dead+=("$f")
      done
    else
      dead=("$YANK_DIR"/sess-*.log(N.mh+12))
    fi
    (( $#dead )) && rm -f -- "${dead[@]}"
  }
  if [[ $SHLVL -eq 1 && -z "$TMUX" && -z "$ZELLIJ" && -z "$_YANK_REC" ]]; then
    export _YANK_FASTFETCH=1
  fi
  export _YANK_LOG="$YANK_DIR/sess-$$-${EPOCHSECONDS:-$RANDOM}.log"
  export _YANK_REC=1
  unset _YANK_TTY
  exec script -qfe -c "zsh" "$_YANK_LOG"
fi
