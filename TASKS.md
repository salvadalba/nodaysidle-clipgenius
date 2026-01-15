# Tasks Plan — ClipGenius

## 📌 Global Assumptions
- Solo developer using Xcode 15+ on macOS 14+
- No external dependencies beyond Apple frameworks
- All data stored locally, no network required
- Target language: Swift 5.9+
- UI framework: SwiftUI with AppKit bridges where needed
- Beta testing via TestFlight before public release

## ⚠️ Risks
- NSPasteboard polling at 0.5s may affect battery life - need to optimize or increase interval
- CoreML embedding model may be large (>50MB) affecting app download size
- Semantic search accuracy depends on quality of on-device embeddings
- SwiftData schema migrations may be complex for future updates
- Menu bar apps have limited discoverability - marketing challenge

## 🧩 Epics
## Foundation & Xcode Project Setup
**Goal:** Initialize the Xcode project with proper configuration, entitlements, and folder structure for a macOS menu bar app

### ✅ Create Xcode project with macOS App target (0.5)

Create a new macOS App project in Xcode targeting macOS 14.0+, set bundle identifier, team, and version info

**Acceptance Criteria**
- Xcode project builds successfully for macOS 14.0+
- App target has proper bundle identifier (com.clipgenius.app)
- Info.plist includes LSUIElement=1 for menu bar app
- Version 1.0.0 set in project settings

**Dependencies**
_None_
### ✅ Configure entitlements and sandbox (0.5)

Add entitlements file with required permissions for pasteboard access, Apple Events for source app detection, and file read for images

**Acceptance Criteria**
- Entitlements file includes com.apple.security.automation.apple-events
- Sandbox enabled with pasteboard read/write
- File read entitlement for image thumbnails
- App builds and runs with sandbox enabled

**Dependencies**
- Create Xcode project with macOS App target
### ✅ Set up project folder structure (0.25)

Create folder structure following MVVM: Models/, Views/, ViewModels/, Services/, Utils/, Resources/

**Acceptance Criteria**
- All folders created in Xcode groups
- Folder structure matches MVVM pattern
- Each folder has proper Swift file template

**Dependencies**
- Create Xcode project with macOS App target
### ✅ Configure logging infrastructure (0.25)

Set up OSLog with subsystem com.clipgenius.app and categories for clipboardMonitor, persistence, search, ui

**Acceptance Criteria**
- Logger utility created with OSLog configuration
- Debug logs in dev builds, error only in release
- Categories: clipboardMonitor, persistence, search, ui defined

**Dependencies**
- Set up project folder structure

## SwiftData Models & Persistence
**Goal:** Define SwiftData models for clips, projects, and tags with relationships and implement CRUD operations

### ✅ Create ClipboardItem SwiftData model (0.5)

Define @Model final class ClipboardItem with id, title, content, timestamp, sourceApp, embedding, isFavorite, and relationships to project and tags

**Acceptance Criteria**
- @Model final class ClipboardItem with all properties
- UUID id, String title (max 256), String content (max 10MB)
- Date timestamp, String? sourceApp, [Double]? embedding
- Bool isFavorite, @Relationship project and tags

**Dependencies**
_None_
### ✅ Create Project and Tag SwiftData models (0.5)

Define @Model final class Project with name, color, and clips relationship; @Model final class Tag with name and clips relationship

**Acceptance Criteria**
- @Model final class Project with UUID, name, Color?, clips relationship
- @Model final class Tag with UUID, name, clips relationship
- Delete rules properly configured (.nullify for clips)

**Dependencies**
- Create ClipboardItem SwiftData model
### ✅ Define supporting types and enums (0.25)

Create ClipCategory enum (text, code, url, image, file, other), OutputFormat enum (plain, markdown, richText, code), ClipMatch struct

**Acceptance Criteria**
- ClipCategory enum with all cases defined
- OutputFormat enum with all cases defined
- ClipMatch struct with clip, score, highlights

**Dependencies**
_None_
### ✅ Configure SwiftData ModelContainer (0.5)

Set up ModelContainer in the app with ClipboardItem, Project, Tag models and automatic migration

**Acceptance Criteria**
- ModelContainer configured with all three models
- Automatic migration enabled
- Container initialized in App entry point

**Dependencies**
- Create ClipboardItem SwiftData model
- Create Project and Tag SwiftData models
### ✅ Implement ClipboardStore protocol and SwiftDataPersistence (1)

Create protocol ClipboardStore with save, fetch, delete methods; implement SwiftDataPersistence class with SwiftData CRUD operations

**Acceptance Criteria**
- Protocol defines save, fetch(predicate:sort:), delete methods
- SwiftDataPersistence implements protocol using ModelContext
- Proper error types: duplicate, notFound, validationFailed, storeUnavailable

**Dependencies**
- Configure SwiftData ModelContainer

## Clipboard Monitoring
**Goal:** Implement NSPasteboard monitoring with change detection, metadata extraction, and duplicate filtering

### ✅ Create ClipboardMonitoring protocol (0.25)

Define protocol with clipboardChanges publisher that emits ClipboardItem events

**Acceptance Criteria**
- Protocol has clipboardChanges: AnyPublisher<ClipboardItem, Never>
- ClipboardItem struct defined with title, content, sourceApp, timestamp

**Dependencies**
_None_
### ✅ Implement NSPasteboard polling monitor (1)

Create ClipboardMonitor class that polls NSPasteboard.general at 0.5s intervals and detects changes via hash comparison

**Acceptance Criteria**
- Polls NSPasteboard every 0.5 seconds
- Detects changes using content hashing (SHA256)
- Emits items on clipboardChanges publisher
- Background thread polling to avoid UI blocking

**Dependencies**
- Create ClipboardMonitoring protocol
### ✅ Extract metadata from clipboard content (0.5)

Implement source app detection using NSRunningApplication and timestamp generation

**Acceptance Criteria**
- Source app extracted from NSRunningApplication.frontmost
- Timestamp set to Date() on clipboard change
- Title generated from content preview (first 100 chars)

**Dependencies**
- Implement NSPasteboard polling monitor
### ✅ Implement duplicate detection (0.5)

Filter duplicate items using SHA256 content hashing with optional user override

**Acceptance Criteria**
- SHA256 hash computed for each clipboard item
- Duplicate items filtered from publisher
- User preference setting to allow duplicates

**Dependencies**
- Implement NSPasteboard polling monitor
### ✅ Add content type detection (0.5)

Detect if clipboard contains text, URL, image, or file using UTI types

**Acceptance Criteria**
- Detects .string, .url, .tiff, .file-url UTI types
- Maps to ClipCategory enum
- Handles unsupported content types with error

**Dependencies**
- Implement NSPasteboard polling monitor

## Semantic Search Engine
**Goal:** Build on-device semantic search using CoreML embeddings with cosine similarity scoring

### ✅ Research and select CoreML embedding model (1)

Evaluate available CoreML text embedding models and select one for on-device use

**Acceptance Criteria**
- Model selected (e.g., NaturalLanguage framework's NLEmbedding)
- Model compatible with macOS 14+
- Embedding dimension documented (e.g., 512)

**Dependencies**
_None_
### ✅ Create SemanticSearchable protocol (0.25)

Define protocol with search(query:limit:) and indexItem methods

**Acceptance Criteria**
- Protocol defines search(query:limit:) -> [ClipMatch]
- Protocol defines indexItem(_ item: ClipboardItem)
- ClipMatch struct includes clip, score, highlights

**Dependencies**
_None_
### ✅ Implement embedding generation (1)

Generate text embeddings using selected CoreML/NaturalLanguage model

**Acceptance Criteria**
- Function to generate embedding from String
- Returns [Double] array of model dimension
- Handles embeddingFailed error

**Dependencies**
- Research and select CoreML embedding model
### ✅ Implement cosine similarity scoring (1)

Compute cosine similarity between query embedding and clip embeddings using Accelerate framework

**Acceptance Criteria**
- Cosine similarity function using vDSP from Accelerate
- Returns score between -1 and 1
- Optimized for batch computation

**Dependencies**
- Implement embedding generation
### ✅ Build incremental search index (1)

Create in-memory index for fast similarity search with incremental updates

**Acceptance Criteria**
- Index stores clip embeddings for quick lookup
- Incremental updates when clips added/modified
- Search ranks results by similarity score

**Dependencies**
- Implement cosine similarity scoring
### ✅ Implement SemanticSearchEngine class (1)

Complete implementation of SemanticSearchable protocol with query parsing and ranking

**Acceptance Criteria**
- search(query:limit:) returns ranked [ClipMatch]
- indexItem called for new/modified clips
- Handles emptyQuery, indexNotReady, embeddingFailed errors

**Dependencies**
- Build incremental search index
- Create SemanticSearchable protocol
### ✅ Add batch embedding queue (0.5)

Queue embedding generation during idle time, batch process up to 10 clips

**Acceptance Criteria**
- Embeddings generated in batches of 10
- Processing during NSApplication idle time
- Progress tracked for UI display

**Dependencies**
- Implement SemanticSearchEngine class

## Auto-Categorization
**Goal:** Implement automatic project assignment and tag suggestion based on clip content using NaturalLanguage

### ✅ Create Categorizing protocol (0.25)

Define protocol with categorize method returning CategorizationResult

**Acceptance Criteria**
- Protocol defines categorize(_ item: ClipboardItem) -> CategorizationResult
- CategorizationResult has suggestedProject, tags, category

**Dependencies**
_None_
### ✅ Implement content type detection (0.5)

Detect if clip is code, text, URL based on patterns (regex for URLs, code blocks, file extensions)

**Acceptance Criteria**
- URL detection using regex
- Code detection (keywords, indentation, common extensions)
- Maps to ClipCategory enum

**Dependencies**
_None_
### ✅ Implement tag suggestion using NLTagger (1)

Use NaturalLanguage's NLTagger to extract keywords and suggest tags

**Acceptance Criteria**
- NLTagger extracts nouns and named entities
- Tags returned as [String]
- Relevant tags filtered by frequency

**Dependencies**
_None_
### ✅ Implement project suggestion logic (1)

Suggest project based on content similarity to existing project clips or create new project

**Acceptance Criteria**
- Compares new clip to existing project content
- Suggests existing project if similarity threshold met
- Returns nil for new projects (user creates)

**Dependencies**
- Implement tag suggestion using NLTagger
### ✅ Create Categorizer service implementation (0.5)

Combine content type, tag suggestion, and project suggestion into Categorizing implementation

**Acceptance Criteria**
- Implements Categorizing protocol
- Returns CategorizationResult with all fields
- Handles analysisFailed error

**Dependencies**
- Implement project suggestion logic
- Create Categorizing protocol

## Menu Bar UI
**Goal:** Build SwiftUI menu bar interface with search, clip list, and keyboard shortcuts

### ✅ Create NSStatusItem with menu bar icon (0.5)

Set up status item in menu bar with SF Symbol icon and click handler

**Acceptance Criteria**
- NSStatusItem visible in menu bar
- Uses document.on.clipboard SF Symbol
- Click action toggles popover

**Dependencies**
_None_
### ✅ Design main SwiftUI popover view (1)

Create main view with .ultraThinMaterial background, search bar, sidebar, and clip list

**Acceptance Criteria**
- NSPopover with SwiftUI content
- Ultra-thin material background applied
- Layout: search bar top, sidebar left, clip list right

**Dependencies**
- Create NSStatusItem with menu bar icon
### ✅ Implement search bar view (0.5)

Create SwiftUI search field with real-time filtering and semantic search integration

**Acceptance Criteria**
- SearchTextField in SwiftUI
- Debounced input (300ms)
- Shows search results as user types

**Dependencies**
- Design main SwiftUI popover view
### ✅ Create clip list view with lazy loading (1)

Build list view with 50-item pagination, swipe actions, and preview

**Acceptance Criteria**
- LazyVStack for clip list
- Loads 50 items initially, 50 more on scroll
- Swipe to delete, long press for preview

**Dependencies**
- Design main SwiftUI popover view
### ✅ Implement project sidebar (1)

Create sidebar showing projects with color indicators and clip counts

**Acceptance Criteria**
- List of projects with color badges
- Shows clip count per project
- Filter clips by project selection

**Dependencies**
- Design main SwiftUI popover view
### ✅ Add keyboard shortcut for quick insert (1)

Implement global keyboard shortcut (Cmd+Shift+V) to show popover and insert selected clip

**Acceptance Criteria**
- NSEventMonitor for global hotkey
- Default Cmd+Shift+V (user configurable)
- Inserts clip at current cursor position

**Dependencies**
- Create NSStatusItem with menu bar icon
### ✅ Create clip detail/edit view (1)

Detail view for editing clip title, content, project assignment, and tags

**Acceptance Criteria**
- Edit title and content
- Assign to project or create new
- Add/remove tags
- Mark as favorite

**Dependencies**
- Create clip list view with lazy loading

## Smart Formatting
**Goal:** Implement AI-suggested formatting with markdown conversion and syntax highlighting

### ✅ Create Formatting protocol (0.25)

Define protocol with format(content:as:) method returning formatted String

**Acceptance Criteria**
- Protocol defines format(content:as: OutputFormat) -> String
- OutputFormat enum already exists

**Dependencies**
_None_
### ✅ Implement plain text formatter (0.25)

Strip all formatting, return raw text content

**Acceptance Criteria**
- Removes markdown syntax
- Removes HTML tags
- Returns clean plain text

**Dependencies**
_None_
### ✅ Implement markdown formatter (0.5)

Convert content to markdown with proper formatting preservation

**Acceptance Criteria**
- Preserves existing markdown
- Auto-formats code blocks with language detection
- Formats URLs as markdown links

**Dependencies**
_None_
### ✅ Implement code formatter with syntax detection (0.5)

Detect programming language and format as markdown code block

**Acceptance Criteria**
- Detects language from file extension or shebang
- Wraps in language code blocks
- Supports common languages (Swift, Python, JS, etc.)

**Dependencies**
- Implement markdown formatter
### ✅ Create Formatter service implementation (0.25)

Combine all formatters implementing Formatting protocol

**Acceptance Criteria**
- Implements Formatting protocol
- Routes to appropriate formatter based on OutputFormat
- Handles transformationFailed error

**Dependencies**
- Implement code formatter with syntax detection
- Create Formatting protocol

## State Management & Combine Pipeline
**Goal:** Build centralized state with Combine publishers for reactive updates across the app

### ✅ Create ClipboardStore ObservableObject (0.5)

Central state class with @Published clips and projects properties

**Acceptance Criteria**
- ObservableObject with @Published var clips: [ClipboardItem]
- @Published var projects: [Project]
- @Published var filteredClips: [ClipboardItem]

**Dependencies**
_None_
### ✅ Implement clipboard pipeline (1)

Combine pipeline: ClipboardMonitor -> persistence -> categorization -> search index -> state update

**Acceptance Criteria**
- ClipboardMonitor changes trigger save
- Categorization runs after save
- Search index updated after categorization
- State update triggers UI refresh

**Dependencies**
- Create ClipboardStore ObservableObject
### ✅ Add search results publisher (0.5)

Combine publisher for search results with debouncing and error handling

**Acceptance Criteria**
- Search query publisher with debounce
- Publishes [ClipMatch] results
- Never failure type, errors logged

**Dependencies**
- Create ClipboardStore ObservableObject
### ✅ Implement caching layer (0.5)

Cache frequently accessed clips and projects in memory

**Acceptance Criteria**
- LRU cache for clip previews
- Weak references for images
- Cache cleared on memory pressure

**Dependencies**
- Create ClipboardStore ObservableObject

## Validation & Error Handling
**Goal:** Implement input validation, rate limiting, and error handling throughout the app

### ✅ Add input validation utilities (0.5)

Validate clip content size, title length, UTF-8 encoding, control character stripping

**Acceptance Criteria**
- Content max 10MB validation
- Title max 256 chars validation
- UTF-8 validation
- Control character stripping function

**Dependencies**
_None_
### ✅ Implement rate limiting (0.5)

Rate limit clipboard captures to 100 per minute

**Acceptance Criteria**
- Token bucket or similar rate limiter
- Max 100 clips per minute
- Graceful handling of rate limit exceeded

**Dependencies**
_None_
### ✅ Create error presentation system (0.5)

Build alert system for non-blocking error notifications to user

**Acceptance Criteria**
- Non-blocking alerts for non-fatal errors
- Alert dialogs with recovery for critical errors
- Error logging via OSLog

**Dependencies**
_None_
### ✅ Add retry logic for clipboard operations (0.5)

Implement exponential backoff retry for failed clipboard writes

**Acceptance Criteria**
- Single retry on failure
- Exponential backoff (100ms, 200ms, 400ms)
- Max 3 retry attempts

**Dependencies**
_None_

## Observability & Performance
**Goal:** Add logging, metrics, and performance optimizations

### ✅ Add Instruments signposts (0.5)

Add signposts for clipboard poll, search, database operations

**Acceptance Criteria**
- Signposts for clipboard poll interval
- Signposts for search latency
- Signposts for database queries
- Visible in Instruments Time Profiler

**Dependencies**
_None_
### ✅ Implement performance metrics tracking (0.5)

Track and log key metrics: poll interval, search latency, query time, memory, clip count

**Acceptance Criteria**
- Metrics logged for clipboard poll (ms)
- Search latency tracked (ms)
- Database query time (ms)
- Memory usage (MB)
- Active clips count

**Dependencies**
_None_
### ✅ Optimize clip list rendering (1)

Optimize for 10k clips with 200ms search target

**Acceptance Criteria**
- Lazy loading implemented
- Pagination by 50 items
- Search under 200ms with 10k clips
- Memory usage under 200MB

**Dependencies**
- Add Instruments signposts
### ✅ Defer non-critical services (0.5)

Defer categorization and indexing until after UI renders

**Acceptance Criteria**
- UI renders immediately on launch
- Categorization starts after first idle
- Indexing queued for background processing

**Dependencies**
- Optimize clip list rendering

## Testing
**Goal:** Write unit, integration, and E2E tests for core functionality

### ✅ Set up testing infrastructure (0.5)

Configure test target, add testing dependencies (XCTest), set up test doubles

**Acceptance Criteria**
- Test target configured in Xcode
- Test doubles for NSPasteboard, SwiftData
- Test utilities for common setup

**Dependencies**
_None_
### ✅ Write ClipboardMonitor unit tests (1)

Test change detection, duplicate filtering, metadata extraction with mocked NSPasteboard

**Acceptance Criteria**
- Tests for change detection
- Tests for duplicate filtering
- Tests for metadata extraction
- Tests for error cases

**Dependencies**
- Set up testing infrastructure
### ✅ Write SemanticSearchEngine unit tests (1)

Test embedding generation, similarity scoring, ranking with mocked embeddings

**Acceptance Criteria**
- Tests for embedding generation
- Tests for cosine similarity
- Tests for result ranking
- Tests for error cases

**Dependencies**
- Set up testing infrastructure
### ✅ Write Categorizer unit tests (1)

Test content type detection, tag suggestion

**Acceptance Criteria**
- Tests for content type detection (code, URL, text)
- Tests for tag extraction
- Tests for edge cases

**Dependencies**
- Set up testing infrastructure
### ✅ Write PersistenceLayer tests (1)

Test CRUD operations with in-memory SwiftData container

**Acceptance Criteria**
- Tests for create, read, update, delete
- Tests for query with predicates
- Tests for relationship handling

**Dependencies**
- Set up testing infrastructure
### ✅ Write integration tests (1.5)

Test clipboard to persistence flow, search with real embeddings, UI state updates

**Acceptance Criteria**
- Clipboard change persists to database
- Search returns expected results
- UI updates on state changes

**Dependencies**
- Write ClipboardMonitor unit tests
- Write SemanticSearchEngine unit tests
### ✅ Write E2E UI tests (1.5)

Test user flows: copy text, search, create project, insert clip

**Acceptance Criteria**
- Copy text appears in clip list
- Search returns matching clips
- Project creation and assignment works
- Keyboard shortcut inserts clip

**Dependencies**
- Write integration tests
### ✅ Performance test with 10k clips (1)

Load test with 10,000 clips, verify search under 200ms

**Acceptance Criteria**
- 10k clips loaded without crash
- Search completes under 200ms
- Memory usage acceptable

**Dependencies**
- Write integration tests

## Preferences & Settings
**Goal:** Build settings UI and persistence for user preferences

### ✅ Create Settings model (0.5)

Define user settings: max clips, keyboard shortcuts, theme, duplicate handling

**Acceptance Criteria**
- @AppStorage or UserDefaults wrapper
- Settings include: maxClips, keyboardShortcut, allowDuplicates, theme

**Dependencies**
_None_
### ✅ Build settings UI (1)

Create SwiftUI settings view with sections for general, shortcuts, appearance

**Acceptance Criteria**
- General section: max clips, allow duplicates
- Shortcuts section: editable hotkey
- Appearance section: theme preference

**Dependencies**
- Create Settings model
### ✅ Implement keyboard shortcut recorder (1)

UI component for recording custom keyboard shortcuts

**Acceptance Criteria**
- Captures key combination
- Validates against system shortcuts
- Persists to settings

**Dependencies**
- Build settings UI

## App Store Preparation
**Goal:** Prepare for TestFlight beta and Mac App Store submission

### ✅ Create app icon and assets (1)

Design app icon for all required sizes, menu bar icon variants

**Acceptance Criteria**
- App icon in all required sizes
- Menu bar icon (normal and selected states)
- Assets catalog organized

**Dependencies**
_None_
### ✅ Write App Store description and screenshots (1)

Create promotional text, description, keywords, and App Store screenshots

**Acceptance Criteria**
- App Store description (promotional text, full description)
- Keywords for search optimization
- 5-6 screenshots showcasing features

**Dependencies**
_None_
### ✅ Configure App Store Connect metadata (0.5)

Set up app in App Store Connect with pricing, territories, age rating

**Acceptance Criteria**
- App created in App Store Connect
- Pricing set (free or paid)
- Territories configured
- Age rating completed

**Dependencies**
_None_
### ✅ Create privacy policy and EULA (0.5)

Write privacy policy and end user license agreement

**Acceptance Criteria**
- Privacy policy explaining local-only data
- EULA for app usage terms
- Hosted or ready for App Store submission

**Dependencies**
_None_
### ✅ Configure TestFlight beta (0.5)

Set up TestFlight with beta tester groups and release notes

**Acceptance Criteria**
- TestFlight configured in App Store Connect
- Beta groups created
- Beta release notes drafted

**Dependencies**
- Configure App Store Connect metadata

## ❓ Open Questions
- Should max clip storage be capped at 100,000 items or unlimited with user warning?
- Confirm macOS 14+ minimum version - ARD states Sonoma, verify no macOS 13 support needed
- How to handle large file copies from Finder - store reference, thumbnail, or skip entirely?
- Confirm keyboard shortcut default - Cmd+Shift+V proposed, is this configurable enough?
- Should deleted clips go to trash (soft delete) or permanent delete immediately?