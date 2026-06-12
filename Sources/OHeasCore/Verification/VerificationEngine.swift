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
        dataQuality: DataQualityReport,
        preferredLanguage: String = "en"
    ) -> VerificationReport {
        let zh = preferredLanguage == "zh"
        if dataQuality.overallConfidence == .low {
            return VerificationReport(
                date: today.date,
                recommendationId: recommendation.id,
                outcome: .unclear,
                confidence: .low,
                findings: localizedMissingReasons(dataQuality.missingReasons, zh: zh),
                explanation: zh
                    ? "关键数据缺失，因此只能保守回顾这条建议。"
                    : "Key data is missing, so the recommendation can only be reviewed conservatively."
            )
        }

        guard let feedback else {
            return VerificationReport(
                date: today.date,
                recommendationId: recommendation.id,
                outcome: .unclear,
                confidence: .low,
                findings: [zh ? "昨天的建议还没有记录反馈。" : "No feedback was recorded for yesterday's recommendation."],
                explanation: zh
                    ? "缺少完成情况和主观评分，暂时无法判断变化是否与建议有关。"
                    : "Without adherence and subjective scores, the loop cannot attribute any change."
            )
        }

        if feedback.adherence == .skipped {
            return VerificationReport(
                date: today.date,
                recommendationId: recommendation.id,
                outcome: .unclear,
                confidence: .medium,
                findings: [zh ? "这条建议昨天被跳过了。" : "The recommendation was skipped."],
                explanation: zh
                    ? "因为行动没有执行，今天的指标不能用来判断建议是否有效。"
                    : "Because the action was skipped, today's metrics cannot be used to judge whether the recommendation worked."
            )
        }

        let findings = metricFindings(today: today, baseline: baseline, feedback: feedback, zh: zh)
        let positiveCount = findings.filter { $0.isPositive }.count
        let negativeCount = findings.filter { $0.isNegative }.count

        let outcome: VerificationOutcome
        let explanation: String
        let pattern: String?
        if positiveCount >= 2, feedback.subjectiveEnergy >= 6 {
            outcome = .likelyHelped
            explanation = zh
                ? "行动已完成或部分完成，多个次日指标相对基线更好。这只能说明它可能有帮助。"
                : "The action was completed or partially completed, and multiple next-day indicators look better relative to baseline. This only suggests it may have helped."
            pattern = zh
                ? "当恢复信号偏弱时，低强度恢复行动可能有助于次日恢复。"
                : "Low-intensity recovery actions may support better next-day recovery when recovery signals are soft."
        } else if negativeCount >= 2 {
            outcome = .likelyNotHelped
            explanation = zh
                ? "行动已完成或部分完成，但几个指标仍低于基线表现。这并不能证明建议无效。"
                : "The action was completed or partially completed, but several indicators still look worse than baseline. This does not prove the advice failed."
            pattern = nil
        } else {
            outcome = .neutral
            explanation = zh
                ? "次日表现有好有坏，因此最稳妥的解读是中性。"
                : "The next-day pattern is mixed, so the safest interpretation is neutral."
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

    private func metricFindings(today: DailyHealthMetrics, baseline: HealthBaseline, feedback: DailyFeedback, zh: Bool) -> [MetricFinding] {
        var findings: [MetricFinding] = []

        if let sleep = today.sleepHours, let baselineSleep = baseline.averageSleepHours {
            let positive = sleep >= baselineSleep
            findings.append(.init(
                text: zh
                    ? "睡眠 \(sleep.roundedString()) 小时，对比基线 \(baselineSleep.roundedString()) 小时。"
                    : "Sleep \(sleep.roundedString())h vs baseline \(baselineSleep.roundedString())h.",
                isPositive: positive,
                isNegative: sleep < baselineSleep - 0.75
            ))
        }
        if let hrv = today.hrv, let baselineHRV = baseline.averageHRV {
            let positive = hrv >= baselineHRV
            findings.append(.init(
                text: zh
                    ? "HRV \(hrv.roundedString())ms，对比基线 \(baselineHRV.roundedString())ms。"
                    : "HRV \(hrv.roundedString())ms vs baseline \(baselineHRV.roundedString())ms.",
                isPositive: positive,
                isNegative: hrv < baselineHRV * 0.85
            ))
        }
        if let rhr = today.restingHeartRate, let baselineRHR = baseline.averageRestingHeartRate {
            let positive = rhr <= baselineRHR
            findings.append(.init(
                text: zh
                    ? "静息心率 \(rhr.roundedString())bpm，对比基线 \(baselineRHR.roundedString())bpm。"
                    : "Resting HR \(rhr.roundedString())bpm vs baseline \(baselineRHR.roundedString())bpm.",
                isPositive: positive,
                isNegative: rhr > baselineRHR + 5
            ))
        }

        findings.append(
            .init(
                text: zh
                    ? "主观精力 \(feedback.subjectiveEnergy)/10，酸痛 \(feedback.soreness)/10，压力 \(feedback.stress)/10。"
                    : "Subjective energy \(feedback.subjectiveEnergy)/10, soreness \(feedback.soreness)/10, stress \(feedback.stress)/10.",
                isPositive: feedback.subjectiveEnergy >= 7 && feedback.stress <= 5,
                isNegative: feedback.subjectiveEnergy <= 3 || feedback.stress >= 8
            )
        )

        return findings
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

private struct MetricFinding {
    var text: String
    var isPositive: Bool
    var isNegative: Bool
}
