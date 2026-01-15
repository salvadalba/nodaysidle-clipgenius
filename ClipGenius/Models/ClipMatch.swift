import Foundation
import SwiftData

/// Result of a semantic search query with relevance scoring
struct ClipMatch: Identifiable {
    let id: UUID = UUID()
    let clip: ClipboardItem
    let score: Double
    let highlights: [String]
    
    /// Returns whether this match has a high relevance score
    var isHighRelevance: Bool {
        score > 0.7
    }
    
    /// Returns whether this match has a medium relevance score
    var isMediumRelevance: Bool {
        score > 0.4 && score <= 0.7
    }
}

/// Context information for paste operations
struct PasteContext {
    let destinationApp: String?
    let currentPosition: String?
    let surroundingText: String?
}
