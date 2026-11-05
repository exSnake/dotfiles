#!/bin/bash
#
# Daily: updates Homebrew formulae, prunes old downloads and dumps the
# Brewfile into the repo so a new Mac can be rebuilt with `brew bundle`.
# Casks are left alone: most update themselves and some ask for sudo.
set -euo pipefail
export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_INSTALL_CLEANUP=1

brew update
brew upgrade --formula
brew cleanup --prune=30
brew bundle dump --force --file="$DOTFILES/Brewfile"
