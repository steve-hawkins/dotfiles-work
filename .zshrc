# .zshrc

# Ensure paths
export PATH="$HOME/.local/bin:$HOME/.dotnet/tools:$PATH"

# Initialize Oh My Posh
if command -v oh-my-posh > /dev/null; then
    eval "$(oh-my-posh init zsh --config ~/.poshthemes/montys.omp.json)"
fi

# Aliases
alias ls='eza --icons --oneline --long --git --no-permissions --no-filesize --no-user --changed --all --group-directories-first --colour-scale --time-style relative'

# Enable command auto-correction
setopt CORRECT

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# Editor
export EDITOR='code'
