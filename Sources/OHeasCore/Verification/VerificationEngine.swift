//
//  VerificationEngine.swift
//  OHeas
//
//  Verifies yesterday recommendation against today metrics.
//  用今日指标验证昨日建议。
//


import Foundation

public struct VerificationEngine: Sendable {
    public init() {}

    public func verify(
        yesterday recommendation: CoachRecommendation,
        feedback: DailyFeedback?,
        today: DailyHealthMetrics,
        baseline: HealthBaseline,
        dataQuality: DataQualityReport
    ) -> VerificationReport {
        if dataQuality.overallConfidence == .low {
            return VerificationReport(
                date: today.date,
                recommendationId: recommendation.id,
                outcome: .unclear,
                confidence: .low,
                findings: dataQuality.missingReasons,
                explanation: "Key data is missing, so the recommendation can only be reviewed conservatively."
            )
        }

        guard let feedback else {
            return VerificationReport(
                date: today.date,
                recommendationId: recommendation.id,
                outcome: .unclear,
                confidence: .low,
                findings: ["No feedback was recorded for yesterday's recommendation."],
                explanation: "Without adherence and subjective scores, the loop cannot attribute any change."
            )
        }

        if feedback.adherence == .skipped {
            return VerificationReport(
                date: today.date,
                recommendationId: recommendation.id,
                outcome: .unclear,
                confidence: .medium,
                findings: ["The recommendation was skipped."],
                explanation: "Because the action was skipped, today's metrics cannot be used to judge whether the recommendation worked."
            )
        }

        let findings = metricFindings(today: today, baseline: baseline, feedback: feedback)
        let positiveCount = findings.filter { $0.isPositive }.count
        let negativeCount = findings.filter { $0.isNegative }.count

        let outcome: VerificationOutcome
        let explanation: String
        let pattern: String?
        if positiveCount >= 2, feedback.subjectiveEnergy >= 6 {
            outcome = .likelyHelped
            explanation = "The action was completed or partially completed, and multiple next-day indicators look better relative to baseline. This only suggests it may have helped."
            pattern = "Low-intensity recovery actions may support better next-day recovery when recovery signals are soft."
        } else if negativeCount >= 2 {
            outcome = .likelyNotHelped
            explanation = "The action was completed or partially completed, but several indicators still look worse than baseline. This does not prove the advice failed."
            pattern = nil
        } else {
            outcome = .neutral
            explanation = "The next-day pattern is mixed, so the safest interpretation is neutral."
            pattern = nil
        }

        return VerificationReport(
            date: today.date,
            recommendationId: recommendation.id,
            outcome: outcome,
            confidence: dataQuality.overallConfidence,
            findings: findings.map(\.text),
            explanation: explanation,
            learnedPatternCandidate: pattern
        )
    }

    private func metricFindings(today: DailyHealthMetrics, baseline: HealthBaseline, feedback: DailyFeedback) -> [MetricFinding] {
        var findings: [MetricFinding] = []

        if let sleep = today.sleepHours, let baselineSleep = baseline.averageSleepHours {
            let positive = sleep >= baselineSleep
            findings.append(.init(text: "Sleep \(sleep.roundedString())h vs baseline \(baselineSleep.roundedString())h.", isPositive: positive, isNegative: sleep < baselineSleep - 0.75))
        }
        if let hrv = today.hrv, let baselineHRV = baseline.averageHRV {
            let positive = hrv >= baselineHRV
            findings.append(.init(text: "HRV \(hrv.roundedString())ms vs baseline \(baselineHRV.roundedString())ms.", isPositive: positive, isNegative: hrv < baselineHRV * 0.85))
        }
        if let rhr = today.restingHeartRate, let baselineRHR = baseline.averageRestingHeartRate {
            let positive = rhr <= baselineRHR
            findings.append(.init(text: "Resting HR \(rhr.roundedString())bpm vs baseline \(baselineRHR.roundedString())bpm.", isPositive: positive, isNegative: rhr > baselineRHR + 5))
        }

        findings.append(
            .init(
                text: "Subjective energy \(feedback.subjectiveEnergy)/10, soreness \(feedback.soreness)/10, stress \(feedback.stress)/10.",
                isPositive: feedback.subjectiveEnergy >= 7 && feedback.stress <= 5,
                isNegative: feedback.subjectiveEnergy <= 3 || feedback.stress >= 8
            )
        )

        return findings
    }
}

private struct MetricFinding {
    var text: String
    var isPositive: Bool
    var isNegative: Bool
}
