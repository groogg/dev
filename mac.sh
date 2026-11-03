#!/usr/bin/env bash
# macOS setup. Remote Linux VMs use remote.sh instead.
#
#   ./mac.sh install   full setup (safe to re-run; installs what's missing, upgrades nothing)
#   ./mac.sh update    upgrade Homebrew packages and toolchains
#   ./mac.sh sync      re-link dotfiles
#
# Once ~/.zshrc is linked, `dev install|update|sync` runs this script.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PATH="/opt/homebrew/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

brew_install() {
    command -v brew >/dev/null 2>&1 && return 0
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

brew_bundle() {
    brew bundle --no-upgrade --file "$repo/Brewfile"
}

link_dotfiles() {
    (cd "$repo/dotfiles" && stow -R -t "$HOME" */)
}

toolchains() {
    command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
    command -v rustc >/dev/null 2>&1 || curl -sSf https://sh.rustup.rs | sh -s -- -y
}

toolchains_update() {
    if command -v uv >/dev/null 2>&1; then uv self update; fi
    if command -v rustup >/dev/null 2>&1; then rustup update; fi
}

# SSH keys live in Secretive
ssh_config() {
    mkdir -p ~/.ssh
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
    grep -q "IdentityAgent" ~/.ssh/config ||
        printf '\nHost *\n\tIdentityAgent "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"\n' >>~/.ssh/config
}

git_hooks() {
    git -C "$repo" config core.hooksPath .githooks
}

macos_prefs() {
    local plist="$HOME/Library/Preferences/com.apple.dock" app

    # Clear existing apps and folders
    defaults delete "$plist" persistent-apps 2>/dev/null || true
    defaults delete "$plist" persistent-others 2>/dev/null || true
    defaults write "$plist" show-recents -bool false

    # Add apps
    local apps=(
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
}

case "${1:-}" in
    install)
        "$repo/scripts/git-identity.sh"
        brew_install
        brew_bundle
        link_dotfiles
        toolchains
        ssh_config
        git_hooks
        macos_prefs
        ;;
    update)
        brew update
        brew_bundle
        brew upgrade
        toolchains_update
        ;;
    sync) link_dotfiles ;;
    *)
        echo "usage: mac.sh install | update | sync" >&2
        exit 1
        ;;
esac
