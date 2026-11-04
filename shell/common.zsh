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

# is_human_shell  ->  false inside a Claude Code shell (CLAUDECODE=1).
# Aliases that replace a standard command (ls, cat, cd, top) are defined only
# when this is true: agents run commands with the standard flags.
function is_human_shell {
  [[ -z "$CLAUDECODE" ]]
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
# fzf-tab must stay before zsh-autosuggestions and zsh-syntax-highlighting.
plugins=(
  git
  you-should-use
  zaw
  fzf-tab
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
for _plugin _url in \
  zaw                          https://github.com/zsh-users/zaw \
  zsh-autosuggestions          https://github.com/zsh-users/zsh-autosuggestions \
  zsh-syntax-highlighting      https://github.com/zsh-users/zsh-syntax-highlighting \
  zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search \
  fzf-tab                      https://github.com/Aloxaf/fzf-tab \
  you-should-use               https://github.com/MichaelAquilina/zsh-you-should-use; do
  [ -d "$ZSH/custom/plugins/$_plugin" ] || \
    print -P "%F{yellow}⚠  plugin '$_plugin' non trovato%f — git clone $_url \"\$ZSH/custom/plugins/$_plugin\""
done
unset _plugin _url

# fzf-tab: its own menu replaces the zsh one; cd and ls completions preview the directory
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:(cd|ls|eza):*' fzf-preview 'eza -1 --icons --color=always $realpath 2>/dev/null || ls -1 $realpath'

# zaw non ha un .plugin.zsh standard: va sourcato a mano
[ -s "$ZSH/custom/plugins/zaw/zaw.zsh" ] && source "$ZSH/custom/plugins/zaw/zaw.zsh"

# fzf (se installato via git/script, fuori dal plugin OMZ)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf lists files with fd: faster, and it skips .git and what .gitignore excludes
if exists fd; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"
fi

# mise: Node, Python & co. per directory (reads .nvmrc and .tool-versions too)
warn_missing mise "$DOTFILES_INSTALL_HINT mise" && eval "$(mise activate zsh)"

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

# atuin owns ^R (history search); the arrows stay with history-substring-search
if warn_missing atuin "$DOTFILES_INSTALL_HINT atuin"; then
  eval "$(atuin init zsh --disable-up-arrow)"
else
  bindkey '^R' zaw-history
fi

# zaw
bindkey '^S' zaw-git-status
bindkey '^T' zaw-git-files
bindkey '^B' zaw-git-branches
bindkey '^[l' zaw-git-log             # ALT+L (Log) — was ^U, which clobbered kill-whole-line
bindkey '^[B' zaw-git-recent-branches # SHIFT+ALT+B — was ^W, which iTerm sends for ALT+DEL (delete word)
bindkey '^[r' zaw-git-reflog          # ALT+R (Reflog) — was ^X, which clobbered the ^X chord prefix

# ----------------------------------------------------------------------------
#  Aliases — listing (eza)
# ----------------------------------------------------------------------------
if is_human_shell && warn_missing eza "$DOTFILES_INSTALL_HINT eza"; then
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
#  Aliases — comandi standard serviti da strumenti migliori (solo shell umane)
# ----------------------------------------------------------------------------
# Same name, same everyday use. find and du are left alone: fd and dust take
# different flags, so `fd` and `dust` / `ncdu` keep their own names.
if is_human_shell; then
  if warn_missing bat "$DOTFILES_INSTALL_HINT bat"; then
    alias cat="bat --paging=never --style=plain"
    export MANPAGER="sh -c 'col -bx | bat --language=man --plain'"
  fi
  exists btop && alias top="btop"
fi

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

# ----------------------------------------------------------------------------
#  zoxide — `cd` impara le cartelle più usate (`cd homelab` ci salta da ovunque,
#  `cdi` apre la scelta con fzf). Va inizializzato per ultimo.
# ----------------------------------------------------------------------------
if is_human_shell && warn_missing zoxide "$DOTFILES_INSTALL_HINT zoxide"; then
  eval "$(zoxide init zsh --cmd cd)"
fi
