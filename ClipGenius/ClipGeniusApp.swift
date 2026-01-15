import SwiftUI
import SwiftData
import Combine

@main
struct ClipGeniusApp: App {
    // MARK: - Properties

    /// Shared instance of the app state for dependency injection
    @StateObject private var appState = AppState()

    /// SwiftData ModelContainer
    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        do {
            // Configure SwiftData with all models
            let schema = Schema([
                ClipboardItem.self,
                Project.self,
                Tag.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            ClipGeniusLogger.info("SwiftData container initialized successfully", category: .general)
        } catch {
            ClipGeniusLogger.fault("Failed to initialize SwiftData container: \(error)", category: .general)
            fatalError("Failed to initialize SwiftData: \(error.localizedDescription)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        // Menu bar extra (status item) scene
        MenuBarExtra("ClipGenius", systemImage: "doc.on.clipboard") {
            MenuBarView()
                .environment(\.modelContext, modelContainer.mainContext)
                .environmentObject(appState)
                .frame(minWidth: 600, minHeight: 400)
        }

        // Settings window (optional, for preferences)
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

/// Global app state for sharing services across views
@MainActor
final class AppState: ObservableObject {
    /// Clipboard store for persistence operations
    var clipboardStore: (any ClipboardStoring)?
    
    /// Clipboard monitor service
    var clipboardMonitor: ClipboardMonitoring?
    
    /// Semantic search engine
    var semanticSearch: SemanticSearchable?
    
    /// Categorizer service
    var categorizer: Categorizing?
    
    /// Formatter service
    var formatter: Formatting?
    
    /// Whether the popover is currently shown
    @Published var isPopoverShown = false
    
    /// Currently selected clip
    @Published var selectedClip: ClipboardItem?
    
    /// Current search query
    @Published var searchQuery = ""
    
    /// Selected project filter (nil = all projects)
    @Published var selectedProject: Project?
    
    /// Current view state
    @Published var viewState: ViewState = .list
    
    /// Model context reference for operations
    private var modelContext: ModelContext?
    
    /// Initialize services with the given model context
    func initialize(with modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Initialize persistence
        let persistence = SwiftDataPersistence(modelContext: modelContext)
        self.clipboardStore = persistence
        
        // Initialize services
        self.clipboardMonitor = ClipboardMonitor()
        self.semanticSearch = SemanticSearchEngine()
        self.categorizer = Categorizer()
        self.formatter = ContentFormatter()
        
        ClipGeniusLogger.info("All services initialized", category: .general)
        
        // Set up clipboard monitoring pipeline
        setupClipboardPipeline()
        
        // Index existing clips
        indexExistingClips()
    }
    
    private func setupClipboardPipeline() {
        guard let monitor = clipboardMonitor,
              let store = clipboardStore,
              let categorizer = categorizer,
              let searchEngine = semanticSearch else {
            return
        }
        
        // Set up the Combine pipeline: Monitor -> Save -> Categorize -> Index
        monitor.clipboardChanges
            .sink { [weak self] item in
                // Save to persistence
                let result = store.save(item)
                
                if case .success(let savedItem) = result {
                    // Categorize the item
                    let categorization = categorizer.categorize(savedItem)
                    
                    // Apply category - need to update through model context
                    savedItem.category = categorization.category
                    
                    // Save the updated item
                    if let context = self?.modelContext {
                        try? context.save()
                    }
                    
                    // Index for search
                    searchEngine.indexItem(savedItem)
                    
                    ClipGeniusLogger.debug("Processed clipboard item: \(savedItem.title)", category: .general)
                }
            }
            .store(in: &cancellables)
        
        // Start monitoring
        monitor.start()
    }
    
    private func indexExistingClips() {
        guard let store = clipboardStore,
              let searchEngine = semanticSearch else {
            return
        }
        
        // Index all existing clips in background
        let clips = store.clips
        if !clips.isEmpty {
            searchEngine.indexItems(clips)
            ClipGeniusLogger.info("Indexed \(clips.count) existing clips", category: .general)
        }
    }
    
    // MARK: - Combine Cancellables
    
    private var cancellables = Set<AnyCancellable>()
}

/// View states for the app
enum ViewState {
    case list
    case search
    case detail(ClipboardItem)
    case settings
    case projects
}
