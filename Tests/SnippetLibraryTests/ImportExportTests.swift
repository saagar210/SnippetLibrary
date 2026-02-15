import XCTest
@testable import SnippetLibrary

final class ImportExportTests: XCTestCase {
    private var originalOllamaConfig: (endpoint: String, model: String, isEnabled: Bool)?

    override func setUp() async throws {
        originalOllamaConfig = await OllamaService.shared.getConfiguration()
        if let config = originalOllamaConfig {
            await OllamaService.shared.configure(endpoint: config.endpoint, model: config.model, isEnabled: false)
        }
    }

    override func tearDown() async throws {
        if let config = originalOllamaConfig {
            await OllamaService.shared.configure(endpoint: config.endpoint, model: config.model, isEnabled: config.isEnabled)
        }
    }

    func testImportPreservesMetadataAndTags() throws {
        let sourceDB = try AppDatabase.makeEmpty()
        let sourceRepo = SnippetRepository(dbQueue: sourceDB.dbQueue)

        let createdAt = ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z")!
        let updatedAt = ISO8601DateFormatter().date(from: "2024-01-02T12:34:56Z")!

        var snippet = Snippet(
            id: nil,
            title: "Exported Snippet",
            content: "echo hello world",
            language: "bash",
            isFavorite: true,
            usageCount: 0,
            createdAt: createdAt,
            updatedAt: updatedAt,
            embedding: nil
        )
        try sourceRepo.insert(&snippet, preserveMetadata: true)
        try sourceRepo.addTag("ops", to: snippet.id!)
        try sourceRepo.addTag("Support", to: snippet.id!)

        let exported = try ImportExportService.exportSnippets(try sourceRepo.fetchAll(), repository: sourceRepo)

        let targetDB = try AppDatabase.makeEmpty()
        let targetRepo = SnippetRepository(dbQueue: targetDB.dbQueue)
        let result = try ImportExportService.importSnippets(from: exported, repository: targetRepo)

        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertTrue(result.errors.isEmpty)

        let imported = try targetRepo.fetchAll()
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].title, "Exported Snippet")
        XCTAssertEqual(imported[0].content, "echo hello world")
        XCTAssertEqual(imported[0].language, "bash")
        XCTAssertEqual(imported[0].createdAt, createdAt)
        XCTAssertEqual(imported[0].updatedAt, updatedAt)
        XCTAssertTrue(imported[0].isFavorite)

        let tags = try targetRepo.fetchTags(for: imported[0].id!).map { $0.name }.sorted()
        XCTAssertEqual(tags, ["ops", "support"])
    }

    func testImportReplaceExistingRemovesPreviousSnippets() throws {
        let db = try AppDatabase.makeEmpty()
        let repository = SnippetRepository(dbQueue: db.dbQueue)

        var oldSnippet = Snippet(
            id: nil,
            title: "Old Snippet",
            content: "legacy",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&oldSnippet)

        let createdAt = ISO8601DateFormatter().date(from: "2025-01-01T00:00:00Z")!
        let payload = ImportExportService.ExportData(
            version: 1,
            exportedAt: Date(),
            snippets: [
                ImportExportService.ExportedSnippet(
                    title: "New Snippet",
                    content: "new data",
                    language: "swift",
                    isFavorite: false,
                    tags: ["new"],
                    createdAt: createdAt,
                    updatedAt: createdAt
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let result = try ImportExportService.importSnippets(from: data, repository: repository, replaceExisting: true)

        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.skipped, 0)

        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].title, "New Snippet")
        XCTAssertEqual(all[0].content, "new data")
    }

    func testImportRejectsUnsupportedVersion() throws {
        let db = try AppDatabase.makeEmpty()
        let repository = SnippetRepository(dbQueue: db.dbQueue)

        let payload = ImportExportService.ExportData(
            version: 2,
            exportedAt: Date(),
            snippets: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        XCTAssertThrowsError(try ImportExportService.importSnippets(from: data, repository: repository)) { error in
            guard case ImportExportError.unsupportedVersion(2) = error else {
                XCTFail("Expected unsupportedVersion(2), got \(error)")
                return
            }
        }
    }
}
