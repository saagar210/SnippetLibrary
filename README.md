# SnippetLibrary

A macOS text expansion utility for managing and quickly inserting code snippets and canned responses.

## What It Does

Save time by creating reusable text snippets with full-text search. Press a global hotkey, search your library, and instantly insert the snippet into any app.

**Target**: IT Support Engineers typing 20-30 responses daily. Saves ~37 min/day.

## Current Features

- Menu bar app with global hotkey (`Cmd+Shift+Space`)
- Floating search panel with keyboard navigation
- Text insertion via clipboard save/restore + simulated paste
- SQLite-backed snippet CRUD and tag management
- FTS5 ranked search (title/content weighting, multi-word queries)
- Language filtering and Recently Used shortcuts
- Optional local semantic search via Ollama embeddings
- JSON import/export (merge or replace)
- Launch at login support (macOS 13+)
- Syntax highlighting in snippet detail view (Highlightr)

## Planned Enhancements

- Auto-update (Sparkle framework)
- SQLCipher encryption for sensitive snippets
- App context detection (filter snippets by active app)
- Inline expansion (`;mfa` trigger style)

## Requirements

- macOS 14+ (Sonoma)
- Swift 6.0+
- Xcode 26.2+

## Build & Run

```bash
# Build
swift build

# Run tests
swift test

# Run app (normal dev)
swift run

# Run app (lean dev: temporary build caches, auto-clean on exit)
bash scripts/run_lean_dev.sh

# Clean heavy build artifacts only
bash scripts/clean_heavy_artifacts.sh

# Full local reproducible-cache cleanup
bash scripts/clean_all_local_caches.sh

# Backward-compatible full cleanup alias
bash scripts/clean.sh

# Dependency vulnerability audit (OSV)
python3 scripts/audit_dependencies.py
```

## Maintenance

- **Normal dev** (`swift run`): fastest repeated startup once caches are warm, but it grows `.build/` in the repo and may reuse shared SwiftPM caches under `~/Library/Caches/org.swift.swiftpm`.
- **Lean dev** (`bash scripts/run_lean_dev.sh`): runs with temporary scratch/module cache directories and removes them automatically when the app exits. This keeps the repo small at the cost of slower startup/build.
- Use `bash scripts/clean_heavy_artifacts.sh` to remove large project-local build outputs (`.build`, `.swiftpm`) while preserving shared dependency caches for better speed later.
- Use `bash scripts/clean_all_local_caches.sh` (or `bash scripts/clean.sh`) for a fuller reproducible cleanup (`.build`, `.swiftpm`, `.codex_audit`, `.DS_Store`, `__pycache__`).
- After cleaning, run `swift build` and `swift test` to regenerate build outputs and confirm everything is healthy.
- Use `python3 scripts/audit_dependencies.py` occasionally to check pinned dependency revisions against OSV.

## Project Structure

```
SnippetLibrary/
├── Models/                  # GRDB records (Snippet, Tag, SnippetTag)
├── Database/                # AppDatabase, SnippetRepository, migrations
├── Services/                # HotkeyService, PasteService, Import/Export, Ollama, etc.
├── Views/
│   ├── Management/          # Snippet list, editor, detail views
│   ├── SearchPanel/         # Floating global search UI
│   └── Settings/            # Ollama + app settings
└── SnippetLibraryApp.swift  # App entrypoint
```

## Database Schema

**snippet** table:
- id, title, content, language, isFavorite, usageCount, createdAt, updatedAt, embedding (BLOB)

**tag** table:
- id, name (unique, normalized lowercase)

**snippetTag** junction table:
- snippetId, tagId (many-to-many relationship)

Database location: `~/Library/Application Support/SnippetLibrary/snippets.sqlite`

## License

Private project for personal use.
