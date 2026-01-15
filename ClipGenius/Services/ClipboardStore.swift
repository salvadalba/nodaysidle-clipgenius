import Foundation
import SwiftData
import Combine
import SwiftData

/// Protocol defining clipboard persistence operations
@MainActor
protocol ClipboardStoring: ObservableObject {
    /// All clipboard items
    var clips: [ClipboardItem] { get }
    
    /// All projects
    var projects: [Project] { get }
    
    /// Save a new clipboard item
    /// - Parameter item: The item to save
    /// - Returns: Result indicating success or error
    func save(_ item: ClipboardItem) -> Result<ClipboardItem, PersistenceError>
    
    /// Update an existing clipboard item
    /// - Parameter item: The item to update
    /// - Returns: Result indicating success or error
    func update(_ item: ClipboardItem) -> Result<ClipboardItem, PersistenceError>
    
    /// Delete a clipboard item
    /// - Parameter item: The item to delete
    /// - Returns: Result indicating success or error
    func delete(_ item: ClipboardItem) -> Result<Void, PersistenceError>
    
    /// Fetch clips with optional predicate and sorting
    /// - Parameters:
    ///   - predicate: Optional filter predicate
    ///   - sort: Optional sort descriptors
    /// - Returns: Array of matching clips
    func fetch(
        predicate: NSPredicate?,
        sort: [SortDescriptor<ClipboardItem>]
    ) -> [ClipboardItem]
    
    /// Fetch a specific clip by ID
    /// - Parameter id: UUID of the clip
    /// - Returns: The clip if found, nil otherwise
    func fetchClip(byId id: UUID) -> ClipboardItem?
    
    /// Save a new project
    /// - Parameter project: The project to save
    /// - Returns: Result indicating success or error
    func saveProject(_ project: Project) -> Result<Project, PersistenceError>
    
    /// Delete a project
    /// - Parameter project: The project to delete
    /// - Returns: Result indicating success or error
    func deleteProject(_ project: Project) -> Result<Void, PersistenceError>
    
    /// Search clips by content
    /// - Parameter query: Search query string
    /// - Returns: Array of matching clips
    func searchClips(_ query: String) -> [ClipboardItem]
    
    /// Get clips for a specific project
    /// - Parameter project: The project to fetch clips for
    /// - Returns: Array of clips in the project
    func clips(for project: Project) -> [ClipboardItem]
    
    /// Toggle favorite status of a clip
    /// - Parameter item: The clip to toggle
    /// - Returns: Result indicating success or error
    func toggleFavorite(_ item: ClipboardItem) -> Result<ClipboardItem, PersistenceError>
    
    /// Get all favorite clips
    /// - Returns: Array of favorite clips
    func favoriteClips() -> [ClipboardItem]
}

/// Errors that can occur during persistence operations
enum PersistenceError: LocalizedError {
    case duplicate
    case notFound
    case validationFailed(String)
    case storeUnavailable(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .duplicate:
            return "An item with this identifier already exists"
        case .notFound:
            return "The requested item was not found"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .storeUnavailable(let error):
            return "Data store is unavailable: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        }
    }
}
