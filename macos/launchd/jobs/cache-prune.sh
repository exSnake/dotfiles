#!/bin/bash
#
# Monthly: empties the npm cache and drops unused uv cache entries.
set -euo pipefail

npm cache clean --force
if command -v uv >/dev/null 2>&1; then
  uv cache prune
fi
