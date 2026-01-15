# ClipGenius

## 🎯 Product Vision
An intelligent macOS clipboard manager that leverages on-device AI to automatically organize, search, and reuse clipboard content with contextual awareness and seamless workflow integration.

## ❓ Problem Statement
Users frequently copy and paste content across multiple contexts but lose track of clipboard history, struggle to find previously copied items, and waste time manually reformatting content when pasting into different applications.

## 🎯 Goals
- Provide unlimited clipboard history with persistent storage
- Enable semantic search across clipboard content using natural language queries
- Automatically categorize and organize clips by project context
- Suggest intelligent formatting based on destination application
- Maintain complete privacy with local-only processing (no network/server)
- Deliver fluid performance with native macOS integration

## 🚫 Non-Goals
- Cross-platform support (Windows, Linux, iOS, iPadOS)
- Cloud synchronization or backup
- Collaborative features or sharing
- Browser extensions or web interface
- Scripting API or plugin system
- Advanced image editing capabilities

## 👥 Target Users
- Developers and engineers who frequently copy code snippets and documentation
- Writers and researchers who gather and reference multiple sources
- Designers who collect visual assets and inspiration
- Product managers who organize information across multiple projects

## 🧩 Core Features
- Persistent clipboard history with configurable retention limits
- Semantic search using NaturalLanguage framework for text understanding
- Project-based auto-grouping using source application and content analysis
- Quick insert with keyboard shortcuts
- AI-suggested formatting (markdown, rich text, plain text, code blocks)
- Quick preview window with .ultraThinMaterial blur effects
- Deduplication of repeated clipboard items
- Favorite/pin system for frequently used clips
- Privacy-focused with automatic sensitive data detection

## ⚙️ Non-Functional Requirements
- Launch time under 0.5 seconds
- Search response time under 200ms for 10,000+ clips
- Memory footprint under 100MB when idle
- Support for 100,000+ clipboard items without degradation
- Native macOS 14+ UI patterns and animations
- Accessibility support (VoiceOver, keyboard navigation)
- Sandbox compliance for Mac App Store distribution

## 📊 Success Metrics
- Average time to find and insert a clip reduced by 60%
- User retention rate (30-day) above 70%
- Daily active users retrieve 10+ clips per day
- Semantic search accuracy above 85% (user-rated relevance)
- App Store rating above 4.5 stars

## 📌 Assumptions
- Users have macOS 14 or later
- Users prioritize privacy over cloud sync features
- Local storage is sufficient for typical clipboard history needs
- CoreML and NaturalLanguage frameworks provide adequate semantic understanding
- NSPasteboard polling at 0.5s intervals balances responsiveness and battery

## ❓ Open Questions
- What is the optimal default retention period for clipboard items?
- Should sensitive data (passwords, credit cards) be excluded from history entirely or just flagged?
- What are the most common project categorization patterns for clipboard content?
- Is 0.5s polling frequency acceptable for battery consumption or should it be adaptive?