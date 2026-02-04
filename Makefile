export PATH := $(HOME)/.local/bin:$(PATH)

brew:
	if ! command -v brew >/dev/null 2>&1; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	else \
		echo "Homebrew already installed"; \
	fi

	brew bundle

.PHONY: shell
shell:
	if [ ! -d $(HOME)/.oh-my-zsh ]; then \
		sh -c "RUNZSH=no KEEP_ZSHRC=yes $$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; \
	fi
	if [ "$$SHELL" != "$$(which zsh)" ]; then \
		sudo chsh -s $$(which zsh) $$(whoami); \
	fi

STOW_PACKAGES := zsh git ghostty nvim zed starship claude

dot:
	cd dotfiles && stow -R -t $(HOME) $(STOW_PACKAGES)

apple:
	xcode-select --install || true
	softwareupdate --install rosetta

uv:
	if ! command -v uv >/dev/null 2>&1; then \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	fi

rust:
	if ! command -v rustc >/dev/null 2>&1; then \
		curl -sSf https://sh.rustup.rs | sh -s -- -y; \
	fi

nvim-clean:
	rm -rf $(HOME)/.config/nvim
	rm -rf $(HOME)/.local/share/nvim
	rm -rf $(HOME)/.local/state/nvim
	rm -rf $(HOME)/.cache/nvim

VM_STOW := zsh git nvim starship

vm-deps:
	sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get update
	sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get install -y --no-upgrade git stow zsh make ripgrep curl unzip gcc

	# fzf
	if ! command -v fzf >/dev/null 2>&1; then \
		arch=$$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/'); \
		ver=$$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep tag_name | cut -d'"' -f4 | tr -d v); \
		curl -fsSL -o /tmp/fzf.tar.gz https://github.com/junegunn/fzf/releases/latest/download/fzf-$$ver-linux_$$arch.tar.gz; \
		sudo tar -xzf /tmp/fzf.tar.gz -C /usr/local/bin; \
		rm /tmp/fzf.tar.gz; \
	fi

	# neovim (need >= 0.10)
	if ! nvim --version 2>/dev/null | head -1 | grep -qE '0\.(1[0-9]|[2-9][0-9])|[1-9]+\.'; then \
		arch=$$(uname -m | sed 's/aarch64/arm64/'); \
		curl -fsSL -o /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$$arch.tar.gz; \
		sudo tar -xzf /tmp/nvim.tar.gz -C /usr/local --strip-components=1; \
		rm /tmp/nvim.tar.gz; \
	fi

	# gh cli
	if ! command -v gh >/dev/null 2>&1; then \
		curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null; \
		sudo apt-get update && sudo apt-get install -y gh; \
	fi

	# zoxide
	if ! command -v zoxide >/dev/null 2>&1; then \
		curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; \
	fi

	# starship
	if ! command -v starship >/dev/null 2>&1; then \
		curl -sS https://starship.rs/install.sh | sh -s -- -y; \
	fi

	# node.js (needed for npx/mcp servers)
	if ! command -v node >/dev/null 2>&1; then \
		arch=$$(uname -m | sed 's/x86_64/x64/' | sed 's/aarch64/arm64/'); \
		curl -fsSL -o /tmp/node.tar.xz https://nodejs.org/dist/latest/node-$$(curl -fsSL https://nodejs.org/dist/latest/ | grep -oP 'node-v[\d.]+-linux-'$$arch'.tar.xz' | head -1); \
		sudo tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1; \
		rm /tmp/node.tar.xz; \
	fi

	# claude-code
	if ! command -v claude >/dev/null 2>&1; then \
		curl -fsSL https://claude.ai/install.sh | bash; \
	fi

vm-dot:
	cd dotfiles && stow -R -t $(HOME) $(VM_STOW)

setup-vm: vm-deps shell vm-dot uv rust claude-mcp claude-skills

claude-skills:
	cd dotfiles && stow -R -t $(HOME) claude

claude-mcp:
	claude mcp remove --scope user context7 2>/dev/null || true
	claude mcp remove --scope user serena 2>/dev/null || true
	claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
	claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd --open-web-dashboard false

ssh-config:
	mkdir -p $(HOME)/.ssh
	grep -q "AddKeysToAgent" $(HOME)/.ssh/config 2>/dev/null || printf "Host *\n\tAddKeysToAgent yes\n\tUseKeyChain yes\n" >> $(HOME)/.ssh/config
	chmod 600 $(HOME)/.ssh/config

setup-mac: brew shell dot apple uv rust ssh-config claude-mcp
