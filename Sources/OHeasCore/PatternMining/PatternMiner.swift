//
//  PatternMiner.swift
//  OHeas
//
//  Mines recurring health patterns from daily metrics and feedback.
//  从每日指标和反馈中挖掘重复出现的健康模式。
//


import Foundation

public struct PatternMiningResult: Codable, Equatable, Sendable {
    public var patterns: [KnownPattern]
    public var successfulInterventions: [InterventionMemory]
    public var ineffectiveInterventions: [InterventionMemory]

    public init(
        patterns: [KnownPattern] = [],
        successfulInterventions: [InterventionMemory] = [],
        ineffectiveInterventions: [InterventionMemory] = []
    ) {
        self.patterns = patterns
        self.successfulInterventions = successfulInterventions
        self.ineffectiveInterventions = ineffectiveInterventions
    }
}

public struct PatternMiner: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func mine(
        recentMetrics: [DailyHealthMetrics],
        feedbackHistory: [DailyFeedback],
        verificationReports: [VerificationReport],
        recommendationHistory: [CoachRecommendation],
        baseline: HealthBaseline,
        preferredLanguage: String = "en"
    ) -> PatternMiningResult {
        let zh = preferredLanguage == "zh"
        guard recentMetrics.count >= 5 else {
            return PatternMiningResult()
        }

        var patterns: [KnownPattern] = []
        if let sleepPattern = sleepRecoveryPattern(recentMetrics: recentMetrics, feedbackHistory: feedbackHistory, baseline: baseline, zh: zh) {
            patterns.append(sleepPattern)
        }
        if let activityPattern = highActivityRecoveryPattern(recentMetrics: recentMetrics, baseline: baseline, zh: zh) {
            patterns.append(activityPattern)
        }
        if let coveragePattern = lowDataCoveragePattern(recentMetrics: recentMetrics, zh: zh) {
            patterns.append(coveragePattern)
        }

        return PatternMiningResult(
            patterns: patterns,
            successfulInterventions: successfulInterventions(reports: verificationReports, recommendations: recommendationHistory, zh: zh),
            ineffectiveInterventions: ineffectiveInterventions(reports: verificationReports, feedback: feedbackHistory, recommendations: recommendationHistory, zh: zh)
        )
    }

    private func sleepRecoveryPattern(
        recentMetrics: [DailyHealthMetrics],
        feedbackHistory: [DailyFeedback],
        baseline: HealthBaseline,
        zh: Bool
    ) -> KnownPattern? {
        guard let baselineSleep = baseline.averageSleepHours else { return nil }
        var examples: [String] = []

        for index in recentMetrics.indices.dropLast() {
            let day = recentMetrics[index]
            let next = recentMetrics[index + 1]
            guard let sleep = day.sleepHours, baselineSleep - sleep >= 0.75 else { continue }

            let hrvWorse = worse(next.hrv, than: baseline.averageHRV, lowerIsWorse: true, threshold: 0.85)
            let rhrWorse = worse(next.restingHeartRate, than: baseline.averageRestingHeartRate, lowerIsWorse: false, absoluteThreshold: 5)
            let lowEnergy = feedbackHistory.first { calendar.isDate($0.date, inSameDayAs: next.date) }?.subjectiveEnergy ?? 10

            if hrvWorse || rhrWorse || lowEnergy <= 4 {
                let date = day.date.formatted(date: .abbreviated, time: .omitted)
                examples.append(zh
                    ? "\(date) 睡眠偏短后，次日恢复信号偏弱。"
                    : "Short sleep on \(date) was followed by softer recovery signals."
                )
            }
        }

        guard examples.count >= 2 else { return nil }
        return KnownPattern(
            title: zh ? "睡眠偏短可能影响次日恢复" : "Short sleep may affect next-day recovery",
            description: zh ? "睡眠偏短后，次日恢复信号可能偏弱，包括 HRV、静息心率或主观精力。" : "Short sleep was followed by softer next-day recovery signals (HRV, RHR, or energy).",
            relatedMetrics: ["sleepHours", "hrv", "restingHeartRate", "subjectiveEnergy"],
            confidence: examples.count >= 3 ? .medium : .low,
            evidenceCount: examples.count,
            firstObservedAt: recentMetrics.first?.date ?? Date(),
            lastObservedAt: recentMetrics.last?.date ?? Date(),
            examples: Array(examples.prefix(3))
        )
    }

    private func highActivityRecoveryPattern(recentMetrics: [DailyHealthMetrics], baseline: HealthBaseline, zh: Bool) -> KnownPattern? {
        guard let baselineSteps = baseline.averageSteps else { return nil }
        var examples: [String] = []

        for index in recentMetrics.indices.dropLast() {
            let day = recentMetrics[index]
            let next = recentMetrics[index + 1]
            let highSteps = day.steps.map { $0 >= baselineSteps * 1.35 } ?? false
            let highWorkout = day.workouts.reduce(0) { $0 + $1.durationMinutes } >= 60
            guard highSteps || highWorkout else { continue }

            let hrvWorse = worse(next.hrv, than: baseline.averageHRV, lowerIsWorse: true, threshold: 0.85)
            let rhrWorse = worse(next.restingHeartRate, than: baseline.averageRestingHeartRate, lowerIsWorse: false, absoluteThreshold: 5)
            if hrvWorse || rhrWorse {
                let date = day.date.formatted(date: .abbreviated, time: .omitted)
                examples.append(zh
                    ? "\(date) 活动量较高后，次日恢复信号偏弱。"
                    : "Higher activity on \(date) was followed by softer recovery signals."
                )
            }
        }

        guard examples.count >= 2 else { return nil }
        return KnownPattern(
            title: zh ? "高活动量后可能需要更长恢复" : "High activity may need longer recovery",
            description: zh ? "较高活动负荷后，次日恢复信号可能偏弱。" : "Higher activity load was followed by softer recovery signals the next day.",
            relatedMetrics: ["steps", "workouts", "hrv", "restingHeartRate"],
            confidence: examples.count >= 3 ? .medium : .low,
            evidenceCount: examples.count,
            firstObservedAt: recentMetrics.first?.date ?? Date(),
            lastObservedAt: recentMetrics.last?.date ?? Date(),
            examples: Array(examples.prefix(3))
        )
    }

    private func lowDataCoveragePattern(recentMetrics: [DailyHealthMetrics], zh: Bool) -> KnownPattern? {
        let last7 = Array(recentMetrics.suffix(7))
        let missingCount = last7.filter { day in
            day.perMetricStatus[.sleepHours] == .missing || day.perMetricStatus[.hrv] == .missing
        }.count

        guard missingCount >= 3 else { return nil }
        return KnownPattern(
            title: zh ? "恢复数据覆盖不足可能影响建议" : "Recovery data coverage may be limiting advice",
            description: zh ? "最近 7 天睡眠或 HRV 数据覆盖不足，会降低恢复判断的置信度。" : "Sleep or HRV data coverage was insufficient in the last 7 days, reducing recovery confidence.",
            relatedMetrics: ["sleepHours", "hrv", "dataQuality"],
            confidence: .medium,
            evidenceCount: missingCount,
            firstObservedAt: last7.first?.date ?? Date(),
            lastObservedAt: last7.last?.date ?? Date(),
            examples: [zh ? "最近 7 天有 \(missingCount) 天缺少睡眠或 HRV 数据。" : "\(missingCount) of the last 7 days had missing sleep or HRV data."]
        )
    }

    private func successfulInterventions(
        reports: [VerificationReport],
        recommendations: [CoachRecommendation],
        zh: Bool
    ) -> [InterventionMemory] {
        reports.compactMap { report in
            guard report.outcome == .likelyHelped,
                  let recommendation = recommendations.first(where: { $0.id == report.recommendationId })
            else { return nil }
            return InterventionMemory(
                intervention: recommendation.recommendation,
                observedEffect: zh ? "这项行动后，次日至少两个指标有所改善。" : "This intervention was followed by improvement in at least two metrics the next day.",
                targetMetrics: recommendation.tomorrowVerification.map(\.metric),
                confidence: .low,
                evidenceCount: 1,
                lastObservedAt: report.date
            )
        }
    }

    private func ineffectiveInterventions(
        reports: [VerificationReport],
        feedback: [DailyFeedback],
        recommendations: [CoachRecommendation],
        zh: Bool
    ) -> [InterventionMemory] {
        let completedIds = Set(feedback.filter { $0.adherence == .completed }.map(\.recommendationId))
        let grouped = Dictionary(grouping: reports.filter { completedIds.contains($0.recommendationId) }) { report in
            recommendations.first(where: { $0.id == report.recommendationId })?.recommendation ?? ""
        }

        return grouped.compactMap { intervention, reports in
            guard !intervention.isEmpty, reports.count >= 3 else { return nil }
            let helped = reports.contains { $0.outcome == .likelyHelped }
            guard !helped else { return nil }
            return InterventionMemory(
                intervention: intervention,
                observedEffect: zh ? "这项行动已多次完成，但没有出现稳定改善。" : "This intervention was completed multiple times without consistent improvement.",
                targetMetrics: ["sleepHours", "hrv", "restingHeartRate", "subjectiveEnergy"],
                confidence: .low,
                evidenceCount: reports.count,
                lastObservedAt: reports.map(\.date).max() ?? Date()
            )
        }
    }

    private func worse(_ value: Double?, than baseline: Double?, lowerIsWorse: Bool, threshold: Double = 0.85, absoluteThreshold: Double = 0) -> Bool {
        guard let value, let baseline else { return false }
        if lowerIsWorse {
            return value < baseline * threshold
        }
        return value > baseline + absoluteThreshold
    }
}
