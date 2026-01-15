import Foundation
import Combine

/// Protocol defining clipboard monitoring capabilities
protocol ClipboardMonitoring {
    /// Publisher that emits new clipboard items as they are detected
    var clipboardChanges: AnyPublisher<ClipboardItem, Never> { get }
    
    /// Starts monitoring the clipboard for changes
    func start()
    
    /// Stops monitoring the clipboard
    func stop()
    
    /// Whether monitoring is currently active
    var isMonitoring: Bool { get }
}

/// Errors that can occur during clipboard monitoring
enum ClipboardError: LocalizedError {
    case emptyPasteboard
    case unsupportedContentType
    case contentTooLarge
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .emptyPasteboard:
            return "The clipboard is empty"
        case .unsupportedContentType:
            return "The clipboard content type is not supported"
        case .contentTooLarge:
            return "The clipboard content exceeds the maximum size limit"
        case .accessDenied:
            return "Access to the clipboard was denied"
        }
    }
}
