# Agent Prompts — ClipGenius

## 🧭 Global Rules

### ✅ Do
- Use SwiftUI for all UI views with .ultraThinMaterial background
- Use Combine publishers for reactive state management
- Use SwiftData for all persistence with @Model classes
- Use NaturalLanguage and CoreML for on-device AI features
- Keep all data local - no network calls whatsoever

### ❌ Don’t
- Do not add external dependencies - use Apple frameworks only
- Do not create a backend server or API
- Do not use CoreData - SwiftData only
- Do not cross-platform - macOS-only using AppKit bridges
- Do not add authentication or cloud sync

## 🧩 Task Prompts
## Xcode Project & SwiftData Models

**Context**
Initialize macOS menu bar app targeting macOS 14+. Create SwiftUI project with LSUIElement=1 for menu bar. Define SwiftData models for clips, projects, and tags.

### Universal Agent Prompt
```
ROLE: Expert macOS SwiftUI Engineer

GOAL: Scaffold Xcode project with SwiftData models for clipboard items, projects, and tags

CONTEXT: Initialize macOS menu bar app targeting macOS 14+. Create SwiftUI project with LSUIElement=1 for menu bar. Define SwiftData models for clips, projects, and tags.

FILES TO CREATE:
- ClipGenius/ClipGeniusApp.swift
- ClipGenius/Models/ClipboardItem.swift
- ClipGenius/Models/Project.swift
- ClipGenius/Models/Tag.swift
- ClipGenius/Models/ClipCategory.swift
- ClipGenius/Utils/Logger.swift

FILES TO MODIFY:
_None_

DETAILED STEPS:
1. Create Xcode project with macOS App target, bundle ID com.clipgenius.app, set LSUIElement=1 in Info.plist
2. Create @Model final class ClipboardItem with UUID id, String title (max 256), String content (max 10MB), Date timestamp, String? sourceApp, [Double]? embedding, Bool isFavorite, @Relationship var project: Project?, @Relationship var tags: [Tag]
3. Create @Model final class Project with UUID id, String name, Color? color, @Relationship var clips: [ClipboardItem]
4. Create @Model final class Tag with UUID id, String name, @Relationship var clips: [ClipboardItem]
5. Configure ModelContainer in App entry point with automatic migration, create Logger utility using OSLog with subsystem com.clipgenius.app

VALIDATION:
xcodebuild -scheme ClipGenius -destination 'platform=macOS' build
```