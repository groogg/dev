# Agent Instructions for dotfiles repository

Two scripts set everything up: `mac.sh` for the Mac (Homebrew + GNU `stow`) and `remote.sh` for
remote Linux VMs (user-space only, removable). Keep it that small.

## Commands

- `./mac.sh install | update | sync` (or `dev ...`) — set up, upgrade, or re-link the Mac
- `~/.dev/remote.sh [--update | --clean]` — set up, refresh, or remove a VM

## Rules

- **Scripts**: `#!/usr/bin/env bash`, `set -euo pipefail`, one function per step, quoted expansions. `mac.sh` must run on macOS's bash 3.2
- **One OS per script**: no OS branches; what both need goes in `dotfiles/shell/.config/shell/rc.sh` (must work in bash and zsh) or `scripts/`
- **remote.sh stays non-invasive**: no sudo, nothing outside `$HOME`, everything it adds removable by `--clean`; downloads checked against GitHub's SHA-256 and at least 7 days old
- **Homebrew**: one `Brewfile`, grouped by purpose with section comments
- **Dotfiles**: one `stow` package per tool under `dotfiles/<pkg>/`, mirroring the home-directory layout
- **Secrets**: never commit identity or credentials — git identity lives in `~/.gitconfig-local`, SSH keys in Secretive

## Testing

- `bash -n mac.sh remote.sh` and `/bin/bash -n mac.sh`
- `./mac.sh sync`, then a new shell
- `remote.sh` in a fresh Ubuntu container as a user without sudo: install, re-run, `--clean`
