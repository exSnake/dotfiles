# ============================================================================
#  ZSHRC — entrypoint
# ============================================================================
# Questo file è symlinkato da ~/.zshrc. Risolve la cartella della repo,
# rileva l'OS e delega a shell/common.zsh, che a sua volta carica
# shell/$DOTFILES_OS.zsh nel punto giusto (prima di Oh My Zsh, così il
# file OS può aggiungere plugin e preparare il PATH).

# Cartella della repo, risolta attraverso il symlink ~/.zshrc
DOTFILES_DIR="${${(%):-%x}:A:h}"
# Fallback se ~/.zshrc è una copia e non un symlink
[[ -r "$DOTFILES_DIR/shell/common.zsh" ]] || DOTFILES_DIR="$HOME/source/dotfiles"

# Rileva l'OS: darwin* = macOS, linux* = Linux (altri OS: solo common)
# WSL è Linux a tutti gli effetti: carica linux.zsh + l'overlay wsl.zsh
case "$OSTYPE" in
  darwin*) DOTFILES_OS="macos" ;;
  linux*)
    DOTFILES_OS="linux"
    [[ -n "$WSL_DISTRO_NAME" || -n "$WSL_INTEROP" ]] && DOTFILES_VARIANT="wsl"
    ;;
  *)       DOTFILES_OS="" ;;
esac

source "$DOTFILES_DIR/shell/common.zsh"
