import Foundation
import NaturalLanguage
import SwiftData
import Accelerate

/// On-device semantic search using NaturalLanguage embeddings
final class SemanticSearchEngine: SemanticSearchable {
    // MARK: - Properties
    
    private let embeddingModel: NLEmbedding?
    private var index: [UUID: [Double]] = [:]
    private var indexedItems: [UUID: ClipboardItem] = [:]
    private let embeddingDimension = 512 // NLEmbedding dimension for sentence embeddings
    private let queue = DispatchQueue(label: "com.clipgenius.search", qos: .userInitiated)
    
    // MARK: - SemanticSearchable
    
    var isIndexReady: Bool { !index.isEmpty }
    
    var indexedCount: Int { index.count }
    
    // MARK: - Initialization
    
    init() {
        // Load the sentence embedding model
        // Available in macOS 14+: NLEmbedding.sentenceEmbedding(for: .english)
        if #available(macOS 14.0, *) {
            self.embeddingModel = NLEmbedding.sentenceEmbedding(for: .english)
        } else {
            self.embeddingModel = nil
        }
        
        if embeddingModel == nil {
            ClipGeniusLogger.error("Failed to load sentence embedding model", category: .search)
        } else {
            ClipGeniusLogger.info("Sentence embedding model loaded successfully", category: .search)
        }
    }
    
    // MARK: - Public Methods
    
    func search(query: String, limit: Int = 20) -> [ClipMatch] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        guard isIndexReady else {
            ClipGeniusLogger.debug("Search index not ready", category: .search)
            return []
        }
        
        guard let model = embeddingModel else {
            ClipGeniusLogger.error("Embedding model not available", category: .search)
            return []
        }
        
        // Generate query embedding
        guard let queryEmbedding = generateEmbedding(for: query, using: model) else {
            ClipGeniusLogger.error("Failed to generate query embedding", category: .search)
            return []
        }
        
        // Compute similarity scores
        var results: [(item: ClipboardItem, score: Double)] = []
        
        for (id, embedding) in index {
            guard let item = indexedItems[id] else { continue }
            
            let score = cosineSimilarity(queryEmbedding, embedding)
            results.append((item: item, score: score))
        }
        
        // Sort by score (descending)
        results.sort { $0.score > $1.score }
        
        // Take top results
        let topResults = Array(results.prefix(limit))
        
        // Generate highlights for each result
        let matches = topResults.map { tuple in
            ClipMatch(
                clip: tuple.item,
                score: tuple.score,
                highlights: generateHighlights(for: query, in: tuple.item.content)
            )
        }
        
        ClipGeniusLogger.debug("Search '\(query)' returned \(matches.count) results", category: .search)
        
        return matches
    }
    
    func indexItem(_ item: ClipboardItem) {
        guard let model = embeddingModel else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Generate embedding for the item's content
            if let embedding = self.generateEmbedding(for: item.content, using: model) {
                self.index[item.id] = embedding
                self.indexedItems[item.id] = item
                
                ClipGeniusLogger.debug("Indexed item: \(item.title.prefix(30))", category: .search)
            }
        }
    }
    
    func indexItems(_ items: [ClipboardItem]) {
        guard let model = embeddingModel else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            for item in items {
                if let embedding = self.generateEmbedding(for: item.content, using: model) {
                    self.index[item.id] = embedding
                    self.indexedItems[item.id] = item
                }
            }
            
            ClipGeniusLogger.info("Batch indexed \(items.count) items", category: .search)
        }
    }
    
    func removeItem(_ itemId: UUID) {
        queue.async { [weak self] in
            self?.index.removeValue(forKey: itemId)
            self?.indexedItems.removeValue(forKey: itemId)
        }
    }
    
    // MARK: - Private Methods
    
    private func generateEmbedding(for text: String, using model: NLEmbedding) -> [Double]? {
        // Prepare the text
        let trimmedText = String(text.prefix(10000)) // Limit to 10k chars for performance

        // Generate embedding using NL framework
        guard let embedding = model.vector(for: trimmedText) else {
            return nil
        }

        // Convert from [Float] to [Double]
        return embedding.map { Double($0) }
    }
    
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }
        
        var dotProduct = 0.0
        var normA = 0.0
        var normB = 0.0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 0 else { return 0 }
        
        return dotProduct / denominator
    }
    
    private func generateHighlights(for query: String, in content: String) -> [String] {
        var highlights: [String] = []
        let queryWords = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        // Find sentences containing query words
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count > 10 else { continue }

            let sentenceLower = trimmed.lowercased()

            // Check if any query word appears in this sentence
            if queryWords.contains(where: { sentenceLower.contains($0) }) {
                // Truncate if too long
                let highlight = String(trimmed.prefix(150))
                highlights.append(highlight)

                if highlights.count >= 3 {
                    break
                }
            }
        }
        
        return highlights
    }
    
    /// Batch process embeddings during idle time
    func processBacklog(items: [ClipboardItem], batchSize: Int = 10) {
        guard !items.isEmpty else { return }
        
        let batches = stride(from: 0, to: items.count, by: batchSize).map {
            Array(items[$0..<min($0 + batchSize, items.count)])
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            for (index, batch) in batches.enumerated() {
                // Use RunLoop idle processing for non-blocking execution
                DispatchQueue.main.async {
                    autoreleasepool {
                        for item in batch {
                            self.indexItem(item)
                        }
                        
                        // Process next batch during next idle
                        if index < batches.count - 1 {
                            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
                        }
                    }
                }
            }
            
            ClipGeniusLogger.info("Processed backlog: \(items.count) items", category: .search)
        }
    }
}
