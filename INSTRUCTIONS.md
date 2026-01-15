# ClipGenius - User Instructions

## Overview

ClipGenius is an intelligent clipboard manager for macOS that helps you capture, organize, and search your clipboard history with on-device AI-powered semantic search.

---

## Installation

### Building from Source

```bash
# Clone the repository
cd /Volumes/omarchyuser/projekti/nodaysidle-clipgenius

# Build with Xcode
xcodebuild -project ClipGenius.xcodeproj -scheme ClipGenius -configuration Debug build

# Run the app
open ~/Library/Developer/Xcode/DerivedData/ClipGenius-*/Build/Products/Debug/ClipGenius.app
```

### First Launch

When you first launch ClipGenius, you'll see a clipboard icon in your menu bar (top-right of your screen). Click it to open the ClipGenius popover.

---

## Getting Started

### Menu Bar Icon

The ClipGenius menu bar icon looks like a clipboard document (`doc.on.clipboard`). Click it anytime to:

- View your clipboard history
- Search for clips
- Access settings

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Click menu bar icon | Open/close ClipGenius |
| `⌘ + ,` | Open Settings |

---

## Features

### 1. Automatic Clipboard Capture

ClipGenius automatically captures everything you copy:

- Text from any app
- Code snippets
- URLs and links
- File paths

Clips are captured immediately when you copy them to your clipboard.

### 2. Smart Categorization

Clips are automatically categorized using on-device AI:

| Category | Icon | What it captures |
|----------|------|------------------|
| **Text** | `doc.text` | Plain text, notes |
| **Code** | `chevron.left.forwardslash.chevron.right` | Code snippets, functions |
| **URL** | `link` | Web links, HTTP(S) URLs |
| **File** | `folder` | File paths, file:// URLs |
| **Image** | `photo` | Image file paths |

### 3. Working with Images

ClipGenius makes working with images seamless:

- **Capture**: Copy any image from Finder, web browser, or design tools. ClipGenius stores the image reference.
- **Preview**: Hover over an image clip in the list to see a thumbnail preview.
- **Paste**: Click the clip to copy the image back to your clipboard, ready to paste into any application.
- **Organize**: Image clips are automatically categorized as "Image" and can be added to projects like any other clip.

### 3. Semantic Search

Find clips using natural language search, not just exact matches:

- Type "database error" to find error messages about databases
- Type "authentication" to find login-related code
- The AI understands the *meaning* of your clips

### 4. Projects

Organize clips into projects:

1. Click the **Projects** tab in the sidebar
2. Click **+ New Project**
3. Enter a project name
4. Drag clips to the project to assign them

### 5. Tags

Clips are auto-tagged with:

- Source app (e.g., "VSCode", "Safari")
- Detected programming language
- Named entities (people, places, organizations)

### 6. Favorites

Mark important clips as favorites:

1. Find the clip in your list
2. Click the **star icon** (☆)
3. Access all favorites from the **Favorites** filter

---

## Interface Guide

### Main Window

```
┌─────────────────────────────────────────────┐
│  🔍 Search clips...                         │
├─────────────────────────────────────────────┤
│  Filters: [All] [Fav] [Projects] [Recent]  │
├─────────────────────────────────────────────┤
│  ┌───────────────────────────────────────┐  │
│  │ 📄 My Function                        │  │
│  │    func example() { return true }     │  │
│  │                         ⭐ 2m ago     │  │
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │ 🔗 https://example.com                │  │
│  │    Example website                    │  │
│  │                         ⭐ 5m ago     │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Clip Actions

When you hover over a clip:

- **Click** - Copy the clip to your clipboard
- **Star icon** - Toggle favorite status
- **Info icon** - View clip details (tags, source app, timestamp)

---

## Settings

Access settings by clicking the gear icon (⚙️) or pressing `⌘ + ,`

### Storage Settings

- **Maximum clips**: Choose how many clips to keep (1,000 to unlimited)
- Older clips are automatically removed when the limit is reached

### Behavior Settings

- **Auto-categorize new clips**: Enable/disable AI categorization
- **Allow duplicate clips**: Whether to store identical copies

### Search Settings

- **Semantic search**: Enable/disable AI-powered search
- **Search scope**: Search in titles, content, or both

---

## Tips & Tricks

### 1. Quick Copy Workflow

1. Copy something in any app
2. Click the ClipGenius menu bar icon
3. The clip is already at the top of your list
4. Click it to re-copy anytime later

### 2. Code Snippet Organization

1. Create a project for each codebase you work on
2. Copy useful snippets as you code
3. They'll be auto-tagged with the programming language
4. Search later with terms like "authentication handler"

### 3. Research Collection

1. Create a "Research" project
2. Copy URLs, quotes, and notes as you browse
3. Use semantic search to find related content later
4. Example: search "machine learning papers" to find all relevant clips

### 4. Temporary Holding

Use ClipGenius as an extended clipboard:

- Copy multiple items in sequence
- They're all saved automatically
- Paste them in any order later

---

## Privacy & Security

- **All data stays on your Mac** - No cloud syncing
- **On-device AI** - NaturalLanguage processing happens locally
- **Sandboxed** - App runs in macOS security sandbox
- **No network access** - Clipboard data never leaves your device

---

## Troubleshooting

### ClipGenius isn't capturing clips

1. Check that the app is running (menu bar icon visible)
2. Open Settings and verify "Allow clipboard monitoring" is enabled
3. Restart the app if needed

### Search isn't finding clips

1. Try simpler search terms
2. Check that the correct filter is selected (All vs. specific project)
3. Re-index clips from Settings > Search > Rebuild Index

### App won't launch

1. Check macOS version (requires macOS 14.0 Sonoma or later)
2. Ensure app has necessary permissions in System Settings > Privacy & Security

---

## System Requirements

- **macOS 14.0 Sonoma** or later
- **Apple Silicon** (M1/M2/M3) or **Intel** Mac
- **100 MB** disk space for database
- **Recommended**: 8 GB RAM

---

## Support

For issues or feature requests, please visit the project repository.

---

*ClipGenius v1.0.0 - Built with SwiftUI, SwiftData, and NaturalLanguage*
