# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Secrets are
encrypted at rest with [age](https://age-encryption.org) — this repository is
public and contains no plaintext secrets.

## Roots of trust

Two, independent of each other:

- **age passphrase** — memorized. Unlocks this repository's secrets.
- **GPG private key** — restored from an offline backup. Unlocks the password store.

Neither depends on the other. The bootstrap order is: age unlocks chezmoi →
chezmoi deploys the SSH key → the SSH key clones the password store.

## New machine

Provide manually: the GPG private key from the offline backup, the age
passphrase, and the GPG passphrase.

```sh
sudo pacman -S chezmoi age gopass gnupg git
gpg --import <offline-backup>
gpg --edit-key <key-id>          # trust -> 5 -> y -> quit

git clone https://github.com/<user>/dotfiles.git ~/Repositories/GitHub/dotfiles
GOPASS_STORE_URL=git@github.com:<user>/password-store.git \
  ~/Repositories/GitHub/dotfiles/install.sh
```

The clone is over HTTPS because the SSH key does not exist yet — deploying it is
what this bootstrap does.

`install.sh` runs three phases as separate chezmoi invocations, so a failure in
one does not undo the previous: `chezmoi init --apply`, then the password store
clone, then a second `chezmoi apply`. Re-running it is safe. The first phase asks
for the machine category and the age passphrase.

`rustup` is deliberately not managed here; install it from upstream if needed.

## Machine categories

One question at `chezmoi init`, answered once per machine and stored in the local
config, decides which secrets that machine receives:

| category   | SSH keys and identity config deployed |
|------------|---------------------------------------|
| `personal` | personal only                         |
| `work`     | work only                             |
| `both`     | both                                  |
| `none`     | neither                               |

Everything non-secret is deployed everywhere. `home/.chezmoiignore.tmpl` is the
boundary, and SSH keys are deny-by-default: a key added without an explicit allow
rule is deployed nowhere, so the failure mode is a missing key, never a leaked one.

For an unattended install, state the category explicitly:

```sh
chezmoi init --promptChoice 'Machine category=work'
```

## Daily use

```sh
chezmoi edit <path> --apply      # edit the source, then apply
chezmoi add <path>               # manage a new file
chezmoi add --encrypt <path>     # manage a new secret
chezmoi update                   # pull and apply, on another machine
chezmoi managed | ignored | status | diff
```

Never edit a deployed file directly — the next `apply` overwrites it from the
source. `chezmoi re-add <path>` recovers an accidental direct edit.

Renaming: `chezmoi forget <old>`, move the target, then `chezmoi add` the new
path. For an SSH key, also update the matching `IdentityFile` under
`~/.ssh/conf.d/` and verify with `ssh -T <host>`.

## Layout

```
.chezmoiroot                     contains "home"; the source starts there
install.sh                       bootstrap wrapper
home/
├── .chezmoi.toml.tmpl           generates the local config, asks the category
├── .chezmoiignore.tmpl          the security boundary
├── .chezmoiscripts/             scripts; never become files in $HOME
│   ├── run_onchange_before_decrypt-private-key.sh.tmpl
│   └── run_onchange_after_install-packages.sh.tmpl
├── key.txt.age                  passphrase-wrapped age key, never deployed
├── dot_zshenv
├── dot_XCompose
├── dot_config/
│   ├── zsh/                     .zshrc and conf.d/, work files encrypted
│   ├── kitty/
│   └── starship.toml
└── private_dot_ssh/
    ├── conf.d/00-defaults.conf  global options; the only place for Host *
    ├── conf.d/personal/
    ├── conf.d/work/             encrypted: contains a company host
    └── keys                     private keys encrypted, public keys as needed
```

Packages are declared inside
`home/.chezmoiscripts/run_onchange_after_install-packages.sh.tmpl`, branching on
`$osID`. Changing the list changes the file hash, so the script re-runs.

## Rules

- The repository is public. Never commit a plaintext secret.
- Audit before publishing: `git ls-files | grep -v '\.age$'`
- Never open a `.age` file by hand. Use `chezmoi edit`, which decrypts and
  re-encrypts transparently.
- `known_hosts`, shell history and completion caches are intentionally unmanaged:
  machine-specific, and they leak.
