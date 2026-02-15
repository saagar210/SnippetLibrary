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

# Clean generated files
bash scripts/clean.sh

# Dependency vulnerability audit (OSV)
python3 scripts/audit_dependencies.py

# Run app
swift run
```

## Maintenance

- Use `bash scripts/clean.sh` to remove generated/local artifacts (`.build`, `.codex_audit`, `.DS_Store`, `__pycache__`) when the repo feels cluttered.
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
