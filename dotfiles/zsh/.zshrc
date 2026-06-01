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
    project)
      ln -sf ~/dev/AGENTS.md ./AGENTS.md
      echo "Linked AGENTS.md"
      mkdir -p .vscode
      ln -sf ~/dev/.vscode/settings.json ./.vscode/settings.json
      echo "Linked .vscode/settings.json"
      uvx --from git+https://github.com/oraios/serena serena project create "$(pwd)"
      echo "Initialized Serena project"
      ;;
    install)
      echo "Select environment:"
      echo "  1) macOS (default)"
      echo "  2) Linux"
      printf "Choice: " && read choice
      if [ "$choice" = "2" ]; then
        make -C ~/dev setup-linux
      else
        make -C ~/dev setup-mac
      fi
      ;;
    sync)
      echo "Select environment:"
      echo "  1) macOS (default)"
      echo "  2) Linux"
      printf "Choice: " && read choice
      if [ "$choice" = "2" ]; then
        make -C ~/dev linux-dot
      else
        make -C ~/dev dot
      fi
      source ~/.zshrc
      echo "Dotfiles re-stowed and shell reloaded"
      ;;
    key)
      printf "Key name: " && read name
      ssh-keygen -t ed25519 -f ~/.ssh/$name
      eval "$(ssh-agent -s)"
      ssh-add ~/.ssh/$name
      echo "Public key:"
      cat ~/.ssh/$name.pub
      ;;
    identity)
      printf "Name: " && read name
      printf "Git email: " && read email
      printf "Directory (e.g. ~/work): " && read dir
      dir="${dir/#\~/$HOME}"
      printf "Key type [ed25519/rsa] (default: ed25519): " && read keytype
      if [[ "$keytype" == "rsa" ]]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/$name
      else
        ssh-keygen -t ed25519 -f ~/.ssh/$name
      fi
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
    identity-remove)
      identities=(${(f)"$(ls ~/.gitconfig-* 2>/dev/null | sed 's|.*\.gitconfig-||')"})
      if [[ ${#identities[@]} -eq 0 ]]; then
        echo "No identities found."
        return 1
      fi
      echo "Select identity to remove:"
      for i in {1..${#identities[@]}}; do
        echo "  $i) ${identities[$i]}"
      done
      printf "Choice: " && read choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#identities[@]} )); then
        name="${identities[$choice]}"
      elif (( ${identities[(Ie)$choice]} )); then
        name="$choice"
      else
        echo "Invalid choice."
        return 1
      fi
      printf "Remove identity '$name'? This deletes the SSH key and git config. [y/N]: " && read confirm
      if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        return 0
      fi
      rm -f ~/.ssh/$name ~/.ssh/$name.pub ~/.gitconfig-$name
      if [[ -f ~/.gitconfig-local ]]; then
        # Remove the includeIf block referencing this identity (2-line block)
        perl -i -0pe "s/\n\[includeIf [^\]]*\]\n\tpath = ~\/\.gitconfig-$name//g" ~/.gitconfig-local
      fi
      echo "Identity '$name' removed."
      ;;
    *) echo "Usage: dev {project|install|sync|key|identity|identity-remove}" ;;
  esac
}
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
