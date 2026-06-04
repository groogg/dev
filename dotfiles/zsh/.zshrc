# --- Oh My Zsh ---

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source $ZSH/oh-my-zsh.sh

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Local secrets (API keys, etc) — not in dotfiles repo
[[ -f ~/.secrets ]] && source ~/.secrets

# --- Tools ---

source <(fzf --zsh)
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# --- Aliases ---

alias python='python3'

# git
alias s='git status'
alias gaa='git add -A'
alias gc='git commit'
alias com='git checkout main'
alias gd='git diff'
alias gdc='git diff --cached'
alias co='git checkout'
alias up='git push'
alias upf='git push --force-with-lease'
alias pu='git pull'
alias pur='git pull --rebase'
alias fe='git fetch'
alias re='git rebase'

# --- Functions ---

mkdircd() {
  mkdir -p "$1" && cd "$1"
}

# [f]uzzy check[o]ut
fo() {
  git branch --no-color --sort=-committerdate --format='%(refname:short)' | fzf --header 'git checkout' | xargs git checkout
}

# [p]ull request check[o]ut
po() {
  gh pr list --author "@me" | fzf --header 'checkout PR' | awk '{print $(NF-5)}' | xargs git checkout
}

dev() {
  just --justfile ~/dev/Justfile "$@"
  [[ "$1" == "sync" ]] && source ~/.zshrc
}
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
