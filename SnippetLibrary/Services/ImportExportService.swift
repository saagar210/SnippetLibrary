import Foundation

/// Handles JSON import/export of snippets
struct ImportExportService {

    // MARK: - Export Models

    struct ExportedSnippet: Codable {
        let title: String
        let content: String
        let language: String?
        let isFavorite: Bool
        let tags: [String]
        let createdAt: Date
        let updatedAt: Date
    }

    struct ExportData: Codable {
        let version: Int
        let exportedAt: Date
        let snippets: [ExportedSnippet]
    }

    // MARK: - Export

    /// Export all snippets to JSON data
    static func exportSnippets(_ snippets: [Snippet], repository: SnippetRepository) throws -> Data {
        var exportedSnippets: [ExportedSnippet] = []

        for snippet in snippets {
            guard let id = snippet.id else { continue }

            // Fetch tags for this snippet
            let tags = try repository.fetchTags(for: id).map { $0.name }

            let exported = ExportedSnippet(
                title: snippet.title,
                content: snippet.content,
                language: snippet.language,
                isFavorite: snippet.isFavorite,
                tags: tags,
                createdAt: snippet.createdAt,
                updatedAt: snippet.updatedAt
            )
            exportedSnippets.append(exported)
        }

        let exportData = ExportData(
            version: 1,
            exportedAt: Date(),
            snippets: exportedSnippets
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    /// Export to file URL
    static func exportToFile(url: URL, snippets: [Snippet], repository: SnippetRepository) throws {
        let data = try exportSnippets(snippets, repository: repository)
        try data.write(to: url)
    }

    // MARK: - Import

    /// Import snippets from JSON data
    static func importSnippets(from data: Data, repository: SnippetRepository, replaceExisting: Bool = false) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData = try decoder.decode(ExportData.self, from: data)
        guard exportData.version == 1 else {
            throw ImportExportError.unsupportedVersion(exportData.version)
        }

        var imported = 0
        var skipped = 0
        var errors: [String] = []

        // If replacing, clear existing snippets
        if replaceExisting {
            try repository.deleteAll()
        }

        for exportedSnippet in exportData.snippets {
            var insertedSnippetId: Int64?
            do {
                var snippet = Snippet(
                    id: nil,
                    title: exportedSnippet.title,
                    content: exportedSnippet.content,
                    language: exportedSnippet.language,
                    isFavorite: exportedSnippet.isFavorite,
                    usageCount: 0,  // Reset usage count
                    createdAt: exportedSnippet.createdAt,
                    updatedAt: exportedSnippet.updatedAt,
                    embedding: nil  // Will regenerate
                )

                try repository.insert(&snippet, preserveMetadata: true)
                insertedSnippetId = snippet.id

                // Add tags
                if let snippetId = snippet.id {
                    for tagName in exportedSnippet.tags {
                        let cleaned = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleaned.isEmpty else { continue }
                        try repository.addTag(cleaned, to: snippetId)
                    }
                }

                imported += 1
            } catch {
                if let id = insertedSnippetId {
                    try? repository.delete(id: id)
                }
                errors.append("Failed to import '\(exportedSnippet.title)': \(error.localizedDescription)")
                skipped += 1
            }
        }

        return ImportResult(
            imported: imported,
            skipped: skipped,
            errors: errors
        )
    }

    /// Import from file URL
    static func importFromFile(url: URL, repository: SnippetRepository, replaceExisting: Bool = false) throws -> ImportResult {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        return try importSnippets(from: data, repository: repository, replaceExisting: replaceExisting)
    }
}

enum ImportExportError: Error, LocalizedError {
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "Unsupported import format version: \(version)"
        }
    }
}

// MARK: - Import Result

struct ImportResult {
    let imported: Int
    let skipped: Int
    let errors: [String]

    var success: Bool {
        imported > 0 && errors.isEmpty
    }

    var message: String {
        if errors.isEmpty {
            return "Imported \(imported) snippet\(imported == 1 ? "" : "s")"
        } else {
            return "Imported \(imported), skipped \(skipped). \(errors.count) error\(errors.count == 1 ? "" : "s")."
        }
    }
}
