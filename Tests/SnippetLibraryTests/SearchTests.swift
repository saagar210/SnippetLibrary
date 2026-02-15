import XCTest
import GRDB
@testable import SnippetLibrary

final class SearchTests: XCTestCase {
    var db: AppDatabase!
    var repository: SnippetRepository!

    override func setUp() async throws {
        db = try AppDatabase.makeEmpty()
        repository = SnippetRepository(dbQueue: db.dbQueue)

        // Create test snippets with different content
        try createTestSnippet(title: "MFA Reset", content: "Multi-factor authentication reset instructions", language: "plaintext")
        try createTestSnippet(title: "Password Policy", content: "Corporate password requirements and guidelines", language: "plaintext")
        try createTestSnippet(title: "VPN Setup", content: "Virtual private network configuration steps", language: "bash")
        try createTestSnippet(title: "SQL Query", content: "SELECT * FROM users WHERE active = true", language: "sql")
        try createTestSnippet(title: "Swift Function", content: "func authenticate() { /* auth code */ }", language: "swift")
    }

    func testFTS5Search() throws {
        // Test multi-word search
        let results = try repository.search(query: "authentication reset")
        XCTAssertTrue(results.count > 0, "Should find snippets matching 'authentication reset'")
        XCTAssertTrue(results.contains { $0.title == "MFA Reset" }, "Should find MFA Reset snippet")
    }

    func testExactTitleMatchRanksHigher() throws {
        // Exact title match should rank higher than content match
        let results = try repository.search(query: "MFA")
        XCTAssertGreaterThan(results.count, 0)

        // MFA Reset has "MFA" in title, should rank highest
        if let first = results.first {
            XCTAssertTrue(first.title.contains("MFA"), "Exact title match should rank first")
        }
    }

    func testPartialMatchSearch() throws {
        // Test partial word matching
        let results = try repository.search(query: "auth")
        XCTAssertGreaterThan(results.count, 0)
        // Should match "authentication" and "authenticate"
        XCTAssertTrue(results.contains { $0.content.lowercased().contains("auth") })
    }

    func testLanguageFilter() throws {
        // Test language filtering
        let sqlResults = try repository.search(query: "", language: "sql")
        XCTAssertEqual(sqlResults.count, 1)
        XCTAssertEqual(sqlResults.first?.title, "SQL Query")

        let swiftResults = try repository.search(query: "", language: "swift")
        XCTAssertEqual(swiftResults.count, 1)
        XCTAssertEqual(swiftResults.first?.title, "Swift Function")
    }

    func testLanguageFilterWithSearch() throws {
        // Combined language filter + search query
        let results = try repository.search(query: "function", language: "swift")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Swift Function")

        // Same query but wrong language should return nothing
        let emptyResults = try repository.search(query: "function", language: "sql")
        XCTAssertEqual(emptyResults.count, 0)
    }

    func testFetchLanguages() throws {
        let languages = try repository.fetchLanguages()
        XCTAssertTrue(languages.contains("plaintext"))
        XCTAssertTrue(languages.contains("bash"))
        XCTAssertTrue(languages.contains("sql"))
        XCTAssertTrue(languages.contains("swift"))
        XCTAssertEqual(languages.count, 4)
    }

    func testRecentlyUsed() throws {
        // Increment usage on some snippets
        let all = try repository.fetchAll()
        if let first = all.first {
            try repository.incrementUsageCount(id: first.id!)
            try repository.incrementUsageCount(id: first.id!)
        }
        if all.count > 1, let second = all[1].id {
            try repository.incrementUsageCount(id: second)
        }

        let recentlyUsed = try repository.fetchRecentlyUsed(limit: 5)
        XCTAssertGreaterThan(recentlyUsed.count, 0)
        XCTAssertTrue(recentlyUsed.allSatisfy { $0.usageCount > 0 })
    }

    func testEmptyQueryReturnsAllByUsage() throws {
        // Increment usage on one snippet
        let all = try repository.fetchAll()
        if let first = all.first {
            try repository.incrementUsageCount(id: first.id!)
        }

        let results = try repository.search(query: "")
        XCTAssertEqual(results.count, 5, "Empty query should return all snippets")

        // Most used should be first
        if let first = results.first {
            XCTAssertGreaterThan(first.usageCount, 0)
        }
    }

    private func createTestSnippet(title: String, content: String, language: String) throws {
        var snippet = Snippet(
            id: nil,
            title: title,
            content: content,
            language: language,
            isFavorite: false,
            usageCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        try repository.insert(&snippet)
    }
}
