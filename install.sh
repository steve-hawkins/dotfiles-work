#!/bin/bash
# Note: Not using set -e to allow script to continue even if some tools fail
# This makes the installation more resilient in different environments

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

warn() {
  echo -e "\033[1;33m[Dotfiles Warning]\033[0m $1"
}

# 1. Zscaler / Network Validation
# We check if we can reach a public endpoint. 
# If Zscaler is intercepting, curl needs the CA bundle.
log "Validating network connectivity (Zscaler check)..."
if ! curl -Is https://github.com > /dev/null 2>&1; then
  warn "Network check failed. Continuing anyway, but some installations may fail."
  warn "If behind Zscaler, ensure NODE_EXTRA_CA_CERTS and REQUESTS_CA_BUNDLE are set."
else
  log "Network connection verified."
fi

# 2. Config Files Association
USER_HOME=${HOME}
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

log "Linking configuration files from $DOTFILES_DIR..."

# Symlink PowerShell profile
PS_CONFIG_DIR="$USER_HOME/.config/powershell"
mkdir -p "$PS_CONFIG_DIR"
if [ -f "$DOTFILES_DIR/Microsoft.PowerShell_profile.ps1" ]; then
  rm -f "$PS_CONFIG_DIR/Microsoft.PowerShell_profile.ps1"
  ln -s "$DOTFILES_DIR/Microsoft.PowerShell_profile.ps1" "$PS_CONFIG_DIR/Microsoft.PowerShell_profile.ps1"
  log "Linked PowerShell profile"
else
  warn "Microsoft.PowerShell_profile.ps1 not found in $DOTFILES_DIR, skipping"
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
  if sudo apt-get install -y zsh; then
    log "Zsh installed successfully"
  else
    error "Failed to install Zsh"
  fi
fi

# Symlink .zshrc
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  rm -f "$USER_HOME/.zshrc"
  ln -s "$DOTFILES_DIR/.zshrc" "$USER_HOME/.zshrc"
  log "Linked .zshrc"
else
  warn ".zshrc not found in $DOTFILES_DIR, skipping"
fi

# Install eza
if ! has_cmd eza; then
  log "Installing eza..."
  # Prerequisites
  if sudo apt-get install -y gpg wget; then
    sudo mkdir -p /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
      if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg; then
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        if sudo apt-get update && sudo apt-get install -y eza; then
          log "eza installed successfully"
        else
          error "Failed to install eza package"
        fi
      else
        error "Failed to download eza GPG key"
      fi
    fi
  else
    error "Failed to install eza prerequisites"
  fi
fi

# Install Oh My Posh
if ! has_cmd oh-my-posh; then
  log "Installing Oh My Posh..."
  if curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin; then
    log "Oh My Posh installed successfully"
  else
    error "Failed to install Oh My Posh"
  fi
fi

# Setup Montys theme
log "Setting up Montys theme..."
mkdir -p "$USER_HOME/.poshthemes"
if curl -sLo "$USER_HOME/.poshthemes/montys.omp.json" https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/montys.omp.json; then
  log "Montys theme installed successfully"
else
  warn "Failed to download Montys theme"
fi

# 4. Specific Utilities

# NPM Utilities
if has_cmd npm; then
  # Azure DevOps MCP
  if ! npm list -g @azure-devops/mcp >/dev/null 2>&1; then
    log "Installing Azure DevOps MCP..."
    if sudo npm install -g @azure-devops/mcp; then
      log "Azure DevOps MCP installed successfully"
    else
      error "Failed to install Azure DevOps MCP"
    fi
  fi

  # GitHub Copilot CLI
  # Using the @github/copilot package as requested for CLI experience
  if ! npm list -g @github/copilot >/dev/null 2>&1; then
    log "Installing GitHub Copilot CLI..."
    if sudo npm install -g @github/copilot; then
      log "GitHub Copilot CLI installed successfully"
    else
      error "Failed to install GitHub Copilot CLI"
    fi
  fi
else
  warn "npm not found. Skipping Azure DevOps MCP and GitHub Copilot CLI."
fi

# uv and spec-kit
if ! has_cmd uv; then
  log "Installing uv..."
  if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    export PATH="$HOME/.local/bin:$PATH"
    log "uv installed successfully"
  else
    error "Failed to install uv"
  fi
fi

if has_cmd uv && ! uv tool list 2>/dev/null | grep -q "specify-cli"; then
  log "Installing spec-kit..."
  if uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --force; then
    log "spec-kit installed successfully"
  else
    error "Failed to install spec-kit"
  fi
fi

# Aspire
if ! has_cmd aspire; then
  log "Installing dotnet Aspire..."
  if curl -sSL https://aspire.dev/install.sh | bash; then
    log "Aspire installed successfully"
  else
    error "Failed to install Aspire"
  fi
fi

# dotnet tools
if has_cmd dotnet; then
  # dotnet outdated
  if ! dotnet tool list --global | grep -q "dotnet-outdated-tool"; then
    log "Installing dotnet-outdated-tool..."
    if dotnet tool install --global dotnet-outdated-tool; then
      log "dotnet-outdated-tool installed successfully"
    else
      error "Failed to install dotnet-outdated-tool"
    fi
  fi
else
  warn "dotnet SDK not found. Skipping dotnet tools."
fi

log "Dotfiles installation complete!"
