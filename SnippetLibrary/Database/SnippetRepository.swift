import Foundation
import GRDB

struct SnippetRepository {
    let dbQueue: DatabaseQueue

    func insert(_ snippet: inout Snippet, preserveMetadata: Bool = false) throws {
        try dbQueue.write { db in
            if preserveMetadata {
                if snippet.updatedAt < snippet.createdAt {
                    snippet.updatedAt = snippet.createdAt
                }
            } else {
                snippet.createdAt = Date()
                snippet.updatedAt = Date()
                snippet.usageCount = 0
                snippet.isFavorite = false
            }
            try snippet.insert(db)
        }

        // Generate embedding asynchronously (don't block insert)
        guard let id = snippet.id else {
            throw DatabaseError.recordNotSaved
        }
        let text = "\(snippet.title) \(snippet.content)"
        Task {
            await generateEmbeddingFor(id: id, text: text)
        }
    }

    func update(_ snippet: Snippet) throws {
        try dbQueue.write { db in
            var updated = snippet
            updated.updatedAt = Date()
            try updated.update(db)
            return ()
        }
    }

    func delete(id: Int64) throws {
        try dbQueue.write { db in
            try Snippet.deleteOne(db, key: id)
            return ()
        }
    }

    func deleteAll() throws {
        try dbQueue.write { db in
            try Snippet.deleteAll(db)
            try Tag.deleteAll(db)
            return ()
        }
    }

    func fetchAll() throws -> [Snippet] {
        try dbQueue.read { db in
            try Snippet.order(Snippet.Columns.updatedAt.desc).fetchAll(db)
        }
    }

    func search(query: String, language: String? = nil) throws -> [Snippet] {
        try dbQueue.read { db in
            if query.isEmpty {
                // Empty query: sort by usage + recency
                var request = Snippet.order(Snippet.Columns.usageCount.desc, Snippet.Columns.updatedAt.desc)
                if let language = language {
                    request = request.filter(Snippet.Columns.language == language)
                }
                return try request.fetchAll(db)
            }

            // FTS5 search with ranking
            // Match query in FTS virtual table, join back to snippet table for full data
            let pattern = FTS5Pattern(matchingAllTokensIn: query) ?? FTS5Pattern(matchingAnyTokenIn: query)

            let sql = """
                SELECT snippet.*, snippetFts.rank
                FROM snippet
                JOIN snippetFts ON snippet.id = snippetFts.rowid
                WHERE snippetFts MATCH ?
                ORDER BY
                    CASE
                        WHEN snippet.title LIKE ? THEN 0
                        WHEN snippet.title LIKE ? THEN 1
                        ELSE 2
                    END,
                    snippetFts.rank,
                    snippet.usageCount DESC
                """

            let exactPattern = query
            let containsPattern = "%\(query)%"

            var snippets = try Snippet.fetchAll(db, sql: sql, arguments: [
                pattern?.rawPattern ?? query,
                exactPattern,
                containsPattern
            ])

            // Filter by language if specified
            if let language = language {
                snippets = snippets.filter { $0.language == language }
            }

            return snippets
        }
    }

    func incrementUsageCount(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE snippet SET usageCount = usageCount + 1 WHERE id = ?",
                arguments: [id]
            )
        }
    }

    func fetchRecentlyUsed(limit: Int = 5) throws -> [Snippet] {
        try dbQueue.read { db in
            try Snippet
                .filter(Snippet.Columns.usageCount > 0)
                .order(Snippet.Columns.updatedAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func fetchByLanguage(_ language: String) throws -> [Snippet] {
        try dbQueue.read { db in
            try Snippet
                .filter(Snippet.Columns.language == language)
                .order(Snippet.Columns.usageCount.desc, Snippet.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    func fetchLanguages() throws -> [String] {
        try dbQueue.read { db in
            let languages = try String.fetchAll(db, sql: """
                SELECT DISTINCT language
                FROM snippet
                WHERE language IS NOT NULL
                ORDER BY language
            """)
            return languages.filter { !$0.isEmpty }
        }
    }

    func addTag(_ tagName: String, to snippetId: Int64) throws {
        try dbQueue.write { db in
            let normalizedName = tagName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedName.isEmpty else {
                throw DatabaseError.invalidData
            }

            // Find or create tag
            var tag: Tag
            if let existing = try Tag.filter(Tag.Columns.name == normalizedName).fetchOne(db) {
                tag = existing
            } else {
                var newTag = Tag(id: nil, name: normalizedName)
                try newTag.insert(db)
                tag = newTag
            }

            // Create junction record if doesn't exist
            guard let tagId = tag.id else {
                throw DatabaseError.recordNotSaved
            }
            let alreadyTagged = try SnippetTag
                .filter(SnippetTag.Columns.snippetId == snippetId && SnippetTag.Columns.tagId == tagId)
                .fetchOne(db) != nil

            if !alreadyTagged {
                let junction = SnippetTag(snippetId: snippetId, tagId: tagId)
                try junction.insert(db)
            }
        }
    }

    func removeTag(_ tagId: Int64, from snippetId: Int64) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM snippetTag WHERE snippetId = ? AND tagId = ?",
                arguments: [snippetId, tagId]
            )
        }
    }

    func fetchTags(for snippetId: Int64) throws -> [Tag] {
        try dbQueue.read { db in
            let request = Tag
                .joining(required: Tag.hasMany(SnippetTag.self).filter(SnippetTag.Columns.snippetId == snippetId))
                .order(Tag.Columns.name)

            return try request.fetchAll(db)
        }
    }

    /// Semantic search using Ollama embeddings
    func semanticSearch(query: String, limit: Int = 20) async throws -> [Snippet] {
        // Get query embedding
        guard let queryEmbedding = try await OllamaService.shared.embed(text: query) else {
            // Ollama not available, fallback to FTS5
            return try search(query: query)
        }

        // Fetch all snippets with embeddings
        let snippets = try await dbQueue.read { db in
            try Snippet.filter(Snippet.Columns.embedding != nil).fetchAll(db)
        }

        // Calculate similarity scores
        var scored: [(snippet: Snippet, score: Double)] = []
        for snippet in snippets {
            if let embedding = snippet.embeddingVector {
                let similarity = OllamaService.cosineSimilarity(queryEmbedding, embedding)
                scored.append((snippet, similarity))
            }
        }

        // Sort by similarity descending
        scored.sort { $0.score > $1.score }

        return scored.prefix(limit).map { $0.snippet }
    }

    /// Generate embedding for a snippet (async, called after insert/update)
    func generateEmbeddingFor(id: Int64, text: String) async {
        do {
            guard let embedding = try await OllamaService.shared.embed(text: text) else {
                return // Ollama not available
            }

            let data = try JSONEncoder().encode(embedding)

            try await dbQueue.write { db in
                try db.execute(
                    sql: "UPDATE snippet SET embedding = ? WHERE id = ?",
                    arguments: [data, id]
                )
                return ()
            }
        } catch {
            print("Failed to generate embedding for snippet \(id): \(error)")
        }
    }
}

enum DatabaseError: Error {
    case recordNotSaved
    case invalidData
}
