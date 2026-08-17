#!/bin/sh
set -eu

repo_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
store_dir="${HOME}/Repositories/GitHub/password-store"
store_url="${GOPASS_STORE_URL:-}"

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "install.sh: chezmoi nao encontrado; instale chezmoi age gopass gnupg git" >&2
    exit 1
fi

if [ -z "$(gpg --list-secret-keys --with-colons 2>/dev/null | grep '^sec:')" ]; then
    echo "install.sh: nenhuma chave GPG secreta encontrada; importe do backup offline" >&2
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
