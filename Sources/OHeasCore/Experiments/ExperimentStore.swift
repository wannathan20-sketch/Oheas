//
//  ExperimentStore.swift
//  OHeas
//
//  Persists and manages personal experiment lifecycle.
//  持久化和管理个人实验生命周期。
//


import Foundation

public enum ExperimentStoreError: Error, Equatable, Sendable {
    case activeExperimentAlreadyExists
    case experimentNotFound
}

public struct ExperimentStore: Sendable {
    private let store: CodableFileStore<PersonalExperiment>
    private let calendar: Calendar

    public init(fileURL: URL, calendar: Calendar = .current) {
        self.store = CodableFileStore(fileURL: fileURL)
        self.calendar = calendar
    }

    public func loadExperiments() throws -> [PersonalExperiment] {
        try store.load().sorted { $0.createdAt < $1.createdAt }
    }

    public func saveExperiments(_ experiments: [PersonalExperiment]) throws {
        try store.save(experiments)
    }

    public func getActiveExperiment() throws -> PersonalExperiment? {
        try loadExperiments().last { $0.status == .active }
    }

    public func proposeExperiment(_ experiment: PersonalExperiment) throws {
        var experiments = try loadExperiments()
        if !experiments.contains(where: { $0.id == experiment.id }) {
            experiments.append(experiment)
        }
        try saveExperiments(experiments)
    }

    public func startExperiment(_ experimentId: UUID) throws {
        var experiments = try loadExperiments()
        guard experiments.first(where: { $0.status == .active }) == nil else {
            throw ExperimentStoreError.activeExperimentAlreadyExists
        }
        guard let index = experiments.firstIndex(where: { $0.id == experimentId }) else {
            throw ExperimentStoreError.experimentNotFound
        }
        experiments[index].status = .active
        try saveExperiments(experiments)
    }

    public func pauseExperiment(_ experimentId: UUID) throws {
        try update(experimentId) { $0.status = .paused }
    }

    public func cancelExperiment(_ experimentId: UUID) throws {
        try update(experimentId) { $0.status = .cancelled }
    }

    public func addCheckin(_ checkin: ExperimentCheckin, to experimentId: UUID) throws {
        try update(experimentId) { experiment in
            if let index = experiment.dailyCheckins.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: checkin.date) }) {
                experiment.dailyCheckins[index] = checkin
            } else {
                experiment.dailyCheckins.append(checkin)
            }
        }
    }

    public func completeExperiment(_ experimentId: UUID, result: ExperimentResult) throws {
        try update(experimentId) {
            $0.status = .completed
            $0.result = result
        }
    }

    public func evaluateExperiment(
        _ experiment: PersonalExperiment,
        recentMetrics: [DailyHealthMetrics],
        baseline: HealthBaseline,
        dataQuality: DataQualityReport
    ) -> ExperimentResult {
        if dataQuality.overallConfidence == .low {
            return ExperimentResult(
                outcome: .unclear,
                confidence: .low,
                summary: "Data is too limited to evaluate the experiment. Marked as unclear for now.",
                evidence: dataQuality.missingReasons
            )
        }

        guard experiment.dailyCheckins.count >= 3 else {
            return ExperimentResult(
                outcome: .unclear,
                confidence: .low,
                summary: "Fewer than 3 check-ins recorded. Cannot yet determine if the experiment is helping.",
                evidence: ["\(experiment.dailyCheckins.count) check-ins recorded."]
            )
        }

        let adherenceRate = Double(experiment.dailyCheckins.filter(\.completed).count) / Double(experiment.dailyCheckins.count)
        guard adherenceRate >= 0.60 else {
            return ExperimentResult(
                outcome: .unclear,
                confidence: .low,
                summary: "Adherence below 60%. Cannot determine whether the intervention itself is effective.",
                evidence: ["Adherence \(Int(adherenceRate * 100))%."]
            )
        }

        let latest = recentMetrics.last
        let improved = improvementCount(today: latest, baseline: baseline, targetMetrics: experiment.targetMetrics)
        if improved >= 2 {
            return ExperimentResult(
                outcome: .likelyHelped,
                confidence: .medium,
                summary: "Adherence above 60% with at least two improved target metrics. The experiment may be helpful.",
                evidence: ["Adherence \(Int(adherenceRate * 100))%.", "\(improved) target metrics looked improved."],
                learnedPatternCandidate: "This lifestyle experiment may be suitable as a basis for future recommendations."
            )
        }

        return ExperimentResult(
            outcome: .neutral,
            confidence: .medium,
            summary: "Adherence is sufficient, but target metrics did not show consistent improvement. Treated as neutral.",
            evidence: ["Adherence \(Int(adherenceRate * 100))%.", "\(improved) target metrics looked improved."]
        )
    }

    private func update(_ experimentId: UUID, mutate: (inout PersonalExperiment) -> Void) throws {
        var experiments = try loadExperiments()
        guard let index = experiments.firstIndex(where: { $0.id == experimentId }) else {
            throw ExperimentStoreError.experimentNotFound
        }
        mutate(&experiments[index])
        try saveExperiments(experiments)
    }

    private func improvementCount(today: DailyHealthMetrics?, baseline: HealthBaseline, targetMetrics: [String]) -> Int {
        guard let today else { return 0 }
        var count = 0
        if targetMetrics.contains("sleepHours"), let value = today.sleepHours, let base = baseline.averageSleepHours, value >= base { count += 1 }
        if targetMetrics.contains("hrv"), let value = today.hrv, let base = baseline.averageHRV, value >= base { count += 1 }
        if targetMetrics.contains("restingHeartRate"), let value = today.restingHeartRate, let base = baseline.averageRestingHeartRate, value <= base { count += 1 }
        if targetMetrics.contains("steps"), let value = today.steps, let base = baseline.averageSteps, value >= base { count += 1 }
        if targetMetrics.contains("exerciseMinutes"), let value = today.exerciseMinutes, let base = baseline.averageExerciseMinutes, value >= base { count += 1 }
        if targetMetrics.contains("subjectiveEnergy"), let energy = latestEnergy(from: today.date), energy >= 7 { count += 1 }
        return count
    }

    private func latestEnergy(from date: Date) -> Int? {
        nil
    }
}
