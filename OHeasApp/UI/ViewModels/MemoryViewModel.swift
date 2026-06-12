//
//  MemoryViewModel.swift
//  OHeas
//
//  Loads and updates user memory and pattern mining results.
//  加载和更新用户记忆和模式挖掘结果。
//


import Foundation
import SwiftUI
import OHeasCore

@MainActor
final class MemoryViewModel: ObservableObject {
    @Published var userMemory: UserMemory = UserMemory()
    @Published var patternCandidates: PatternMiningResult = PatternMiningResult()

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var preferredLanguage: String {
        (AppLanguage(rawValue: languageRawValue) ?? .chinese).rawValue
    }

    private let memoryStore = MemoryStore(fileURL: OHeasStorageURLs.memory)
    private let errorReporter: ErrorReporter

    init(errorReporter: ErrorReporter) {
        self.errorReporter = errorReporter
    }

    func loadMemory() {
        do {
            userMemory = try memoryStore.loadMemory()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to load memory: \(error.localizedDescription)")
            userMemory = UserMemory()
        }
    }

    func updateMemory(
        recentMetrics: [DailyHealthMetrics],
        feedbackHistory: [DailyFeedback],
        verificationReports: [VerificationReport],
        recommendationHistory: [CoachRecommendation],
        baseline: HealthBaseline
    ) {
        let updater = MemoryUpdateService(store: memoryStore)
        do {
            let result = try updater.updateMemory(
                recentMetrics: recentMetrics,
                feedbackHistory: feedbackHistory,
                verificationReports: verificationReports,
                recommendationHistory: recommendationHistory,
                baseline: baseline,
                preferredLanguage: preferredLanguage
            )
            userMemory = result.memory
            patternCandidates = result.candidates
        } catch {
            errorReporter.record(category: .storage, message: "Failed to update memory: \(error.localizedDescription)")
        }
    }

    func saveMemory() {
        do {
            try memoryStore.saveMemory(userMemory)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save memory: \(error.localizedDescription)")
        }
    }

    func resetMemory() {
        do {
            try memoryStore.saveMemory(UserMemory())
            userMemory = UserMemory()
            patternCandidates = PatternMiningResult()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to reset memory: \(error.localizedDescription)")
        }
    }
}
