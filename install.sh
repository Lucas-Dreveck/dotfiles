#!/bin/sh
set -eu

repo_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
store_dir="${HOME}/Repositories/GitHub/password-store"
store_url="${GOPASS_STORE_URL:-}"
age_key="${HOME}/.config/chezmoi/key.txt"

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "install.sh: chezmoi nao encontrado; instale chezmoi age gopass gnupg git" >&2
    exit 1
fi

if [ -z "$(gpg --list-secret-keys --with-colons 2>/dev/null | grep '^sec:')" ]; then
    echo "install.sh: nenhuma chave GPG secreta encontrada; importe do backup offline" >&2
fi

if [ ! -f "$age_key" ]; then
    if ! command -v age >/dev/null 2>&1; then
        echo "install.sh: age nao encontrado; instale age" >&2
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
                printf 'install.sh: chave age encontrada em %s\n' "$found"
                printf 'install.sh: Enter para usar, ou informe outro caminho: '
            else
                printf 'install.sh: caminho do key.txt.age no backup offline: '
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
            echo "install.sh: nao encontrei: $src" >&2
            attempt=$((attempt + 1))
            if [ "$attempt" -ge 3 ]; then
                echo "install.sh: desistindo apos 3 tentativas" >&2
                exit 1
            fi
        done
    fi

    if [ -z "$src" ] || [ ! -f "$src" ]; then
        echo "install.sh: arquivo nao encontrado: ${src:-<nenhum caminho informado>}" >&2
        exit 1
    fi
    if ! head -c 200 "$src" | grep -aqE 'age-encryption\.org|BEGIN AGE ENCRYPTED'; then
        echo "install.sh: $src nao parece um arquivo age" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$age_key")"
    if ! (umask 077; age --decrypt --output "$age_key.tmp" "$src"); then
        rm -f "$age_key.tmp"
        echo "install.sh: falha ao decifrar a chave age" >&2
        exit 1
    fi
    mv "$age_key.tmp" "$age_key"
    echo "install.sh: chave age instalada; o backup em $src nao foi alterado"
fi

chezmoi init --apply --source="$repo_dir"

if [ ! -d "$store_dir" ]; then
    if [ -n "$store_url" ]; then
        git clone "$store_url" "$store_dir" ||
            echo "install.sh: clone do password-store falhou" >&2
    else
        echo "install.sh: defina GOPASS_STORE_URL para clonar o password-store" >&2
    fi
fi

if [ -d "$store_dir" ] && command -v gopass >/dev/null 2>&1; then
    gopass config mounts.path "$store_dir" ||
        echo "install.sh: gopass config mounts.path falhou" >&2
fi

chezmoi apply
