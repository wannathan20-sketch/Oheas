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
        dataQuality: DataQualityReport,
        preferredLanguage: String = "en"
    ) -> ExperimentResult {
        let zh = preferredLanguage == "zh"
        if dataQuality.overallConfidence == .low {
            return ExperimentResult(
                outcome: .unclear,
                confidence: .low,
                summary: zh ? "当前数据太少，暂时无法评估实验效果，先标记为不明确。" : "Data is too limited to evaluate the experiment. Marked as unclear for now.",
                evidence: localizedMissingReasons(dataQuality.missingReasons, zh: zh)
            )
        }

        guard experiment.dailyCheckins.count >= 3 else {
            return ExperimentResult(
                outcome: .unclear,
                confidence: .low,
                summary: zh ? "记录少于 3 次打卡，暂时无法判断实验是否有帮助。" : "Fewer than 3 check-ins recorded. Cannot yet determine if the experiment is helping.",
                evidence: [zh ? "已记录 \(experiment.dailyCheckins.count) 次打卡。" : "\(experiment.dailyCheckins.count) check-ins recorded."]
            )
        }

        let adherenceRate = Double(experiment.dailyCheckins.filter(\.completed).count) / Double(experiment.dailyCheckins.count)
        guard adherenceRate >= 0.60 else {
            return ExperimentResult(
                outcome: .unclear,
                confidence: .low,
                summary: zh ? "完成率低于 60%，暂时无法判断行动本身是否有效。" : "Adherence below 60%. Cannot determine whether the intervention itself is effective.",
                evidence: [zh ? "完成率 \(Int(adherenceRate * 100))%。" : "Adherence \(Int(adherenceRate * 100))%."]
            )
        }

        let latest = recentMetrics.last
        let improved = improvementCount(today: latest, baseline: baseline, targetMetrics: experiment.targetMetrics)
        if improved >= 2 {
            return ExperimentResult(
                outcome: .likelyHelped,
                confidence: .medium,
                summary: zh ? "完成率超过 60%，且至少两个目标指标有所改善。这个实验可能有帮助。" : "Adherence above 60% with at least two improved target metrics. The experiment may be helpful.",
                evidence: [
                    zh ? "完成率 \(Int(adherenceRate * 100))%。" : "Adherence \(Int(adherenceRate * 100))%.",
                    zh ? "\(improved) 个目标指标看起来有所改善。" : "\(improved) target metrics looked improved."
                ],
                learnedPatternCandidate: zh ? "这个生活方式实验可以作为未来建议的参考。" : "This lifestyle experiment may be suitable as a basis for future recommendations."
            )
        }

        return ExperimentResult(
            outcome: .neutral,
            confidence: .medium,
            summary: zh ? "完成率足够，但目标指标没有持续改善，结果按中性处理。" : "Adherence is sufficient, but target metrics did not show consistent improvement. Treated as neutral.",
            evidence: [
                zh ? "完成率 \(Int(adherenceRate * 100))%。" : "Adherence \(Int(adherenceRate * 100))%.",
                zh ? "\(improved) 个目标指标看起来有所改善。" : "\(improved) target metrics looked improved."
            ]
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

    private func localizedMissingReasons(_ reasons: [String], zh: Bool) -> [String] {
        guard zh else { return reasons }
        return reasons.map { reason in
            let lower = reason.lowercased()
            if lower.contains("sleep data has been missing") && lower.contains("consecutive days") {
                return "睡眠数据已连续多天缺失，请检查 Apple Watch 睡眠设置或夜间佩戴情况。"
            }
            if lower.contains("recovery data has been missing") && lower.contains("consecutive days") {
                return "恢复数据已连续多天缺失，建议睡眠时佩戴 Apple Watch 以建立可靠基线。"
            }
            if lower.contains("apple watch data may still be syncing") {
                return "Apple Watch 数据可能仍在同步。如果已佩戴手表，请稍等几分钟后刷新。"
            }
            if lower.contains("sleep data is missing") {
                return "睡眠数据缺失，可能是夜间未佩戴 Apple Watch 或未开启睡眠追踪。"
            }
            if lower.contains("hrv data is missing") {
                return "HRV 数据缺失，会限制恢复解读。"
            }
            if lower.contains("resting heart rate is missing") {
                return "静息心率缺失，会限制压力和恢复判断。"
            }
            if lower.contains("step count is missing") {
                return "步数数据缺失。"
            }
            if lower.contains("active energy is missing") {
                return "活动能量数据缺失。"
            }
            if lower.contains("exercise minutes are missing") {
                return "运动分钟数缺失。"
            }
            if lower.contains("workout records could not be queried") {
                return "无法读取运动记录。"
            }
            if lower.contains("aggregated metrics hidden by privacy settings") {
                return "聚合指标已被隐私设置隐藏。"
            }
            return reason
        }
    }
}
