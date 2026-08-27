#!/bin/sh
set -eu
key="${HOME}/.config/chezmoi/key.txt"
if [ ! -f "$key" ]; then
    echo "chave age ausente em $key" >&2
    echo "rode install.sh, ou decifre do backup offline:" >&2
    echo "  age --decrypt --output \"$key\" /caminho/key.txt.age" >&2
    exit 1
fi
