//
//  ExperimentViewModel.swift
//  OHeas
//
//  Manages experiment lifecycle — propose, start, check-in, evaluate.
//  管理实验生命周期 — 提议、开始、签到、评估。
//


import Foundation
import SwiftUI
import OHeasCore

@MainActor
final class ExperimentViewModel: ObservableObject {
    @Published var activeExperiment: PersonalExperiment?
    @Published var proposedExperiment: PersonalExperiment?
    @Published var experimentHistory: [PersonalExperiment] = []
    @Published var experimentCheckinCompleted = false
    @Published var experimentCheckinEnergy: Double = 6
    @Published var experimentCheckinNote: String = ""

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var preferredLanguage: String {
        (AppLanguage(rawValue: languageRawValue) ?? .chinese).rawValue
    }

    private let experimentStore = ExperimentStore(fileURL: OHeasStorageURLs.experiments)
    private let experimentPlanner = ExperimentPlanner()
    private let errorReporter: ErrorReporter
    private var syncEngine: SyncEngine?
    private var analyticsService: BetaAnalyticsService?

    init(errorReporter: ErrorReporter) {
        self.errorReporter = errorReporter
    }

    func configure(syncEngine: SyncEngine, analyticsService: BetaAnalyticsService) {
        self.syncEngine = syncEngine
        self.analyticsService = analyticsService
    }

    func loadExperiments() {
        do {
            experimentHistory = try experimentStore.loadExperiments()
            activeExperiment = try experimentStore.getActiveExperiment()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to load experiments: \(error.localizedDescription)")
            experimentHistory = []
            activeExperiment = nil
        }
    }

    func proposeExperiment(
        memory: UserMemory,
        recentMetrics: [DailyHealthMetrics],
        recentSignals: [HealthSignal],
        dataQuality: DataQualityReport,
        userGoal: String
    ) {
        guard activeExperiment == nil else { return }

        if let existingProposal = experimentHistory.last(where: { $0.status == .proposed }) {
            proposedExperiment = existingProposal
            return
        }

        let proposal = experimentPlanner.propose(
            memory: memory,
            recentMetrics: recentMetrics,
            recentSignals: recentSignals,
            dataQuality: dataQuality,
            userGoal: userGoal,
            previousExperiments: experimentHistory,
            preferredLanguage: preferredLanguage
        )
        proposedExperiment = proposal
        if let proposedExperiment {
            do {
                try experimentStore.proposeExperiment(proposedExperiment)
            } catch {
                errorReporter.record(category: .storage, message: "Failed to save experiment proposal: \(error.localizedDescription)")
            }
        }
    }

    func startProposedExperiment() {
        guard let proposedExperiment else { return }
        do {
            try experimentStore.startExperiment(proposedExperiment.id)
            experimentHistory = try experimentStore.loadExperiments()
            activeExperiment = try experimentStore.getActiveExperiment()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to start experiment: \(error.localizedDescription)")
        }
        if let activeExperiment {
            do {
                try syncEngine?.enqueue(activeExperiment, entityType: .personalExperiment, entityId: activeExperiment.id.uuidString)
            } catch {
                errorReporter.record(category: .sync, message: "Failed to enqueue experiment: \(error.localizedDescription)")
            }
        }
        analyticsService.map { _ = try? $0.record(eventType: .experimentStarted, userId: "local") }
        self.proposedExperiment = nil
    }

    func saveExperimentCheckin() {
        guard let activeExperiment else { return }
        let checkin = ExperimentCheckin(
            date: Date(),
            completed: experimentCheckinCompleted,
            note: experimentCheckinNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : experimentCheckinNote,
            subjectiveEnergy: Int(experimentCheckinEnergy.rounded())
        )
        do {
            try experimentStore.addCheckin(checkin, to: activeExperiment.id)
            experimentHistory = try experimentStore.loadExperiments()
            self.activeExperiment = try experimentStore.getActiveExperiment()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save checkin: \(error.localizedDescription)")
        }
        if let activeExperiment = self.activeExperiment {
            do {
                try syncEngine?.enqueue(activeExperiment, entityType: .personalExperiment, entityId: activeExperiment.id.uuidString)
            } catch {
                errorReporter.record(category: .sync, message: "Failed to enqueue experiment: \(error.localizedDescription)")
            }
        }
        analyticsService.map { _ = try? $0.record(eventType: .experimentCheckin, userId: "local") }
    }

    func pauseActiveExperiment() {
        guard let activeExperiment else { return }
        do {
            try experimentStore.pauseExperiment(activeExperiment.id)
            experimentHistory = try experimentStore.loadExperiments()
            self.activeExperiment = nil
        } catch {
            errorReporter.record(category: .storage, message: "Failed to pause experiment: \(error.localizedDescription)")
        }
    }

    func completeActiveExperiment(
        baseline: HealthBaseline,
        dataQuality: DataQualityReport,
        recentMetrics: [DailyHealthMetrics]
    ) {
        guard let activeExperiment else { return }
        let result = experimentStore.evaluateExperiment(
            activeExperiment,
            recentMetrics: recentMetrics,
            baseline: baseline,
            dataQuality: dataQuality,
            preferredLanguage: preferredLanguage
        )
        do {
            try experimentStore.completeExperiment(activeExperiment.id, result: result)
            experimentHistory = try experimentStore.loadExperiments()
            self.activeExperiment = nil
        } catch {
            errorReporter.record(category: .storage, message: "Failed to complete experiment: \(error.localizedDescription)")
        }
        if let completed = experimentHistory.first(where: { $0.id == activeExperiment.id }) {
            do {
                try syncEngine?.enqueue(completed, entityType: .personalExperiment, entityId: completed.id.uuidString)
            } catch {
                errorReporter.record(category: .sync, message: "Failed to enqueue completed experiment: \(error.localizedDescription)")
            }
        }
    }

#if DEBUG
    func persistDemoExperiments(_ experiments: [PersonalExperiment]) {
        do {
            try experimentStore.saveExperiments(experiments)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save demo experiments: \(error.localizedDescription)")
        }
    }
#endif

    func resetExperiments() {
        do {
            try experimentStore.saveExperiments([])
            experimentHistory = []
            activeExperiment = nil
            proposedExperiment = nil
        } catch {
            errorReporter.record(category: .storage, message: "Failed to reset experiments: \(error.localizedDescription)")
        }
    }
}
