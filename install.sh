#!/bin/bash
set -e

# Polyfill sudo if not present (e.g. running as root in container)
if ! command -v sudo >/dev/null 2>&1; then
  sudo() {
    "$@"
  }
fi

# Logger
log() {
  echo -e "\033[1;32m[Dotfiles]\033[0m $1"
}

error() {
  echo -e "\033[1;31m[Dotfiles Error]\033[0m $1"
}

# 1. Zscaler / Network Validation
# We check if we can reach a public endpoint. 
# If Zscaler is intercepting, curl needs the CA bundle.
log "Validating network connectivity (Zscaler check)..."
if ! curl -Is https://github.com > /dev/null; then
  error "Network check failed. Please ensure Zscaler certificates are correctly configured in the devcontainer."
  error "Ensure NODE_EXTRA_CA_CERTS and REQUESTS_CA_BUNDLE are set if behind Zscaler."
  exit 1
fi
log "Network connection verified."

# 2. Config Files Association
USER_HOME=${HOME}
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

log "Linking configuration files from $DOTFILES_DIR..."

# Symlink .zshrc
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  rm -f "$USER_HOME/.zshrc"
  ln -s "$DOTFILES_DIR/.zshrc" "$USER_HOME/.zshrc"
  log "Linked .zshrc"
fi

# Symlink PowerShell profile
PS_CONFIG_DIR="$USER_HOME/.config/powershell"
mkdir -p "$PS_CONFIG_DIR"
if [ -f "$DOTFILES_DIR/Microsoft.PowerShell_profile.ps1" ]; then
  rm -f "$PS_CONFIG_DIR/Microsoft.PowerShell_profile.ps1"
  ln -s "$DOTFILES_DIR/Microsoft.PowerShell_profile.ps1" "$PS_CONFIG_DIR/Microsoft.PowerShell_profile.ps1"
  log "Linked PowerShell profile"
fi

# 3. Core Utilities

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# Update package lists if we are going to install apt packages
if ! has_cmd zsh || ! has_cmd eza; then
  if [ -f "/etc/debian_version" ]; then
    log "Updating apt..."
    sudo apt-get update
  fi
fi

# Install Zsh
if ! has_cmd zsh; then
  log "Installing Zsh..."
  sudo apt-get install -y zsh
fi

# Install eza
if ! has_cmd eza; then
  log "Installing eza..."
  # Prerequisites
  sudo apt-get install -y gpg wget
  sudo mkdir -p /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update && sudo apt-get install -y eza
fi

# Install Oh My Posh
if ! has_cmd oh-my-posh; then
  log "Installing Oh My Posh..."
  curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin
fi

# Setup Montys theme
log "Setting up Montys theme..."
mkdir -p "$USER_HOME/.poshthemes"
curl -sLo "$USER_HOME/.poshthemes/montys.omp.json" https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/montys.omp.json


# 4. Specific Utilities

# NPM Utilities
if has_cmd npm; then
  # Azure DevOps MCP
  if ! npm list -g @azure-devops/mcp >/dev/null 2>&1; then
    log "Installing Azure DevOps MCP..."
    sudo npm install -g @azure-devops/mcp
  fi

  # GitHub Copilot CLI
  # Using the @githubnext/github-copilot-cli package as requested for CLI experience
  if ! npm list -g @githubnext/github-copilot-cli >/dev/null 2>&1; then
    log "Installing GitHub Copilot CLI..."
    sudo npm install -g @githubnext/github-copilot-cli
  fi
else
  error "npm not found. Cannot install Azure DevOps MCP or GitHub Copilot CLI."
fi

# uv and spec-kit
if ! has_cmd uv; then
  log "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! uv tool list 2>/dev/null | grep -q "specify-cli"; then
  log "Installing spec-kit..."
  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --force
fi

# dotnet tools
if has_cmd dotnet; then
  # Aspire
  if ! dotnet workload list | grep -q aspire; then
    log "Installing dotnet Aspire workload..."
    # This might require sudo if dotnet is installed in root location
    sudo dotnet workload install aspire
  fi

  # dotnet outdated
  if ! dotnet tool list -g | grep -q "dotnet-outdated-tool"; then
    log "Installing dotnet-outdated-tool..."
    dotnet tool install --global dotnet-outdated-tool
  fi
else
  error "dotnet SDK not found. Skipping dotnet tools."
fi

# VS Code Extensions
if has_cmd code; then
  log "Checking VS Code extensions..."

  EXTENSIONS=(
    "streetsidesoftware.code-spell-checker"
    "yzhang.markdown-all-in-one"
    "davidanson.vscode-markdownlint"
    "esbenp.prettier-vscode"
    "eamodio.gitlens"
    "ms-vscode.powershell"
    "redhat.vscode-yaml"
  )

  for ext in "${EXTENSIONS[@]}"; do
    if ! code --list-extensions | grep -qi "^${ext}$"; then
      log "Installing VS Code extension: $ext"
      code --install-extension "$ext"
    fi
  done
else
  error "VS Code CLI not found. Skipping extension installation."
fi

log "Dotfiles installation complete!"
