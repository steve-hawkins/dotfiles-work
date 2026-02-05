#!/bin/bash
set -e

# Logger
log() {
  echo -e "\033[1;32m[Dotfiles]\033[0m $1"
}

error() {
  echo -e "\033[1;31m[Dotfiles Error]\033[0m $1"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

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
