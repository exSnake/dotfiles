#!/bin/bash
#
# Entry point for every LaunchAgent: runs jobs/<name>.sh with a usable PATH,
# timestamps the log and shows a macOS notification when the job fails.
#
# Usage: run-job.sh <job-name>
set -uo pipefail

job="$1"
here="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$here/../.." && pwd)"
export DOTFILES
export JOB_LOG_DIR="$HOME/Library/Logs/dotfiles"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
mkdir -p "$JOB_LOG_DIR"

echo "=== $(date '+%F %T') $job: inizio"
"$here/jobs/$job.sh"
status=$?
echo "=== $(date '+%F %T') $job: exit $status"

if [ "$status" -ne 0 ]; then
  osascript -e "display notification \"exit $status, log in ~/Library/Logs/dotfiles/$job.log\" with title \"Job $job fallito\""
fi
exit "$status"
