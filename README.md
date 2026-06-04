<div align="center">

<img src="./alien.jpg" width="200" />

</div>

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/groogg/dev/main/install.sh | bash
```

## Usage

A `dev` CLI is available after install — it wraps the underlying `just` commands. Run `dev` at any time to see available commands.

## Git config

Personal identity is kept out of the repo. On first run, `dev install` prompts for your name and email and writes them to `~/.gitconfig-local`, which is included by `dotfiles/git/.gitconfig` at runtime. Nothing personal is committed.

SSH keys are managed via [Secretive](https://github.com/maxgoedjen/secretive), which stores them in the Secure Enclave (macOS only).

## Agentic setup

The install optionally sets up AI coding agents with a shared library of instructions and skills. See [`agents/skills/`](agents/skills/) for details.

