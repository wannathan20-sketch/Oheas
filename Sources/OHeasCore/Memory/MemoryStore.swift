//
//  MemoryStore.swift
//  OHeas
//
//  Persists user memory patterns with 30-day half-life decay.
//  持久化用户记忆模式，30 天半衰期衰减。
//


import Foundation

public struct MemoryStore: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL, encoder: JSONEncoder = .oheasPretty, decoder: JSONDecoder = .oheas) {
        self.fileURL = fileURL
        self.encoder = encoder
        self.decoder = decoder
    }

    public func loadMemory() throws -> UserMemory {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return UserMemory()
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(UserMemory.self, from: data)
    }

    public func saveMemory(_ memory: UserMemory) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        var compacted = memory
        compactMemoryIfNeeded(&compacted)
        compacted.updatedAt = Date()
        let data = try encoder.encode(compacted)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func updatePreferences(_ preferences: UserPreferences) throws {
        var memory = try loadMemory()
        memory.preferences = preferences
        try saveMemory(memory)
    }

    @discardableResult
    public func addOrUpdatePattern(_ pattern: KnownPattern) throws -> UserMemory {
        var memory = try loadMemory()
        merge(pattern, into: &memory)
        try saveMemory(memory)
        return try loadMemory()
    }

    @discardableResult
    public func addSuccessfulIntervention(_ intervention: InterventionMemory) throws -> UserMemory {
        var memory = try loadMemory()
        merge(intervention, into: &memory.successfulInterventions)
        try saveMemory(memory)
        return try loadMemory()
    }

    @discardableResult
    public func addIneffectiveIntervention(_ intervention: InterventionMemory) throws -> UserMemory {
        var memory = try loadMemory()
        merge(intervention, into: &memory.ineffectiveInterventions)
        try saveMemory(memory)
        return try loadMemory()
    }

    @discardableResult
    public func addRiskNote(_ note: RiskNote) throws -> UserMemory {
        var memory = try loadMemory()
        memory.riskNotes.append(note)
        try saveMemory(memory)
        return try loadMemory()
    }

    public func compactMemoryIfNeeded(_ memory: inout UserMemory) {
        memory.knownPatterns = Array(memory.knownPatterns.sorted { $0.lastObservedAt > $1.lastObservedAt }.prefix(20)).map { pattern in
            var compacted = pattern
            compacted.examples = Array(pattern.examples.prefix(3))
            return compacted
        }
        memory.successfulInterventions = Array(memory.successfulInterventions.sorted { $0.lastObservedAt > $1.lastObservedAt }.prefix(20))
        memory.ineffectiveInterventions = Array(memory.ineffectiveInterventions.sorted { $0.lastObservedAt > $1.lastObservedAt }.prefix(20))
        memory.riskNotes = Array(memory.riskNotes.sorted { $0.createdAt > $1.createdAt }.prefix(10))
    }

    private func merge(_ pattern: KnownPattern, into memory: inout UserMemory) {
        let key = normalized(pattern.title)
        if let index = memory.knownPatterns.firstIndex(where: { normalized($0.title) == key }) {
            var existing = memory.knownPatterns[index]
            existing.evidenceCount += pattern.evidenceCount
            existing.lastObservedAt = max(existing.lastObservedAt, pattern.lastObservedAt)
            existing.firstObservedAt = min(existing.firstObservedAt, pattern.firstObservedAt)
            existing.examples = Array((existing.examples + pattern.examples).prefix(3))
            existing.confidence = upgradedConfidence(existing.confidence, evidenceCount: existing.evidenceCount)
            memory.knownPatterns[index] = existing
        } else {
            memory.knownPatterns.append(pattern)
        }
    }

    private func merge(_ intervention: InterventionMemory, into interventions: inout [InterventionMemory]) {
        let key = normalized(intervention.intervention)
        if let index = interventions.firstIndex(where: { normalized($0.intervention) == key }) {
            var existing = interventions[index]
            existing.evidenceCount += intervention.evidenceCount
            existing.lastObservedAt = max(existing.lastObservedAt, intervention.lastObservedAt)
            existing.confidence = upgradedConfidence(existing.confidence, evidenceCount: existing.evidenceCount)
            interventions[index] = existing
        } else {
            interventions.append(intervention)
        }
    }

    private func upgradedConfidence(_ confidence: SignalSeverity, evidenceCount: Int) -> SignalSeverity {
        if evidenceCount >= 5 { return .high }
        if evidenceCount >= 2 { return .medium }
        return confidence
    }

    private func normalized(_ value: String) -> String {
        value.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Decay

    /// Returns patterns whose decayed weight exceeds the given threshold.
    /// Default half-life is 30 days — a pattern observed 30 days ago has half the weight of a recent one.
    public func effectivePatterns(at date: Date, minWeight: Double = 0.1, halfLifeDays: Double = 30) -> [KnownPattern] {
        let halfLife = halfLifeDays * 86_400
        return loadMemoryOrEmpty().knownPatterns.filter { pattern in
            decayedWeight(for: pattern.lastObservedAt, at: date, halfLife: halfLife) > minWeight
        }
    }

    /// Returns successful interventions with decayed weight above the threshold.
    public func effectiveInterventions(at date: Date, minWeight: Double = 0.1, halfLifeDays: Double = 30) -> [InterventionMemory] {
        let halfLife = halfLifeDays * 86_400
        return loadMemoryOrEmpty().successfulInterventions.filter { intervention in
            decayedWeight(for: intervention.lastObservedAt, at: date, halfLife: halfLife) > minWeight
        }
    }

    /// Computes exponential decay weight: 1.0 at t=0, 0.5 at t=halfLife, approaches 0 over time.
    public func decayedWeight(
        for observedAt: Date,
        at referenceDate: Date,
        halfLife: TimeInterval = 30 * 86_400
    ) -> Double {
        let age = referenceDate.timeIntervalSince(observedAt)
        guard age > 0 else { return 1.0 }
        // Exponential decay: weight = 2^(-age / halfLife)
        return pow(2.0, -age / halfLife)
    }

    private func loadMemoryOrEmpty() -> UserMemory {
        (try? loadMemory()) ?? UserMemory()
    }
}
