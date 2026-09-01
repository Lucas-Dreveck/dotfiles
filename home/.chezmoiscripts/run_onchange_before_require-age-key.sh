#!/bin/sh
set -eu
key="${HOME}/.config/chezmoi/key.txt"
if [ ! -f "$key" ]; then
    echo "age key missing at $key" >&2
    echo "run install.sh, or decrypt it from the offline backup:" >&2
    echo "  age --decrypt --output \"$key\" /path/to/key.txt.age" >&2
    exit 1
fi
