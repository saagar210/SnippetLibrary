import Foundation
import GRDB

struct AppDatabase {
    let dbQueue: DatabaseQueue

    init() throws {
        let path = AppDatabase.databasePath()
        dbQueue = try DatabaseQueue(path: path)
        try migrator.migrate(dbQueue)
    }

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1_createSnippets") { db in
            try db.create(table: "snippet") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("content", .text).notNull()
                t.column("language", .text)
                t.column("isFavorite", .boolean).notNull().defaults(to: false)
                t.column("usageCount", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }

        migrator.registerMigration("v1_createTags") { db in
            try db.create(table: "tag") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique()
            }

            try db.create(table: "snippetTag") { t in
                t.column("snippetId", .integer).notNull()
                    .references("snippet", onDelete: .cascade)
                t.column("tagId", .integer).notNull()
                    .references("tag", onDelete: .cascade)
                t.primaryKey(["snippetId", "tagId"])
            }
        }

        migrator.registerMigration("v2_addFTS") { db in
            try db.create(virtualTable: "snippetFts", using: FTS5()) { t in
                t.synchronize(withTable: "snippet")
                t.tokenizer = .unicode61()
                t.column("title")
                t.column("content")
            }
        }

        migrator.registerMigration("v3_addEmbeddings") { db in
            try db.alter(table: "snippet") { t in
                t.add(column: "embedding", .blob)
            }
        }

        return migrator
    }

    static func databasePath() -> String {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Could not locate Application Support directory")
        }
        let appDir = appSupport.appendingPathComponent("SnippetLibrary", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        } catch {
            fatalError("Could not create Application Support directory at \(appDir.path): \(error)")
        }
        return appDir.appendingPathComponent("snippets.sqlite").path
    }

    static let shared: AppDatabase = {
        do {
            return try AppDatabase()
        } catch {
            fatalError("Database setup failed: \(error)")
        }
    }()

    // For testing: create an in-memory database
    static func makeEmpty() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue()
        return try AppDatabase(dbQueue: dbQueue)
    }
}
