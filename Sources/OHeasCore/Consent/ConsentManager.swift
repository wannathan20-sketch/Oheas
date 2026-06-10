//
//  ConsentManager.swift
//  OHeas
//
//  Manages user consent for AI, cloud sync, and analytics.
//  管理用户对 AI、云同步和分析的同意。
//


import Foundation

public enum ConsentType: String, Codable, CaseIterable, Sendable {
    case healthKitRead = "healthkit_read"
    case aiLifestyleAdvice = "ai_lifestyle_advice"
    case cloudSync = "cloud_sync"
    case betaAnalytics = "beta_analytics"
    case notifications
}

public struct ConsentRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: ConsentType
    public var version: String
    public var accepted: Bool
    public var acceptedAt: Date?
    public var revokedAt: Date?
    public var textSummary: String

    public init(
        id: UUID = UUID(),
        type: ConsentType,
        version: String = "2026-06-beta",
        accepted: Bool,
        acceptedAt: Date? = nil,
        revokedAt: Date? = nil,
        textSummary: String
    ) {
        self.id = id
        self.type = type
        self.version = version
        self.accepted = accepted
        self.acceptedAt = acceptedAt
        self.revokedAt = revokedAt
        self.textSummary = textSummary
    }
}

public struct ConsentManager: Sendable {
    private let store: CodableFileStore<ConsentRecord>

    public init(fileURL: URL) {
        self.store = CodableFileStore(fileURL: fileURL)
    }

    public func recordConsent(type: ConsentType, accepted: Bool, version: String = "2026-06-beta", textSummary: String) throws {
        let record = ConsentRecord(
            type: type,
            version: version,
            accepted: accepted,
            acceptedAt: accepted ? Date() : nil,
            revokedAt: accepted ? nil : Date(),
            textSummary: textSummary
        )
        var records = try store.load()
        records.append(record)
        try store.save(records)
    }

    public func revokeConsent(type: ConsentType, textSummary: String = "Revoked by user.") throws {
        try recordConsent(type: type, accepted: false, textSummary: textSummary)
    }

    public func hasConsent(_ type: ConsentType) -> Bool {
        guard let latest = try? latestConsents() else { return false }
        return latest[type]?.accepted ?? false
    }

    public func latestConsents() throws -> [ConsentType: ConsentRecord] {
        var latest: [ConsentType: ConsentRecord] = [:]
        for record in try store.load().sorted(by: { ($0.acceptedAt ?? $0.revokedAt ?? Date.distantPast) < ($1.acceptedAt ?? $1.revokedAt ?? Date.distantPast) }) {
            latest[record.type] = record
        }
        return latest
    }

    public func all() throws -> [ConsentRecord] {
        try store.load()
    }
}
