#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

"$ROOT_DIR/scripts/clean_heavy_artifacts.sh"

echo "Cleaning additional reproducible local caches"

if [ -d ".codex_audit" ]; then
  rm -rf ".codex_audit"
  echo "- removed .codex_audit/"
else
  echo "- .codex_audit/ not present"
fi

find . -type f -name ".DS_Store" -delete
echo "- removed .DS_Store files"

find . -type d -name "__pycache__" -prune -exec rm -rf {} +
echo "- removed __pycache__ directories"

echo "Full local cache cleanup complete."
