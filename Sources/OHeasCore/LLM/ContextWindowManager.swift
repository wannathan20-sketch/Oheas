//
//  ContextWindowManager.swift
//  OHeas
//
//  Token estimation and sliding window for LLM conversation context.
//  Prevents context overflow and enables intelligent summarization.
//

import Foundation

// MARK: - Configuration

public struct ContextWindowConfig: Sendable {
    /// Max tokens for the system prompt.
    public let maxSystemTokens: Int
    /// Max tokens for conversation history.
    public let maxHistoryTokens: Int
    /// Max tokens for RAG results.
    public let maxRAGTokens: Int
    /// Message count threshold to trigger summarization.
    public let summarizeAtMessageCount: Int
    /// Token estimate threshold to trigger summarization.
    public let summarizeAtTokenEstimate: Int

    public init(
        maxSystemTokens: Int = 1200,
        maxHistoryTokens: Int = 3000,
        maxRAGTokens: Int = 500,
        summarizeAtMessageCount: Int = 15,
        summarizeAtTokenEstimate: Int = 3500
    ) {
        self.maxSystemTokens = maxSystemTokens
        self.maxHistoryTokens = maxHistoryTokens
        self.maxRAGTokens = maxRAGTokens
        self.summarizeAtMessageCount = summarizeAtMessageCount
        self.summarizeAtTokenEstimate = summarizeAtTokenEstimate
    }

    public static let `default` = ContextWindowConfig()
}

// MARK: - Window manager

public struct ContextWindowManager: Sendable {

    public init() {}

    // MARK: - Token estimation

    /// Estimate token count for mixed Chinese/English text.
    /// Heuristic: ~2.5 characters per token works reasonably for both languages.
    /// Chinese: ~1.5-2 chars/token. English: ~3-4 chars/token. Mixed: ~2.5.
    public func estimateTokens(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        let count = Double(text.count)
        // Count CJK characters (higher token density)
        let cjkCount = text.unicodeScalars.filter { scalar in
            (0x4E00...0x9FFF).contains(scalar.value)       // CJK Unified
            || (0x3400...0x4DBF).contains(scalar.value)    // CJK Extension A
            || (0x20000...0x2A6DF).contains(scalar.value)  // CJK Extension B
            || (0xF900...0xFAFF).contains(scalar.value)    // CJK Compatibility
        }.count
        let nonCJK = max(1.0, Double(count) - Double(cjkCount) * 1.5)
        let cjkTokens = Double(cjkCount) / 1.8
        let otherTokens = nonCJK / 4.0
        return max(1, Int((cjkTokens + otherTokens).rounded(.up)))
    }

    /// Estimate tokens for an array of chat messages.
    public func estimateMessageTokens(_ messages: [ChatMessage]) -> Int {
        messages.reduce(0) { $0 + estimateTokens($1.content) }
    }

    // MARK: - Sliding window

    /// Build a sliding window of recent messages that fits within the token budget.
    /// If a summary is provided, it's prepended as context.
    /// Always keeps the most recent messages; older ones are dropped.
    public func buildSlidingWindow(
        messages: [ChatMessage],
        maxTokens: Int,
        summary: String? = nil
    ) -> [ChatMessage] {
        guard !messages.isEmpty else { return [] }

        var window: [ChatMessage] = []
        var tokenBudget = maxTokens

        // Reserve tokens for summary if present
        if let summary {
            tokenBudget -= estimateTokens(summary)
        }

        // Walk from newest to oldest, accumulating until budget exhausted
        for msg in messages.reversed() {
            let msgTokens = estimateTokens(msg.content)
            if tokenBudget - msgTokens < 0 {
                break
            }
            window.insert(msg, at: 0)
            tokenBudget -= msgTokens
        }

        return window
    }

    /// Build API-ready message list with system prompt, optional summary, and sliding window.
    public func buildMessages(
        systemPrompt: String,
        messages: [ChatMessage],
        summary: String? = nil,
        ragContext: String = "",
        maxHistoryTokens: Int = 3000,
        newUserMessage: String? = nil
    ) -> [[String: String]] {
        var apiMessages: [[String: String]] = []

        // System prompt (with RAG appended)
        var fullSystem = systemPrompt
        let ragTokens = estimateTokens(ragContext)
        if ragTokens <= ContextWindowConfig.default.maxRAGTokens {
            fullSystem += ragContext
        } else {
            // Truncate RAG to budget
            let truncated = String(ragContext.prefix(ContextWindowConfig.default.maxRAGTokens * 3))
            fullSystem += truncated
        }
        apiMessages.append(["role": "system", "content": fullSystem])

        // Inject summary as a synthetic system message
        if let summary, !summary.isEmpty {
            apiMessages.append([
                "role": "system",
                "content": "Previous conversation summary:\n\(summary)\n\nContinue the conversation naturally, referencing the summary when relevant."
            ])
        }

        // Sliding window of recent messages
        let window = buildSlidingWindow(messages: messages, maxTokens: maxHistoryTokens, summary: summary)
        for msg in window {
            apiMessages.append([
                "role": msg.role == .user ? "user" : "assistant",
                "content": msg.content
            ])
        }

        // New user message (already appended to session, include separately if needed)
        if let newMsg = newUserMessage {
            apiMessages.append(["role": "user", "content": newMsg])
        }

        return apiMessages
    }

    // MARK: - Summarization

    /// Check whether the conversation should be summarized.
    public func shouldSummarize(
        messages: [ChatMessage],
        config: ContextWindowConfig = .default
    ) -> Bool {
        guard messages.count >= config.summarizeAtMessageCount else { return false }
        let tokens = estimateMessageTokens(messages)
        return tokens >= config.summarizeAtTokenEstimate
    }

    /// Split messages into "to summarize" (older) and "to keep" (recent) portions.
    /// Older portion is ~60% of messages or everything beyond the keep threshold.
    public func splitForSummarization(
        messages: [ChatMessage],
        keepRecent: Int = 8
    ) -> (toSummarize: [ChatMessage], toKeep: [ChatMessage]) {
        guard messages.count > keepRecent else {
            return ([], messages)
        }
        let splitIndex = max(0, messages.count - keepRecent)
        let toSummarize = Array(messages[0..<splitIndex])
        let toKeep = Array(messages[splitIndex...])
        return (toSummarize, toKeep)
    }

    /// Build a prompt requesting the LLM to summarize conversation history.
    /// Use this to generate a compact summary that preserves key context.
    public func buildSummarizeRequest(messages: [ChatMessage]) -> String {
        var request = """
        Summarize the following conversation between a user and their health coach.
        Keep it under 200 words. Capture:
        - Key topics discussed
        - User's concerns, goals, or commitments
        - Coach's main recommendations
        - Any data points that were discussed (sleep, HRV, heart rate, activity)
        - The user's emotional state or stated preferences

        Conversation:
        """

        for msg in messages {
            let role = msg.role == .user ? "User" : "Coach"
            // Truncate very long messages in the summary prompt
            let content = msg.content.count > 300 ? String(msg.content.prefix(300)) + "..." : msg.content
            request += "\n\(role): \(content)"
        }

        request += "\n\nSummary:"
        return request
    }

    /// Build a rule-based summary when LLM is unavailable.
    /// Extracts user messages and coach recommendations as bullet points.
    public func ruleBasedSummary(messages: [ChatMessage]) -> String {
        var points: [String] = []

        for msg in messages {
            if msg.role == .user {
                let clean = msg.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    points.append("User asked: \(String(clean.prefix(100)))")
                }
            } else if msg.role == .coach {
                // Extract recommendation-like sentences
                let recommendationHints = ["建议", "试试", "推荐", "可以", "try", "consider", "recommend", "suggest", "focus on", "prioritize"]
                let lower = msg.content.lowercased()
                let hasRecommendation = recommendationHints.contains { lower.contains($0) }
                if hasRecommendation {
                    points.append("Coach suggested: \(String(msg.content.prefix(150)))")
                }
            }
        }

        guard !points.isEmpty else {
            return "The user and coach exchanged \(messages.count) messages about health topics."
        }

        return points.prefix(15).joined(separator: "\n")
    }
}
