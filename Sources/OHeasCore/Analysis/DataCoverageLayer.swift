//
//  DataCoverageLayer.swift
//  OHeas
//
//  Assesses data quality, completeness, and confidence.
//  评估数据质量、完整性和置信度。
//


import Foundation

public struct DataCoverageLayer: Sendable {
    public init() {}

    public func report(for metrics: DailyHealthMetrics) -> DataQualityReport {
        let statuses = metrics.perMetricStatus
        let (confidence, missingReasons, shouldAsk, suggestedQ) = evaluate(
            statuses: statuses,
            recentMetrics: nil
        )
        return DataQualityReport(
            perMetricStatus: statuses,
            overallConfidence: confidence,
            missingReasons: missingReasons,
            shouldAskUserFollowup: shouldAsk,
            suggestedFollowupQuestion: suggestedQ
        )
    }

    /// Enhanced report that considers consecutive missing days for persistent issues.
    /// - Parameter recentMetrics: Sorted array of recent DailyHealthMetrics (newest last), should include today.
    public func reportWithHistory(today: DailyHealthMetrics, recentMetrics: [DailyHealthMetrics]) -> DataQualityReport {
        let statuses = today.perMetricStatus
        let (confidence, missingReasons, shouldAsk, suggestedQ) = evaluate(
            statuses: statuses,
            recentMetrics: recentMetrics
        )
        return DataQualityReport(
            perMetricStatus: statuses,
            overallConfidence: confidence,
            missingReasons: missingReasons,
            shouldAskUserFollowup: shouldAsk,
            suggestedFollowupQuestion: suggestedQ
        )
    }

    // MARK: - Private evaluation

    private func evaluate(
        statuses: [HealthMetric: MetricStatus],
        recentMetrics: [DailyHealthMetrics]?
    ) -> (ConfidenceLevel, [String], Bool, String?) {
        let criticalMetrics: [HealthMetric] = [.sleepHours, .hrv, .restingHeartRate]
        let activityMetrics: [HealthMetric] = [.steps, .activeEnergyKcal, .exerciseMinutes]

        let missingCritical = criticalMetrics.filter { statuses[$0] == .missing }
        let validActivityCount = activityMetrics.filter { statuses[$0] == .valid || statuses[$0] == .partial }.count

        let confidence: ConfidenceLevel
        if missingCritical.count >= 2 {
            confidence = .low
        } else if missingCritical.count == 1 {
            confidence = .medium
        } else if validActivityCount >= 2 {
            confidence = .high
        } else {
            confidence = .medium
        }

        let reasons = buildMissingReasons(statuses: statuses, recentMetrics: recentMetrics)
        let shouldAsk = confidence != .high || !reasons.isEmpty
        let suggestedQ = shouldAsk ? suggestedQuestion(missingCritical: missingCritical, missingReasons: reasons) : nil

        return (confidence, reasons, shouldAsk, suggestedQ)
    }

    private func buildMissingReasons(
        statuses: [HealthMetric: MetricStatus],
        recentMetrics: [DailyHealthMetrics]?
    ) -> [String] {
        var reasons: [String] = []

        for metric in HealthMetric.allCases {
            guard statuses[metric] == .missing else { continue }

            let base = missingReason(for: metric)
            // Append consecutive-days context when history is available
            if let history = recentMetrics, !history.isEmpty {
                let consecutive = consecutiveMissingDays(for: metric, in: history)
                if consecutive >= 7 {
                    reasons.append("\(base) Sleep data has been missing for \(consecutive) consecutive days. Check Apple Watch → Sleep settings: sleep tracking may be disabled.")
                    continue
                } else if consecutive >= 3 && metric == .sleepHours {
                    reasons.append("\(base) Sleep data has been missing for \(consecutive) consecutive days. Is your Apple Watch being worn overnight?")
                    continue
                } else if consecutive >= 3 && (metric == .hrv || metric == .restingHeartRate) {
                    reasons.append("\(base) Recovery data has been missing for \(consecutive) consecutive days. Consider wearing your Apple Watch during sleep for 5+ nights to establish a reliable baseline.")
                    continue
                }
            }
            reasons.append(base)
        }

        // Sync-delay hint: key recovery/activity metrics missing today but present yesterday
        if let history = recentMetrics, !history.isEmpty {
            let keyMetrics: [HealthMetric] = [.sleepHours, .hrv, .restingHeartRate, .steps, .activeEnergyKcal, .exerciseMinutes]
            let todayKeyMetricsMissing = keyMetrics.allSatisfy { statuses[$0] == .missing || statuses[$0] == .partial }
            let previousDayHasData = history.dropLast().last.map { day in
                keyMetrics.contains { day.perMetricStatus[$0] == .valid }
            } ?? false
            if todayKeyMetricsMissing && previousDayHasData {
                reasons.append("Apple Watch data may still be syncing. If Apple Watch was worn, wait a few minutes and refresh.")
            }
        }

        return reasons
    }

    private func missingReason(for metric: HealthMetric) -> String {
        switch metric {
        case .sleepHours:
            return "Sleep data is missing, possibly because Apple Watch was not worn overnight or sleep tracking is disabled."
        case .hrv:
            return "HRV data is missing, which limits recovery interpretation."
        case .restingHeartRate:
            return "Resting heart rate is missing, which limits strain and recovery interpretation."
        case .steps:
            return "Step count is missing."
        case .activeEnergyKcal:
            return "Active energy is missing."
        case .exerciseMinutes:
            return "Exercise minutes are missing."
        case .workouts:
            return "Workout records could not be queried."
        }
    }

    /// Count how many consecutive days (counting backwards from the most recent day) a metric is missing.
    private func consecutiveMissingDays(for metric: HealthMetric, in sortedMetrics: [DailyHealthMetrics]) -> Int {
        var count = 0
        for day in sortedMetrics.reversed() {
            if day.perMetricStatus[metric] == .missing {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private func suggestedQuestion(missingCritical: [HealthMetric], missingReasons: [String]) -> String? {
        guard !missingReasons.isEmpty else { return nil }
        if missingCritical.contains(.sleepHours) && missingCritical.contains(.hrv) {
            return "Did you wear your Apple Watch while sleeping last night?"
        }
        if missingCritical.contains(.sleepHours) {
            return "Did anything unusual affect your sleep tracking last night?"
        }
        if missingCritical.contains(.hrv) || missingCritical.contains(.restingHeartRate) {
            return "Was your watch worn normally overnight and this morning?"
        }
        return "Is any Apple Health permission disabled for activity or workout data?"
    }
}

// MARK: - Consecutive missing summary (for baseline-guidance use)

extension DataCoverageLayer {
    /// Returns a summary of data completeness across the provided history window.
    public func completenessSummary(metrics: [DailyHealthMetrics]) -> CompletenessSummary {
        let criticalMetrics: [HealthMetric] = [.sleepHours, .hrv, .restingHeartRate]
        let totalDays = metrics.count
        var daysWithData: [HealthMetric: Int] = [:]
        for metric in criticalMetrics {
            daysWithData[metric] = metrics.filter { $0.perMetricStatus[metric] == .valid || $0.perMetricStatus[metric] == .partial }.count
        }

        // A day is "complete" if at least 2 critical recovery metrics have data
        let completeDays = metrics.filter { day in
            criticalMetrics.filter { day.perMetricStatus[$0] == .valid || day.perMetricStatus[$0] == .partial }.count >= 2
        }.count

        return CompletenessSummary(
            totalDays: totalDays,
            completeRecoveryDays: completeDays,
            daysWithSleep: daysWithData[.sleepHours] ?? 0,
            daysWithHRV: daysWithData[.hrv] ?? 0,
            daysWithRestingHR: daysWithData[.restingHeartRate] ?? 0
        )
    }
}

public struct CompletenessSummary: Sendable {
    public let totalDays: Int
    public let completeRecoveryDays: Int
    public let daysWithSleep: Int
    public let daysWithHRV: Int
    public let daysWithRestingHR: Int

    public init(totalDays: Int, completeRecoveryDays: Int, daysWithSleep: Int, daysWithHRV: Int, daysWithRestingHR: Int) {
        self.totalDays = totalDays
        self.completeRecoveryDays = completeRecoveryDays
        self.daysWithSleep = daysWithSleep
        self.daysWithHRV = daysWithHRV
        self.daysWithRestingHR = daysWithRestingHR
    }

    /// Returns a weight multiplier (0.0–1.0) for how much a metric should contribute
    /// to the Body Budget Score based on its data quality.
    /// - Parameter metric: The health metric to evaluate.
    /// - Returns: 1.0 for valid data, 0.5 for partial, 0.0 for missing.
    public func confidenceWeight(for metric: HealthMetric, in statuses: [HealthMetric: MetricStatus]) -> Double {
        switch statuses[metric] {
        case .valid:   return 1.0
        case .partial: return 0.5
        case .missing, .none: return 0.0
        }
    }

    /// True when the user likely hasn't established enough recovery data for a reliable baseline.
    public var isBaselineInsufficient: Bool {
        completeRecoveryDays < 7
    }

    public var baselineGuidanceMessage: String? {
        guard isBaselineInsufficient else { return nil }
        if completeRecoveryDays <= 2 {
            return "Just getting started! Wear your Apple Watch during sleep for 5–7 nights to build a reliable recovery baseline. Until then, recommendations will be conservative."
        }
        return "Building your baseline (\(completeRecoveryDays)/7 days with recovery data). Keep wearing your Apple Watch during sleep — recommendations will become more personalized soon."
    }
}
