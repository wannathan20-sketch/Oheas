//
//  ChatMessageStore.swift
//  OHeas
//
//  Persistent storage for chat conversation sessions.
//  聊天对话会话的持久化存储。
//

import Foundation

// MARK: - Chat message model

public struct ChatMessage: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date

    public enum Role: String, Equatable, Codable, Sendable {
        case user
        case coach
    }

    public init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Chat session model

/// A single conversation session — like one "chat" in ChatGPT's sidebar.
public struct ChatSession: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public var messages: [ChatMessage]
    /// Compressed summary of earlier conversation turns. Nil until first summarization.
    public var summary: String?

    public init(
        id: UUID = UUID(),
        title: String = "New Chat",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = [],
        summary: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.summary = summary
    }

    /// Derive a display-friendly title from the first user message.
    public var displayTitle: String {
        if title != "New Chat" { return title }
        guard let firstUser = messages.first(where: { $0.role == .user }) else {
            return "New Chat"
        }
        let preview = String(firstUser.content.prefix(40))
        return preview.count < firstUser.content.count ? "\(preview)…" : preview
    }

    /// Last few words from the most recent coach message as preview.
    public var preview: String {
        guard let last = messages.last(where: { $0.role == .coach }) ?? messages.last else {
            return ""
        }
        return String(last.content.prefix(60))
    }
}

// MARK: - Conversation starter model

public struct ConversationStarter: Identifiable, Sendable {
    public let id = UUID()
    public let text: String
    public let icon: String

    public init(text: String, icon: String) {
        self.text = text
        self.icon = icon
    }
}

// MARK: - Chat message store

/// Persists chat sessions to a JSON file.
public struct ChatMessageStore: Sendable {
    private let fileURL: URL
    private let maxMessagesPerSession: Int
    private let maxSessions: Int
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL, maxMessagesPerSession: Int = 200, maxSessions: Int = 50) {
        self.fileURL = fileURL
        self.maxMessagesPerSession = maxMessagesPerSession
        self.maxSessions = maxSessions
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
    }

    // MARK: - Sessions

    /// Load all sessions, newest first.
    public func loadSessions() throws -> [ChatSession] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([ChatSession].self, from: data)
    }

    /// Save all sessions, trimming old messages and old sessions.
    public func saveSessions(_ sessions: [ChatSession]) throws {
        let trimmed = sessions.map { session -> ChatSession in
            var s = session
            if s.messages.count > maxMessagesPerSession {
                s.messages = Array(s.messages.suffix(maxMessagesPerSession))
            }
            return s
        }
        let capped = Array(trimmed.suffix(maxSessions))

        let directory = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let data = try encoder.encode(capped)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Delete all sessions.
    public func deleteAll() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
