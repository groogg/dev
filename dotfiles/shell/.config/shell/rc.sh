# Shell setup shared by macOS (zsh) and remote VMs (bash or zsh). Sourced, so no strict mode.

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac

# --- History, completion and Up/Down search for what's already typed, alike in zsh and bash ---

HISTSIZE=50000
if [ -n "${ZSH_VERSION:-}" ]; then
  HISTFILE=~/.zsh_history
  SAVEHIST=50000
  setopt share_history hist_ignore_all_dups auto_cd
  autoload -Uz compinit && compinit
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
  autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey '^[[A' up-line-or-beginning-search
  bindkey '^[[B' down-line-or-beginning-search
elif [[ $- == *i* ]]; then
  HISTFILESIZE=50000
  HISTCONTROL=ignoredups:erasedups
  shopt -s histappend autocd
  bind 'set completion-ignore-case on'
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
fi

# --- Tools ---

if [ -n "${ZSH_VERSION:-}" ]; then _shell=zsh; else _shell=bash; fi
command -v fzf >/dev/null 2>&1 && eval "$(fzf --$_shell)"
command -v starship >/dev/null 2>&1 && eval "$(starship init $_shell)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init $_shell)"
unset _shell

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
