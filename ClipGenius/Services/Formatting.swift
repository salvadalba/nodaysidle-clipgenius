import Foundation

/// Protocol defining content formatting capabilities
protocol Formatting {
    /// Format content to the specified output format
    /// - Parameters:
    ///   - content: The content to format
    ///   - format: The desired output format
    ///   - context: Optional paste context for smart formatting
    /// - Returns: Formatted content string
    func format(
        content: String,
        as format: OutputFormat,
        context: PasteContext?
    ) -> String
    
    /// Detect the programming language from content
    /// - Parameter content: Code content to analyze
    /// - Returns: Detected language identifier or nil
    func detectLanguage(content: String) -> String?
    
    /// Convert markdown to another format
    /// - Parameters:
    ///   - markdown: Markdown content
    ///   - targetFormat: Desired output format
    /// - Returns: Converted content
    func convertMarkdown(
        _ markdown: String,
        to targetFormat: OutputFormat
    ) -> String
}

/// Errors that can occur during formatting
enum FormattingError: LocalizedError {
    case unsupportedFormat
    case transformationFailed(Error)
    case invalidMarkdown
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "The requested format is not supported"
        case .transformationFailed(let error):
            return "Content transformation failed: \(error.localizedDescription)"
        case .invalidMarkdown:
            return "Invalid markdown content"
        }
    }
}
