import Foundation
import GRDB

struct SnippetTag: Codable {
    var snippetId: Int64
    var tagId: Int64

    enum Columns {
        static let snippetId = Column(CodingKeys.snippetId)
        static let tagId = Column(CodingKeys.tagId)
    }
}

extension SnippetTag: FetchableRecord, PersistableRecord {
    static let databaseTableName = "snippetTag"
    static let snippet = belongsTo(Snippet.self)
    static let tag = belongsTo(Tag.self)
}
