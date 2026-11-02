# Essentials, always installed: the setup and dotfiles depend on these

# shell and setup
brew 'git'
brew 'gitleaks' # pre-commit hook
brew 'stow'
brew 'just'
brew 'make'
brew 'fzf'
brew 'starship'
brew 'zoxide'
brew 'jq'

# editor and code
brew 'neovim'
brew 'ripgrep'
brew 'fd'
brew 'node'
brew 'gh'

# macOS only: apps, and zsh (Linux uses apt's, which chsh accepts)
if OS.mac?
  brew 'zsh'
  cask 'ghostty'
  cask 'secretive' # ~/.ssh/config points at its agent
  cask 'font-jetbrains-mono-nerd-font' # starship's icons
  cask 'visual-studio-code'
  cask 'claude-code'
end
