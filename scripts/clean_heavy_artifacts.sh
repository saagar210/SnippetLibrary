#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Cleaning heavy build artifacts in $ROOT_DIR"

if [ -d ".build" ]; then
  if rm -rf ".build" 2>/dev/null; then
    echo "- removed .build/"
  else
    find ".build" -type f -delete || true
    find ".build" -depth -type d -empty -delete || true
    echo "- partially cleaned .build/ (directory in use)"
  fi
else
  echo "- .build/ not present"
fi

if [ -d ".swiftpm" ]; then
  rm -rf ".swiftpm"
  echo "- removed .swiftpm/"
else
  echo "- .swiftpm/ not present"
fi

echo "Heavy artifact cleanup complete."
