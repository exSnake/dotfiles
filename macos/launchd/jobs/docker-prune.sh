#!/bin/bash
#
# Weekly: removes images unused for 30 days and trims the build cache.
# Volumes are never touched: they hold the local databases of stopped projects.
set -euo pipefail

if ! docker info >/dev/null 2>&1; then
  echo "Docker non attivo, salto"
  exit 0
fi

docker image prune --all --force --filter until=720h
docker builder prune --force --reserved-space 10GB
