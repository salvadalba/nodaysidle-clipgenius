# ClipGenius

An intelligent macOS clipboard manager that leverages on-device AI to automatically organize, search, and reuse clipboard content with contextual awareness and seamless workflow integration.

> **[📖 Usage Instructions](INSTRUCTIONS.md)** - See the full user guide for how to use ClipGenius.

## Features

- **Unlimited clipboard history** with persistent SwiftData storage
- **Semantic search** using NaturalLanguage framework for understanding content
- **Auto-categorization** by project context using content analysis
- **Quick insert** with customizable keyboard shortcuts (⌘⇧V)
- **Privacy-focused** - all processing is local, no network calls
- **Native macOS UI** with .ultraThinMaterial effects

## Requirements

- macOS 14.0 Sonoma or later
- Xcode 15.0 or later
- Swift 5.9+

## Building from Source

### Manual Setup with Xcode

1. Open Xcode and create a new macOS App project:
   - Product Name: `ClipGenius`
   - Bundle Identifier: `com.clipgenius.app`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: macOS 14.0

2. Configure project settings:
   - Set `LSUIElement = true` in Info.plist (menu bar only)
   - Add entitlements file with App Sandbox enabled
   - Add "Automation" entitlement for Apple Events (source app detection)

3. Add all source files from this repository:
   ```
   ClipGenius/
   ├── Models/
   │   ├── ClipboardItem.swift
   │   ├── ClipboardItem+Extensions.swift
   │   ├── Project.swift
   │   ├── Tag.swift
   │   ├── ClipCategory.swift
   │   ├── OutputFormat.swift
   │   └── ClipMatch.swift
   ├── Views/
   │   ├── MenuBarView.swift
   │   ├── ClipRowView.swift
   │   ├── ClipDetailView.swift
   │   ├── ProjectListView.swift
   │   └── SettingsView.swift
   ├── ViewModels/
   │   └── ClipboardViewModel.swift
   ├── Services/
   │   ├── ClipboardMonitoring.swift
   │   ├── ClipboardMonitor.swift
   │   ├── SemanticSearchable.swift
   │   ├── SemanticSearchEngine.swift
   │   ├── Categorizing.swift
   │   ├── Categorizer.swift
   │   ├── Formatting.swift
   │   ├── Formatter.swift
   │   ├── ClipboardStore.swift
   │   └── SwiftDataPersistence.swift
   ├── Utils/
   │   └── Logger.swift
   ├── Resources/
   │   ├── Assets.xcassets
   │   ├── Info.plist
   │   └── ClipGenius.entitlements
   └── ClipGeniusApp.swift
   ```

4. Add Assets:
   - Create `Assets.xcassets` in Resources
   - Add app icon (required for menu bar)

5. Build and run (⌘R)

## Architecture

- **Event-driven MVVM** with Combine for reactive data flow
- **SwiftData** for local persistence
- **NaturalLanguage** framework for semantic search
- **CoreML** embeddings for intelligent categorization
- **AppKit bridges** for menu bar integration

## Data Model

```
ClipboardItem
├── id: UUID
├── title: String (max 256 chars)
├── content: String (max 10MB)
├── timestamp: Date
├── sourceApp: String?
├── embedding: Data?
├── isFavorite: Bool
├── category: ClipCategory
├── project: Project?
└── tags: Set<Tag>?

Project
├── id: UUID
├── name: String
├── color: Color?
├── createdAt: Date
├── updatedAt: Date
└── clips: [ClipboardItem]

Tag
├── id: UUID
├── name: String
├── createdAt: Date
└── clips: Set<ClipboardItem>
```

## License

Copyright © 2024 NoDaysIdle. All rights reserved.
