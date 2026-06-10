//
//  WeeklyReviewEngine.swift
//  OHeas
//
//  Computes weekly adherence, effectiveness, and insights.
//  计算周完成率、效果和洞察。
//


import Foundation

public struct WeeklyReviewEngine: Sendable {
    private let calendar: Calendar
    private let safetyGuardrail: SafetyGuardrail

    public init(calendar: Calendar = .current, safetyGuardrail: SafetyGuardrail = SafetyGuardrail()) {
        self.calendar = calendar
        self.safetyGuardrail = safetyGuardrail
    }

    public func review(
        plan: WeeklyPlan,
        feedbackHistory: [DailyFeedback],
        recommendationHistory: [CoachRecommendation],
        verificationReports: [VerificationReport],
        experimentHistory: [PersonalExperiment],
        memory: UserMemory,
        metricsForWeek: [DailyHealthMetrics]
    ) -> WeeklyReview {
        let completed = plan.days.filter { $0.status == .completed }.count
        let skipped = plan.days.filter { $0.status == .skipped }.count
        let completionRate = plan.days.isEmpty ? 0 : Double(completed) / Double(plan.days.count)
        let adjusted = plan.days.filter { $0.status == .adjusted }.count
        let missingDays = metricsForWeek.filter {
            $0.perMetricStatus[.sleepHours] == .missing || $0.perMetricStatus[.hrv] == .missing
        }.count
        let confidence: ConfidenceLevel = missingDays >= 3 ? .low : (metricsForWeek.count >= 5 ? .medium : .low)

        let avgSleep = average(metricsForWeek.compactMap(\.sleepHours))
        let avgSteps = average(metricsForWeek.compactMap(\.steps))
        let experimentSummary = experimentHistory.last(where: { $0.status == .completed })?.result?.summary
            ?? "No completed experiment result this week."

        let review = WeeklyReview(
            weekStartDate: plan.weekStartDate,
            completionRate: completionRate,
            adherenceSummary: "Completed \(completed) of \(plan.days.count) planned days. Skipped \(skipped). Adjusted \(adjusted). Skipped plans are not treated as failed health advice.",
            recoverySummary: avgSleep.map { "Average sleep was \($0.roundedString())h. \(missingDays) days had missing sleep or HRV data." } ?? "Recovery summary is limited by missing sleep data.",
            activitySummary: avgSteps.map { "Average steps were \($0.roundedString()) per day." } ?? "Activity summary is limited by missing step data.",
            experimentSummary: experimentSummary,
            usefulPatterns: memory.knownPatterns.prefix(3).map { $0.description },
            planAdjustmentsForNextWeek: nextWeekAdjustments(completionRate: completionRate, confidence: confidence, adjusted: adjusted),
            memoryUpdates: verificationReports.suffix(3).compactMap(\.learnedPatternCandidate),
            confidence: confidence
        )
        return safetyGuardrail.sanitize(review: review).0
    }

    private func nextWeekAdjustments(completionRate: Double, confidence: ConfidenceLevel, adjusted: Int) -> [String] {
        var output: [String] = []
        if confidence == .low {
            output.append("Prioritize data coverage before increasing intensity.")
        }
        if completionRate < 0.5 {
            output.append("Make next week's plan smaller and easier to complete.")
        }
        if adjusted >= 2 {
            output.append("Keep adaptive recovery buffers in the plan.")
        }
        if output.isEmpty {
            output.append("Keep a similar structure and make only small changes.")
        }
        return output
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
