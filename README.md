<div align="center">

<img src="./alien.jpg" width="200" />

</div>

## Mac

```bash
curl -fsSL https://raw.githubusercontent.com/groogg/dev/main/install.sh | bash
```

Then `dev install | update | sync` (`dev` links to `~/dev/mac.sh`): install everything in the `Brewfile` and link the dotfiles, upgrade it all, or just re-link.

## Remote VMs

On any Linux VM that can reach GitHub:

```bash
git clone https://github.com/groogg/dev ~/.dev && ~/.dev/remote.sh
```

No sudo: everything stays in your home folder, and the login shell is untouched.

`~/.dev/remote.sh --update` refreshes it; `~/.dev/remote.sh --clean` removes everything, sign-ins included.

## Notes

- Git name and email live in `~/.gitconfig-local`, outside the repo; both scripts ask for them once.
- SSH keys live in [Secretive](https://github.com/maxgoedjen/secretive). On a VM, forward them with `ssh -A`, or make a key there with `ssh-keygen -t ed25519`.
