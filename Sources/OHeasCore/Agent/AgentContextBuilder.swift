//
//  AgentContextBuilder.swift
//  OHeas
//
//  Builds AgentContext from health data, memory, and experiments.
//  从健康数据、记忆和实验中构建 AgentContext。
//


import Foundation

public struct AgentContextBuilder: Sendable {
    public init() {}

    public func build(
        userGoal: String,
        todayMetrics: DailyHealthMetrics,
        baseline14d: HealthBaseline,
        dataQuality: DataQualityReport,
        detectedSignals: [HealthSignal],
        userMemory: UserMemory? = nil,
        activeExperiment: PersonalExperiment? = nil,
        recentExperimentResults: [ExperimentResult] = [],
        activeGoals: [UserGoal] = [],
        currentWeeklyPlan: WeeklyPlan? = nil,
        todayDailyPlan: DailyPlan? = nil,
        recentPlanAdjustments: [PlanAdjustment] = [],
        weeklyReviewSummary: String? = nil,
        remindersEnabled: Bool = false,
        privacySettings: PrivacySettings = .defaults,
        preferredLanguage: String = "en"
    ) -> AgentContext {
        let memory = userMemory ?? UserMemory()
        let zh = preferredLanguage == "zh"
        // AgentContext 是未来发给 LLM 的单一事实来源，UI 不直接拼 prompt。
        let context = AgentContext(
            userGoal: userGoal,
            todayMetrics: todayMetrics,
            baseline14d: baseline14d,
            dataQuality: dataQuality,
            detectedSignals: detectedSignals,
            coachingConstraints: zh ? [
                "不要做出医学诊断。",
                "如果数据置信度低，使用保守的语言。",
                "始终解释证据。",
                "始终提供一个小的可执行建议。",
                "始终包含明天的验证指标。",
                "如果用户提到危险症状，建议咨询合格的医疗专业人员。"
            ] : [
                "Do not make medical diagnosis.",
                "If data confidence is low, use conservative language.",
                "Always explain evidence.",
                "Always provide one small actionable recommendation.",
                "Always include tomorrow verification metrics.",
                "If dangerous symptoms are mentioned by the user, recommend consulting a qualified medical professional."
            ],
            recommendedDecisionFrame: decisionFrame(for: dataQuality, signals: detectedSignals, preferredLanguage: preferredLanguage),
            userMemorySummary: userMemory.map(UserMemorySummary.init(memory:)),
            knownPatterns: Array(memory.knownPatterns.prefix(5)),
            successfulInterventions: Array(memory.successfulInterventions.prefix(5)),
            ineffectiveInterventions: Array(memory.ineffectiveInterventions.prefix(5)),
            activeExperiment: activeExperiment,
            recentExperimentResults: Array(recentExperimentResults.prefix(3)),
            activeGoals: activeGoals,
            currentWeeklyPlan: currentWeeklyPlan,
            todayDailyPlan: todayDailyPlan,
            recentPlanAdjustments: recentPlanAdjustments,
            weeklyReviewSummary: weeklyReviewSummary,
            remindersEnabled: remindersEnabled,
            preferredLanguage: preferredLanguage
        )
        return PrivacyManager(settings: privacySettings).redactedContext(context)
    }

    private func decisionFrame(for quality: DataQualityReport, signals: [HealthSignal], preferredLanguage: String = "en") -> String {
        let zh = preferredLanguage == "zh"
        // 决策框架约束 LLM 的语气和行动建议，避免把生活方式 coaching 说成医疗判断。
        if quality.overallConfidence == .low {
            return zh
                ? "使用保守的恢复优先框架。避免强断言，最多问一个关于缺失穿戴数据的后续问题。"
                : "Use a conservative recovery-first frame. Avoid strong claims and ask at most one follow-up about missing wearable data."
        }
        if signals.contains(where: { $0.severity == .high }) {
            return zh
                ? "将今天视为低容量日。优先选择低风险行动、补水、提前放松，除非用户明确感觉良好，否则避免高强度训练。"
                : "Treat today as a lower-capacity day. Prefer low-risk actions, hydration, earlier wind-down, and avoid intense training unless the user feels clearly well."
        }
        if signals.isEmpty {
            return zh
                ? "没有明显偏离基线。保持建议轻松、实用，专注于维持日常节奏。"
                : "No major deviation from baseline. Keep advice light, practical, and focused on maintaining normal routines."
        }
        return zh
            ? "使用基线相对教练模式。指出最强的信号，然后建议一个小型生活方式行动和明天的验证指标。"
            : "Use baseline-relative coaching. Name the strongest signal, then suggest one small lifestyle action and tomorrow's verification metrics."
    }
}
