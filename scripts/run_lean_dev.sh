#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LEAN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/snippetlibrary-lean.XXXXXX")"
SCRATCH_DIR="$LEAN_ROOT/scratch"
MODULE_CACHE_DIR="$LEAN_ROOT/module-cache"
mkdir -p "$SCRATCH_DIR" "$MODULE_CACHE_DIR"

cleanup() {
  if [ -d "$LEAN_ROOT" ]; then
    rm -rf "$LEAN_ROOT"
  fi
}

echo "Lean dev mode"
echo "- scratch path: $SCRATCH_DIR"
echo "- module cache: $MODULE_CACHE_DIR"
echo "- app command: swift run"

swift run \
  --scratch-path "$SCRATCH_DIR" \
  -Xswiftc -module-cache-path \
  -Xswiftc "$MODULE_CACHE_DIR" \
  "$@" &
APP_PID=$!

on_signal() {
  kill "$APP_PID" 2>/dev/null || true
  wait "$APP_PID" 2>/dev/null || true
}

trap on_signal INT TERM
trap cleanup EXIT

wait "$APP_PID"
