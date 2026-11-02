export PATH := env_var('HOME') + "/.local/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:" + env_var('HOME') + "/.cargo/bin:" + env_var('PATH')

# Every dotfiles/<pkg>/; Linux skips the macOS-only apps
stow_packages := if os() == "macos" { "*/" } else { "$(ls -d */ | grep -vxE 'ghostty/|vscode/')" }

# Show available recipes
default:
    @just --list --unsorted

# Full setup for current OS
[macos]
install: _setup-mac

[linux]
install: _setup-linux

# Upgrade installed tools
update: _brew-update _toolchains-update

# Re-stow dotfiles
sync: _dot

# Prompt for git name and email if not set
_configure:
    #!/usr/bin/env bash
    if git config -f ~/.gitconfig-local user.name >/dev/null 2>&1 && \
       git config -f ~/.gitconfig-local user.email >/dev/null 2>&1; then
        echo "Git user already configured, skipping."
    else
        printf "Git name: " && read -r name
        printf "Git email: " && read -r email
        if [[ -z "$name" || -z "$email" ]]; then
            echo "Error: name and email must not be empty."
            exit 1
        fi
        git config -f ~/.gitconfig-local user.name "$name"
        git config -f ~/.gitconfig-local user.email "$email"
        echo "Git user configured."
    fi

# Pick entries from a Brewfile with fzf and install them; all="true" pre-selects every entry.
# Linux only offers `brew` lines not marked "macOS only". Skipped without a terminal (CI).
_brew-pick file all="false":
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -t 0 ]] || { echo "No terminal, skipping {{ file }}."; exit 0; }
    entries=$(awk -v linux={{ if os() == "linux" { "1" } else { "0" } }} \
        '/^(brew|cask) / && !(linux && (/^cask / || /macOS only/))' "{{ justfile_directory() }}/{{ file }}")
    [[ -n "$entries" ]] || exit 0
    # Enter with nothing ticked skips, instead of fzf's default of installing the highlighted line
    picked=$(fzf --multi {{ if all == "true" { "--bind load:select-all" } else { "" } }} \
        --bind 'enter:transform:[[ $FZF_SELECT_COUNT -eq 0 ]] && echo abort || echo accept' \
        --header "{{ file }}: Tab to toggle, Enter to install, Esc to skip" <<< "$entries" || true)
    [[ -n "$picked" ]] || { echo "Nothing picked from {{ file }}."; exit 0; }
    brew bundle --no-upgrade --file=- <<< "$picked"

# Generate a new SSH key
key:
    #!/usr/bin/env bash
    printf "Key name: " && read name
    keytype=$(printf 'ed25519\nrsa\n' | fzf --header "Select key type")
    [[ -z "$keytype" ]] && keytype="ed25519"
    [[ "$keytype" == "rsa" ]] && ssh-keygen -t rsa -b 4096 -f ~/.ssh/$name || ssh-keygen -t ed25519 -f ~/.ssh/$name
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/$name
    cat ~/.ssh/$name.pub

# --- Internal ---

_setup-mac: _configure _brew (_brew-pick "Brewfile.optional") (_brew-pick "Brewfile.personal" "true") _dot _shell _uv _rust _ssh-config _hooks _agentic _macos

_setup-linux: _configure _linux-deps _brew (_brew-pick "Brewfile.optional") _dot _shell _uv _rust _ssh-config _hooks _agentic-optional

_agentic-optional:
    #!/usr/bin/env bash
    printf "Install Claude Code? [y/N] " && read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        just --justfile {{ justfile() }} _agentic
    else
        echo "Skipping Claude Code."
    fi

_brew: _brew-install _brew-bundle

_brew-install:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

# Homebrew's just replaces install.sh's bootstrap copy, which would shadow it on PATH
_brew-bundle:
    brew bundle --no-upgrade --file {{ justfile_directory() }}/Brewfile
    rm -f ~/.local/bin/just

_brew-update:
    brew update
    {{ just_executable() }} --justfile {{ justfile() }} _brew-bundle
    brew upgrade

_shell:
    #!/usr/bin/env bash
    if [ ! -d ~/.oh-my-zsh ]; then
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    if [ "$SHELL" != "$(which zsh)" ]; then
        sudo chsh -s "$(which zsh)" "$(whoami)"
    fi

_dot:
    cd {{ justfile_directory() }}/dotfiles && stow --adopt -R -t {{ env_var('HOME') }} {{ stow_packages }}

_hooks:
    git -C {{ justfile_directory() }} config core.hooksPath .githooks

_uv:
    #!/usr/bin/env bash
    if ! command -v uv >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi

_rust:
    #!/usr/bin/env bash
    if ! command -v rustc >/dev/null 2>&1; then
        curl -sSf https://sh.rustup.rs | sh -s -- -y
    fi

_toolchains-update:
    #!/usr/bin/env bash
    if command -v uv >/dev/null 2>&1; then
        uv self update
    fi
    if command -v rustup >/dev/null 2>&1; then
        rustup update
    fi

# Homebrew's build requirements, plus zsh for the login shell
_linux-deps:
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get update
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get install -y --no-upgrade build-essential procps curl file git zsh

_agentic: _claude

_claude:
    #!/usr/bin/env bash
    if ! command -v claude >/dev/null 2>&1; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi


# macOS keys live in Secretive; Linux keys go through ssh-agent
ssh_agent_option := if os() == "macos" { 'IdentityAgent "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"' } else { "AddKeysToAgent yes" }

_ssh-config:
    #!/usr/bin/env bash
    set -euo pipefail
    option='{{ ssh_agent_option }}'
    mkdir -p ~/.ssh
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
    grep -q "${option%% *}" ~/.ssh/config || printf '\nHost *\n\t%s\n' "$option" >> ~/.ssh/config

_macos:
    #!/usr/bin/env bash
    set -euo pipefail
    plist="$HOME/Library/Preferences/com.apple.dock"

    # Clear existing apps and folders
    defaults delete "$plist" persistent-apps 2>/dev/null || true
    defaults delete "$plist" persistent-others 2>/dev/null || true
    defaults write "$plist" show-recents -bool false

    # Add apps
    apps=(
        "/Applications/Brave Browser.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Ghostty.app"
        "/Applications/Bitwarden.app"
        "/Applications/Slack.app"
        "/System/Applications/Messages.app"
        "/Applications/Spotify.app"
    )
    for app in "${apps[@]}"; do
        [[ -d "$app" ]] || continue
        defaults write "$plist" persistent-apps -array-add \
            "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    done

    killall Dock

    # Login items
    for app in Secretive Flux LookAway; do
        [[ -d "/Applications/$app.app" ]] || continue
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/$app.app\", hidden:false}" >/dev/null 2>&1 || true
    done
