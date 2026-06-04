#!/usr/bin/env bash
set -euo pipefail

if ! command -v just >/dev/null 2>&1; then
    echo "Installing just..."
    mkdir -p ~/.local/bin
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ ! -d ~/dev ]; then
    echo "Cloning dev..."
    git clone https://github.com/groogg/dev.git ~/dev
fi

just --justfile ~/dev/Justfile install
