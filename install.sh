#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v just >/dev/null 2>&1; then
    echo "Installing just..."
    mkdir -p ~/.local/bin
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
fi

if [ ! -d ~/dev ]; then
    echo "Cloning dev..."
    git clone https://github.com/groogg/dev.git ~/dev
fi

# Redirect stdin from terminal so interactive prompts work when piped via curl | bash
just --justfile ~/dev/Justfile install </dev/tty
