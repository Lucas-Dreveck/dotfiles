
: ${YANK_DIR:="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/yank"}
zmodload zsh/datetime 2>/dev/null

_yank_should_record() {
  [[ -o interactive ]]            || return 1
  [[ -t 0 && -t 1 ]]             || return 1
  [[ -z "$YANK_DISABLE" ]]      || return 1
  command -v script >/dev/null   || return 1
  [[ -n "$_YANK_REC" && "$_YANK_TTY" == "$TTY" ]] && return 1
  return 0
}

if [[ -n "$_YANK_REC" && -z "$_YANK_TTY" ]]; then
  export _YANK_TTY=$TTY
elif _yank_should_record; then
  mkdir -p "$YANK_DIR"
  find "$YANK_DIR" -maxdepth 1 -type f -name 'sess-*.log' -mtime +1 -delete 2>/dev/null
  if [[ $SHLVL -eq 1 && -z "$TMUX" && -z "$ZELLIJ" && -z "$_YANK_REC" ]]; then
    export _YANK_FASTFETCH=1
  fi
  export _YANK_LOG="$YANK_DIR/sess-$$-${EPOCHSECONDS:-$RANDOM}.log"
  export _YANK_REC=1
  unset _YANK_TTY
  exec script -qfe -c "zsh" "$_YANK_LOG"
fi

if [[ -n "$_YANK_REC" ]]; then
  autoload -Uz add-zsh-hook

  _yank_preexec() {
    local b64
    b64=$(print -rn -- "$1" | base64 | tr -d '\n')
    print -rn -- $'\e_yankcmd:'"$b64"$'\e\\'   # parsing marker (APC, para o yank)
    print -rn -- $'\e]133;C\e\\'               # OSC 133: começou a rodar um comando
  }
  _yank_precmd() {
    local ec=$?
    print -rn -- $'\e_yankend:'"$ec"$'\e\\'     # parsing marker (APC)
    print -rn -- $'\e]133;D;'"$ec"$'\e\\'       # OSC 133: comando terminou (exit $ec)
    print -rn -- $'\e]133;A\e\\'                # OSC 133: prompt começando (estou ocioso)
    return $ec
  }
  add-zsh-hook preexec _yank_preexec
  precmd_functions=(_yank_precmd ${precmd_functions:#_yank_precmd})

  if command -v wl-copy >/dev/null 2>&1; then
    _YANK_CLIP='wl-copy'
  elif command -v xclip >/dev/null 2>&1; then
    _YANK_CLIP='xclip -selection clipboard'
  elif command -v xsel >/dev/null 2>&1; then
    _YANK_CLIP='xsel --clipboard --input'
  else
    _YANK_CLIP=''
  fi
fi

_yank_help() {
  print -r -- 'yank — show the last command(s) + output, cleaned for pasting

  yank                last 1 command
  yank -n 2           last 2 commands
  yank --full         do not truncate large outputs (docker build etc.)
  yank --lines H:T    show first H + last T lines (default 40:20)
  yank --no-copy      only print, do not copy to clipboard
  yank -h             this help

Automatic clipboard copy when wl-copy/xclip/xsel is available.'
}

yank() {
  emulate -L zsh
  local n=1 full=0 head=40 tail=20 thresh=200 do_copy=1
  while (( $# )); do
    case "$1" in
      -n)          n="$2"; shift 2;;
      -n*)         n="${1#-n}"; shift;;
      -f|--full)   full=1; shift;;
      --lines)     head="${2%%:*}"; tail="${2##*:}"; shift 2;;
      -p|--no-copy) do_copy=0; shift;;
      -h|--help)   _yank_help; return 0;;
      *) print -u2 -- "yank: opção desconhecida: $1 (veja: yank -h)"; return 2;;
    esac
  done

  if [[ -z "$_YANK_REC" ]]; then
    print -u2 -- "yank: recording disabled in this session (YANK_DISABLE or 'script' not available)."
    return 1
  fi
  if [[ -z "$_YANK_LOG" || ! -r "$_YANK_LOG" ]]; then
    print -u2 -- "yank: no capture log ($_YANK_LOG)."
    return 1
  fi

  local out
  out=$(YANK_N=$n YANK_FULL=$full YANK_HEAD=$head YANK_TAIL=$tail YANK_THRESH=$thresh \
    perl -e '
      use strict; use warnings;
      use MIME::Base64 qw(decode_base64);
      my $n   = int($ENV{YANK_N}      // 1); $n = 1 if $n < 1;
      my $fl  = $ENV{YANK_FULL}       // 0;
      my $hd  = int($ENV{YANK_HEAD}   // 40); $hd = 0 if $hd < 0;
      my $tl  = int($ENV{YANK_TAIL}   // 20); $tl = 0 if $tl < 0;
      my $thr = int($ENV{YANK_THRESH} // 200);

      local $/;
      my $data = <>;
      my @blocks;
      while ($data =~ /\x1b_yankcmd:([A-Za-z0-9+\/=]*)\x1b\\(.*?)\x1b_yankend:(-?\d+)\x1b\\/gs) {
        push @blocks, [ decode_base64($1), $2, $3 ];
      }
      # ignore yank own invocations
      @blocks = grep { $_->[0] !~ /\A\s*yank(\s|\z)/ } @blocks;
      return unless @blocks;
      @blocks = @blocks[-$n .. -1] if @blocks > $n;

      sub clean {
        my ($s) = @_;
        $s =~ s/\r\n/\n/g;
        $s =~ s/[^\n]*\r//g;                          # collapse CR rewrites (progress bars)
        $s =~ s/\x1b[_P^X].*?\x1b\\//gs;              # APC/DCS/PM/SOS
        $s =~ s/\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)//g; # OSC
        $s =~ s/\x1b\[[0-9;?]*[ -\/]*[\@-~]//g;       # CSI
        $s =~ s/\x1b[\@-Z\\-_]//g;                    # 2-char escapes
        $s =~ s/\x1b[()][A-Za-z0-9]//g;               # charset selection
        $s =~ s/.\x08//g;                             # overstrike with backspace
        $s =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f]//g;      # stray controls (keep \t \n)
        return $s;
      }

      my @parts;
      for my $b (@blocks) {
        my ($cmd, $raw, $ec) = @$b;
        my $o = clean($raw);
        $o =~ s/\A\n+//; $o =~ s/\n+\z//;
        my @L = split /\n/, $o, -1;
        if (!$fl && @L > $thr && @L > $hd + $tl) {
          my $om = @L - $hd - $tl;
          @L = (@L[0 .. $hd-1],
                "[... $om lines omitted ...]",
                @L[$#L-$tl+1 .. $#L]);
        }
        my $body = join("\n", @L);
        my $t = "\$ $cmd";
        $t .= "\n$body" if length $body;
        $t .= "\n# exit: $ec" if $ec ne "0";
        push @parts, $t;
      }
      print join("\n\n", @parts);
    ' "$_YANK_LOG")

  if [[ -z "$out" ]]; then
    print -u2 -- "yank: nothing captured yet in this session."
    return 1
  fi

  print -r -- "$out"

  if (( do_copy )) && [[ -n "$_YANK_CLIP" ]]; then
    print -rn -- "$out" | ${=_YANK_CLIP} 2>/dev/null \
      && print -r -- $'\e[2m✓ copied to clipboard\e[0m'
  fi
}
