#!/bin/sh
set -eu

repo_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
store_dir="${HOME}/Repositories/GitHub/password-store"
store_url="${GOPASS_STORE_URL:-}"
age_key="${HOME}/.config/chezmoi/key.txt"

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "install.sh: chezmoi not found; install chezmoi age gopass gnupg git" >&2
    exit 1
fi

if [ -z "$(gpg --list-secret-keys --with-colons 2>/dev/null | grep '^sec:')" ]; then
    echo "install.sh: no GPG secret key found; import it from the offline backup" >&2
fi

if [ ! -f "$age_key" ]; then
    if ! command -v age >/dev/null 2>&1; then
        echo "install.sh: age not found; install age" >&2
        exit 1
    fi

    src="${AGE_KEY_FILE:-}"
    if [ -z "$src" ]; then
        for candidate in /run/media/"$(id -un)"/*/key.txt.age /media/"$(id -un)"/*/key.txt.age; do
            if [ -f "$candidate" ]; then
                src="$candidate"
                break
            fi
        done

        found="$src"
        attempt=0
        while :; do
            if [ -n "$found" ]; then
                printf 'install.sh: age key found at %s\n' "$found"
                printf 'install.sh: press Enter to use it, or give another path: '
            else
                printf 'install.sh: path to key.txt.age on the offline backup: '
            fi
            read -r answer || answer=""
            answer=$(printf '%s' "$answer" | tr -d '[:cntrl:]')
            if [ -n "$answer" ]; then
                case "$answer" in
                    "~/"*) answer="${HOME}/${answer#\~/}" ;;
                esac
                src="$answer"
            else
                src="$found"
            fi
            if [ -n "$src" ] && [ -f "$src" ]; then
                break
            fi
            echo "install.sh: not found: $src" >&2
            attempt=$((attempt + 1))
            if [ "$attempt" -ge 3 ]; then
                echo "install.sh: giving up after 3 attempts" >&2
                exit 1
            fi
        done
    fi

    if [ -z "$src" ] || [ ! -f "$src" ]; then
        echo "install.sh: file not found: ${src:-<no path given>}" >&2
        exit 1
    fi
    if ! head -c 200 "$src" | grep -aqE 'age-encryption\.org|BEGIN AGE ENCRYPTED'; then
        echo "install.sh: $src does not look like an age file" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$age_key")"
    if ! (umask 077; age --decrypt --output "$age_key.tmp" "$src"); then
        rm -f "$age_key.tmp"
        echo "install.sh: could not decrypt the age key" >&2
        exit 1
    fi
    mv "$age_key.tmp" "$age_key"
    echo "install.sh: age key installed; the backup at $src was left untouched"
fi

chezmoi init --apply --source="$repo_dir"

if [ ! -d "$store_dir" ]; then
    if [ -n "$store_url" ]; then
        git clone "$store_url" "$store_dir" ||
            echo "install.sh: password store clone failed" >&2
    else
        echo "install.sh: set GOPASS_STORE_URL to clone the password store" >&2
    fi
fi

if [ -d "$store_dir" ] && command -v gopass >/dev/null 2>&1; then
    gopass config mounts.path "$store_dir" ||
        echo "install.sh: gopass config mounts.path failed" >&2
fi

chezmoi apply
