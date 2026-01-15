import Foundation
import NaturalLanguage
import SwiftData
import Accelerate

/// Auto-categorization using NaturalLanguage framework
final class Categorizer: Categorizing {
    // MARK: - Properties
    
    private let tagger: NLTagger
    private let embeddingModel: NLEmbedding?
    
    // MARK: - Initialization
    
    init() {
        // Initialize tagger for keyword extraction
        self.tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        
        // Load embedding model for similarity-based project suggestion
        if #available(macOS 14.0, *) {
            self.embeddingModel = NLEmbedding.sentenceEmbedding(for: .english)
        } else {
            self.embeddingModel = nil
        }
    }
    
    // MARK: - Categorizing
    
    func categorize(_ item: ClipboardItem) -> CategorizationResult {
        // Detect category
        let category = detectCategory(content: item.content)
        
        // Suggest tags
        let tags = suggestTags(for: item)
        
        // Confidence based on content length and pattern detection
        let confidence = calculateConfidence(for: item, category: category)
        
        return CategorizationResult(
            suggestedProject: nil, // Will be set by suggestProject separately
            tags: tags,
            category: category,
            confidence: confidence
        )
    }
    
    func suggestTags(for item: ClipboardItem) -> [String] {
        let content = item.content
        var tags: Set<String> = []
        
        tagger.string = content
        
        // Extract named entities (names, organizations, places)
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(
            in: content.startIndex..<content.endIndex,
            unit: .word,
            scheme: .nameType,
            options: options
        ) { tag, range in
            if let tag = tag {
                switch tag {
                case .personalName, .placeName, .organizationName:
                    let word = String(content[range]).capitalized
                    if word.count > 2 && word.count < 30 {
                        tags.insert(word)
                    }
                default:
                    break
                }
            }
            return true
        }
        
        // Extract nouns using lexical class
        tagger.enumerateTags(
            in: content.startIndex..<content.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, range in
            if tag == .noun {
                let word = String(content[range])
                // Filter meaningful nouns
                if word.count > 3 && word.count < 25 &&
                   word.range(of: "^[a-zA-Z]+$", options: .regularExpression) != nil {
                    tags.insert(word.lowercased())
                }
            }
            return true
        }
        
        // Add category-based tags
        let category = detectCategory(content: content)
        switch category {
        case .code:
            // Extract programming language
            if let language = detectLanguage(content: content) {
                tags.insert(language)
            }
        case .url:
            tags.insert("link")
        case .file:
            tags.insert("file")
        default:
            break
        }
        
        // Add source app tag if available
        if let sourceApp = item.sourceApp {
            let appName = sourceApp.components(separatedBy: ".").last?.capitalized ?? sourceApp
            tags.insert(appName)
        }
        
        // Limit tags to top 5
        let sortedTags = Array(tags).sorted().prefix(5)
        return Array(sortedTags)
    }
    
    func detectCategory(content: String) -> ClipCategory {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for URL
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") ||
           trimmed.hasPrefix("www.") || trimmed.hasPrefix("ftp://") {
            return .url
        }
        
        // Check for file URL
        if trimmed.hasPrefix("file://") || trimmed.hasPrefix("/Volumes/") ||
           trimmed.hasPrefix("/Users/") || trimmed.hasPrefix("/private/") {
            return .file
        }
        
        // Check for image paths
        if trimmed.hasSuffix(".png") || trimmed.hasSuffix(".jpg") ||
           trimmed.hasSuffix(".jpeg") || trimmed.hasSuffix(".gif") ||
           trimmed.hasSuffix(".webp") || trimmed.hasSuffix(".svg") {
            return .image
        }
        
        // Check for code patterns
        let codePatterns = [
            // Programming keywords
            "\\bfunc\\s+", "\\bdef\\s+", "\\bclass\\s+", "\\bimport\\s+",
            "\\bvar\\s+", "\\blet\\s+", "\\bconst\\s+", "\\bfunction\\s+",
            "\\bstruct\\s+", "\\benum\\s+", "\\binterface\\s+",
            "\\bif\\s*\\(", "\\bfor\\s*\\(", "\\bwhile\\s*\\(",
            // Common file extensions
            "\\.swift$", "\\.py$", "\\.js$", "\\.ts$", "\\.jsx$",
            "\\.tsx$", "\\.java$", "\\.kt$", "\\.rs$", "\\.go$",
            "\\.rb$", "\\.php$", "\\.cs$", "\\.cpp$", "\\.c$",
            "\\.h$", "\\.m$", "\\.mm$", "\\.sh$", "\\.sql$",
            // Code-like patterns
            "^\\s*([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(",
            "\\s*=>\\s*", "\\s*->\\s*", "\\{\\s*$", "^\\s*\\}\\s*$"
        ]
        
        let codePatternCount = codePatterns.filter { pattern in
            content.range(of: pattern, options: .regularExpression) != nil
        }.count
        
        // Check for indentation (common in code)
        let lines = trimmed.components(separatedBy: "\n")
        let hasSignificantIndentation = lines.dropFirst().filter { line in
            line.hasPrefix("    ") || line.hasPrefix("\t") ||
            line.hasPrefix("  ") && line.count > 10
        }.count > 2
        
        // Check for brackets (common in code)
        let hasBrackets = content.contains("{") && content.contains("}") ||
                         content.contains("(") && content.contains(")")
        
        if codePatternCount >= 2 || hasSignificantIndentation || (hasBrackets && codePatternCount >= 1) {
            return .code
        }
        
        // Check if very short (likely just a word or phrase)
        if trimmed.count < 50 && !trimmed.contains("\n") {
            return .text
        }
        
        // Default to text
        return .text
    }
    
    func suggestProject(
        for item: ClipboardItem,
        from existingProjects: [Project]
    ) -> Project? {
        guard let model = embeddingModel, !existingProjects.isEmpty else {
            return nil
        }

        // Generate embedding for the new item
        let trimmedText = String(item.content.prefix(5000))

        guard let itemEmbedding = model.vector(for: trimmedText) else {
            return nil
        }

        let itemEmbeddingDouble = itemEmbedding.map { Double($0) }

        // Find project with most similar content
        var bestMatch: (project: Project, score: Double)?

        for project in existingProjects {
            guard let clips = project.clips, !clips.isEmpty else { continue }

            // Get embedding from first clip with embedding
            var projectScore = 0.0
            var clipCount = 0

            for clip in clips {
                // Use content to compute similarity
                let clipText = String(clip.content.prefix(5000))

                if let clipEmbedding = model.vector(for: clipText) {
                    let clipEmbeddingDouble = clipEmbedding.map { Double($0) }
                    let similarity = cosineSimilarity(itemEmbeddingDouble, clipEmbeddingDouble)
                    projectScore += similarity
                    clipCount += 1
                }
            }

            if clipCount > 0 {
                let avgScore = projectScore / Double(clipCount)
                if avgScore > 0.7 { // Threshold for suggesting existing project
                    if bestMatch == nil || avgScore > bestMatch!.score {
                        bestMatch = (project, avgScore)
                    }
                }
            }
        }

        return bestMatch?.project
    }
    
    // MARK: - Private Methods
    
    private func calculateConfidence(for item: ClipboardItem, category: ClipCategory) -> Double {
        var confidence = 0.5 // Base confidence
        
        // Higher confidence for longer content
        if item.content.count > 100 {
            confidence += 0.1
        }
        
        // Higher confidence for clear categories
        switch category {
        case .url, .file:
            confidence += 0.3
        case .code:
            confidence += 0.2
        case .image:
            confidence += 0.2
        default:
            break
        }
        
        // Higher confidence with source app info
        if item.sourceApp != nil {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    private func detectLanguage(content: String) -> String? {
        let patterns: [(String, String)] = [
            // Swift
            ("import SwiftUI|import Foundation|import UIKit|@State|@Published", "Swift"),
            // Python
            ("import pandas|from django|def \\w+\\(|print\\(|if __name__", "Python"),
            // JavaScript
            ("const \\w+ = |let \\w+ = |console\\.log|require\\(|import \\w+ from", "JavaScript"),
            // TypeScript
            ("interface \\w+|type \\w+ = |: string|: number|: boolean", "TypeScript"),
            // Java
            ("public class|public static void|System\\.out|import java\\.", "Java"),
            // Kotlin
            ("fun \\w+\\(|val \\w+|var \\w+|import kotlinx\\.", "Kotlin"),
            // Rust
            ("fn \\w+\\(|let mut|use \\w+;|impl \\w+", "Rust"),
            // Go
            ("func \\w+\\(|package \\w+|import \\(|go \\w+\\(", "Go"),
            // Ruby
            ("def \\w+\\(|require '|include |puts ", "Ruby"),
            // PHP
            ("\\$\\w+ = |function \\w+\\(|use \\w+;", "PHP"),
            // SQL
            ("SELECT \\* FROM|INSERT INTO|UPDATE \\w+ SET|DELETE FROM", "SQL"),
            // Shell
            ("#!/bin/bash|if \\[.*\\]; then|echo \\$", "Shell"),
            // C/C++
            ("#include <stdio.h>|int main\\(|std::|cout <<", "C/C++"),
            // HTML
            ("<!DOCTYPE html>|<div |<span |class=\"", "HTML"),
            // CSS
            ("\\.\\w+\\s*\\{|#\\w+\\s*\\{|@media", "CSS"),
            // JSON
            ("^\\s*\\{.*\"\\w+\"\\s*:", "JSON"),
            // YAML
            ("^\\w+:\\s*$", "YAML")
        ]
        
        for (pattern, language) in patterns {
            if content.range(of: pattern, options: .regularExpression) != nil {
                return language
            }
        }
        
        return nil
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
}
