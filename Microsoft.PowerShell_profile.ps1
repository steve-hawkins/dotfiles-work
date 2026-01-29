# Microsoft.PowerShell_profile.ps1

# Path Configuration
$paths = @(
    "$env:HOME/.local/bin",
    "$env:HOME/.dotnet/tools"
)

foreach ($path in $paths) {
    if ($env:PATH -notlike "*$path*") {
        if ($IsLinux -or $IsMacOS) {
            $env:PATH = "$path:$env:PATH"
        } else {
            $env:PATH = "$path;$env:PATH"
        }
    }
}

# Initialize Oh My Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:HOME/.poshthemes/montys.omp.json" | Invoke-Expression
}

# Eza Alias Configuration
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function Get-ChildItemEza {
        # Pass all arguments to eza along with user preferences
        eza $args --icons --oneline --long --git --no-permissions --no-filesize --no-user --changed --all --group-directories-first --colour-scale --time-style relative
    }
    
    # Override standard ls alias
    Set-Alias -Name ls -Value Get-ChildItemEza -Scope Global -Force
}
