#!/usr/bin/env bash
# Prompt for git name and email once and store them in ~/.gitconfig-local (kept out of the repo).
set -euo pipefail

if git config -f ~/.gitconfig-local user.name >/dev/null 2>&1 &&
   git config -f ~/.gitconfig-local user.email >/dev/null 2>&1; then
    echo "Git user already configured, skipping."
    exit 0
fi

printf "Git name: " && read -r name
printf "Git email: " && read -r email
if [[ -z "$name" || -z "$email" ]]; then
    echo "Error: name and email must not be empty." >&2
    exit 1
fi
git config -f ~/.gitconfig-local user.name "$name"
git config -f ~/.gitconfig-local user.email "$email"
echo "Git user configured."
