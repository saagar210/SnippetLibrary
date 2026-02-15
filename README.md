# SnippetLibrary

A macOS text expansion utility for managing and quickly inserting code snippets and canned responses.

## What This Does

Save time by creating reusable text snippets with full-text search. Press a global hotkey, search your library, and instantly insert the snippet into any app.

**Target**: IT Support Engineers typing 20-30 responses daily. Saves ~37 min/day.

## Current Status: Phase 4 Complete ✓

**What works now:**
- ✅ Phase 0: SQLite database, CRUD, tag management
- ✅ Phase 1: Menu bar app with global hotkey (Cmd+Shift+Space)
  - Floating search panel with keyboard navigation
  - Text insertion via clipboard + Cmd+V simulation
  - Permission handling (Input Monitoring + Accessibility)
- ✅ Phase 2: FTS5 search intelligence
  - Ranked full-text search (exact title > title contains > content)
  - Multi-word queries ("authentication reset" finds both)
  - Language filtering (Swift, Python, Bash, SQL, etc.)
  - "Recently Used" section for quick access
- ✅ Phase 3: Ollama semantic search
  - Local LLM embeddings via Ollama (nomic-embed-text)
  - Semantic search with cosine similarity ranking
  - Automatic embedding generation on snippet save
  - Settings UI for endpoint, model selection, enable/disable
  - Graceful fallback to FTS5 when Ollama unavailable
- ✅ Phase 4: Polish & productivity features
  - JSON import/export with merge or replace options
  - Launch at login via SMAppService (macOS 13+)
  - Syntax highlighting in snippet detail view (Highlightr)
  - Auto-switches theme based on system appearance
  - 28/28 tests passing

**Future enhancements:**
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

# Dependency vulnerability audit (OSV)
python3 scripts/audit_dependencies.py

# Run app
swift run
```

## Project Structure

```
SnippetLibrary/
├── Models/                  # GRDB records (Snippet, Tag, SnippetTag)
├── Database/                # AppDatabase, SnippetRepository, migrations
├── Services/                # (Phase 1+) HotkeyService, PasteService, PermissionService
├── Views/
│   └── Management/          # Snippet list, editor, detail views
└── Utilities/               # (Future) Constants, Logger
```

## Database Schema

**snippet** table:
- id, title, content, language, isFavorite, usageCount, createdAt, updatedAt, embedding (BLOB)

**tag** table:
- id, name (unique, normalized lowercase)

**snippetTag** junction table:
- snippetId, tagId (many-to-many relationship)

Database location: `~/Library/Application Support/SnippetLibrary/snippets.sqlite`

## Phase 0 Verification Checklist

- [x] Project builds successfully
- [x] All 10 unit tests pass
- [x] Can create a snippet via UI
- [x] Can view snippet list
- [x] Can edit snippet
- [x] Can delete snippet
- [x] Can search/filter snippets
- [x] Data persists after app restart
- [x] Special characters (emoji, newlines) preserved

## Next Steps (Phase 1)

1. Convert to menu bar app (MenuBarExtra, LSUIElement=YES)
2. Create FloatingPanel (NSPanel) for search UI
3. Implement CGEventTap for global hotkey
4. Implement PasteService (clipboard save/restore + Cmd+V simulation)
5. Add permission handling UI for Input Monitoring and Accessibility

## License

Private project for personal use.
