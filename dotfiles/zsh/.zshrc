# Homebrew's installer doesn't put itself on PATH
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Local secrets (API keys, etc) — not in dotfiles repo
[[ -f ~/.secrets ]] && source ~/.secrets

alias ls='ls -G'

# History, completion, aliases and tools, shared with remote VMs
source ~/.config/shell/rc.sh
