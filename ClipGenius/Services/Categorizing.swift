import Foundation
import SwiftData

/// Result of categorizing a clipboard item
struct CategorizationResult {
    /// Suggested project assignment (nil if no suggestion or new project needed)
    var suggestedProject: Project?
    
    /// Suggested tags based on content analysis
    var tags: [String]
    
    /// Detected content category
    var category: ClipCategory
    
    /// Confidence score for the categorization (0-1)
    var confidence: Double
}

/// Protocol defining automatic categorization capabilities
protocol Categorizing {
    /// Analyze a clipboard item and suggest categorization
    /// - Parameter item: The clipboard item to categorize
    /// - Returns: CategorizationResult with suggestions
    func categorize(_ item: ClipboardItem) -> CategorizationResult
    
    /// Suggest tags for a clipboard item based on content
    /// - Parameter item: The clipboard item to analyze
    /// - Returns: Array of suggested tag names
    func suggestTags(for item: ClipboardItem) -> [String]
    
    /// Detect the content category of a clipboard item
    /// - Parameter content: The content string to analyze
    /// - Returns: Detected ClipCategory
    func detectCategory(content: String) -> ClipCategory
    
    /// Suggest a project for a clipboard item
    /// - Parameter item: The clipboard item to analyze
    /// - Parameter existingProjects: Available projects to choose from
    /// - Returns: Suggested project or nil for new project
    func suggestProject(
        for item: ClipboardItem,
        from existingProjects: [Project]
    ) -> Project?
}

/// Errors that can occur during categorization
enum CategorizationError: LocalizedError {
    case analysisFailed(Error)
    case insufficientContent
    
    var errorDescription: String? {
        switch self {
        case .analysisFailed(let error):
            return "Content analysis failed: \(error.localizedDescription)"
        case .insufficientContent:
            return "Insufficient content for categorization"
        }
    }
}
