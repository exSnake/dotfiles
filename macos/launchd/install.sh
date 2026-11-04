#!/usr/bin/env bash
#
# Installs the maintenance LaunchAgents from plists/ and registers the recently
# active repos under ~/source for `git maintenance`. Idempotent: an agent is
# reloaded only when its rendered plist changed, and agents whose template was
# removed from the repo are unloaded and deleted.
#
# Usage: macos/launchd/install.sh   (also called by the top-level install.sh)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$here/../.." && pwd)"
AGENTS="$HOME/Library/LaunchAgents"
LOGS="$HOME/Library/Logs/dotfiles"
DOMAIN="gui/$(id -u)"
PREFIX="com.exsnake.dotfiles"
GIT_ROOT="${GIT_MAINTENANCE_ROOT:-$HOME/source}"
GIT_ACTIVE_DAYS="${GIT_MAINTENANCE_ACTIVE_DAYS:-90}"

info() { printf '→  %s\n' "$*"; }
ok()   { printf '✓  %s\n' "$*"; }

mkdir -p "$AGENTS" "$LOGS"

install_agent() {
  local tpl="$1" label dest rendered
  label="$(basename "$tpl" .plist)"
  dest="$AGENTS/$label.plist"
  rendered="$(sed -e "s|__DOTFILES__|$DOTFILES|g" -e "s|__HOME__|$HOME|g" "$tpl")"

  if [ -f "$dest" ] && [ "$(cat "$dest")" = "$rendered" ] \
     && launchctl print "$DOMAIN/$label" >/dev/null 2>&1; then
    ok "job $label già attivo"
    return
  fi

  printf '%s\n' "$rendered" > "$dest"
  plutil -lint -s "$dest"
  launchctl bootout "$DOMAIN/$label" 2>/dev/null || true
  launchctl bootstrap "$DOMAIN" "$dest"
  ok "job $label caricato"
}

remove_orphans() {
  local dest label
  for dest in "$AGENTS/$PREFIX".*.plist; do
    [ -e "$dest" ] || continue
    label="$(basename "$dest" .plist)"
    [ -e "$here/plists/$label.plist" ] && continue
    launchctl bootout "$DOMAIN/$label" 2>/dev/null || true
    rm -f "$dest"
    info "job $label rimosso (non è più nella repo)"
  done
}

register_git_maintenance() {
  local now repo last first="" count=0
  now="$(date +%s)"
  for repo in "$GIT_ROOT"/*/; do
    repo="${repo%/}"
    [ -d "$repo/.git" ] || continue
    last="$(git -C "$repo" log -1 --format=%ct 2>/dev/null)" || continue
    [ $(( now - last )) -lt $(( GIT_ACTIVE_DAYS * 86400 )) ] || continue
    git -C "$repo" maintenance register
    first="${first:-$repo}"
    count=$(( count + 1 ))
  done
  if [ -n "$first" ]; then
    git -C "$first" maintenance start --scheduler=launchctl
    ok "git maintenance attivo su $count repo (commit negli ultimi $GIT_ACTIVE_DAYS giorni)"
  fi
}

for tpl in "$here"/plists/*.plist; do
  install_agent "$tpl"
done
remove_orphans
register_git_maintenance
