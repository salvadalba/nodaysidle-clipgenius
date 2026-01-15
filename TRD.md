# Technical Requirements Document

## 🧭 System Context
ClipGenius is a native macOS 14+ menu bar clipboard manager using SwiftUI, SwiftData, and on-device CoreML/NaturalLanguage frameworks. Single-process architecture with event-driven MVVM, Combine-based reactive data flow, and NSPasteboard monitoring. Local-first with no network dependencies.

## 🔌 API Contracts
### ClipboardMonitor
- **Method:** event
- **Path:** NSPasteboard.PasteboardDidChangeNotification
- **Auth:** 
- **Request:** NSPasteboard.general.string(forType: .string)
- **Response:** ClipboardItem(title: String, content: String, sourceApp: String?, timestamp: Date)
- **Errors:**
- emptyPasteboard
- unsupportedContentType
- duplicateItem

### SemanticSearch
- **Method:** query
- **Path:** internal:///semantic/search
- **Auth:** 
- **Request:** {query: String, limit: Int, filters: ClipFilters}
- **Response:** [ClipMatch(clip: ClipboardItem, score: Double, highlights: [String])]
- **Errors:**
- emptyQuery
- indexNotReady
- embeddingFailed

### Categorizer
- **Method:** analyze
- **Path:** internal:///categorize
- **Auth:** 
- **Request:** ClipboardItem
- **Response:** {suggestedProject: String?, tags: [String], category: ClipCategory}
- **Errors:**
- analysisFailed

### Formatter
- **Method:** transform
- **Path:** internal:///format
- **Auth:** 
- **Request:** {content: String, format: OutputFormat, context: PasteContext}
- **Response:** String
- **Errors:**
- unsupportedFormat
- transformationFailed

### SwiftDataPersistence
- **Method:** crud
- **Path:** internal:///persistence
- **Auth:** 
- **Request:** CREATE | READ | UPDATE | DELETE ClipboardItem
- **Response:** Result<ClipboardItem, PersistenceError>
- **Errors:**
- duplicate
- notFound
- validationFailed
- storeUnavailable

## 🧱 Modules
### ClipboardMonitor
- **Responsibilities:**
- Poll NSPasteboard at 0.5s intervals
- Detect clipboard changes
- Extract metadata (source app, timestamp)
- Emit new clip events via Combine
- Detect and filter duplicate items
- **Interfaces:**
- Protocol ClipboardMonitoring { var clipboardChanges: AnyPublisher<ClipboardItem, Never> }
- **Depends on:**
- AppKit.NSPasteboard
- Combine

### PersistenceLayer
- **Responsibilities:**
- SwiftData model container management
- CRUD operations for ClipboardItem and Project
- Automatic schema migrations
- Query operations with predicates
- **Interfaces:**
- Protocol ClipboardStore { func save(_ item: ClipboardItem), func fetch(predicate: NSPredicate?, sort: [SortDescriptor]) -> [ClipboardItem], func delete(_ item: ClipboardItem) }
- **Depends on:**
- SwiftData
- Foundation

### SemanticSearchEngine
- **Responsibilities:**
- Generate text embeddings via CoreML
- Compute similarity scores (cosine similarity)
- Index management for fast search
- Handle query parsing and ranking
- **Interfaces:**
- Protocol SemanticSearchable { func search(query: String, limit: Int) -> [ClipMatch], func indexItem(_ item: ClipboardItem) }
- **Depends on:**
- CoreML
- NaturalLanguage
- Accelerate

### Categorizer
- **Responsibilities:**
- Auto-assign clips to projects
- Suggest tags based on content
- Detect clip type (code, text, URL, image)
- Extract source app from NSRunningApplication
- **Interfaces:**
- Protocol Categorizing { func categorize(_ item: ClipboardItem) -> CategorizationResult }
- **Depends on:**
- NaturalLanguage
- AppKit.NSRunningApplication

### Formatter
- **Responsibilities:**
- Convert clips to markdown, plain text, rich text
- Apply syntax highlighting for code
- Strip or preserve formatting based on context
- **Interfaces:**
- Protocol Formatting { func format(_ content: String, as: OutputFormat) -> String }
- **Depends on:**
- Foundation

### MenuBarUI
- **Responsibilities:**
- NSStatusItem with popover
- Search interface with real-time filtering
- Clip list with pagination
- Project sidebar/filter
- Quick insert keyboard shortcut
- **Interfaces:**
- Protocol MenuBarPresentable { var popover: NSPopover, func togglePopover() }
- **Depends on:**
- AppKit.NSStatusItem
- SwiftUI
- ClipboardMonitor
- PersistenceLayer
- SemanticSearchEngine

### ClipboardStore
- **Responsibilities:**
- Centralized Combine-based state
- Cache frequently accessed clips
- Broadcast updates to all subscribers
- **Interfaces:**
- class ClipboardStore: ObservableObject { @Published var clips: [ClipboardItem], @Published var projects: [Project] }
- **Depends on:**
- Combine
- PersistenceLayer

## 🗃 Data Model Notes
- @Model final class ClipboardItem { var id: UUID, var title: String, var content: String, var timestamp: Date, var sourceApp: String?, var embedding: [Double]?, var isFavorite: Bool, @Relationship var project: Project?, @Relationship var tags: Set<Tag> }
- @Model final class Project { var id: UUID, var name: String, var color: Color?, @Relationship(deleteRule: .nullify) var clips: [ClipboardItem] }
- @Model final class Tag { var id: UUID, var name: String, @Relationship var clips: Set<ClipboardItem> }
- enum ClipCategory { case text, code, url, image, file, other }
- enum OutputFormat { case plain, markdown, richText, code }
- struct ClipMatch { let clip: ClipboardItem, let score: Double, let highlights: [String] }
- SwiftData ModelContainer configured with automatic migration

## 🔐 Validation & Security
- Max clip content size: 10MB to prevent memory pressure
- Rate limiting: Max 100 clips per minute to prevent abuse
- Input sanitization: Strip control characters, validate UTF-8
- Sandbox compliance: Only pasteboard, file read (for images), network disabled
- Entitlements: com.apple.security.automation.apple-events for source app detection
- Data validation: Title max 256 chars, content max 10MB, required fields non-empty
- XSS prevention: No HTML rendering, markdown only
- Privacy: No analytics, no crash reporting, all data local

## 🧯 Error Handling Strategy
Combine-based error propagation with Never failure type for UI streams. Non-fatal errors logged and presented as non-blocking alerts. Critical errors trigger alert dialogs with recovery options. Duplicate detection via content hashing (SHA256) with optional user override. Failed clipboard writes are retried once with exponential backoff.

## 🔭 Observability
- **Logging:** OSLog with subsystem com.clipgenius.app. Categories: clipboardMonitor, persistence, search, ui. Development builds emit debug/verbose, release builds error/fault only.
- **Tracing:** Instruments-compatible signposts for clipboard poll, search, database operations. No distributed tracing (single-process).
- **Metrics:**
- Clipboard poll interval (ms)
- Search latency (ms)
- Database query time (ms)
- Memory usage (MB)
- Active clips count
- Search result accuracy (implicit via clicks)

## ⚡ Performance Notes
- Lazy loading for clip list: Load 50 items initially, paginate by 50 on scroll
- Embedding generation: Batch process up to 10 clips, queue during idle time
- Search indexing: Incremental updates, reindex only changed clips
- Memory: Weak references for clip preview images, purge cache on memory pressure
- Startup: Defer non-critical services (categorization, indexing) until after UI renders

## 🧪 Testing Strategy
### Unit
- ClipboardMonitor: Mock NSPasteboard, test change detection
- SemanticSearchEngine: Mock embeddings, test similarity ranking
- Categorizer: Test content type detection, tag suggestion
- PersistenceLayer: In-memory SwiftData container, CRUD operations
### Integration
- Clipboard to persistence flow with real NSPasteboard
- Search with real embedding generation
- UI state updates across Combine pipeline
### E2E
- Launch app, copy text, verify clip appears in search
- Create project, auto-categorize clips, verify grouping
- Insert clip via keyboard shortcut, verify paste
- Performance: 10k clips, search under 200ms

## 🚀 Rollout Plan
- Phase 1: Core clipboard monitoring + SwiftUI list display
- Phase 2: SwiftData persistence + project organization
- Phase 3: Semantic search with CoreML embeddings
- Phase 4: Auto-categorization + smart formatting
- Phase 5: Beta testing via TestFlight
- Phase 6: Mac App Store submission

## ❓ Open Questions
- Should max clip storage be capped (e.g., 100,000 items) or unlimited with user warning?
- What is the minimum macOS version? ARD says 14+, confirm Sonoma requirement
- Handle large file copies from Finder—store reference, thumbnail, or skip?
- Keyboard shortcut default? Proposed: Cmd+Shift+V (configurable)
- Should deleted clips go to trash or permanent delete?