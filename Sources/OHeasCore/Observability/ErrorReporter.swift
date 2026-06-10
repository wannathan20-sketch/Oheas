//
//  ErrorReporter.swift
//  OHeas
//
//  Local error logging with sensitive field redaction.
//  本地错误日志，敏感字段脱敏。
//


import Foundation

public enum ErrorCategory: String, Codable, CaseIterable, Sendable {
    case healthKit = "healthkit"
    case llm
    case sync
    case onboarding
    case storage
    case notification
    case safety
}

public struct ErrorEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var category: ErrorCategory
    public var message: String
    public var context: [String: String]
    public var createdAt: Date

    public init(id: UUID = UUID(), category: ErrorCategory, message: String, context: [String: String] = [:], createdAt: Date = Date()) {
        self.id = id
        self.category = category
        self.message = message
        self.context = context
        self.createdAt = createdAt
    }
}

public struct ErrorReporter: Sendable {
    private let store: CodableFileStore<ErrorEvent>

    public init(fileURL: URL) {
        self.store = CodableFileStore(fileURL: fileURL)
    }

    public func record(category: ErrorCategory, message: String, context: [String: String] = [:]) {
        let sanitized = context.filter { key, _ in
            let lower = key.lowercased()
            return !lower.contains("raw") && !lower.contains("sample") && !lower.contains("apikey") && !lower.contains("token")
        }
        var events = (try? store.load()) ?? []
        events.append(ErrorEvent(category: category, message: message, context: sanitized))
        try? store.save(events)
    }

    public func recent(limit: Int = 20) -> [ErrorEvent] {
        Array(((try? store.load()) ?? []).sorted { $0.createdAt < $1.createdAt }.suffix(limit))
    }
}
