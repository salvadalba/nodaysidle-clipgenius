import Foundation
import SwiftData

/// SwiftData model representing a tag for categorizing clips
@Model
final class Tag {
    /// Unique identifier for this tag
    var id: UUID
    
    /// Tag name (should be unique)
    var name: String
    
    /// Creation date
    var createdAt: Date
    
    /// Clips associated with this tag
    @Relationship(deleteRule: .nullify)
    var clips: Set<ClipboardItem>?
    
    /// Designated initializer
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
    
    /// Returns the count of clips with this tag
    var clipCount: Int {
        clips?.count ?? 0
    }
}

/// Hashable conformance for Set operations
extension Tag: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}
