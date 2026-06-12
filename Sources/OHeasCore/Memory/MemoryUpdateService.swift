//
//  MemoryUpdateService.swift
//  OHeas
//
//  Updates memory from feedback, verification, and mined patterns.
//  从反馈、验证和挖掘的模式中更新记忆。
//


import Foundation

public struct MemoryUpdateService: Sendable {
    private let miner: PatternMiner
    private let store: MemoryStore

    public init(miner: PatternMiner = PatternMiner(), store: MemoryStore) {
        self.miner = miner
        self.store = store
    }

    public func updateMemory(
        recentMetrics: [DailyHealthMetrics],
        feedbackHistory: [DailyFeedback],
        verificationReports: [VerificationReport],
        recommendationHistory: [CoachRecommendation],
        baseline: HealthBaseline,
        preferredLanguage: String = "en"
    ) throws -> (memory: UserMemory, candidates: PatternMiningResult) {
        let candidates = miner.mine(
            recentMetrics: recentMetrics,
            feedbackHistory: feedbackHistory,
            verificationReports: verificationReports,
            recommendationHistory: recommendationHistory,
            baseline: baseline,
            preferredLanguage: preferredLanguage
        )

        var memory = try store.loadMemory()
        for pattern in candidates.patterns {
            memory = merge(pattern, into: memory)
        }
        for intervention in candidates.successfulInterventions {
            memory = merge(intervention, into: memory, successful: true)
        }
        for intervention in candidates.ineffectiveInterventions {
            memory = merge(intervention, into: memory, successful: false)
        }
        try store.saveMemory(memory)
        return (try store.loadMemory(), candidates)
    }

    private func merge(_ pattern: KnownPattern, into memory: UserMemory) -> UserMemory {
        var memory = memory
        let key = pattern.title.normalizedMemoryKey
        if let index = memory.knownPatterns.firstIndex(where: { $0.title.normalizedMemoryKey == key }) {
            memory.knownPatterns[index].evidenceCount += pattern.evidenceCount
            memory.knownPatterns[index].lastObservedAt = pattern.lastObservedAt
            memory.knownPatterns[index].examples = Array((memory.knownPatterns[index].examples + pattern.examples).prefix(3))
        } else {
            memory.knownPatterns.append(pattern)
        }
        return memory
    }

    private func merge(_ intervention: InterventionMemory, into memory: UserMemory, successful: Bool) -> UserMemory {
        var memory = memory
        var list = successful ? memory.successfulInterventions : memory.ineffectiveInterventions
        let key = intervention.intervention.normalizedMemoryKey
        if let index = list.firstIndex(where: { $0.intervention.normalizedMemoryKey == key }) {
            list[index].evidenceCount += intervention.evidenceCount
            list[index].lastObservedAt = intervention.lastObservedAt
        } else {
            list.append(intervention)
        }
        if successful {
            memory.successfulInterventions = list
        } else {
            memory.ineffectiveInterventions = list
        }
        return memory
    }
}

private extension String {
    var normalizedMemoryKey: String {
        lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
