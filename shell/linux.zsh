# ============================================================================
#  LINUX — configurazione specifica Linux (incluso WSL, che aggiunge wsl.zsh)
# ============================================================================
# Caricato da shell/common.zsh prima di Oh My Zsh.

# ----------------------------------------------------------------------------
#  Package manager (usato da warn_missing e command_not_found)
# ----------------------------------------------------------------------------
if exists apt; then
  DOTFILES_INSTALL_HINT="sudo apt install"
elif exists pacman; then
  DOTFILES_INSTALL_HINT="sudo pacman -S"
fi

# ----------------------------------------------------------------------------
#  Oh My Zsh — plugin solo Linux (su macOS l'agent lo gestisce il Keychain)
# ----------------------------------------------------------------------------
plugins+=(ssh-agent)

# ----------------------------------------------------------------------------
#  Tool integrations
# ----------------------------------------------------------------------------
# nvm (installato via script ufficiale in ~/.nvm)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
else
  print -P "%F{yellow}⚠  nvm non installato%f — https://github.com/nvm-sh/nvm#installing-and-updating"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ----------------------------------------------------------------------------
#  Aliases — package manager & system
# ----------------------------------------------------------------------------
alias apt="sudo apt"
alias aptitude="sudo aptitude"
alias pacman="sudo pacman"
alias systemctl="sudo systemctl"
alias shutdown="sudo shutdown"
alias reboot="sudo reboot"
