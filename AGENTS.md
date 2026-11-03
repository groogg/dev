# Agent Instructions for dotfiles repository

This repo sets up a Mac for development, and brings a light, removable version of the same shell to
remote Linux VMs. Two scripts do everything: `mac.sh` (macOS, Homebrew + GNU `stow`) and `remote.sh`
(Linux VMs, user-space only).

## Commands

- `./mac.sh install` (or `dev install`) — full Mac setup: Homebrew essentials, the optional/personal pickers, dotfiles, toolchains, SSH, Dock
- `./mac.sh update` (or `dev update`) — upgrade Homebrew packages and toolchains
- `./mac.sh sync` (or `dev sync`) — re-stow dotfiles
- `git clone https://github.com/groogg/dev ~/.dev && ~/.dev/remote.sh` — set up a remote VM; `--update` refreshes, `--clean` removes everything

## Code Style Guidelines

- **Scripts**: `#!/usr/bin/env bash` with `set -euo pipefail`; one function per step; quote all expansions, leaving one unquoted only when it is a fixed value meant to split or glob, never user input or file contents
- **One OS per script**: `mac.sh` is macOS-only and `remote.sh` is Linux-only; don't add OS branches to either. Anything both need goes in `dotfiles/shell/.config/shell/rc.sh` (shell setup) or `scripts/` (helpers)
- **remote.sh stays non-invasive**: no sudo, nothing outside `$HOME`, everything it adds recorded so `--clean` removes it; existing files are moved to `*.dev-backup` and restored on clean; downloads are checked against GitHub's SHA-256 and skip releases younger than 7 days
- **Homebrew**: `brew`/`cask` entries grouped by purpose with section comments; essentials the setup depends on in `Brewfile`, picked extras in `Brewfile.optional`, personal apps in `Brewfile.personal`. The picker reads plain `brew`/`cask` lines, so keep the files flat
- **Dotfiles**: one `stow` package per tool under `dotfiles/<pkg>/`, mirroring the real home-directory layout; shell config that VMs also need belongs in `rc.sh`, which must work in both bash and zsh
- **Secrets**: never commit personal identity or credentials — git identity lives in `~/.gitconfig-local`, SSH keys in Secretive

## File Organization

- `mac.sh` / `remote.sh` — the two entry points
- `install.sh` — Mac bootstrap (clones the repo, runs `mac.sh install`)
- `Brewfile` / `Brewfile.optional` / `Brewfile.personal` — essentials, optional tools, personal apps
- `dotfiles/<pkg>/` — stow packages (zsh, shell, git, ghostty, vscode, starship, nvim)
- `scripts/git-identity.sh` — git name/email prompt shared by both scripts
- `terminfo/xterm-ghostty.src` — Ghostty's terminal description, installed on VMs by `remote.sh`

## Testing

- `bash -n mac.sh remote.sh` — syntax check
- Re-run `./mac.sh install` / `./mac.sh sync` — idempotent; symlinks should resolve correctly (`ls -la` the targets)
- After editing dotfiles, open a new shell or `source ~/.zshrc`
- Test `remote.sh` in a fresh Ubuntu container as a non-root user without sudo: install, re-run, `--clean`, and check the home folder is left as it was
