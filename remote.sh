#!/usr/bin/env bash
# Portable dev setup for remote Linux VMs: your home folder only, no sudo, fully removable.
#
#   git clone https://github.com/groogg/dev ~/.dev && ~/.dev/remote.sh
#   ~/.dev/remote.sh --update   pull the repo and refresh every tool
#   ~/.dev/remote.sh --clean    remove everything this script added, sign-ins and ~/.dev included
set -euo pipefail
umask 022 # nothing this script creates is writable by the VM's other users

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bin="$HOME/.local/bin"
state="$HOME/.local/share/dev-remote"
manifest="$state/installed" # files this script created, deleted by --clean
marker="# dev-remote"
min_age=$((7 * 86400)) # supply-chain cooldown: skip releases published in the last 7 days

# Dotfiles linked into $HOME, as "path in repo:path in home"
links=(
    "dotfiles/shell/.config/shell/rc.sh:.config/shell/rc.sh"
    "dotfiles/git/.config/git/ignore:.config/git/ignore"
    "dotfiles/starship/.config/starship.toml:.config/starship.toml"
    "dotfiles/nvim/.config/nvim:.config/nvim"
)

# What the tools write while you use them (gh's GitHub token and Claude Code's sign-in among them).
# --clean deletes these unless they were already on the VM before setup.
tool_data=(
    .config/gh .local/state/gh
    .local/share/nvim .local/state/nvim .cache/nvim
    .local/share/zoxide .cache/starship
    .local/bin/claude .local/share/claude .local/state/claude .cache/claude .claude .claude.json
)

die() { echo "remote.sh: $*" >&2; exit 1; }

record() { owned "$1" || echo "$1" >>"$manifest"; }
owned() { grep -qxF "$1" "$manifest" 2>/dev/null; }

# GET a GitHub API URL. The token, if any, goes in on a file descriptor so other users can't see it in ps.
github_api() {
    if [[ -n "$token" ]]; then
        curl -fsS --retry 3 -H @<(printf 'Authorization: Bearer %s\n' "$token") "$1"
    else
        curl -fsS --retry 3 "$1"
    fi
}

# Print "url sha256" for the newest stable release asset of GitHub repo $1 matching regex $2,
# skipping releases younger than the cooldown
release_asset() {
    local releases
    releases=$(github_api "https://api.github.com/repos/$1/releases?per_page=10") ||
        die "couldn't look up $1's releases (curl's error is above). A 403 means GitHub's limit of 60 lookups an hour per network without a token: wait, or set GITHUB_TOKEN."
    python3 -c '
import calendar, json, re, sys, time
repo, regex, min_age = sys.argv[1], re.compile(sys.argv[2]), int(sys.argv[3])
for release in json.load(sys.stdin):
    published = calendar.timegm(time.strptime(release["published_at"], "%Y-%m-%dT%H:%M:%SZ"))
    if release["draft"] or release["prerelease"] or time.time() - published < min_age:
        continue
    tag = release["tag_name"]
    for asset in release["assets"]:
        if regex.search(asset["name"]) and (asset.get("digest") or "").startswith("sha256:"):
            print(asset["browser_download_url"], asset["digest"][len("sha256:"):])
            sys.exit(0)
    sys.exit(f"remote.sh: no checksummed asset matching {regex.pattern} in {repo} {tag}")
sys.exit(f"remote.sh: no release of {repo} older than the cooldown")
' "$1" "$2" "$min_age" <<<"$releases"
}

# Download that asset to $tmp/asset and check it against GitHub's recorded SHA-256
fetch() {
    local url sum
    read -r url sum < <(release_asset "$1" "$2")
    curl -fsSL --retry 3 -o "$tmp/asset" "$url"
    echo "$sum  $tmp/asset" | sha256sum -c --quiet
}

# Install binary $1 from GitHub repo $2's release asset matching $3
install_tool() {
    # Leave a binary alone if it's already there, unless it's ours and --update asked for a refresh
    [[ -x "$bin/$1" ]] && { [[ -z "$refresh" ]] || ! owned "$bin/$1"; } && return 0
    echo "Installing $1..."
    fetch "$2" "$3"
    rm -rf "$tmp/unpacked" && mkdir "$tmp/unpacked"
    tar -xzf "$tmp/asset" -C "$tmp/unpacked"
    install -m 755 "$(find "$tmp/unpacked" -type f -name "$1" | head -n 1)" "$bin/$1"
    record "$bin/$1"
}

install_tools() {
    local gnu deb
    case "$(uname -m)" in
        x86_64) gnu=x86_64 deb=amd64 ;;
        aarch64) gnu=aarch64 deb=arm64 ;;
        *) die "unsupported CPU: $(uname -m)" ;;
    esac

    install_tool starship starship/starship "^starship-$gnu-unknown-linux-musl\.tar\.gz$"
    install_tool fzf junegunn/fzf "^fzf-.*-linux_$deb\.tar\.gz$"
    install_tool zoxide ajeetdsouza/zoxide "^zoxide-.*-$gnu-unknown-linux-musl\.tar\.gz$"
    install_tool rg BurntSushi/ripgrep "^ripgrep-.*-$gnu-unknown-linux-musl\.tar\.gz$"
    install_tool fd sharkdp/fd "^fd-.*-$gnu-unknown-linux-musl\.tar\.gz$"
    install_tool gh cli/cli "^gh_.*_linux_$deb\.tar\.gz$"

    # Neovim needs its runtime files next to the binary, so it keeps its own folder
    if [[ ! -x "$bin/nvim" ]] || { [[ -n "$refresh" ]] && owned "$bin/nvim"; }; then
        echo "Installing nvim..."
        fetch neovim/neovim "^nvim-linux-${gnu/aarch64/arm64}\.tar\.gz$"
        rm -rf "$state/nvim" && mkdir -p "$state/nvim"
        tar -xzf "$tmp/asset" -C "$state/nvim" --strip-components=1
        ln -sfn "$state/nvim/bin/nvim" "$bin/nvim"
        record "$bin/nvim"
    fi

    # Anthropic's installer is user-space too, and Claude Code updates itself afterwards
    if [[ ! -x "$bin/claude" ]]; then
        echo "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash
    fi
}

link_dotfiles() {
    local pair src dst
    for pair in "${links[@]}"; do
        src="$repo/${pair%%:*}" dst="$HOME/${pair#*:}"
        [[ "$(readlink "$dst" 2>/dev/null)" == "$src" ]] && continue
        mkdir -p "$(dirname "$dst")"
        if [[ -e "$dst" || -L "$dst" ]]; then
            mv "$dst" "$dst.dev-backup"
            echo "Moved your existing $dst to $dst.dev-backup"
        fi
        ln -s "$src" "$dst"
    done
}

# Add this repo's git settings to the VM's own ~/.gitconfig, keeping whatever the client set there
include_gitconfig() {
    local ours="$repo/dotfiles/git/.gitconfig"
    git config --global --get-all include.path 2>/dev/null | grep -qxF "$ours" && return 0
    [[ -f "$HOME/.gitconfig" ]] || record "$HOME/.gitconfig"
    git config --global --add include.path "$ours"
}

# Load rc.sh from bash, and from zsh when the VM uses it, without changing the login shell
hook_shells() {
    local rc
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ "$rc" == */.bashrc || -f "$rc" ]] || continue
        [[ -e "$rc" ]] || record "$rc"
        grep -qF "$marker" "$rc" 2>/dev/null && continue
        # Start on a fresh line without adding a blank one, so --clean leaves the file byte-for-byte as it was
        [[ -s "$rc" && -n "$(tail -c 1 "$rc")" ]] && echo >>"$rc"
        printf '[ -f "$HOME/.config/shell/rc.sh" ] && . "$HOME/.config/shell/rc.sh" %s\n' "$marker" >>"$rc"
    done
}

setup() {
    for cmd in curl tar python3 sha256sum; do
        command -v "$cmd" >/dev/null 2>&1 || die "needs $cmd, which this VM doesn't have"
    done
    local path
    mkdir -p "$bin" "$state"
    for path in "${tool_data[@]}"; do
        [[ -e "$HOME/$path" ]] || record "$HOME/$path"
    done
    # A token lifts GitHub's anonymous limit: GITHUB_TOKEN, GH_TOKEN, or gh's own sign-in
    token=${GITHUB_TOKEN:-${GH_TOKEN:-$("$bin/gh" auth token 2>/dev/null || true)}}
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    # Ask for a git identity only when the VM has none, so the client's stays in charge
    if [[ -t 0 ]] && ! git config --global user.email >/dev/null 2>&1; then
        [[ -e "$HOME/.gitconfig-local" ]] || record "$HOME/.gitconfig-local"
        "$repo/scripts/git-identity.sh"
    fi
    install_tools
    link_dotfiles
    include_gitconfig
    hook_shells
    echo "Done. Open a new shell, or run: source ~/.config/shell/rc.sh"
}

clean() {
    local pair dst rc
    git config --global --unset-all include.path "$repo/dotfiles/git/.gitconfig" 2>/dev/null || true
    [[ -f "$manifest" ]] && xargs -d '\n' rm -rf <"$manifest"
    for pair in "${links[@]}"; do
        dst="$HOME/${pair#*:}"
        [[ "$(readlink "$dst" 2>/dev/null)" == "$repo/${pair%%:*}" ]] && rm "$dst"
        [[ -e "$dst.dev-backup" || -L "$dst.dev-backup" ]] && mv "$dst.dev-backup" "$dst"
    done
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -f "$rc" ]] && sed -i "/$marker\$/d" "$rc"
    done
    rm -rf "$state"
    [[ "$repo" == "$HOME/.dev" ]] && rm -rf "$repo"
    echo "Removed. Open a new shell to drop the aliases from this session."
}

# Show what changed upstream and ask before running it: whoever can push to the repo runs code here
update() {
    local incoming answer
    git -C "$repo" fetch --quiet
    incoming=$(git -C "$repo" log --oneline HEAD..@{u})
    if [[ -n "$incoming" ]]; then
        echo "$incoming"
        [[ -t 0 ]] || die "--update asks before applying new commits; run it from a terminal"
        read -r -p "Apply these commits? [y/N] " answer
        [[ "$answer" == [yY] ]] || die "not updated"
        git -C "$repo" merge --ff-only --quiet @{u}
    fi
    exec "$repo/remote.sh" --refresh
}

[[ "$(uname -s)" == Linux ]] || die "this script is for remote Linux VMs; on the Mac use dev install"
refresh="" token=""
case "${1:-}" in
    "") setup ;;
    --update) update ;;
    --refresh) refresh=1 && setup ;; # internal: re-run by --update after pulling
    --clean) clean ;;
    *) die "usage: remote.sh [--update | --clean]" ;;
esac
