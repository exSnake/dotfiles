#!/bin/bash
#
# Daily: copies ~/.claude (memories, skills, hooks, settings, transcripts) to
# the NAS. Nothing is deleted on the NAS side, so transcripts that Claude Code
# expires locally stay in the backup.
# With the NAS unreachable (VPN off) the run is skipped; it fails only when the
# last successful copy is older than MAX_AGE_DAYS.
set -euo pipefail

DEST_HOST="nas"
DEST_DIR="/volume1/homes/exSnake/backup/mac-claude"
MAX_AGE_DAYS=3
stamp="$JOB_LOG_DIR/claude-backup.last"

if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$DEST_HOST" "mkdir -p '$DEST_DIR'" 2>/dev/null; then
  if [ -n "$(find "$stamp" -mtime -"$MAX_AGE_DAYS" 2>/dev/null)" ]; then
    echo "NAS non raggiungibile, salto (ultimo backup riuscito: $(date -r "$stamp" '+%F %T'))"
    exit 0
  fi
  echo "NAS non raggiungibile e nessun backup riuscito negli ultimi $MAX_AGE_DAYS giorni"
  exit 1
fi

rsync -a \
  --exclude '/cache/' --exclude '/debug/' --exclude '/telemetry/' \
  --exclude '/paste-cache/' --exclude '/shell-snapshots/' --exclude '/session-env/' \
  --exclude '/ide/' --exclude '/plugins/' --exclude '/downloads/' --exclude '/chrome/' \
  --exclude 'node_modules/' --exclude '__pycache__/' \
  "$HOME/.claude/" "$DEST_HOST:$DEST_DIR/"
touch "$stamp"
