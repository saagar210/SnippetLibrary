#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running full local cache cleanup in $ROOT_DIR"
"$ROOT_DIR/scripts/clean_all_local_caches.sh"
