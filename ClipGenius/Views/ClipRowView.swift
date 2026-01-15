import SwiftUI
import SwiftData

/// Row view for a single clipboard item
struct ClipRowView: View {
    let clip: ClipboardItem
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var body: some View {
        Button {
            copyClip()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Category icon
                categoryIcon
                
                // Content
                contentView
                
                Spacer()

                // Actions and metadata
                trailingView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isHovering ? Color.secondary.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var categoryIcon: some View {
        Image(systemName: clip.category.iconName)
            .font(.body)
            .foregroundStyle(clip.category == .code ? .purple : .secondary)
            .frame(width: 24, height: 24)
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title
            Text(clip.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            // Preview
            Text(clip.preview(maxLength: 100))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var trailingView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Favorite indicator
            if clip.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
            
            Spacer()
            
            // Timestamp
            Text(clip.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            // Source app indicator
            if let sourceApp = clip.sourceApp {
                Text(sourceAppName(from: sourceApp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private func sourceAppName(from bundleId: String) -> String {
        bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId
    }
    
    private func copyClip() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(clip.content, forType: .string)
        
        // Provide feedback
        NSSound.beep()
    }
}

/// Detail view for a clip
struct ClipDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let clip: ClipboardItem
    
    @State private var editingTitle: String
    @State private var editingContent: String
    
    init(clip: ClipboardItem) {
        self.clip = clip
        self._editingTitle = State(initialValue: clip.title)
        self._editingContent = State(initialValue: clip.content)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clip Details")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                Section("Title") {
                    TextField("Title", text: $editingTitle)
                }
                
                Section("Content") {
                    TextEditor(text: $editingContent)
                        .frame(minHeight: 150)
                }
                
                Section("Metadata") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(clip.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let sourceApp = clip.sourceApp {
                        HStack {
                            Text("Source")
                            Spacer()
                            Text(sourceApp)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(clip.category.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Button {
                    deleteClip()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .controlSize(.large)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .controlSize(.large)
                
                Button {
                    saveChanges()
                } label: {
                    Text("Save")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
    
    private func saveChanges() {
        clip.title = editingTitle
        clip.content = editingContent
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteClip() {
        modelContext.delete(clip)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ClipboardItem.self, configurations: config)
    
    let clip = ClipboardItem(
        title: "Example Clip",
        content: "This is an example clipboard item with some content that demonstrates how clips will appear in the list view.",
        sourceApp: "com.apple.Safari",
        category: .text
    )
    
    return MenuBarView()
        .modelContainer(container)
        .environmentObject(AppState())
}
