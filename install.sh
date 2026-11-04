#!/usr/bin/env bash
#
# install.sh — setup completo e idempotente dei dotfiles
#
# Uso:
#   cd ~/source/dotfiles && ./install.sh
#
# Rilanciabile quante volte vuoi (es. dopo un git pull):
#   • symlink        → ricreati solo se puntano altrove (backup dei file reali)
#   • pacchetti      → installati solo quelli mancanti
#   • Oh My Zsh      → installato solo se manca
#   • plugin custom  → clonati se mancano, aggiornati (git pull) se presenti
#
set -euo pipefail

# Cartella della repo (dove si trova questo script), risolta in modo robusto
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- output helpers ----------------------------------------------------------
info() { printf '→  %s\n' "$*"; }
ok()   { printf '✓  %s\n' "$*"; }
warn() { printf '⚠  %s\n' "$*"; }
exists() { command -v "$1" >/dev/null 2>&1; }

# --- OS detection (stessa logica di zshrc) -----------------------------------
case "$OSTYPE" in
  darwin*) OS="macos" ;;
  linux*)  OS="linux" ;;
  *)       OS="" ;;
esac
IS_WSL=0
if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
  IS_WSL=1
fi

# ==============================================================================
#  1. Symlink
# ==============================================================================
# link <file-nella-repo> <destinazione-in-$HOME>
link() {
  local src="$DOTFILES/$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    warn "manca nella repo: $src"
    return 1
  fi

  # Già a posto? Non fare nulla (idempotenza)
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "$dest già collegato"
    return 0
  fi

  # Se la destinazione esiste ed è un file reale (non un symlink), la salvo
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
    info "backup del vecchio $dest"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  ok "$dest  ->  $src"
}

# ----------------------------------------------------------------------------
#  Mappa dei symlink — aggiungi qui i nuovi dotfiles
#  NB: i file in shell/ NON vanno linkati — li carica `zshrc` via source
# ----------------------------------------------------------------------------
link zshrc             "$HOME/.zshrc"
link tmux/tmux.conf    "$HOME/.tmux.conf"
link mise/global.toml  "$HOME/.config/mise/config.toml"
link atuin/config.toml "$HOME/.atuin/config.toml"
# link vimrc     "$HOME/.vimrc"

# ~/.gitconfig resta personale (email, alias, maintenance.repo): la repo è
# pubblica. Ci aggiungiamo solo l'include con la configurazione di delta.
GIT_INCLUDE="$DOTFILES/git/delta.gitconfig"
if git config --global --get-all include.path | grep -qxF "$GIT_INCLUDE"; then
  ok "$HOME/.gitconfig include già git/delta.gitconfig"
else
  git config --global --add include.path "$GIT_INCLUDE"
  ok "$HOME/.gitconfig ora include git/delta.gitconfig"
fi

# ==============================================================================
#  2. Pacchetti (solo quelli mancanti)
# ==============================================================================
if [ "$OS" = "macos" ]; then
  if exists brew; then
    for f in eza fzf gh mise shellcheck tmux \
             atuin bat btop dust fd git-delta ncdu tlrc watchexec zoxide; do
      if brew list --formula "$f" >/dev/null 2>&1; then
        ok "$f già installato"
      else
        info "installo $f..."
        brew install "$f"
      fi
    done
    if [ -d /Applications/Raycast.app ]; then
      ok "Raycast già installato"
    else
      info "installo Raycast..."
      brew install --cask raycast
    fi
    if exists mise; then
      mise install --yes
    fi
    if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
      ok "font Nerd già installato"
    else
      info "installo il Nerd Font (icone eza + tema agnoster)..."
      brew install --cask font-meslo-lg-nerd-font
    fi
  else
    warn "Homebrew mancante — installa da https://brew.sh e rilancia ./install.sh"
  fi

elif [ "$OS" = "linux" ]; then
  APT_UPDATED=0
  # pkg_install <comando> — installa il pacchetto per il comando mancante
  pkg_install() {
    local pkg="$1"
    if exists apt-get; then
      if [ "$APT_UPDATED" = 0 ]; then sudo apt-get update -qq; APT_UPDATED=1; fi
      sudo apt-get install -y "$pkg"
    elif exists pacman; then
      [ "$pkg" = "gh" ] && pkg="github-cli"
      sudo pacman -S --needed --noconfirm "$pkg"
    else
      return 1
    fi
  }

  for c in zsh git curl eza fzf gh shellcheck tmux btop ncdu zoxide; do
    if exists "$c"; then
      ok "$c già installato"
    else
      info "installo $c..."
      pkg_install "$c" || warn "$c: non trovato nel package manager, installalo a mano"
    fi
  done

  # nvm: niente pacchetto, script ufficiale in ~/.nvm
  if [ -d "$HOME/.nvm" ]; then
    ok "nvm già installato"
  else
    info "installo nvm..."
    # PROFILE=/dev/null: lo script non deve toccare ~/.zshrc (la config è già nostra)
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
  fi
fi

# ==============================================================================
#  3. Oh My Zsh
# ==============================================================================
if [ -d "$HOME/.oh-my-zsh" ]; then
  ok "Oh My Zsh già installato"
else
  info "installo Oh My Zsh..."
  # KEEP_ZSHRC: l'installer non deve sostituire il nostro symlink ~/.zshrc
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ==============================================================================
#  4. Plugin OMZ custom (clona se mancano, aggiorna se presenti)
# ==============================================================================
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for entry in \
  "zaw https://github.com/zsh-users/zaw" \
  "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions" \
  "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting" \
  "zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search" \
  "fzf-tab https://github.com/Aloxaf/fzf-tab" \
  "you-should-use https://github.com/MichaelAquilina/zsh-you-should-use"; do
  p="${entry%% *}"
  url="${entry#* }"
  dir="$ZSH_CUSTOM/plugins/$p"
  if [ -d "$dir/.git" ]; then
    if git -C "$dir" pull --ff-only --quiet; then
      ok "plugin $p aggiornato"
    else
      warn "plugin $p: aggiornamento fallito (modifiche locali?)"
    fi
  else
    info "clono il plugin $p..."
    git clone --quiet --depth 1 "$url" "$dir"
  fi
done

# ==============================================================================
#  5. Job di manutenzione (solo macOS): LaunchAgents + git maintenance
# ==============================================================================
if [ "$OS" = "macos" ]; then
  "$DOTFILES/macos/launchd/install.sh"
fi

# ==============================================================================
#  6. Check finali
# ==============================================================================
case "${SHELL:-}" in
  */zsh) ok "shell di default: zsh" ;;
  *)     warn "la shell di default non è zsh — esegui:  chsh -s \"\$(command -v zsh)\"" ;;
esac

if [ "$IS_WSL" = 1 ]; then
  warn "WSL: imposta un Nerd Font in Windows Terminal (es. MesloLGS NF) per il tema agnoster"
fi

echo
ok "Setup completo. Riavvia il terminale o esegui:  exec zsh"
