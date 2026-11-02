# Agent Instructions for dotfiles repository

This repo manages dotfiles, Homebrew packages, and AI coding-agent setup. It is
driven by `just` (wrapped by a `dev` CLI) and GNU `stow`.

## Build/Install Commands

- `just install` (or `dev install`) — full setup for the current OS (`_setup-mac` / `_setup-linux`)
- `just update` (or `dev update`) — upgrade Homebrew packages and installed toolchains
- `just sync` — re-stow dotfiles
- `just key` — generate a new SSH key (for Linux/non-Secretive setups; on macOS keys are managed by Secretive)
- `brew bundle --file Brewfile` — install the essentials (macOS and Linux)
- `just _brew-pick Brewfile.optional` / `just _brew-pick Brewfile.personal true` — fzf picker for optional tools (none pre-selected) and personal apps (all pre-selected)

## Code Style Guidelines

- **Justfile**: keep recipes small and single-purpose; internal recipes are prefixed with `_`
- **OS-specific behavior**: use `[macos]` / `[linux]` recipe attributes when the recipe bodies differ, and `os()` when only a value differs — never branch on `uname`
- **Shell scripts**: `#!/usr/bin/env bash` with `set -euo pipefail`; quote all expansions; leave one unquoted only when it is a fixed value meant to split or glob, never user input or file contents
- **Homebrew**: `brew`/`cask` entries grouped by purpose with section comments; essentials the setup depends on in `Brewfile` (shared by macOS and Linux; macOS-only entries inside `if OS.mac?`), picked extras in `Brewfile.optional`, personal apps in `Brewfile.personal`. The picker reads plain `brew`/`cask` lines, so the two picked files stay flat; mark a formula with no Linux build `# macOS only`
- **Dotfiles**: one `stow` package per tool under `dotfiles/<pkg>/`, mirroring the real home-directory layout
- **Secrets**: never commit personal identity or credentials — git identity lives in `~/.gitconfig-local`, SSH keys in Secretive

## File Organization

- `Justfile` — all setup/maintenance recipes; `_setup-mac` / `_setup-linux` are the OS entry points
- `Brewfile` / `Brewfile.optional` / `Brewfile.personal` — essentials, optional tools, personal apps
- `dotfiles/<pkg>/` — stow packages (zsh, git, ghostty, vscode, starship)
- `install.sh` — bootstrap entry point (clones repo, installs `just`, runs `just install`)

## Testing

- `just --list` and `just --show <recipe>` — verify the Justfile parses and a recipe resolves the expected OS variant
- Re-run `just install` / `just sync` — recipes are idempotent; symlinks should resolve correctly (`ls -la` the targets)
- After editing dotfiles, source to test: `source ~/.zshrc`
- Verify OS-specific recipes on both macOS and Linux where possible
