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

1. **symlink** in `$HOME` (es. `~/.zshrc` → `~/source/dotfiles/zshrc`) — se un
   file esiste già come file reale, backup con timestamp prima di sostituirlo;
   se il link è già giusto, non tocca nulla;
2. **pacchetti** mancanti (eza, gh, nvm + Nerd Font su macOS; via apt/pacman
   su Linux, nvm con lo script ufficiale);
3. **Oh My Zsh**, se assente (senza toccare il symlink `~/.zshrc`);
4. **plugin OMZ custom** (zaw, autosuggestions, syntax-highlighting,
   history-substring-search): clonati se mancano, `git pull` se presenti.

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
│   ├── macos.zsh        # Homebrew /opt/homebrew, nvm, iTerm2, plugin macos
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
| `^R`         | zaw-history                  |
| `^S`         | zaw-git-status               |
| `^T`         | zaw-git-files                |
| `^B`         | zaw-git-branches             |
| `^U`         | zaw-git-log                  |
| `^W`         | zaw-git-recent-branches      |
| `^X`         | zaw-git-reflog               |

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
| `shell/macos.zsh`  | —          | Solo macOS (Homebrew, nvm, iTerm2)          |
| `shell/linux.zsh`  | —          | Solo Linux (apt/pacman, nvm, pnpm, alias)   |
| `shell/wsl.zsh`    | —          | Overlay WSL (clipboard → Windows)           |

## Dipendenze

`./install.sh` installa tutto da solo. Se salti l'installer, all'avvio della
shell ricevi comunque un avviso per ogni tool mancante, con il comando di
installazione giusto per l'OS in cui sei. Per riferimento, a mano:

macOS:

```bash
brew install eza gh nvm shellcheck
brew install --cask font-meslo-lg-nerd-font   # icone per eza + tema agnoster
```

Linux / WSL (Debian/Ubuntu):

```bash
sudo apt install eza gh shellcheck
# nvm: https://github.com/nvm-sh/nvm#installing-and-updating
```

Su WSL il tema agnoster richiede un Nerd Font impostato in Windows Terminal
(es. MesloLGS NF, lo stesso usato su iTerm2).

Plugin OMZ custom (tutti gli OS):

```bash
for p in zaw zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
  git clone "https://github.com/zsh-users/$p" "$HOME/.oh-my-zsh/custom/plugins/$p"
done
```
