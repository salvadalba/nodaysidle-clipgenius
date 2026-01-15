import Foundation
import OSLog

/// Centralized logging utility using OSLog with subsystem categorization
enum ClipGeniusLogger {
    /// Subsystem identifier for all ClipGenius logs
    static let subsystem = "com.clipgenius.app"
    
    /// Logger categories for different parts of the application
    enum Category {
        case clipboardMonitor
        case persistence
        case search
        case ui
        case categorization
        case formatting
        case general
        
        var osLogCategory: String {
            switch self {
            case .clipboardMonitor: return "ClipboardMonitor"
            case .persistence: return "Persistence"
            case .search: return "Search"
            case .ui: return "UI"
            case .categorization: return "Categorization"
            case .formatting: return "Formatting"
            case .general: return "General"
            }
        }
    }
    
    /// Creates an OSLog instance for the given category
    private static func makeLog(category: Category) -> OSLog {
        OSLog(subsystem: subsystem, category: category.osLogCategory)
    }
    
    // MARK: - Debug Logs (Development Only)
    
    static func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        os_log("%{public}@", log: makeLog(category: category), type: .debug, message)
        #endif
    }
    
    static func debug(_ message: String, category: Category = .general, _ args: CVarArg...) {
        #if DEBUG
        let formatted = String(format: message, arguments: args)
        debug(formatted, category: category)
        #endif
    }
    
    // MARK: - Info Logs
    
    static func info(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: makeLog(category: category), type: .info, message)
    }
    
    static func info(_ message: String, category: Category = .general, _ args: CVarArg...) {
        let formatted = String(format: message, arguments: args)
        info(formatted, category: category)
    }
    
    // MARK: - Error Logs
    
    static func error(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: makeLog(category: category), type: .error, message)
    }
    
    static func error(_ message: String, category: Category = .general, _ args: CVarArg...) {
        let formatted = String(format: message, arguments: args)
        error(formatted, category: category)
    }
    
    static func error(_ error: Error, category: Category = .general, message: String? = nil) {
        let errorMsg = message ?? error.localizedDescription
        os_log("%{public}@", log: makeLog(category: category), type: .error, errorMsg)
    }
    
    // MARK: - Fault Logs
    
    static func fault(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: makeLog(category: category), type: .fault, message)
    }
    
    static func fault(_ message: String, category: Category = .general, _ args: CVarArg...) {
        let formatted = String(format: message, arguments: args)
        fault(formatted, category: category)
    }
    
    // MARK: - Performance Metrics
    
    /// Log timing information for operations
    static func logTiming(_ operation: String, duration: TimeInterval, category: Category = .general) {
        #if DEBUG
        debug("\(operation) took %.2fms", category: category, duration * 1000)
        #else
        if duration > 0.2 { // Only log slow operations in release
            info("\(operation) took %.2fms", category: category, duration * 1000)
        }
        #endif
    }
    
    /// Measure and log the duration of a block
    static func measure<T>(_ operation: String, category: Category = .general, block: () throws -> T) rethrows -> T {
        let start = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(start)
        logTiming(operation, duration: duration, category: category)
        return result
    }
}
