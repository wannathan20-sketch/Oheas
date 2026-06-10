//
//  EffectivenessAnalyzer.swift
//  OHeas
//
//  Analyzes long-term effectiveness of recommendations and interventions.
//  分析建议和干预的长期效果。
//


import Foundation

public struct EffectivenessReport: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var periodStart: Date
    public var periodEnd: Date
    public var recommendationAdherenceRate: Double
    public var planCompletionRate: Double
    public var experimentCompletionRate: Double
    public var likelyHelpedRate: Double
    public var unclearRate: Double
    public var dataCoverageRate: Double
    public var averageConfidence: Double
    public var mostPromisingInterventions: [String]
    public var weakestAreas: [String]
    public var summary: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        periodStart: Date,
        periodEnd: Date,
        recommendationAdherenceRate: Double,
        planCompletionRate: Double,
        experimentCompletionRate: Double,
        likelyHelpedRate: Double,
        unclearRate: Double,
        dataCoverageRate: Double,
        averageConfidence: Double,
        mostPromisingInterventions: [String],
        weakestAreas: [String],
        summary: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.recommendationAdherenceRate = recommendationAdherenceRate
        self.planCompletionRate = planCompletionRate
        self.experimentCompletionRate = experimentCompletionRate
        self.likelyHelpedRate = likelyHelpedRate
        self.unclearRate = unclearRate
        self.dataCoverageRate = dataCoverageRate
        self.averageConfidence = averageConfidence
        self.mostPromisingInterventions = mostPromisingInterventions
        self.weakestAreas = weakestAreas
        self.summary = summary
        self.createdAt = createdAt
    }
}

public struct EffectivenessAnalyzer: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func analyze(
        recommendations: [CoachRecommendation],
        feedbackHistory: [DailyFeedback],
        verificationReports: [VerificationReport],
        experiments: [PersonalExperiment],
        weeklyPlans: [WeeklyPlan],
        dailyMetrics: [DailyHealthMetrics],
        dataQualityHistory: [DataQualityReport] = [],
        preferredLanguage: String = "en"
    ) -> EffectivenessReport {
        let zh = preferredLanguage == "zh"
        let dates = dailyMetrics.map(\.date) + recommendations.map(\.date) + weeklyPlans.flatMap { $0.days.map(\.date) }
        let periodStart = dates.min() ?? Date()
        let periodEnd = dates.max() ?? Date()

        let feedbackByRecommendation = Dictionary(grouping: feedbackHistory, by: \.recommendationId)
        let recommendationsWithFeedback = recommendations.filter { feedbackByRecommendation[$0.id]?.isEmpty == false }
        let completedFeedback = recommendationsWithFeedback.filter { recommendation in
            feedbackByRecommendation[recommendation.id]?.contains { $0.adherence == .completed || $0.adherence == .partial } == true
        }.count
        let recommendationAdherenceRate = rate(completedFeedback, recommendationsWithFeedback.count)

        let plannedDays = weeklyPlans.flatMap(\.days)
        let completedPlanDays = plannedDays.filter { $0.status == .completed }.count
        let planCompletionRate = rate(completedPlanDays, plannedDays.count)

        let startedExperiments = experiments.filter { [.active, .completed, .paused, .cancelled].contains($0.status) }
        let completedExperiments = startedExperiments.filter { $0.status == .completed }.count
        let experimentCompletionRate = rate(completedExperiments, startedExperiments.count)

        let verifiable = verificationReports.filter { $0.outcome != .unclear }
        let likelyHelped = verifiable.filter { $0.outcome == .likelyHelped }.count
        let likelyHelpedRate = rate(likelyHelped, verifiable.count)
        let unclearRate = rate(verificationReports.filter { $0.outcome == .unclear }.count, verificationReports.count)

        let coverageDays = dailyMetrics.filter { metrics in
            let recoveryStatuses = [.sleepHours, .hrv, .restingHeartRate].compactMap { metrics.perMetricStatus[$0] }
            guard recoveryStatuses.count >= 3 else { return false }
            return recoveryStatuses.allSatisfy { $0 == .valid || $0 == .partial }
        }.count
        let dataCoverageRate = rate(coverageDays, dailyMetrics.count)

        let confidenceValues = confidenceScores(from: verificationReports, qualityHistory: dataQualityHistory, metrics: dailyMetrics)
        var averageConfidence = confidenceValues.isEmpty ? dataCoverageRate : confidenceValues.reduce(0, +) / Double(confidenceValues.count)
        if dataCoverageRate < 0.7 {
            averageConfidence = min(averageConfidence, 0.45)
        }

        let promising = mostPromisingInterventions(
            recommendations: recommendations,
            verificationReports: verificationReports,
            experiments: experiments
        )
        let weakest = weakestAreas(
            recommendationAdherenceRate: recommendationAdherenceRate,
            planCompletionRate: planCompletionRate,
            experimentCompletionRate: experimentCompletionRate,
            dataCoverageRate: dataCoverageRate,
            unclearRate: unclearRate,
            zh: zh
        )
        let summary = summary(
            dataCoverageRate: dataCoverageRate,
            likelyHelpedRate: likelyHelpedRate,
            averageConfidence: averageConfidence,
            weakestAreas: weakest,
            zh: zh
        )

        return EffectivenessReport(
            periodStart: periodStart,
            periodEnd: periodEnd,
            recommendationAdherenceRate: recommendationAdherenceRate,
            planCompletionRate: planCompletionRate,
            experimentCompletionRate: experimentCompletionRate,
            likelyHelpedRate: likelyHelpedRate,
            unclearRate: unclearRate,
            dataCoverageRate: dataCoverageRate,
            averageConfidence: averageConfidence,
            mostPromisingInterventions: promising,
            weakestAreas: weakest,
            summary: summary
        )
    }

    private func confidenceScores(
        from reports: [VerificationReport],
        qualityHistory: [DataQualityReport],
        metrics: [DailyHealthMetrics]
    ) -> [Double] {
        let reportScores = reports.map { score($0.confidence) }
        let qualityScores = qualityHistory.map { score($0.overallConfidence) }
        if !reportScores.isEmpty || !qualityScores.isEmpty {
            return reportScores + qualityScores
        }
        return metrics.map { metrics in
            let missing = [.sleepHours, .hrv, .restingHeartRate].filter { metrics.perMetricStatus[$0] == .missing }.count
            return missing >= 2 ? 0.25 : 0.75
        }
    }

    private func mostPromisingInterventions(
        recommendations: [CoachRecommendation],
        verificationReports: [VerificationReport],
        experiments: [PersonalExperiment]
    ) -> [String] {
        let recommendationById = Dictionary(uniqueKeysWithValues: recommendations.map { ($0.id, $0) })
        var items = verificationReports.compactMap { report -> String? in
            guard report.outcome == .likelyHelped, let recommendation = recommendationById[report.recommendationId] else {
                return nil
            }
            return recommendation.recommendation
        }
        items.append(contentsOf: experiments.compactMap { experiment in
            experiment.result?.outcome == .likelyHelped ? experiment.intervention : nil
        })
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }

    private func weakestAreas(
        recommendationAdherenceRate: Double,
        planCompletionRate: Double,
        experimentCompletionRate: Double,
        dataCoverageRate: Double,
        unclearRate: Double,
        zh: Bool
    ) -> [String] {
        var areas: [String] = []
        if recommendationAdherenceRate < 0.5 { areas.append(zh ? "建议执行跟进" : "Recommendation follow-through") }
        if planCompletionRate < 0.5 { areas.append(zh ? "周计划完成度" : "Weekly plan completion") }
        if experimentCompletionRate < 0.5 { areas.append(zh ? "实验完成度" : "Experiment completion") }
        if dataCoverageRate < 0.75 { areas.append(zh ? "穿戴设备数据覆盖" : "Wearable data coverage") }
        if unclearRate > 0.5 { areas.append(zh ? "验证清晰度" : "Verification clarity") }
        return areas.isEmpty ? [(zh ? "现有数据中没有明显的薄弱环节。" : "No major weak area in the available data.")] : areas
    }

    private func summary(dataCoverageRate: Double, likelyHelpedRate: Double, averageConfidence: Double, weakestAreas: [String], zh: Bool) -> String {
        if zh {
            var parts = [
                "本报告仅展示观察到的生活方式趋势，不构成医学证明。",
                "在可验证的案例中，可能有效率为 \(percent(likelyHelpedRate))。"
            ]
            if dataCoverageRate < 0.75 {
                parts.append("数据覆盖有限，结论应保持谨慎。")
            }
            parts.append("总体置信度为 \(percent(averageConfidence))。")
            if !weakestAreas.isEmpty {
                parts.append("主要改进方向：\(weakestAreas.first ?? "无")。")
            }
            return parts.joined(separator: " ")
        }
        var parts = [
            "This report shows observed lifestyle trends only, not medical proof.",
            "Likely-helped rate is \(percent(likelyHelpedRate)) among verifiable cases."
        ]
        if dataCoverageRate < 0.75 {
            parts.append("Data coverage is limited, so conclusions should stay cautious.")
        }
        parts.append("Overall confidence is \(percent(averageConfidence)).")
        if !weakestAreas.isEmpty {
            parts.append("Main improvement area: \(weakestAreas.first ?? "none").")
        }
        return parts.joined(separator: " ")
    }

    private func rate(_ numerator: Int, _ denominator: Int) -> Double {
        guard denominator > 0 else { return 0 }
        return Double(numerator) / Double(denominator)
    }

    private func score(_ confidence: ConfidenceLevel) -> Double {
        switch confidence {
        case .high: 1
        case .medium: 0.65
        case .low: 0.3
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
