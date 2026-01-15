import SwiftUI

/// Settings and preferences view
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("maxClips") private var maxClips: Int = 10000
    @AppStorage("allowDuplicates") private var allowDuplicates: Bool = false
    @AppStorage("pollingInterval") private var pollingInterval: Double = 0.5
    @AppStorage("enableSemanticSearch") private var enableSemanticSearch: Bool = true
    @AppStorage("autoCategorize") private var autoCategorize: Bool = true
    
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case clipboard = "Clipboard"
        case search = "Search"
        case about = "About"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            generalSettings
            clipboardSettings
            searchSettings
            aboutSettings
        }
        .frame(width: 500, height: 350)
    }
    
    private var generalSettings: some View {
        Form {
            Section("Storage") {
                HStack {
                    Text("Maximum clips")
                    Spacer()
                    Picker("", selection: $maxClips) {
                        Text("1,000").tag(1000)
                        Text("5,000").tag(5000)
                        Text("10,000").tag(10000)
                        Text("50,000").tag(50000)
                        Text("Unlimited").tag(Int.max)
                    }
                    .frame(width: 120)
                }
                
                Text("Older clips will be automatically removed when the limit is reached.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Behavior") {
                Toggle("Auto-categorize new clips", isOn: $autoCategorize)
                Toggle("Allow duplicate clips", isOn: $allowDuplicates)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(SettingsTab.general.rawValue)
        .tag(SettingsTab.general)
    }
    
    private var clipboardSettings: some View {
        Form {
            Section("Monitoring") {
                HStack {
                    Text("Polling interval")
                    Spacer()
                    Picker("", selection: $pollingInterval) {
                        Text("0.1s (Fast)").tag(0.1)
                        Text("0.25s").tag(0.25)
                        Text("0.5s (Default)").tag(0.5)
                        Text("1.0s").tag(1.0)
                        Text("2.0s (Slow)").tag(2.0)
                    }
                    .frame(width: 140)
                    .onChange(of: pollingInterval) { _, newValue in
                        restartMonitoring(with: newValue)
                    }
                }
                
                Text("More frequent polling uses more battery. 0.5s is recommended for most users.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Keyboard Shortcut") {
                HStack {
                    Text("Quick insert")
                    Spacer()
                    Text("⌘⇧V")
                        .foregroundStyle(.secondary)
                    Button("Customize") {
                        // TODO: Implement custom shortcut recorder
                    }
                    .disabled(true)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(SettingsTab.clipboard.rawValue)
        .tag(SettingsTab.clipboard)
    }
    
    private var searchSettings: some View {
        Form {
            Section("Semantic Search") {
                Toggle("Enable semantic search", isOn: $enableSemanticSearch)
                
                if enableSemanticSearch {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Semantic search uses on-device AI to find clips based on meaning rather than exact text matches.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let engine = appState.semanticSearch {
                            HStack {
                                Text("Indexed clips")
                                Spacer()
                                Text("\(engine.indexedCount)")
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Text("Index status")
                                Spacer()
                                Text(engine.isIndexReady ? "Ready" : "Building...")
                                    .foregroundStyle(engine.isIndexReady ? .green : .orange)
                            }
                            
                            if !engine.isIndexReady {
                                Button("Rebuild Index") {
                                    // TODO: Implement index rebuild
                                }
                            }
                        }
                    }
                }
            }
            
            Section("Privacy") {
                Text("All search indexing is performed locally on your device. No data is sent to external servers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(SettingsTab.search.rawValue)
        .tag(SettingsTab.search)
    }
    
    private var aboutSettings: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("ClipGenius")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Text("Intelligent clipboard manager with on-device AI")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/nodaysidle/clipgenius")!) {
                    Label("GitHub Repository", systemImage: "link")
                }
                
                Link(destination: URL(string: "https://nodaysidle.com")!) {
                    Label("Website", systemImage: "globe")
                }
                
                Button {
                    NSWorkspace.shared.open(URL(string: "mailto:hello@nodaysidle.com")!)
                } label: {
                    Label("Contact Support", systemImage: "envelope")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(SettingsTab.about.rawValue)
        .tag(SettingsTab.about)
    }
    
    private func restartMonitoring(with interval: TimeInterval) {
        // Stop current monitor and restart with new interval
        if let monitor = appState.clipboardMonitor {
            monitor.stop()
            
            // Create new monitor with updated interval
            let newMonitor = ClipboardMonitor(pollingInterval: interval)
            appState.clipboardMonitor = newMonitor
            newMonitor.start()
            
            ClipGeniusLogger.info("Restarted clipboard monitoring with interval: \(interval)s", category: .clipboardMonitor)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .frame(width: 500, height: 350)
}
