import Foundation

/// Supported output formats for clipboard content transformation
enum OutputFormat: String, Codable, CaseIterable {
    case plain
    case markdown
    case richText
    case code
    
    /// Display name for the format
    var displayName: String {
        switch self {
        case .plain: return "Plain Text"
        case .markdown: return "Markdown"
        case .richText: return "Rich Text"
        case .code: return "Code Block"
        }
    }
    
    /// File extension for the format
    var fileExtension: String {
        switch self {
        case .plain: return "txt"
        case .markdown: return "md"
        case .richText: return "rtf"
        case .code: return "txt"
        }
    }
}
