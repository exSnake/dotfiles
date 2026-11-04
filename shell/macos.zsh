# ============================================================================
#  MACOS — configurazione specifica macOS
# ============================================================================
# Caricato da shell/common.zsh prima di Oh My Zsh.

# ----------------------------------------------------------------------------
#  Homebrew (Apple Silicon)
# ----------------------------------------------------------------------------
eval "$('/opt/homebrew/bin/brew' shellenv)"

# Come si installano i pacchetti qui (usato da warn_missing e command_not_found)
DOTFILES_INSTALL_HINT="brew install"

# ----------------------------------------------------------------------------
#  Oh My Zsh — plugin solo macOS
# ----------------------------------------------------------------------------
plugins+=(macos)

# ----------------------------------------------------------------------------
#  Tool integrations
# ----------------------------------------------------------------------------
# iTerm2 shell integration (opzionale, nessun warning se assente)
[ -e "${HOME}/.iterm2_shell_integration.zsh" ] && source "${HOME}/.iterm2_shell_integration.zsh"

# Node, Python & co. come from mise, activated in common.zsh.

# ----------------------------------------------------------------------------
#  Aliases — macOS only
# ----------------------------------------------------------------------------
alias ohmyzsh="mate ~/.oh-my-zsh"         # mate = TextMate
