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
  case "$1" in
    init)
      ln -sf ~/dev/AGENTS.md ./AGENTS.md
      echo "Linked AGENTS.md"
      mkdir -p .vscode
      ln -sf ~/dev/.vscode/settings.json ./.vscode/settings.json
      echo "Linked .vscode/settings.json"
      uvx --from git+https://github.com/oraios/serena serena project create "$(pwd)"
      echo "Initialized Serena project"
      ;;
    edit)
      nvim ~/dev
      ;;
    setup)
      echo "Select environment:"
      echo "  1) macOS (default)"
      echo "  2) VM"
      printf "Choice: " && read choice
      if [ "$choice" = "2" ]; then
        make -C ~/dev setup-vm
      else
        make -C ~/dev setup-mac
      fi
      ;;
    ssh-key)
      printf "Key name: " && read name
      ssh-keygen -t ed25519 -f ~/.ssh/$name
      eval "$(ssh-agent -s)"
      ssh-add ~/.ssh/$name
      echo "Public key:"
      cat ~/.ssh/$name.pub
      ;;
    git-setup)
      printf "Name: " && read name
      printf "Git email: " && read email
      printf "Directory (e.g. ~/work): " && read dir
      dir="${dir/#\~/$HOME}"
      ssh-keygen -t ed25519 -f ~/.ssh/$name
      eval "$(ssh-agent -s)"
      ssh-add ~/.ssh/$name
      echo "Public key:"
      cat ~/.ssh/$name.pub
      cat > ~/.gitconfig-$name <<EOF
[user]
	email = $email

[core]
	sshCommand = ssh -o IdentitiesOnly=yes -i ~/.ssh/$name
EOF
      echo "\n[includeIf \"gitdir:$dir/\"]" >> ~/.gitconfig-local
      echo "\tpath = ~/.gitconfig-$name" >> ~/.gitconfig-local
      mkdir -p "$dir"
      echo "Done! Clone repos into $dir/"
      ;;
    source)
      echo "Select environment:"
      echo "  1) macOS (default)"
      echo "  2) VM"
      printf "Choice: " && read choice
      if [ "$choice" = "2" ]; then
        make -C ~/dev vm-dot
      else
        make -C ~/dev dot
      fi
      source ~/.zshrc
      echo "Dotfiles re-stowed and shell reloaded"
      ;;
    *) echo "Usage: dev {init|edit|setup|source|ssh-key|git-setup}" ;;
  esac
}
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
