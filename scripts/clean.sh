#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Cleaning generated files in $ROOT_DIR"

if [ -d ".build" ]; then
  if rm -rf ".build" 2>/dev/null; then
    echo "- removed .build/"
  else
    # Fallback when swift processes still hold parts of .build.
    find ".build" -type f -delete || true
    find ".build" -depth -type d -empty -delete || true
    echo "- partially cleaned .build/ (directory in use)"
  fi
else
  echo "- .build/ not present"
fi

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

echo "Clean complete."
