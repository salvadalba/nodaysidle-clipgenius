# Architecture Requirements Document

## 🧱 System Overview
ClipGenius is a native macOS clipboard manager that runs as a background menu bar application. It monitors NSPasteboard for clipboard changes, persists items to SwiftData, and provides a quick-access search UI powered by on-device CoreML and NaturalLanguage frameworks for semantic search and intelligent categorization.

## 🏗 Architecture Style
Event-driven MVVM with a single-process architecture. The app runs as a menu bar utility with a pop-over search interface, using Combine for reactive data flow between clipboard monitoring, persistence, and UI layers.

## 🎨 Frontend Architecture
- **Framework:** SwiftUI with .ultraThinMaterial visual effects and matchedGeometryEffect for smooth transitions
- **State Management:** Combine publishers with @Published properties in ViewModels, centralized ClipboardStore as single source of truth
- **Routing:** Single-view hierarchy with search/results/detail states managed by @State and enum-based navigation
- **Build Tooling:** Xcode project with Swift Package Manager for dependencies, native macOS 14+ target deployment

## 🧠 Backend Architecture
- **Approach:** Single-process Swift application with background NSTimer-based clipboard polling, no separate services
- **API Style:** Internal Combine-based service layer with protocol-oriented abstractions, no external APIs
- **Services:**
- ClipboardMonitor: NSPasteboard polling service emitting change events
- SemanticSearch: CoreML/NaturalLanguage embedding generation and similarity scoring
- Categorizer: Auto-grouping logic using source app detection and content analysis
- Formatter: Smart format conversion based on paste destination context

## 🗄 Data Layer
- **Primary Store:** SwiftData for clipboard item persistence with automatic migration support
- **Relationships:** One-to-many from Project to Clip, many-to-many for tags/favorites via relationships
- **Migrations:** SwiftData automatic schema migration with versioned models

## ☁️ Infrastructure
- **Hosting:** Mac App Store distribution, sandboxed macOS application bundle
- **Scaling Strategy:** Single-device only, no horizontal scaling; vertical optimization via lazy loading and pagination for large clip libraries
- **CI/CD:** GitHub Actions or Xcode Cloud for automated builds, TestFlight for beta distribution

## ⚖️ Key Trade-offs
- SwiftData chosen over Core Data for simpler SwiftUI integration despite being newer technology
- 0.5s polling interval balances responsiveness vs battery life; adaptive polling could be added later
- In-app semantic search instead of Spotlight integration for richer search UX but requires separate indexing
- Menu bar only (no dock icon) reduces screen real estate but may confuse users expecting traditional app behavior
- Local-only processing prioritizes privacy but precludes cross-device sync

## 📐 Non-Functional Requirements
- Launch time under 0.5 seconds
- Search response under 200ms for 10,000+ clips
- Memory footprint under 100MB when idle
- Support for 100,000+ clipboard items
- macOS 14+ minimum version
- Accessibility: VoiceOver, keyboard navigation
- Sandbox compliance for Mac App Store
- On-device only: no network calls