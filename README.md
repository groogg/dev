<div align="center">

<img src="./alien.jpg" width="200" />

</div>

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/groogg/dev/main/install.sh | bash
```

## Usage

A `dev` CLI is available after install — it wraps the underlying `just` commands. Run `dev` at any time to see available commands.

- `dev install` installs missing dependencies and applies the configuration without upgrading existing tools. It always installs the essentials in `Brewfile`, then opens a picker for optional tools (`Brewfile.optional`, none pre-selected) and, on macOS, personal apps (`Brewfile.personal`, all pre-selected). Tab toggles, Enter installs, Esc skips.
- `dev update` upgrades Homebrew packages and updates installed toolchains, on macOS and Linux.
- `dev sync` re-applies dotfile symlinks without downloading or upgrading anything.

## Git config

Personal identity is kept out of the repo. On first run, `dev install` prompts for your name and email and writes them to `~/.gitconfig-local`, which is included by `dotfiles/git/.gitconfig` at runtime. Nothing personal is committed.

SSH keys are managed via [Secretive](https://github.com/maxgoedjen/secretive), which stores them in the Secure Enclave (macOS only).

## Agentic setup

The install optionally sets up Claude Code.
