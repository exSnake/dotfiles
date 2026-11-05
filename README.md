# dotfiles

Le mie configurazioni personali (zsh, ecc.), versionate e ripristinabili con un comando.

## Installazione su una macchina nuova

```bash
git clone git@github.com:exSnake/dotfiles.git ~/source/dotfiles
cd ~/source/dotfiles
./install.sh
```

`install.sh` fa il setup **completo** ed è **idempotente**: puoi rilanciarlo
quando vuoi (es. dopo ogni `git pull`) e fa solo ciò che manca:

1. **symlink** in `$HOME` (`~/.zshrc`, `~/.tmux.conf`,
   `~/.config/mise/config.toml`, `~/.atuin/config.toml`): se un file esiste già
   come file reale, backup con timestamp prima di sostituirlo; se il link è già
   giusto, non tocca nulla. In `~/.gitconfig` aggiunge solo
   `include.path = git/delta.gitconfig`;
2. **pacchetti** mancanti (su macOS con brew: eza, fzf, gh, mise, shellcheck,
   tmux, atuin, bat, btop, dust, fd, git-delta, ncdu, tlrc, watchexec, zoxide,
   Raycast, Nerd Font, poi `mise install`; su Linux via apt/pacman la parte
   disponibile, nvm con lo script ufficiale);
3. **Oh My Zsh**, se assente (senza toccare il symlink `~/.zshrc`);
4. **plugin OMZ custom** (zaw, autosuggestions, syntax-highlighting,
   history-substring-search, fzf-tab, you-should-use): clonati se mancano,
   `git pull` se presenti.

Cosa NON fa (te lo segnala e basta): installare Homebrew su macOS, cambiare
la shell di default (`chsh`), installare il Nerd Font lato Windows per WSL.

## Come funziona

I file "veri" vivono in questa repo (senza il punto iniziale, es. `zshrc`).
In `$HOME` c'è solo un symlink che punta qui. Quindi:

- editi `~/.zshrc` normalmente → stai modificando `~/source/dotfiles/zshrc`
- `git status` vede subito la modifica → `git commit` + `git push`

## Struttura della config zsh

La configurazione è divisa per sistema operativo, con il codice comune in un unico punto:

```
dotfiles/
├── zshrc                # entrypoint: rileva l'OS ($OSTYPE) e carica common
├── shell/
│   ├── common.zsh       # condiviso: history, plugin OMZ, keybinding, helper
│   │                    #   (exists, warn_missing), alias eza/gh, coreutils
│   ├── macos.zsh        # Homebrew /opt/homebrew, iTerm2, plugin macos
│   ├── linux.zsh        # apt/pacman, nvm ~/.nvm, pnpm, plugin ssh-agent
│   └── wsl.zsh          # overlay sopra linux.zsh: pbcopy/pbpaste → clip.exe
├── install.sh
└── README.md
```

Solo `zshrc` è symlinkato (`~/.zshrc`); i file in `shell/` vengono caricati
via `source` dall'entrypoint, quindi **non** vanno aggiunti a `install.sh`.

Ordine di caricamento (conta, non cambiarlo a caso):

1. `zshrc` risolve la cartella della repo e imposta `$DOTFILES_OS` da `$OSTYPE`
   (`darwin*` → `macos`, `linux*` → `linux`, altrimenti solo common); su WSL
   (rilevato via `$WSL_DISTRO_NAME`) imposta anche `$DOTFILES_VARIANT=wsl`;
2. `common.zsh` definisce env, helper e la lista base dei plugin;
3. `common.zsh` carica `shell/$DOTFILES_OS.zsh` (e poi l'eventuale variante,
   es. `wsl.zsh`) **prima** di Oh My Zsh, così il file OS può aggiungere
   plugin (`plugins+=(...)`), preparare il PATH (es. Homebrew, necessario
   perché il check di `eza` lo trovi) e dichiarare `$DOTFILES_INSTALL_HINT`;
4. `common.zsh` carica Oh My Zsh e **poi** definisce keybinding e alias comuni
   (devono venire dopo, perché OMZ sovrascriverebbe `ls`, `grep`, ecc.).

Se il file dell'OS corrente non esiste, viene semplicemente saltato.

### Stessa esperienza su tutti gli OS

Prompt (agnoster), plugin, alias (`ll`/`la`/`lt` via eza, `pbcopy`/`pbpaste`
anche su WSL) e keybinding sono identici ovunque:

| Tasto        | Azione                       |
|--------------|------------------------------|
| `↑` / `↓`    | history-substring-search     |
| `^R`         | atuin (zaw-history se atuin manca) |
| `Tab`        | fzf-tab (`**` + Tab: completamento fzf) |
| `^S`         | zaw-git-status               |
| `^T`         | zaw-git-files                |
| `^B`         | zaw-git-branches             |
| `Alt+L`      | zaw-git-log                  |
| `Shift+Alt+B`| zaw-git-recent-branches      |
| `Alt+R`      | zaw-git-reflog               |

### Comandi standard serviti da strumenti migliori

Nelle shell interattive alcuni comandi di tutti i giorni passano da uno
strumento più comodo, con lo stesso nome:

| Scrivi | Gira | Note |
|---|---|---|
| `ls`, `ll`, `la`, `lt` | eza | icone, stato git, albero |
| `cat` | bat | evidenziazione della sintassi; in una pipe esce testo semplice |
| `man` | bat come pager | man page colorate |
| `cd` | zoxide | `cd homelab` salta alla cartella più usata che corrisponde; `cdi` la sceglie con fzf |
| `top` | btop | |
| `git diff`, `log -p`, `show` | delta | via `git/delta.gitconfig` |
| `^R` | atuin | cronologia in SQLite, ricerca fuzzy, filtri per cartella e host |

Con nomi propri, perché le opzioni sono diverse da quelle del comando
standard: `fd` (cerca file, usato anche da fzf), `dust` (cosa occupa spazio),
`ncdu` (lo stesso, interattivo, con cancellazione), `tldr` (esempi d'uso),
`watchexec` (rilancia un comando quando cambia un file).

Nelle shell di Claude Code (`CLAUDECODE=1`) questi alias non vengono definiti:
un agente scrive i comandi con le opzioni standard, e `ls -t` su eza vuol dire
un'altra cosa. La funzione `is_human_shell` in `common.zsh` fa il controllo.

### Dipendenze mancanti → hint automatico

Ogni file OS dichiara come si installano i pacchetti (`DOTFILES_INSTALL_HINT`:
`brew install` su macOS, `sudo apt install` / `sudo pacman -S` su Linux):

- all'avvio, `warn_missing` segnala i tool assenti con il comando giusto
  per l'OS corrente (idem i plugin OMZ custom da clonare);
- a runtime, `command_not_found_handler` intercetta i comandi inesistenti e
  suggerisce come installarli (su Debian/Ubuntu delega a `command-not-found`,
  che conosce il nome esatto del pacchetto).

## Aggiungere il supporto a un nuovo OS

1. Crea `shell/<nome>.zsh` (es. `shell/freebsd.zsh`) con env, plugin e alias
   specifici di quell'OS.
2. Aggiungi un ramo al `case "$OSTYPE"` in `zshrc`:
   ```zsh
   freebsd*) DOTFILES_OS="freebsd" ;;
   ```
3. Fatto: `common.zsh` lo caricherà automaticamente al punto giusto.

## Aggiungere un nuovo dotfile

1. Sposta il file nella repo senza il punto:
   ```bash
   mv ~/.gitconfig ~/source/dotfiles/gitconfig
   ```
2. Aggiungi la riga in `install.sh`:
   ```bash
   link gitconfig "$HOME/.gitconfig"
   ```
3. Ri-esegui `./install.sh` e committa.

## Contenuto

| File               | Symlink    | Descrizione                                 |
|--------------------|------------|---------------------------------------------|
| `zshrc`            | `~/.zshrc` | Entrypoint: OS detection + source di shell/ |
| `shell/common.zsh` | —          | Config zsh condivisa + Oh My Zsh            |
| `shell/macos.zsh`  | —          | Solo macOS (Homebrew, iTerm2)               |
| `shell/linux.zsh`  | —          | Solo Linux (apt/pacman, nvm, pnpm, alias)   |
| `shell/wsl.zsh`    | —          | Overlay WSL (clipboard → Windows)           |
| `tmux/tmux.conf`   | `~/.tmux.conf` | mouse, cronologia lunga, finestre da 1, split nella cartella corrente |
| `mise/global.toml` | `~/.config/mise/config.toml` | versioni globali (Node 22) e lettura dei `.nvmrc` |
| `atuin/config.toml`| `~/.atuin/config.toml` | ricerca fuzzy, lista compatta, Invio che non esegue subito |
| `git/delta.gitconfig` | incluso da `~/.gitconfig` | delta come pager di git |
| `macos/launchd/`   | —          | Job launchd di manutenzione (vedi sotto)    |
| `Brewfile`         | —          | Pacchetti Homebrew, scritto da `brew-upgrade`, solo locale |

## Job di manutenzione (macOS)

`install.sh` carica anche alcuni LaunchAgent in `~/Library/LaunchAgents/`,
generati dai template in `macos/launchd/plists/`. Ogni job passa da
`macos/launchd/run-job.sh`, che imposta il PATH, scrive il log in
`~/Library/Logs/dotfiles/<job>.log` e manda una notifica se il job fallisce.

| Job | Quando | Cosa fa |
|---|---|---|
| `brew-upgrade` | ogni giorno, 4:00 | `brew update`, `upgrade --formula`, `cleanup --prune=30`, riscrive `Brewfile` (in `.gitignore`) |
| `docker-prune` | ogni giorno, 3:30 | immagini inutilizzate da 30 giorni e build cache oltre 10 GB (i volumi restano) |
| `cache-prune` | il 1° del mese, 11:00 | `npm cache clean`, `uv cache prune` |
| `claude-backup` | ogni giorno, 3:00 e 13:00 | `rsync` di `~/.claude` sul NAS, senza cancellare nulla dall'altra parte |

Se all'ora prevista il Mac dorme, il job parte al risveglio.
`claude-backup` con il NAS irraggiungibile salta il giro e fallisce solo se
l'ultimo backup riuscito ha più di 3 giorni.

Lo stesso script registra per `git maintenance` (prefetch orario, gc) i repo
in `~/source` con un commit negli ultimi 90 giorni.

```bash
macos/launchd/install.sh                                    # solo i job
launchctl kickstart -k gui/$(id -u)/com.exsnake.dotfiles.claude-backup   # lancia subito
launchctl print gui/$(id -u)/com.exsnake.dotfiles.claude-backup          # stato e ultimo exit
tail ~/Library/Logs/dotfiles/claude-backup.log
```

Un nuovo job: lo script in `macos/launchd/jobs/<nome>.sh`, il template in
`macos/launchd/plists/com.exsnake.dotfiles.<nome>.plist`, poi `./install.sh`.
Un template tolto dalla repo fa scaricare e cancellare il job corrispondente.

## Dipendenze

`./install.sh` installa tutto da solo. Se salti l'installer, all'avvio della
shell ricevi comunque un avviso per ogni tool mancante, con il comando di
installazione giusto per l'OS in cui sei. Per riferimento, a mano:

macOS:

```bash
brew install eza fzf gh mise shellcheck tmux \
  atuin bat btop dust fd git-delta ncdu tlrc watchexec zoxide
brew install --cask raycast font-meslo-lg-nerd-font   # font: icone per eza + tema agnoster
mise install
```

Linux / WSL (Debian/Ubuntu):

```bash
sudo apt install eza fzf gh shellcheck tmux btop ncdu zoxide
# nvm: https://github.com/nvm-sh/nvm#installing-and-updating
```

Su WSL il tema agnoster richiede un Nerd Font impostato in Windows Terminal
(es. MesloLGS NF, lo stesso usato su iTerm2).

Plugin OMZ custom (tutti gli OS):

```bash
for p in zaw zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
  git clone "https://github.com/zsh-users/$p" "$HOME/.oh-my-zsh/custom/plugins/$p"
done
git clone https://github.com/Aloxaf/fzf-tab "$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
git clone https://github.com/MichaelAquilina/zsh-you-should-use "$HOME/.oh-my-zsh/custom/plugins/you-should-use"
```

- **fzf-tab**: il Tab apre un menu fzf con ricerca fuzzy; su `cd`, `ls` ed
  `eza` mostra in anteprima il contenuto della cartella. `**` seguito da Tab
  resta il completamento di fzf.
- **you-should-use**: quando scrivi per intero un comando che ha un alias
  (es. `git status` invece di `gst`), stampa l'alias.
