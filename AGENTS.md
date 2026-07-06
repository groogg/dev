# Agent Instructions for dotfiles repository

This repo manages dotfiles, Homebrew packages, and AI coding-agent setup. It is
driven by `just` (wrapped by a `dev` CLI) and GNU `stow`.

> Note: `agents/AGENTS.md` is a *different* file — it is the shared instruction
> payload copied into other projects via `just init-project`. This file is about
> working on this repo itself.

## Build/Install Commands

- `just install` (or `dev install`) — full setup for the current OS (`_setup-mac` / `_setup-linux`)
- `just sync` — re-stow dotfiles and update skill submodules
- `just link-skills` — symlink an external skills directory (e.g. a cloned skills repo) into selected agent destinations (claude, gemini, junie, amp)
- `just init-project` — copy `agents/AGENTS.md` into the current directory
- `just key` — generate a new SSH key (for Linux/non-Secretive setups; on macOS keys are managed by Secretive)
- `brew bundle --file Brewfile` — install core Homebrew packages
- `brew bundle --file Brewfile.personal` — install personal apps (optional, prompted during install)

## Code Style Guidelines

- **Justfile**: keep recipes small and single-purpose; internal recipes are prefixed with `_`
- **OS-specific behavior**: use `just`'s `[macos]` / `[linux]` recipe attributes or the `os()` function — do not branch on `command -v`/`uname` when an attribute fits
- **Shell scripts**: `#!/usr/bin/env bash` with `set -euo pipefail`; quote all expansions
- **Homebrew**: `brew`/`cask` entries grouped by purpose with section comments; core tools in `Brewfile`, personal apps in `Brewfile.personal`
- **Dotfiles**: one `stow` package per tool under `dotfiles/<pkg>/`, mirroring the real home-directory layout
- **Secrets**: never commit personal identity or credentials — git identity lives in `~/.gitconfig-local`, SSH keys in Secretive

## File Organization

- `Justfile` — all setup/maintenance recipes; `_setup-mac` / `_setup-linux` are the OS entry points
- `Brewfile` / `Brewfile.personal` — core vs. optional Homebrew packages
- `dotfiles/<pkg>/` — stow packages (zsh, git, ghostty, vscode, starship)
- `agents/skills/` — canonical skills library, symlinked into each agent's global config; vendor skills come from the `mattpocock-skills` git submodule
- `agents/AGENTS.md`, `agents/statusline.sh` — shared payload shipped to projects/agents
- `install.sh` — bootstrap entry point (clones repo, installs `just`, runs `just install`)

## Testing

- `just --list` and `just --show <recipe>` — verify the Justfile parses and a recipe resolves the expected OS variant
- Re-run `just install` / `just sync` — recipes are idempotent; symlinks should resolve correctly (`ls -la` the targets)
- After editing dotfiles, source to test: `source ~/.zshrc`
- Verify OS-specific recipes on both macOS and Linux where possible
