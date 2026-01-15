import Foundation
import SwiftData

/// Protocol defining semantic search capabilities
protocol SemanticSearchable {
    /// Search for clips matching the query using semantic similarity
    /// - Parameters:
    ///   - query: Natural language search query
    ///   - limit: Maximum number of results to return
    /// - Returns: Array of clips ranked by similarity score
    func search(query: String, limit: Int) -> [ClipMatch]
    
    /// Index a clip for semantic search by generating and storing its embedding
    /// - Parameter item: The clipboard item to index
    func indexItem(_ item: ClipboardItem)
    
    /// Batch index multiple clips
    /// - Parameter items: Array of clipboard items to index
    func indexItems(_ items: [ClipboardItem])
    
    /// Remove an item from the search index
    /// - Parameter itemId: UUID of the item to remove
    func removeItem(_ itemId: UUID)
    
    /// Whether the search index is ready for queries
    var isIndexReady: Bool { get }
    
    /// Total number of items currently indexed
    var indexedCount: Int { get }
}

/// Errors that can occur during semantic search
enum SearchError: LocalizedError {
    case emptyQuery
    case indexNotReady
    case embeddingFailed(Error)
    case modelUnavailable
    
    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Search query cannot be empty"
        case .indexNotReady:
            return "Search index is not ready"
        case .embeddingFailed(let error):
            return "Failed to generate embedding: \(error.localizedDescription)"
        case .modelUnavailable:
            return "Semantic search model is not available"
        }
    }
}
