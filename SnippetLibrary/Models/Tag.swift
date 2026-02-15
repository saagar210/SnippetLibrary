import Foundation
import GRDB

struct Tag: Codable, Identifiable {
    var id: Int64?
    var name: String

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}

extension Tag: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "tag"
    static let snippets = hasMany(Snippet.self, through: hasMany(SnippetTag.self), using: SnippetTag.snippet)

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
