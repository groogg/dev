#!/usr/bin/env bash
# Bootstrap a Mac: clone this repo and run the setup.
#   curl -fsSL https://raw.githubusercontent.com/groogg/dev/main/install.sh | bash
set -euo pipefail

if [ ! -d ~/dev ]; then
    echo "Cloning dev..."
    git clone https://github.com/groogg/dev.git ~/dev
fi

# Read prompts from the terminal, since stdin is this script when piped via curl | bash
~/dev/mac.sh install </dev/tty
