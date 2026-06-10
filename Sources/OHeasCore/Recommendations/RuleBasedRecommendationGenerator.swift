//
//  RuleBasedRecommendationGenerator.swift
//  OHeas
//
//  Deterministic fallback recommendation engine (5 coach states).
//  确定性降级建议引擎（5 种教练状态）。
//


import Foundation

public struct RuleBasedRecommendationGenerator: Sendable {
    public init() {}

    public func generate(
        context: AgentContext,
        previousFeedback: DailyFeedback? = nil,
        yesterdayRecommendation: CoachRecommendation? = nil
    ) -> CoachRecommendation {
        let zh = context.preferredLanguage == "zh"
        let signalTypes = Set(context.detectedSignals.map(\.type))
        let state = state(for: context.dataQuality, signals: signalTypes)
        let confidence = context.dataQuality.overallConfidence

        return CoachRecommendation(
            date: context.todayMetrics.date,
            state: state,
            confidence: confidence,
            title: title(for: state, zh: zh),
            summary: summary(for: state, quality: context.dataQuality, zh: zh),
            evidence: evidence(from: context, zh: zh),
            recommendation: recommendation(for: state, zh: zh),
            tonightAction: tonightAction(for: state, zh: zh),
            tomorrowVerification: verificationMetrics(for: state, zh: zh),
            followupQuestion: followupQuestion(for: context.dataQuality, zh: zh),
            safetyNote: zh ? "仅为生活方式指导，不构成医学诊断。" : "Lifestyle guidance only. This is not a medical diagnosis."
        )
    }

    private func state(for quality: DataQualityReport, signals: Set<SignalType>) -> CoachState {
        if quality.overallConfidence == .low {
            return .uncertain
        }
        if signals.contains(.hrvLow), signals.contains(.restingHeartHigh), signals.contains(.sleepLow) {
            return .recoveryLow
        }
        if signals.contains(.activityHigh), signals.contains(.hrvLow) || signals.contains(.restingHeartHigh) || signals.contains(.sleepLow) {
            return .overloaded
        }
        if signals.contains(.activityLow), !signals.contains(.hrvLow), !signals.contains(.restingHeartHigh), !signals.contains(.sleepLow) {
            return .ready
        }
        return .balanced
    }

    private func title(for state: CoachState, zh: Bool) -> String {
        if zh {
            switch state {
            case .ready: "状态良好，可以适当增加活动"
            case .balanced: "身体状态平稳"
            case .recoveryLow: "恢复指标偏低"
            case .overloaded: "可能存在过度训练"
            case .uncertain: "数据不足，难以判断"
            }
        } else {
            switch state {
            case .ready: "Ready for a small build"
            case .balanced: "Balanced day"
            case .recoveryLow: "Recovery looks low"
            case .overloaded: "Possible overload"
            case .uncertain: "Data is too limited"
            }
        }
    }

    private func summary(for state: CoachState, quality: DataQualityReport, zh: Bool) -> String {
        if quality.overallConfidence == .low {
            return zh ? "关键恢复数据缺失，今天的建议保持保守。" : "Key recovery data is missing, so today's guidance stays conservative."
        }
        if zh {
            return switch state {
            case .ready: "恢复信号没有明显下降，活动量低于基线。"
            case .balanced: "现有指标未显示明显偏离基线。"
            case .recoveryLow: "睡眠、HRV 和静息心率显示今天恢复偏低。"
            case .overloaded: "较高活动量结合偏软的恢复信号，建议优先保护恢复。"
            case .uncertain: "可靠的恢复数据不足以做出强判断。"
            }
        } else {
            return switch state {
            case .ready: "Recovery signals do not show a major drop, while activity is below baseline."
            case .balanced: "Available metrics do not show a strong deviation from baseline."
            case .recoveryLow: "Sleep, HRV, and resting heart rate point toward lower recovery today."
            case .overloaded: "High activity combined with softer recovery signals suggests protecting recovery."
            case .uncertain: "There is not enough reliable recovery data for a strong interpretation."
            }
        }
    }

    private func evidence(from context: AgentContext, zh: Bool) -> [EvidenceItem] {
        if context.detectedSignals.isEmpty {
            return [
                EvidenceItem(
                    metric: "overall",
                    observation: zh ? "未检测到明显信号。" : "No strong signal detected.",
                    baselineComparison: zh ? "今天整体接近 14 天基线。" : "Today is broadly near the 14-day baseline.",
                    importance: zh ? "建议保持轻松、以维持为主。" : "Keeps the recommendation light and maintenance-oriented."
                )
            ]
        }

        return context.detectedSignals.map { signal in
            EvidenceItem(
                metric: signal.type.rawValue,
                observation: signal.evidence,
                baselineComparison: zh ? "与用户的 14 天基线对比。" : "Compared with the user's 14-day baseline.",
                importance: signal.explanation
            )
        }
    }

    private func recommendation(for state: CoachState, zh: Bool) -> String {
        if zh {
            switch state {
            case .ready: "进行一次轻松到中等的运动，控制在 30 分钟以内。"
            case .balanced: "保持日常节奏，额外增加 10 分钟散步。"
            case .recoveryLow: "今天以恢复为主，降低训练强度。"
            case .overloaded: "今天跳过高强度训练，改为低强度柔韧性活动。"
            case .uncertain: "选择低风险方案：轻松散步、补水，不要追求强度。"
            }
        } else {
            switch state {
            case .ready: "Do one easy-to-moderate movement session, capped at 30 minutes."
            case .balanced: "Keep your normal routine and add one 10-minute walk."
            case .recoveryLow: "Keep training easy today and choose recovery over intensity."
            case .overloaded: "Skip intense training today and use low-intensity mobility instead."
            case .uncertain: "Choose a low-risk option: an easy walk, hydration, and no intensity push."
            }
        }
    }

    private func tonightAction(for state: CoachState, zh: Bool) -> String {
        if zh {
            switch state {
            case .ready, .balanced: "保持固定的放松时间，避免晚上增加高强度任务。"
            case .recoveryLow, .overloaded, .uncertain: "提前 30 分钟开始放松，晚上保持低刺激环境。"
            }
        } else {
            switch state {
            case .ready, .balanced: "Keep a steady wind-down time and avoid adding late intense work."
            case .recoveryLow, .overloaded, .uncertain: "Start wind-down 30 minutes earlier and keep the evening low stimulation."
            }
        }
    }

    private func verificationMetrics(for state: CoachState, zh: Bool) -> [VerificationMetric] {
        [
            VerificationMetric(metric: "sleepHours", expectedDirection: "increase_or_stable", reason: zh ? "睡眠是最容易验证的次日恢复锚点。" : "Sleep is the easiest next-day recovery anchor to verify."),
            VerificationMetric(metric: "hrv", expectedDirection: state == .ready ? "stable" : "increase", reason: zh ? "HRV 回归基线将支持恢复判断。" : "HRV moving toward baseline would support the recovery plan."),
            VerificationMetric(metric: "restingHeartRate", expectedDirection: "decrease_or_stable", reason: zh ? "静息心率下降或稳定支持保守恢复解读。" : "A lower or stable resting heart rate supports a conservative recovery interpretation."),
            VerificationMetric(metric: "subjectiveEnergy", expectedDirection: "increase_or_stable", reason: zh ? "用户自评精力分数可以补充穿戴数据。" : "The user-reported energy score closes the loop beyond wearable data.")
        ]
    }

    private func followupQuestion(for quality: DataQualityReport, zh: Bool) -> String? {
        guard quality.overallConfidence == .low || quality.shouldAskUserFollowup else { return nil }
        return quality.suggestedFollowupQuestion
    }
}
