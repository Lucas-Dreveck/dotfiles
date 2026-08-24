# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Secrets are
encrypted at rest with [age](https://age-encryption.org).

## New machine

Provide by hand: the GPG private key from the offline backup, the age
passphrase, the GPG passphrase.

```sh
sudo pacman -S chezmoi age gopass gnupg git
gpg --import <offline-backup>
gpg --edit-key <key-id>          # trust -> 5 -> y -> quit

git clone <this repo, over https> ~/Repositories/GitHub/dotfiles
GOPASS_STORE_URL=<password store, ssh> ~/Repositories/GitHub/dotfiles/install.sh
```

HTTPS for the clone because the SSH key does not exist yet.

`install.sh` is idempotent, so just re-run it if a phase fails. It asks for the
machine category and the age passphrase.

`rustup` is not managed here; install it from upstream if needed.

Unattended install:

```sh
chezmoi init --promptChoice 'Machine category=work'
```

## Machine category

Asked once at `chezmoi init` and stored in the local config: `personal`, `work`,
`both` or `none`. It decides which identity files that machine receives.
`home/.chezmoiignore.tmpl` is where that is decided, deny by default.

## Git identity

No global `user.*`. Identity comes from a per-forge file under
`~/Repositories/<forge>/`, wired by `includeIf gitdir:`. A repository outside
those trees has no identity and git refuses to commit, which is the point.

## Daily use

```sh
chezmoi edit <path> --apply      # edit the source, then apply
chezmoi add <path>               # manage a new file
chezmoi add --encrypt <path>     # manage a new secret
chezmoi update                   # pull and apply, on another machine
chezmoi managed | ignored | status | diff
```

Never edit a deployed file directly, the next `apply` overwrites it.
`chezmoi re-add <path>` recovers an accidental direct edit.

Renaming: `chezmoi forget <old>`, move the target, then `chezmoi add` the new
path. For an SSH key, also update the matching `IdentityFile` and verify with
`ssh -T <host>`.

Package list lives in the `run_onchange` install script under
`home/.chezmoiscripts/`. Editing it changes the hash, so it re-runs.

## Rules

- The repository is public. Never commit a plaintext secret.
- Audit before publishing: `git ls-files | grep -v '\.age$'`
- Never open a `.age` file by hand. Use `chezmoi edit`.
- `known_hosts`, shell history and completion caches stay unmanaged on purpose.
