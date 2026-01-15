import Foundation

/// Content formatting for different output formats
final class ContentFormatter: Formatting {
    
    // MARK: - Formatting
    
    func format(
        content: String,
        as format: OutputFormat,
        context: PasteContext? = nil
    ) -> String {
        switch format {
        case .plain:
            return formatAsPlainText(content)
        case .markdown:
            return formatAsMarkdown(content)
        case .richText:
            return formatAsRichText(content)
        case .code:
            return formatAsCodeBlock(content)
        }
    }
    
    func detectLanguage(content: String) -> String? {
        let patterns: [(String, String)] = [
            ("import SwiftUI|import Foundation|@State|@Published|:\\s*\\w+\\s*->", "swift"),
            ("import pandas|from django|def \\w+\\(|print\\(|if __name__", "python"),
            ("const \\w+ = |let \\w+ = |console\\.log|require\\(|import \\w+ from|\\.", "javascript"),
            ("interface \\w+|type \\w+ = |: string|: number|: boolean|enum \\w+", "typescript"),
            ("public class|public static void|System\\.out|import java\\.", "java"),
            ("package \\w+;|fun \\w+\\(|val \\w+|var \\w+", "kotlin"),
            ("fn \\w+\\(|let mut|use \\w+;|impl \\w+", "rust"),
            ("package \\w+|import \\(|func \\w+\\(|go \\w+\\(", "go"),
            ("def \\w+\\(|require '|include |puts |end$", "ruby"),
            ("\\$\\w+ = |function \\w+\\(|use \\w+;", "php"),
            ("SELECT |INSERT INTO|UPDATE |DELETE FROM|CREATE TABLE", "sql"),
            ("#!/bin/bash|if \\[|echo \\$|\\|\\|", "bash"),
            ("#include <stdio.h>|#include <stdlib.h>|int main\\(|std::", "c"),
            ("class \\w+\\s*\\{|public \\w+\\s*\\(|@Override", "java"),
            ("<!DOCTYPE html>|<html|<div |class=|<script", "html"),
            ("\\.\\w+\\s*\\{|#\\w+\\s*\\{|@media|flexbox|grid", "css"),
            ("\\{\\s*\".*\"\\s*:\\s*|true|null", "json"),
            ("^\\w+:\\s*$|\\|\\-", "yaml"),
            ("<\\?xml|<svg |xmlns=", "xml")
        ]
        
        for (pattern, language) in patterns {
            if content.range(of: pattern, options: .regularExpression) != nil {
                return language
            }
        }
        
        // Check for shebang
        let lines = content.components(separatedBy: .newlines)
        if let firstLine = lines.first, firstLine.hasPrefix("#!") {
            let shebang = firstLine.dropFirst(2)
            if shebang.contains("bash") || shebang.contains("sh") {
                return "bash"
            } else if shebang.contains("python") {
                return "python"
            } else if shebang.contains("node") {
                return "javascript"
            }
        }
        
        return nil
    }
    
    func convertMarkdown(_ markdown: String, to targetFormat: OutputFormat) -> String {
        switch targetFormat {
        case .plain:
            return formatAsPlainText(markdown)
        case .markdown:
            return markdown
        case .richText:
            return markdownToRichText(markdown)
        case .code:
            return formatAsCodeBlock(markdown)
        }
    }
    
    // MARK: - Private Methods
    
    private func formatAsPlainText(_ content: String) -> String {
        var result = content
        
        // Remove markdown syntax
        result = removeMarkdownSyntax(result)
        
        // Remove HTML tags
        result = removeHTMLTags(result)
        
        // Normalize whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatAsMarkdown(_ content: String) -> String {
        var result = content
        
        // If content looks like code, wrap in code block
        if looksLikeCode(content) {
            let language = detectLanguage(content: content) ?? ""
            return "```\(language)\n\(content)\n```"
        }
        
        // Format URLs as markdown links
        result = formatURLsAsLinks(result)
        
        // Format file references
        result = formatFileReferences(result)
        
        return result
    }
    
    private func formatAsRichText(_ content: String) -> String {
        // For macOS, we can use NSAttributedString for rich text
        // But since we're returning String, we'll return formatted text
        // The actual formatting would be handled at paste time
        return content
    }
    
    private func formatAsCodeBlock(_ content: String) -> String {
        let language = detectLanguage(content: content) ?? ""
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return "```\(language)\n\(trimmed)\n```"
    }
    
    private func removeMarkdownSyntax(_ text: String) -> String {
        var result = text
        
        // Remove bold/italic markers
        result = result.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\*(.+?)\\*", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "__(.+?)__", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "_(.+?)_", with: "$1", options: .regularExpression)
        
        // Remove strikethrough
        result = result.replacingOccurrences(of: "~~(.+?)~~", with: "$1", options: .regularExpression)
        
        // Remove code markers
        result = result.replacingOccurrences(of: "`(.+?)`", with: "$1", options: .regularExpression)
        
        // Remove code blocks
        result = result.replacingOccurrences(of: "```[\\w\\W]*?```", with: "", options: .regularExpression)
        
        // Remove headers
        result = result.replacingOccurrences(of: "^#{1,6}\\s+", with: "", options: [.regularExpression])
        
        // Remove blockquotes
        result = result.replacingOccurrences(of: "^>\\s*", with: "", options: [.regularExpression])
        
        // Remove links but keep text
        result = result.replacingOccurrences(of: "\\[(.+?)\\]\\(.+?\\)", with: "$1", options: .regularExpression)
        
        // Remove image markers
        result = result.replacingOccurrences(of: "!\\[.*?\\]\\(.+?\\)", with: "", options: .regularExpression)
        
        // Remove horizontal rules
        result = result.replacingOccurrences(of: "^[-*_]{3,}\\s*$", with: "", options: [.regularExpression])
        
        return result
    }
    
    private func removeHTMLTags(_ text: String) -> String {
        return text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
    
    private func formatURLsAsLinks(_ text: String) -> String {
        // Find URLs and convert to markdown links
        let urlPattern = "(https?://[^\\s]+)"
        let result = text.replacingOccurrences(
            of: urlPattern,
            with: "[$0]($0)",
            options: .regularExpression
        )
        return result
    }
    
    private func formatFileReferences(_ text: String) -> String {
        // Format file paths as code
        let filePattern = "([~/]?[\\w./-]+\\.[\\w]+)"
        return text.replacingOccurrences(
            of: filePattern,
            with: "`$0`",
            options: .regularExpression
        )
    }
    
    private func markdownToRichText(_ markdown: String) -> String {
        // This would ideally use NSAttributedString for actual rich text
        // For now, return the markdown as-is for the UI to handle
        return markdown
    }
    
    private func looksLikeCode(_ content: String) -> String {
        // Count code-like indicators
        var codeScore = 0
        
        // Check for common programming keywords
        let keywords = ["func", "var", "let", "const", "if", "else", "for", "while", "class", "import", "return", "function", "def"]
        for keyword in keywords {
            if content.contains(keyword) {
                codeScore += 1
            }
        }
        
        // Check for brackets
        if content.contains("{") && content.contains("}") {
            codeScore += 2
        }
        
        // Check for indentation
        let lines = content.components(separatedBy: .newlines)
        let indentedLines = lines.filter { $0.hasPrefix("    ") || $0.hasPrefix("\t") }
        if indentedLines.count > lines.count / 3 {
            codeScore += 3
        }
        
        // Check for common symbols
        let symbols = ["=", ";", "(", ")", "[", "]", "{", "}"]
        for symbol in symbols {
            if content.contains(symbol) {
                codeScore += 1
            }
        }
        
        return codeScore >= 5 ? "true" : "false"
    }
}

/// Helper to determine if content looks like code
extension ContentFormatter {
    private func looksLikeCode(_ content: String) -> Bool {
        var codeScore = 0
        
        let keywords = ["func", "var", "let", "const", "if", "else", "for", "while", "class", "import", "return", "function", "def"]
        for keyword in keywords {
            if content.contains(keyword) {
                codeScore += 1
            }
        }
        
        if content.contains("{") && content.contains("}") {
            codeScore += 2
        }
        
        let lines = content.components(separatedBy: .newlines)
        let indentedLines = lines.filter { $0.hasPrefix("    ") || $0.hasPrefix("\t") }
        if indentedLines.count > lines.count / 3 {
            codeScore += 3
        }
        
        return codeScore >= 5
    }
}
