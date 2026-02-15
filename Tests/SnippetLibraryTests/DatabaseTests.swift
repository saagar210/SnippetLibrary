import XCTest
import GRDB
@testable import SnippetLibrary

final class DatabaseTests: XCTestCase {
    var db: AppDatabase!
    var repository: SnippetRepository!

    override func setUp() async throws {
        db = try AppDatabase.makeEmpty()
        repository = SnippetRepository(dbQueue: db.dbQueue)
    }

    func testCreateSnippet() throws {
        var snippet = Snippet(
            id: nil,
            title: "Test Snippet",
            content: "This is a test",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        try repository.insert(&snippet)

        XCTAssertNotNil(snippet.id, "Snippet should have ID after insert")
        XCTAssertEqual(snippet.usageCount, 0, "New snippet should have 0 usage count")
    }

    func testFetchAllSnippets() throws {
        // Insert multiple snippets
        for i in 1...5 {
            var snippet = Snippet(
                id: nil,
                title: "Snippet \(i)",
                content: "Content \(i)",
                language: "plaintext",
                isFavorite: false,
                usageCount: 0,
                createdAt: Date(),
                updatedAt: Date()
            )
            try repository.insert(&snippet)
        }

        let snippets = try repository.fetchAll()
        XCTAssertEqual(snippets.count, 5, "Should have 5 snippets")
    }

    func testUpdateSnippet() throws {
        var snippet = Snippet(
            id: nil,
            title: "Original Title",
            content: "Original Content",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        let id = snippet.id!
        snippet.title = "Updated Title"
        try repository.update(snippet)

        let fetched = try db.dbQueue.read { db in
            try Snippet.fetchOne(db, key: id)
        }

        XCTAssertEqual(fetched?.title, "Updated Title")
    }

    func testDeleteSnippet() throws {
        var snippet = Snippet(
            id: nil,
            title: "To Delete",
            content: "Will be deleted",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        let id = snippet.id!
        try repository.delete(id: id)

        let remaining = try repository.fetchAll()
        XCTAssertTrue(remaining.isEmpty, "Snippet should be deleted")
    }

    func testSearchSnippets() throws {
        let snippets = [
            ("MFA Reset", "Instructions for resetting MFA"),
            ("Password Policy", "Corporate password requirements"),
            ("VPN Setup", "How to configure VPN")
        ]

        for (title, content) in snippets {
            var snippet = Snippet(
                id: nil,
                title: title,
                content: content,
                language: "plaintext",
                isFavorite: false,
                usageCount: 0,
                createdAt: Date(),
                updatedAt: Date()
            )
            try repository.insert(&snippet)
        }

        let results = try repository.search(query: "mfa")
        XCTAssertEqual(results.count, 1, "Should find 1 snippet matching 'mfa'")
        XCTAssertEqual(results.first?.title, "MFA Reset")

        let allResults = try repository.search(query: "")
        XCTAssertEqual(allResults.count, 3, "Empty query should return all snippets")
    }

    func testIncrementUsageCount() throws {
        var snippet = Snippet(
            id: nil,
            title: "Popular Snippet",
            content: "Frequently used",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        let id = snippet.id!
        try repository.incrementUsageCount(id: id)
        try repository.incrementUsageCount(id: id)

        let fetched = try db.dbQueue.read { db in
            try Snippet.fetchOne(db, key: id)
        }

        XCTAssertEqual(fetched?.usageCount, 2, "Usage count should be incremented")
    }

    func testAddTag() throws {
        var snippet = Snippet(
            id: nil,
            title: "Tagged Snippet",
            content: "With tags",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        try repository.addTag("security", to: snippet.id!)
        try repository.addTag("okta", to: snippet.id!)

        let tags = try repository.fetchTags(for: snippet.id!)
        XCTAssertEqual(tags.count, 2, "Should have 2 tags")
        XCTAssertTrue(tags.contains { $0.name == "security" })
        XCTAssertTrue(tags.contains { $0.name == "okta" })
    }

    func testTagNormalization() throws {
        var snippet = Snippet(
            id: nil,
            title: "Tagged Snippet",
            content: "With tags",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        // Add tags with different casing
        try repository.addTag("Security", to: snippet.id!)
        try repository.addTag("SECURITY", to: snippet.id!)
        try repository.addTag("  security  ", to: snippet.id!)

        let tags = try repository.fetchTags(for: snippet.id!)
        XCTAssertEqual(tags.count, 1, "Should normalize to single tag")
        XCTAssertEqual(tags.first?.name, "security")
    }

    func testRemoveTag() throws {
        var snippet = Snippet(
            id: nil,
            title: "Tagged Snippet",
            content: "With tags",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        try repository.addTag("security", to: snippet.id!)
        try repository.addTag("okta", to: snippet.id!)

        let tagsBeforeRemoval = try repository.fetchTags(for: snippet.id!)
        let securityTag = tagsBeforeRemoval.first { $0.name == "security" }!

        try repository.removeTag(securityTag.id!, from: snippet.id!)

        let tagsAfterRemoval = try repository.fetchTags(for: snippet.id!)
        XCTAssertEqual(tagsAfterRemoval.count, 1)
        XCTAssertEqual(tagsAfterRemoval.first?.name, "okta")
    }

    func testAddTagRejectsEmptyOrWhitespace() throws {
        var snippet = Snippet(
            id: nil,
            title: "Invalid Tag Test",
            content: "Tag validation",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        XCTAssertThrowsError(try repository.addTag("   ", to: snippet.id!)) { error in
            guard case SnippetLibrary.DatabaseError.invalidData = error else {
                XCTFail("Expected invalidData error, got \(error)")
                return
            }
        }
    }

    func testSnippetPersistence() throws {
        var snippet = Snippet(
            id: nil,
            title: "Test Persistence",
            content: "With emoji 🚀 and newlines\n\nMultiple paragraphs\n",
            language: "plaintext",
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)

        let fetched = try db.dbQueue.read { db in
            try Snippet.fetchOne(db, key: snippet.id!)
        }

        XCTAssertEqual(fetched?.content, snippet.content, "Content should be preserved exactly")
    }
}
