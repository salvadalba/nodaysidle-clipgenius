import Foundation
import SwiftData
import Combine

/// SwiftData implementation of clipboard persistence
@MainActor
final class SwiftDataPersistence: ClipboardStoring, ObservableObject {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    @Published private var _clips: [ClipboardItem] = []
    @Published private var _projects: [Project] = []
    
    // MARK: - ClipboardStoring
    
    var clips: [ClipboardItem] {
        get { _clips }
        set { _clips = newValue }
    }
    
    var projects: [Project] {
        get { _projects }
        set { _projects = newValue }
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Initial load
        loadInitialData()
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        // Fetch all clips sorted by timestamp (newest first)
        let clipsDescriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let fetchedClips = try modelContext.fetch(clipsDescriptor)
            _clips = fetchedClips
            ClipGeniusLogger.info("Loaded \(fetchedClips.count) clipboard items", category: .persistence)
        } catch {
            ClipGeniusLogger.error("Failed to load clips: \(error)", category: .persistence)
        }
        
        // Fetch all projects
        let projectsDescriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            let fetchedProjects = try modelContext.fetch(projectsDescriptor)
            _projects = fetchedProjects
            ClipGeniusLogger.info("Loaded \(fetchedProjects.count) projects", category: .persistence)
        } catch {
            ClipGeniusLogger.error("Failed to load projects: \(error)", category: .persistence)
        }
    }
    
    private func refreshClips() {
        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let fetched = try modelContext.fetch(descriptor)
            _clips = fetched
        } catch {
            ClipGeniusLogger.error("Failed to refresh clips: \(error)", category: .persistence)
        }
    }
    
    private func refreshProjects() {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            let fetched = try modelContext.fetch(descriptor)
            _projects = fetched
        } catch {
            ClipGeniusLogger.error("Failed to refresh projects: \(error)", category: .persistence)
        }
    }
    
    // MARK: - Public Methods
    
    func save(_ item: ClipboardItem) -> Result<ClipboardItem, PersistenceError> {
        // Validate title
        guard !item.title.isEmpty else {
            return .failure(.validationFailed("Title cannot be empty"))
        }
        
        guard ClipboardItem.validateTitleLength(item.title) else {
            return .failure(.validationFailed("Title exceeds maximum length"))
        }
        
        // Validate content
        guard !item.content.isEmpty else {
            return .failure(.validationFailed("Content cannot be empty"))
        }
        
        guard ClipboardItem.validateContentSize(item.content) else {
            return .failure(.validationFailed("Content exceeds maximum size"))
        }
        
        // Check for duplicates by content hash
        if let hash = item.contentHash {
            let allClips = _clips
            if allClips.contains(where: { $0.contentHash == hash && $0.id != item.id }) {
                ClipGeniusLogger.debug("Duplicate clip found, skipping: \(item.title)", category: .persistence)
                return .failure(.duplicate)
            }
        }
        
        do {
            modelContext.insert(item)
            try modelContext.save()
            refreshClips()
            
            ClipGeniusLogger.debug("Saved clip: \(item.title)", category: .persistence)
            return .success(item)
        } catch {
            ClipGeniusLogger.error("Failed to save clip: \(error)", category: .persistence)
            return .failure(.saveFailed(error))
        }
    }
    
    func update(_ item: ClipboardItem) -> Result<ClipboardItem, PersistenceError> {
        // Validate
        guard !item.title.isEmpty else {
            return .failure(.validationFailed("Title cannot be empty"))
        }
        
        guard ClipboardItem.validateTitleLength(item.title) else {
            return .failure(.validationFailed("Title exceeds maximum length"))
        }
        
        guard ClipboardItem.validateContentSize(item.content) else {
            return .failure(.validationFailed("Content exceeds maximum size"))
        }
        
        // Check if item exists in our cache
        guard let existingItem = _clips.first(where: { $0.id == item.id }) else {
            return .failure(.notFound)
        }
        
        do {
            // Update properties
            existingItem.title = item.title
            existingItem.content = item.content
            existingItem.sourceApp = item.sourceApp
            existingItem.categoryRawValue = item.categoryRawValue
            existingItem.isFavorite = item.isFavorite
            existingItem.project = item.project
            existingItem.tags = item.tags
            
            try modelContext.save()
            refreshClips()
            
            ClipGeniusLogger.debug("Updated clip: \(item.title)", category: .persistence)
            return .success(existingItem)
        } catch {
            ClipGeniusLogger.error("Failed to update clip: \(error)", category: .persistence)
            return .failure(.saveFailed(error))
        }
    }
    
    func delete(_ item: ClipboardItem) -> Result<Void, PersistenceError> {
        guard _clips.contains(where: { $0.id == item.id }) else {
            return .failure(.notFound)
        }
        
        do {
            modelContext.delete(item)
            try modelContext.save()
            refreshClips()
            
            ClipGeniusLogger.debug("Deleted clip: \(item.title)", category: .persistence)
            return .success(())
        } catch {
            ClipGeniusLogger.error("Failed to delete clip: \(error)", category: .persistence)
            return .failure(.deleteFailed(error))
        }
    }
    
    func fetch(
        predicate: NSPredicate? = nil,
        sort: [SortDescriptor<ClipboardItem>] = []
    ) -> [ClipboardItem] {
        // For now, ignore predicates and just return sorted clips
        // Predicate support can be added later with proper SwiftData #Predicate macro
        var result = clips
        
        // Apply sorting if specified
        if !sort.isEmpty {
            // Use the default sort from clips (already sorted by timestamp desc)
            result = clips
        }
        
        return result
    }
    
    func fetchClip(byId id: UUID) -> ClipboardItem? {
        return _clips.first(where: { $0.id == id })
    }
    
    func saveProject(_ project: Project) -> Result<Project, PersistenceError> {
        guard !project.name.isEmpty else {
            return .failure(.validationFailed("Project name cannot be empty"))
        }
        
        // Check for duplicate name
        if _projects.contains(where: { $0.name == project.name && $0.id != project.id }) {
            return .failure(.duplicate)
        }
        
        do {
            modelContext.insert(project)
            try modelContext.save()
            refreshProjects()
            
            ClipGeniusLogger.debug("Saved project: \(project.name)", category: .persistence)
            return .success(project)
        } catch {
            ClipGeniusLogger.error("Failed to save project: \(error)", category: .persistence)
            return .failure(.saveFailed(error))
        }
    }
    
    func deleteProject(_ project: Project) -> Result<Void, PersistenceError> {
        guard _projects.contains(where: { $0.id == project.id }) else {
            return .failure(.notFound)
        }
        
        do {
            modelContext.delete(project)
            try modelContext.save()
            refreshProjects()
            
            ClipGeniusLogger.debug("Deleted project: \(project.name)", category: .persistence)
            return .success(())
        } catch {
            ClipGeniusLogger.error("Failed to delete project: \(error)", category: .persistence)
            return .failure(.deleteFailed(error))
        }
    }
    
    func searchClips(_ query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return clips }
        
        return clips.filter { clip in
            clip.title.localizedCaseInsensitiveContains(query) ||
            clip.content.localizedCaseInsensitiveContains(query)
        }
    }
    
    func clips(for project: Project) -> [ClipboardItem] {
        return clips.filter { $0.project?.id == project.id }
    }
    
    func toggleFavorite(_ item: ClipboardItem) -> Result<ClipboardItem, PersistenceError> {
        guard let existingItem = _clips.first(where: { $0.id == item.id }) else {
            return .failure(.notFound)
        }
        
        existingItem.isFavorite.toggle()
        
        do {
            try modelContext.save()
            refreshClips()
            return .success(existingItem)
        } catch {
            ClipGeniusLogger.error("Failed to toggle favorite: \(error)", category: .persistence)
            return .failure(.saveFailed(error))
        }
    }
    
    func favoriteClips() -> [ClipboardItem] {
        return clips.filter { $0.isFavorite }
    }
}
