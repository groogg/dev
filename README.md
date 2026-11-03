<div align="center">

<img src="./alien.jpg" width="200" />

</div>

## Mac

```bash
curl -fsSL https://raw.githubusercontent.com/groogg/dev/main/install.sh | bash
```

After that, `dev` runs `~/dev/mac.sh`:

- `dev install` installs what's missing without upgrading anything. It always installs the essentials in `Brewfile`, then opens a picker for optional tools (`Brewfile.optional`, none pre-selected) and personal apps (`Brewfile.personal`, all pre-selected). Tab toggles, Enter installs, Esc skips.
- `dev update` upgrades Homebrew packages and toolchains.
- `dev sync` re-links the dotfiles.

## Remote VMs

On any Linux VM that can reach GitHub, from wherever you connect:

```bash
git clone https://github.com/groogg/dev ~/.dev && ~/.dev/remote.sh
```

It installs starship, fzf, zoxide, ripgrep, fd, gh, Neovim and Claude Code into `~/.local/bin`, links your shell, git, starship and Neovim config, and hooks your aliases into bash (and zsh if the VM uses it). It needs no sudo and doesn't change the login shell. Downloads are checked against GitHub's SHA-256 and skip releases younger than 7 days.

- `~/.dev/remote.sh --update` pulls the repo and refreshes every tool.
- `~/.dev/remote.sh --clean` removes everything it added, including Claude Code's sign-in and `~/.dev` itself, and restores any files it moved aside.

If GitHub's anonymous limit (60 lookups an hour per network) gets in the way, set `GITHUB_TOKEN`, or run `gh auth login` first.

## Git config

Personal identity is kept out of the repo. On first run, both scripts ask for your name and email and write them to `~/.gitconfig-local`, which `dotfiles/git/.gitconfig` includes. Nothing personal is committed.

SSH keys are managed via [Secretive](https://github.com/maxgoedjen/secretive), which stores them in the Secure Enclave. On a VM, use agent forwarding (`ssh -A`) when connecting from your Mac, or create a key there with `ssh-keygen -t ed25519`.
