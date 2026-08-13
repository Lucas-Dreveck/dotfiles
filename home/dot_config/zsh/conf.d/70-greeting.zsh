if [[ -n "$_YANK_REC" ]]; then
    if [[ -n "$_YANK_FASTFETCH" ]]; then
        fastfetch
        unset _YANK_FASTFETCH
    fi
elif [[ $SHLVL -eq 1 && -z "$TMUX" && -z "$ZELLIJ" ]]; then
    fastfetch
fi
