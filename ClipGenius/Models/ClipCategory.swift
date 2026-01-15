import Foundation

/// Enumeration of clipboard content types for categorization and filtering
enum ClipCategory: String, Codable, CaseIterable {
    case text
    case code
    case url
    case image
    case file
    case other
    
    /// Display name for the category
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .code: return "Code"
        case .url: return "URL"
        case .image: return "Image"
        case .file: return "File"
        case .other: return "Other"
        }
    }
    
    /// SF Symbol icon for the category
    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .code: return "curlybraces"
        case .url: return "link"
        case .image: return "photo"
        case .file: return "doc"
        case .other: return "doc.on.doc"
        }
    }
}
