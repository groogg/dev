# Homebrew's installer doesn't put itself on PATH
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Local secrets (API keys, etc) — not in dotfiles repo
[[ -f ~/.secrets ]] && source ~/.secrets

# --- zsh ---

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups auto_cd

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Up/Down search history for what's already typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

alias ls='ls -G'

# Aliases, functions and tools shared with remote VMs
source ~/.config/shell/rc.sh

dev() {
  ~/dev/mac.sh "$@" || return
  if [[ "$1" == "sync" ]]; then source ~/.zshrc; fi
}
