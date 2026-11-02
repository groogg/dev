export PATH := env_var('HOME') + "/.local/bin:/opt/homebrew/bin:/usr/local/bin:" + env_var('HOME') + "/.cargo/bin:" + env_var('PATH')

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
[macos]
update: _brew-update _toolchains-update

[linux]
update: _toolchains-update

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

_brew-personal:
    #!/usr/bin/env bash
    printf "Install personal apps? [y/N] " && read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        brew bundle --no-upgrade --file {{ justfile_directory() }}/Brewfile.personal
    else
        echo "Skipping personal apps."
    fi

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

_setup-mac: _configure _brew _brew-personal _shell _dot _uv _rust _ssh-config _hooks _agentic _macos

_setup-linux: _configure _linux-deps _shell _dot _uv _rust _ssh-config _hooks _agentic-optional

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
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

# Homebrew's just replaces install.sh's bootstrap copy, which would shadow it on PATH
_brew-bundle:
    brew bundle --no-upgrade --file {{ justfile_directory() }}/Brewfile
    rm -f ~/.local/bin/just

_brew-update: _brew-bundle
    brew update
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

_linux-deps:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get update
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get install -y --no-upgrade \
        git stow zsh make ripgrep curl unzip xz-utils gcc jq zoxide

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    case "$(uname -m)" in
        x86_64) gnu=x86_64 deb=amd64 short=x64 ;;
        aarch64) gnu=aarch64 deb=arm64 short=arm64 ;;
    esac

    # Download the latest release asset matching $2 from GitHub repo $1 to $tmp/asset,
    # checked against the SHA-256 GitHub records for it
    gh_release() {
        local url digest
        read -r url digest < <(curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
            | jq -r --arg re "$2" '.assets[] | select(.name | test($re)) | "\(.browser_download_url) \(.digest)"')
        [[ "$digest" == sha256:* ]] || { echo "No SHA-256 for $1 release asset" >&2; return 1; }
        curl -fsSL -o "$tmp/asset" "$url"
        echo "${digest#sha256:}  $tmp/asset" | sha256sum -c --quiet
    }

    if ! command -v fzf >/dev/null 2>&1; then
        gh_release junegunn/fzf "linux_${deb}\\.tar\\.gz$"
        sudo tar -xzf "$tmp/asset" -C /usr/local/bin fzf
    fi

    if ! command -v gitleaks >/dev/null 2>&1; then
        gh_release gitleaks/gitleaks "linux_${short}\\.tar\\.gz$"
        sudo tar -xzf "$tmp/asset" -C /usr/local/bin gitleaks
    fi

    # Neovim plugins require >= 0.10; distro packages may be older.
    if ! nvim --version 2>/dev/null | head -1 | grep -qE '0\.(1[0-9]|[2-9][0-9])|[1-9]+\.'; then
        gh_release neovim/neovim "^nvim-linux-${gnu/aarch64/arm64}\\.tar\\.gz$"
        sudo tar -xzf "$tmp/asset" -C /usr/local --strip-components=1
    fi

    if ! command -v starship >/dev/null 2>&1; then
        gh_release starship/starship "^starship-${gnu}-unknown-linux-musl\\.tar\\.gz$"
        sudo tar -xzf "$tmp/asset" -C /usr/local/bin starship
    fi

    if ! command -v gh >/dev/null 2>&1; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update && sudo apt-get install -y gh
    fi

    if ! command -v node >/dev/null 2>&1; then
        read -r sum name < <(curl -fsSL https://nodejs.org/dist/latest/SHASUMS256.txt | grep -E "  node-v[0-9.]+-linux-${short}\\.tar\\.xz$")
        curl -fsSL -o "$tmp/asset" "https://nodejs.org/dist/latest/${name}"
        echo "${sum}  $tmp/asset" | sha256sum -c --quiet
        sudo tar -xJf "$tmp/asset" -C /usr/local --strip-components=1
    fi

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
