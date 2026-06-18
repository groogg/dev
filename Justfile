export PATH := env_var('HOME') + "/.local/bin:/opt/homebrew/bin:/usr/local/bin:" + env_var('HOME') + "/.cargo/bin:" + env_var('PATH')

os := shell('uname')
stow_packages := if os == "Darwin" { "zsh git ghostty starship" } else { "zsh git starship" }

# Show available recipes
default:
    @just --list --unsorted

# Full setup for current OS
install:
    #!/usr/bin/env bash
    [[ "{{ os }}" == "Darwin" ]] && just _setup-mac || just _setup-linux

# Re-stow dotfiles and update skill submodules
sync: _dot _submodules

# Prompt for git name and email if not set
_configure:
    #!/usr/bin/env bash
    if git config -f ~/.gitconfig-local user.name >/dev/null 2>&1 && \
       git config -f ~/.gitconfig-local user.email >/dev/null 2>&1; then
        echo "Git user already configured, skipping."
    else
        printf "Git name: " && read name
        printf "Git email: " && read email
        git config -f ~/.gitconfig-local user.name "$name"
        git config -f ~/.gitconfig-local user.email "$email"
        echo "Git user configured."
    fi

_brew-personal:
    #!/usr/bin/env bash
    printf "Install personal apps? [y/N] " && read answer
    [[ "$answer" =~ ^[Yy]$ ]] && brew bundle --file {{ justfile_directory() }}/Brewfile.personal || echo "Skipping personal apps."

# Set up current directory as a dev project
project:
    ln -sf {{ justfile_directory() }}/agents/AGENTS.md "{{ invocation_directory() }}/AGENTS.md"

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

# Symlink skills from a source directory into Claude and/or Gemini
skills:
    #!/usr/bin/env bash
    set -euo pipefail

    # Prompt for source path
    printf "Path to skills directory: " && read -e src
    src="${src/#\~/$HOME}"

    # Validate source
    if [[ ! -d "$src" ]]; then
        echo "Error: '$src' is not a directory." >&2
        exit 1
    fi

    # Check there are subdirectories to link
    dirs=("$src"/*/)
    if [[ ${#dirs[@]} -eq 0 || ! -d "${dirs[0]}" ]]; then
        echo "Error: no skill subdirectories found in '$src'." >&2
        exit 1
    fi

    # Pick destination(s)
    dest=$(printf 'claude\ngemini\n' | fzf -m --header "Select destination(s) (Tab to multi-select)")
    [[ -z "$dest" ]] && echo "No destination selected." && exit 0

    claude_dir="$HOME/.claude/skills"
    gemini_dir="$HOME/.gemini/config/skills"

    for target in $dest; do
        if [[ "$target" == "claude" ]]; then
            dest_dir="$claude_dir"
        else
            dest_dir="$gemini_dir"
        fi

        mkdir -p "$dest_dir"
        count=0

        for skill in "$src"/*/; do
            name=$(basename "$skill")
            link="$dest_dir/$name"

            # Remove existing entry (directory or old symlink)
            if [[ -e "$link" || -L "$link" ]]; then
                rm -rf "$link"
                echo "  replaced: $name -> $target"
            else
                echo "  linked:   $name -> $target"
            fi

            ln -s "$(cd "$skill" && pwd)" "$link"
            count=$((count + 1))
        done

        echo "✓ $count skill(s) symlinked into $dest_dir"
    done

_submodules:
    #!/usr/bin/env bash
    set -euo pipefail
    git -C {{ justfile_directory() }} submodule update --init --remote

    vendor="{{ justfile_directory() }}/agents/vendor/mattpocock-skills/skills"
    dest="{{ justfile_directory() }}/agents/skills"

    for group in engineering productivity; do
        [[ ! -d "$vendor/$group" ]] && continue
        for skill in "$vendor/$group"/*/; do
            name=$(basename "$skill")
            link="$dest/$name"
            [[ -d "$skill" ]] || continue
            [[ ! -f "$skill/SKILL.md" ]] && continue
            if [[ -L "$link" ]]; then
                rm "$link"
            elif [[ -e "$link" ]]; then
                continue  # don't clobber local skills
            fi
            ln -s "$skill" "$link"
        done
    done
    echo "✓ Vendor skills symlinked"

# --- Internal ---

_setup-mac: _configure _brew _brew-personal _shell _dot _apple _uv _rust _ssh-config _vscode _agentic

_setup-linux: _configure _linux-deps _shell _dot _uv _rust _ssh-config _agentic

_agentic:
    #!/usr/bin/env bash
    selected=$(printf 'claude\nantigravity\n' | fzf -m --header "Select agentic tools to set up (Tab to multi-select)")
    [[ -z "$selected" ]] && exit 0
    [[ "$selected" == *claude* ]] && just _claude
    [[ "$selected" == *antigravity* ]] && just _antigravity

_brew:
    #!/usr/bin/env bash
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$(command -v brew >/dev/null 2>&1 && brew shellenv || /opt/homebrew/bin/brew shellenv)"
    brew bundle --file {{ justfile_directory() }}/Brewfile

_shell:
    #!/usr/bin/env bash
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "RUNZSH=no KEEP_ZSHRC=yes $(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    if [ "$SHELL" != "$(which zsh)" ]; then
        sudo chsh -s "$(which zsh)" "$(whoami)"
    fi

_dot:
    cd {{ justfile_directory() }}/dotfiles && stow --adopt -R -t {{ env_var('HOME') }} {{ stow_packages }}

_apple:
    xcode-select --install || true
    softwareupdate --install rosetta

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
        node_file=$(curl -fsSL https://nodejs.org/dist/latest/ | grep -oP "node-v[\d.]+-linux-${arch}\.tar\.xz" | head -1)
        curl -fsSL -o /tmp/node.tar.xz "https://nodejs.org/dist/latest/${node_file}"
        sudo tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1
        rm /tmp/node.tar.xz
    fi


_claude: _submodules
    #!/usr/bin/env bash
    if ! command -v claude >/dev/null 2>&1; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi
    mkdir -p ~/.claude
    ln -sfn {{ justfile_directory() }}/agents/skills ~/.claude/skills
    ln -sfn {{ justfile_directory() }}/agents/statusline.sh ~/.claude/statusline.sh

_vscode:
    #!/usr/bin/env bash
    dest="$HOME/Library/Application Support/Code/User/settings.json"
    mkdir -p "$(dirname "$dest")"
    ln -sf {{ justfile_directory() }}/dotfiles/vscode/settings.json "$dest"

_ssh-config:
    #!/usr/bin/env bash
    mkdir -p ~/.ssh
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config

    marker_begin="# BEGIN dev-managed"
    marker_end="# END dev-managed"

    # Remove previously managed block so we can re-write it cleanly
    if grep -q "$marker_begin" ~/.ssh/config; then
        sed -i '' "/$marker_begin/,/$marker_end/d" ~/.ssh/config
    fi

    if [[ "{{ os }}" == "Darwin" ]]; then
        # Skip if IdentityAgent is already configured outside our block
        if grep -q "IdentityAgent" ~/.ssh/config 2>/dev/null; then
            echo "Secretive IdentityAgent already configured, skipping."
        else
            printf '\n%s\nHost *\n\tIdentityAgent "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"\n%s\n' \
                "$marker_begin" "$marker_end" >> ~/.ssh/config
            echo "Secretive IdentityAgent added to ~/.ssh/config"
        fi
    else
        if grep -q "AddKeysToAgent" ~/.ssh/config 2>/dev/null; then
            echo "AddKeysToAgent already configured, skipping."
        else
            printf '\n%s\nHost *\n\tAddKeysToAgent yes\n%s\n' \
                "$marker_begin" "$marker_end" >> ~/.ssh/config
            echo "AddKeysToAgent added to ~/.ssh/config"
        fi
    fi

_antigravity: _submodules
    #!/usr/bin/env bash
    if ! command -v agy >/dev/null 2>&1; then
        curl -fsSL https://antigravity.google/cli/install.sh | bash
    fi
    cd {{ justfile_directory() }}/dotfiles && stow --adopt -R -t {{ env_var('HOME') }} gemini
    mkdir -p ~/.gemini/config
    ln -sfn {{ justfile_directory() }}/agents/skills ~/.gemini/config/skills
