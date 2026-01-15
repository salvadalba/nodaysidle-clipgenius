import Foundation
import Combine
import AppKit
import CryptoKit

/// Default implementation of clipboard monitoring using NSPasteboard polling
final class ClipboardMonitor: ClipboardMonitoring {
    // MARK: - Properties
    
    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastHash: String = ""
    private let subject = PassthroughSubject<ClipboardItem, Never>()
    private let pollingInterval: TimeInterval
    private let allowDuplicates: Bool
    
    // MARK: - ClipboardMonitoring
    
    var clipboardChanges: AnyPublisher<ClipboardItem, Never> {
        subject.eraseToAnyPublisher()
    }
    
    private(set) var isMonitoring: Bool = false
    
    // MARK: - Initialization
    
    init(
        pollingInterval: TimeInterval = 0.5,
        allowDuplicates: Bool = false
    ) {
        self.pollingInterval = pollingInterval
        self.allowDuplicates = allowDuplicates
        self.lastChangeCount = pasteboard.changeCount
    }
    
    // MARK: - Public Methods
    
    func start() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount
        
        // Start polling timer on main thread
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(
                withTimeInterval: self?.pollingInterval ?? 0.5,
                repeats: true
            ) { [weak self] _ in
                self?.checkForChanges()
            }
        }
        
        ClipGeniusLogger.info("Clipboard monitoring started", category: .clipboardMonitor)
    }
    
    func stop() {
        guard isMonitoring else { return }
        
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        
        ClipGeniusLogger.info("Clipboard monitoring stopped", category: .clipboardMonitor)
    }
    
    // MARK: - Private Methods
    
    private func checkForChanges() {
        guard isMonitoring else { return }
        
        let currentChangeCount = pasteboard.changeCount
        
        // Check if pasteboard has changed
        guard currentChangeCount != lastChangeCount else {
            return
        }
        
        lastChangeCount = currentChangeCount
        
        // Extract clipboard content
        guard let content = extractContent() else {
            return
        }
        
        // Compute hash for duplicate detection
        let hash = computeHash(content: content)
        
        // Check for duplicates unless allowed
        if !allowDuplicates && hash == lastHash {
            ClipGeniusLogger.debug("Duplicate clipboard item detected, skipping", category: .clipboardMonitor)
            return
        }
        
        lastHash = hash
        
        // Create clipboard item
        let item = createClipboardItem(content: content, hash: hash)
        subject.send(item)
        
        ClipGeniusLogger.debug("Clipboard item detected: \(item.title.prefix(50))", category: .clipboardMonitor)
    }
    
    private func extractContent() -> String? {
        // Try to get string content
        if let string = pasteboard.string(forType: .string) {
            // Validate content size
            guard string.utf8.count <= ClipboardItem.maxContentSize else {
                ClipGeniusLogger.error("Clipboard content exceeds maximum size", category: .clipboardMonitor)
                return nil
            }
            return string
        }
        
        // Try to get URL content
        if let url = pasteboard.string(forType: .URL) {
            return url
        }
        
        // Try to get file URL
        if let fileURL = pasteboard.string(forType: .fileURL) {
            return fileURL
        }
        
        ClipGeniusLogger.debug("No supported content type on pasteboard", category: .clipboardMonitor)
        return nil
    }
    
    private func createClipboardItem(content: String, hash: String) -> ClipboardItem {
        // Generate title from content preview
        let title = generateTitle(from: content)
        
        // Detect source application
        let sourceApp = detectSourceApp()
        
        // Detect content category
        let category = detectCategory(content: content)
        
        // Create clipboard item
        let item = ClipboardItem(
            title: title,
            content: content,
            sourceApp: sourceApp,
            category: category
        )
        
        return item
    }
    
    private func generateTitle(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // For URLs, use the URL itself
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return String(trimmed.prefix(ClipboardItem.maxTitleLength))
        }
        
        // For content with line breaks, use first line
        if let newlineIndex = trimmed.firstIndex(of: "\n") {
            let firstLine = String(trimmed[..<newlineIndex]).trimmingCharacters(in: .whitespaces)
            return String(firstLine.prefix(ClipboardItem.maxTitleLength))
        }
        
        // Otherwise use preview
        return String(trimmed.prefix(ClipboardItem.maxTitleLength))
    }
    
    private func detectSourceApp() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
    
    private func detectCategory(content: String) -> ClipCategory {
        // Check for URL
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return .url
        }
        
        // Check for file URL
        if content.hasPrefix("file://") {
            return .file
        }
        
        // Check for code-like patterns (indentation, brackets, etc.)
        let codeIndicators = ["func ", "var ", "let ", "const ", "function", "def ", "class ", "import ", "struct ", "enum "]
        let hasCodeIndicators = codeIndicators.contains { content.contains($0) }
        
        // Check for multi-line with indentation
        let lines = content.components(separatedBy: "\n")
        let hasIndentation = lines.dropFirst().contains { $0.hasPrefix("    ") || $0.hasPrefix("\t") }
        
        if hasCodeIndicators || hasIndentation {
            return .code
        }
        
        // Default to text
        return .text
    }
    
    private func computeHash(content: String) -> String {
        guard let data = content.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    deinit {
        stop()
    }
}
