import SwiftUI
import SwiftData

/// Main menu bar popover view
struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var clips: [ClipboardItem]
    @Query private var projects: [Project]
    
    @State private var searchText = ""
    @State private var selectedCategory: ClipCategory?
    @State private var showFavoritesOnly = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with search
                headerView
                
                Divider()
                
                // Main content
                contentView
            }
            .background(.ultraThinMaterial)
        }
        .onAppear {
            // Initialize services on first appear
            if appState.clipboardStore == nil {
                appState.initialize(with: modelContext)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // App title and icon
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("ClipGenius")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Settings button
                Button {
                    appState.viewState = .settings
                    openSettingsWindow()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body)
                
                TextField("Search clips...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Filter chips
            filterChipsView
        }
        .padding(16)
    }
    
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // Category filters
                ForEach(ClipCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.iconName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
                
                // Favorites toggle
                FilterChip(
                    title: "Favorites",
                    icon: "star.fill",
                    isSelected: showFavoritesOnly
                ) {
                    showFavoritesOnly.toggle()
                }
            }
        }
    }
    
    private var contentView: some View {
        Group {
            if filteredClips.isEmpty {
                emptyStateView
            } else {
                clipListView
            }
        }
    }
    
    private var filteredClips: [ClipboardItem] {
        var result = clips
        
        // Apply text search
        if !searchText.isEmpty {
            result = result.filter { clip in
                clip.title.localizedCaseInsensitiveContains(searchText) ||
                clip.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Apply favorites filter
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        
        return result
    }
    
    private var clipListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredClips) { clip in
                    ClipRowView(clip: clip)
                        .contextMenu {
                            clipContextMenu(for: clip)
                        }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        } else if clips.isEmpty {
            return "clipboard"
        } else {
            return "tray"
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results"
        } else if clips.isEmpty {
            return "No Clips Yet"
        } else {
            return "No Clips"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms"
        } else if clips.isEmpty {
            return "Copy something to get started"
        } else {
            return "Try changing the filters"
        }
    }
    
    private func clipContextMenu(for clip: ClipboardItem) -> some View {
        Group {
            Button {
                copyToClipboard(clip.content)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                toggleFavorite(clip)
            } label: {
                Label(clip.isFavorite ? "Remove Favorite" : "Add Favorite",
                      systemImage: clip.isFavorite ? "star" : "star.fill")
            }
            
            Divider()
            
            Button {
                deleteClip(clip)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func copyToClipboard(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
    
    private func toggleFavorite(_ clip: ClipboardItem) {
        if let store = appState.clipboardStore {
            _ = store.toggleFavorite(clip)
        }
    }
    
    private func deleteClip(_ clip: ClipboardItem) {
        modelContext.delete(clip)
        try? modelContext.save()
    }
    
    private func openSettingsWindow() {
        if #available(macOS 15.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}

/// Filter chip component
struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .secondary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
