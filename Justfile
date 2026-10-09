export PATH := env_var('HOME') + "/.local/bin:/opt/homebrew/bin:/usr/local/bin:" + env_var('HOME') + "/.cargo/bin:" + env_var('PATH')

stow_packages := if os() == "macos" { "zsh git ghostty vscode nvim starship" } else { "zsh git nvim starship" }

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

_brew:
    #!/usr/bin/env bash
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew bundle --no-upgrade --file {{ justfile_directory() }}/Brewfile

_brew-update:
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
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get update
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get install -y --no-upgrade \
        git stow zsh make ripgrep curl unzip gcc

    if ! command -v fzf >/dev/null 2>&1; then
        arch=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
        ver=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep tag_name | cut -d'"' -f4 | tr -d v)
        curl -fsSL -o /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/latest/download/fzf-${ver}-linux_${arch}.tar.gz"
        sudo tar -xzf /tmp/fzf.tar.gz -C /usr/local/bin
        rm /tmp/fzf.tar.gz
    fi

    if ! command -v gitleaks >/dev/null 2>&1; then
        arch=$(uname -m | sed 's/x86_64/x64/' | sed 's/aarch64/arm64/')
        ver=$(curl -fsSL https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep tag_name | cut -d'"' -f4 | tr -d v)
        asset="gitleaks_${ver}_linux_${arch}.tar.gz"
        curl -fsSL -o "/tmp/${asset}" "https://github.com/gitleaks/gitleaks/releases/latest/download/${asset}"
        curl -fsSL -o /tmp/gitleaks_checksums.txt "https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_${ver}_checksums.txt"
        grep "  ${asset}$" /tmp/gitleaks_checksums.txt > /tmp/gitleaks.sha256
        (cd /tmp && sha256sum -c gitleaks.sha256)
        sudo tar -xzf "/tmp/${asset}" -C /usr/local/bin gitleaks
        rm "/tmp/${asset}" /tmp/gitleaks_checksums.txt /tmp/gitleaks.sha256
    fi

    # Neovim plugins require >= 0.10; distro packages may be older.
    if ! nvim --version 2>/dev/null | head -1 | grep -qE '0\.(1[0-9]|[2-9][0-9])|[1-9]+\.'; then
        arch=$(uname -m | sed 's/aarch64/arm64/')
        curl -fsSL -o /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz"
        sudo tar -xzf /tmp/nvim.tar.gz -C /usr/local --strip-components=1
        rm /tmp/nvim.tar.gz
    fi

    if ! command -v gh >/dev/null 2>&1; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update && sudo apt-get install -y gh
    fi

    if ! command -v zoxide >/dev/null 2>&1; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    if ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    if ! command -v node >/dev/null 2>&1; then
        arch=$(uname -m | sed 's/x86_64/x64/' | sed 's/aarch64/arm64/')
        node_file=$(curl -fsSL https://nodejs.org/dist/latest/ | grep -oE "node-v[0-9.]+-linux-${arch}\.tar\.xz" | head -1)
        curl -fsSL -o /tmp/node.tar.xz "https://nodejs.org/dist/latest/${node_file}"
        sudo tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1
        rm /tmp/node.tar.xz
    fi


_agentic: _claude

_claude:
    #!/usr/bin/env bash
    if ! command -v claude >/dev/null 2>&1; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi


_ssh-config:
    #!/usr/bin/env bash
    mkdir -p ~/.ssh
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
    if [[ "{{ os() }}" == "macos" ]]; then
        grep -q "IdentityAgent" ~/.ssh/config 2>/dev/null || \
            printf '\nHost *\n\tIdentityAgent "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"\n' >> ~/.ssh/config
    else
        grep -q "AddKeysToAgent" ~/.ssh/config 2>/dev/null || \
            printf '\nHost *\n\tAddKeysToAgent yes\n' >> ~/.ssh/config
    fi

_macos:
    #!/usr/bin/env bash
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
        defaults write "$plist" persistent-apps -array-add \
            "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    done

    killall Dock

    # Login items
    for app in Secretive Flux LookAway; do
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/$app.app\", hidden:false}" >/dev/null 2>&1 || true
    done
