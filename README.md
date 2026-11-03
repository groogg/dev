<div align="center">

<img src="./alien.jpg" width="200" />

</div>

## Mac

```bash
curl -fsSL https://raw.githubusercontent.com/groogg/dev/main/install.sh | bash
```

Then `dev install | update | sync` (it runs `~/dev/mac.sh`): install everything in the `Brewfile` and link the dotfiles, upgrade it all, or just re-link.

## Remote VMs

On any Linux VM that can reach GitHub:

```bash
git clone https://github.com/groogg/dev ~/.dev && ~/.dev/remote.sh
```

Installs starship, fzf, zoxide, ripgrep, fd, gh, Neovim and Claude Code into `~/.local/bin` (checksummed, releases at least 7 days old), links your shell, git, starship and Neovim config, and hooks your aliases into bash or zsh. No sudo, login shell untouched.

`~/.dev/remote.sh --update` refreshes it; `~/.dev/remote.sh --clean` removes everything, sign-ins included.

## Notes

- Git name and email live in `~/.gitconfig-local`, outside the repo; both scripts ask for them once.
- SSH keys live in [Secretive](https://github.com/maxgoedjen/secretive). On a VM, forward them with `ssh -A`, or make a key there with `ssh-keygen -t ed25519`.
