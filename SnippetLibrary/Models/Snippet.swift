import Foundation
import GRDB

struct Snippet: Codable, Identifiable, Hashable {
    var id: Int64?
    var title: String
    var content: String
    var language: String?       // e.g. "swift", "python", "bash", "plaintext"
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date
    var updatedAt: Date
    var embedding: Data?        // Ollama embedding vector (serialized as Data)

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let content = Column(CodingKeys.content)
        static let language = Column(CodingKeys.language)
        static let isFavorite = Column(CodingKeys.isFavorite)
        static let usageCount = Column(CodingKeys.usageCount)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
        static let embedding = Column(CodingKeys.embedding)
    }

    // Helper to convert [Double] to Data and back
    var embeddingVector: [Double]? {
        get {
            guard let data = embedding else { return nil }
            return try? JSONDecoder().decode([Double].self, from: data)
        }
        set {
            embedding = try? JSONEncoder().encode(newValue)
        }
    }
}

extension Snippet: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "snippet"

    static let tags = hasMany(Tag.self, through: hasMany(SnippetTag.self), using: SnippetTag.tag)

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
