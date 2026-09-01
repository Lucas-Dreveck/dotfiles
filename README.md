# dotfiles

Managed with [chezmoi](https://chezmoi.io). Secrets encrypted with [age](https://age-encryption.org).

## New machine

From the offline backup: `key.txt.age`, the GPG private key, both passphrases.

```sh
sudo pacman -S chezmoi age gopass gnupg git

gpg --import <backup>
gpg --edit-key <key-id>          # trust -> 5 -> y -> quit

git clone <this repo, https> ~/Repositories/GitHub/dotfiles
GOPASS_STORE_URL=<store, ssh> ~/Repositories/GitHub/dotfiles/install.sh
```

HTTPS for the clone: the SSH key does not exist yet.

`install.sh` looks for `key.txt.age` on mounted media and decrypts it to
`~/.config/chezmoi/key.txt`. `AGE_KEY_FILE=<path>` overrides the search. The
backup is read, never moved. Safe to re-run.

Unattended:

```sh
chezmoi init --promptChoice 'Machine category=work'
```

## Password store

Separate private repo. `install.sh` clones it when `GOPASS_STORE_URL` is set.
By hand:

```sh
git clone <store> ~/Repositories/GitHub/password-store
gopass config mounts.path ~/Repositories/GitHub/password-store
gopass ls
```

The GPG key has to be imported and trusted first.

## Machine category

Asked once at `chezmoi init`: `personal`, `work`, `both`, `none`. Decides which
identity files reach the machine. Rules in `home/.chezmoiignore.tmpl`, deny by
default.

## Git identity

No global `user.*`. Per-forge file under `~/Repositories/<forge>/`, wired by
`includeIf gitdir:`. Outside those trees git refuses to commit.

## Provisioning

`home/.chezmoiscripts/` holds a `run_onchange` script with the package list plus
the Rust toolchain, node LTS and the `uv` tools. Editing it changes the hash, so
it re-runs; satisfied steps are skipped.
