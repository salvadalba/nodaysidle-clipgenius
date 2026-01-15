import Foundation
import SwiftData
import CryptoKit

/// SwiftData model representing a single clipboard item
@Model
final class ClipboardItem {
    /// Unique identifier for this clip
    var id: UUID
    
    /// Display title (preview of content, max 256 chars)
    var title: String
    
    /// Full clipboard content (max 10MB)
    var content: String
    
    /// When this item was copied to clipboard
    var timestamp: Date
    
    /// Source application bundle identifier (e.g., "com.apple.Safari")
    var sourceApp: String?
    
    /// Semantic embedding vector for search (computed via CoreML/NL)
    var embedding: Data?
    
    /// Whether user has marked this as a favorite
    var isFavorite: Bool
    
    /// Auto-detected content category
    var categoryRawValue: String
    
    /// Computed category property
    var category: ClipCategory {
        get { ClipCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
    
    /// Project this clip belongs to (optional)
    @Relationship(deleteRule: .nullify)
    var project: Project?
    
    /// Tags associated with this clip
    @Relationship
    var tags: Set<Tag>?
    
    /// Content hash for duplicate detection
    var contentHash: String?
    
    /// Designated initializer
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        timestamp: Date = Date(),
        sourceApp: String? = nil,
        category: ClipCategory = .other,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.sourceApp = sourceApp
        self.categoryRawValue = category.rawValue
        self.isFavorite = isFavorite
        self.contentHash = Self.computeHash(content: content)
    }
    
    /// Maximum title length constant
    static let maxTitleLength = 256
    
    /// Maximum content size constant (10MB)
    static let maxContentSize = 10 * 1024 * 1024
    
    /// Validates if content size is within limits
    static func validateContentSize(_ content: String) -> Bool {
        return content.utf8.count <= maxContentSize
    }
    
    /// Validates if title length is within limits
    static func validateTitleLength(_ title: String) -> Bool {
        return title.count <= maxTitleLength
    }
    
    /// Computes SHA256 hash of content for duplicate detection
    private static func computeHash(content: String) -> String {
        guard let data = content.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Generates a preview string for display
    func preview(maxLength: Int = 100) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxLength {
            return trimmed
        }
        let index = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<index]) + "…"
    }
}
