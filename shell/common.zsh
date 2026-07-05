# ============================================================================
#  COMMON — configurazione zsh condivisa tra tutti gli OS
# ============================================================================
# Caricato dall'entrypoint `zshrc`. Carica a sua volta shell/<os>.zsh
# PRIMA di Oh My Zsh (vedi sezione "OS-specific" per il perché).

# ----------------------------------------------------------------------------
#  Environment & PATH
# ----------------------------------------------------------------------------
export LANG=en_US.UTF-8

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------------------------------------------
#  Helper functions (definite prima di ogni utilizzo, anche nei file OS)
# ----------------------------------------------------------------------------
# exists <cmd>  ->  true if command is available
function exists {
  type "$1" &> /dev/null
}

# warn_missing <cmd> <hint>  ->  true if present; else print a warning, false
# Uso:  warn_missing eza "$DOTFILES_INSTALL_HINT eza" && alias ls="eza ..."
function warn_missing {
  if exists "$1"; then
    return 0
  fi
  print -P "%F{yellow}⚠  '$1' non installato%f — $2"
  return 1
}

# ----------------------------------------------------------------------------
#  Oh My Zsh — impostazioni (il caricamento avviene dopo il file OS)
# ----------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"
DEFAULT_USER="$USER"

# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
# I file OS possono aggiungerne altri con:  plugins+=(nome)
plugins=(
  git
  zaw
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  fzf
  bundler
  rake
  docker
  docker-compose
  yarn
)

# ----------------------------------------------------------------------------
#  OS-specific — caricato PRIMA di Oh My Zsh, così il file OS può:
#    • aggiungere plugin con plugins+=(...)
#    • preparare il PATH (es. Homebrew) per i check `exists` qui sotto
#    • impostare DOTFILES_INSTALL_HINT (es. "brew install", "sudo apt install")
# ----------------------------------------------------------------------------
if [[ -n "$DOTFILES_OS" && -r "$DOTFILES_DIR/shell/$DOTFILES_OS.zsh" ]]; then
  source "$DOTFILES_DIR/shell/$DOTFILES_OS.zsh"
fi

# Variante opzionale sopra l'OS base (es. WSL = linux + wsl)
if [[ -n "$DOTFILES_VARIANT" && -r "$DOTFILES_DIR/shell/$DOTFILES_VARIANT.zsh" ]]; then
  source "$DOTFILES_DIR/shell/$DOTFILES_VARIANT.zsh"
fi

# Fallback se il file OS non ha impostato l'hint di installazione
: "${DOTFILES_INSTALL_HINT:=installa}"

# ----------------------------------------------------------------------------
#  Oh My Zsh — caricamento
# ----------------------------------------------------------------------------
source "$ZSH/oh-my-zsh.sh"

# Override: show 2 trailing path segments in the prompt
prompt_dir() {
  prompt_segment blue black '%2~'
}

# ----------------------------------------------------------------------------
#  History (dopo Oh My Zsh: sovrascrive i default della sua lib/history)
# ----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=20000
SAVEHIST=20000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY         # salva subito, non alla chiusura
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS          # niente duplicati nella ricerca
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# ----------------------------------------------------------------------------
#  Tool integrations
# ----------------------------------------------------------------------------
# Plugin custom: OMZ li ignora in silenzio se mancano — qui invece avvisiamo
for _plugin in zaw zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
  [ -d "$ZSH/custom/plugins/$_plugin" ] || \
    print -P "%F{yellow}⚠  plugin '$_plugin' non trovato%f — git clone https://github.com/zsh-users/$_plugin \"\$ZSH/custom/plugins/$_plugin\""
done
unset _plugin

# zaw non ha un .plugin.zsh standard: va sourcato a mano
[ -s "$ZSH/custom/plugins/zaw/zaw.zsh" ] && source "$ZSH/custom/plugins/zaw/zaw.zsh"

# fzf (se installato via git/script, fuori dal plugin OMZ)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ----------------------------------------------------------------------------
#  Keybindings (identici su tutti gli OS — memoria muscolare)
# ----------------------------------------------------------------------------
stty -ixon 2>/dev/null            # libera ^S/^Q dal flow control del terminale

# history-substring-search: frecce su/giù filtrano per quanto già digitato
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up    # varianti per terminali diversi
bindkey '^[OB' history-substring-search-down

# zaw
bindkey '^R' zaw-history
bindkey '^S' zaw-git-status
bindkey '^T' zaw-git-files
bindkey '^B' zaw-git-branches
bindkey '^U' zaw-git-log
bindkey '^W' zaw-git-recent-branches
bindkey '^X' zaw-git-reflog

# ----------------------------------------------------------------------------
#  Aliases — listing (eza)
# ----------------------------------------------------------------------------
if warn_missing eza "$DOTFILES_INSTALL_HINT eza"; then
  alias ls="eza --icons --group-directories-first"
  alias l="eza --icons --group-directories-first"
  alias ll="eza -lah --icons --group-directories-first --git"
  alias la="eza -a --icons --group-directories-first"
  alias lt="eza --tree --level=2 --icons"
  alias ll.="eza -lahd .* --icons"        # solo file nascosti
elif [[ "$OSTYPE" == darwin* ]]; then
  # fallback al ls nativo (BSD)
  alias ls="ls -Gh"
  alias l="ls -CFGh"
  alias ll="ls -laGh"
  alias la="ls -aGh"
else
  # fallback al ls nativo (GNU)
  alias ls="ls -h --color=auto"
  alias l="ls -CF --color=auto"
  alias ll="ls -lah --color=auto"
  alias la="ls -ah --color=auto"
fi

# ----------------------------------------------------------------------------
#  Aliases — coreutils (BSD-safe: funzionano anche su GNU)
# ----------------------------------------------------------------------------
alias sed="sed -E"                        # BSD usa -E, non -r (GNU li supporta entrambi)
alias grep="grep -E"
alias mkdir="mkdir -p"

alias df="df -h"                          # BSD df non ha --total
alias du="du -ch"                         # -c stampa il totale finale
alias c="clear"

# Allow alias expansion after sudo
alias sudo="sudo "

# ----------------------------------------------------------------------------
#  Aliases — dev
# ----------------------------------------------------------------------------
if exists gh; then
  alias ghpr="gh pr create --web"
  alias ghco="gh pr checkout"
  alias ghs="gh pr status"
fi

alias sail="./vendor/bin/sail"            # Laravel Sail (innocuo se assente)

# ----------------------------------------------------------------------------
#  Command not found → suggerisci come installare
# ----------------------------------------------------------------------------
command_not_found_handler() {
  # Su Debian/Ubuntu delega a command-not-found, che conosce il pacchetto esatto
  if [ -x /usr/lib/command-not-found ]; then
    /usr/lib/command-not-found -- "$1"
    return $?
  fi
  print -P "%F{red}✗  comando non trovato:%f $1"
  print -P "   prova:  %F{green}$DOTFILES_INSTALL_HINT $1%f"
  return 127
}
