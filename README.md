# Devcontainer Dotfiles

This directory contains configuration files and an installation script to set up your personal development environment across devcontainers.

## Contents

- **install.sh**: The main entry point. Installs utilities (zsh, eza, etc.), tools (Copilot, etc.), and links configuration files.
- **Microsoft.PowerShell_profile.ps1**: Configuration for PowerShell, including Oh My Posh (Montys theme) and `eza` aliases.
- **.zshrc**: Configuration for Zsh, matching the PowerShell setup.

## Usage

### Method 1: VS Code Dotfiles (Recommended)

1. Open VS Code Settings (`Ctrl+,`).
2. Search for "Dotfiles".
3. Set **Dotfiles: Repository** to `https://github.com/steve-hawkins/dotfiles-work`.
4. Set **Dotfiles: Install Command** to `install.sh`.
5. Set **Dotfiles: Target Path** to `~/dotfiles` (or your preferred path).

VS Code will automatically clone this repo and run `install.sh` when building a new devcontainer.

### Method 2: Manual / mounting

You can also mount this folder into your container and run `./install.sh` manually.
