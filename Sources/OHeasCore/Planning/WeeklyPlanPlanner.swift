//
//  WeeklyPlanPlanner.swift
//  OHeas
//
//  Generates personalized weekly plans with constraints.
//  生成带约束的个性化周计划。
//


import Foundation

public struct WeeklyPlanPlannerInput: Sendable {
    public var activeGoals: [UserGoal]
    public var recentMetrics: [DailyHealthMetrics]
    public var baseline: HealthBaseline
    public var dataQuality: DataQualityReport
    public var detectedSignals: [HealthSignal]
    public var userMemory: UserMemory
    public var activeExperiment: PersonalExperiment?
    public var recentRecommendations: [CoachRecommendation]
    public var recentFeedback: [DailyFeedback]
    public var previousPlan: WeeklyPlan?
    public var preferredLanguage: String

    public init(
        activeGoals: [UserGoal],
        recentMetrics: [DailyHealthMetrics],
        baseline: HealthBaseline,
        dataQuality: DataQualityReport,
        detectedSignals: [HealthSignal],
        userMemory: UserMemory,
        activeExperiment: PersonalExperiment?,
        recentRecommendations: [CoachRecommendation],
        recentFeedback: [DailyFeedback],
        previousPlan: WeeklyPlan?,
        preferredLanguage: String = "en"
    ) {
        self.activeGoals = activeGoals
        self.recentMetrics = recentMetrics
        self.baseline = baseline
        self.dataQuality = dataQuality
        self.detectedSignals = detectedSignals
        self.userMemory = userMemory
        self.activeExperiment = activeExperiment
        self.recentRecommendations = recentRecommendations
        self.recentFeedback = recentFeedback
        self.previousPlan = previousPlan
        self.preferredLanguage = preferredLanguage
    }
}

public protocol WeeklyPlanAgent: Sendable {
    func generatePlan(input: WeeklyPlanPlannerInput, weekStartDate: Date) -> WeeklyPlan
}

public struct RuleBasedWeeklyPlanGenerator: WeeklyPlanAgent {
    private let calendar: Calendar
    private let safetyGuardrail: SafetyGuardrail

    public init(calendar: Calendar = .current, safetyGuardrail: SafetyGuardrail = SafetyGuardrail()) {
        self.calendar = calendar
        self.safetyGuardrail = safetyGuardrail
    }

    public func generatePlan(input: WeeklyPlanPlannerInput, weekStartDate: Date) -> WeeklyPlan {
        let zh = input.preferredLanguage == "zh"
        let goals = input.activeGoals
        let signalTypes = Set(input.detectedSignals.map(\.type))
        var days: [DailyPlan] = []

        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: weekStartDate) ?? weekStartDate
            var plan = basePlan(for: date, goals: goals, offset: offset, zh: zh)

            if input.dataQuality.overallConfidence == .low, offset == 0 || offset == 6 {
                plan = dataCoveragePlan(date: date, reason: zh ? "数据置信度较低；优先重建穿戴设备数据覆盖。" : "Data confidence is low; prioritize rebuilding wearable coverage.", zh: zh)
            } else if let experiment = input.activeExperiment, offset < min(experiment.durationDays, 5) {
                plan = experimentPlan(date: date, experiment: experiment)
            } else if goals.contains(where: { $0.type == .recoveryFirst }) || signalTypes.contains(.hrvLow) || signalTypes.contains(.restingHeartHigh) {
                if plan.intensity == .high || plan.intensity == .medium {
                    plan = lightRecoveryPlan(date: date, reason: zh ? "恢复优先目标或恢复信号降低了强度。" : "Recovery-first goal or recovery signal lowered intensity.", zh: zh)
                }
            } else if goals.contains(where: { $0.type == .improveSleep }), offset % 2 == 0 {
                plan = sleepFocusPlan(date: date, zh: zh)
            }

            if days.last?.intensity == .high, plan.intensity == .high {
                plan = lightRecoveryPlan(date: date, reason: zh ? "避免连续高强度训练日。" : "Avoiding consecutive high intensity days.", zh: zh)
            }

            days.append(plan)
        }

        let plan = WeeklyPlan(
            weekStartDate: weekStartDate,
            goals: goals,
            days: days,
            strategySummary: strategySummary(goals: goals, quality: input.dataQuality, experiment: input.activeExperiment, zh: zh),
            generatedFromContextSummary: zh ? "基于当前目标、14天基线、数据质量、记忆和活跃实验生成。" : "Generated from active goals, 14-day baseline, current data quality, memory, and active experiment.",
            status: .active
        )
        let context = AgentContext(
            userGoal: goals.map(\.title).joined(separator: ", "),
            todayMetrics: input.recentMetrics.last ?? DailyHealthMetrics(date: Date()),
            baseline14d: input.baseline,
            dataQuality: input.dataQuality,
            detectedSignals: input.detectedSignals,
            coachingConstraints: [],
            recommendedDecisionFrame: ""
        )
        return safetyGuardrail.sanitize(plan: plan, context: context).0
    }

    private func basePlan(for date: Date, goals: [UserGoal], offset: Int, zh: Bool) -> DailyPlan {
        if goals.contains(where: { $0.type == .improveCardio }), [1, 3, 5].contains(offset) {
            return makePlan(date: date, type: .moderateCardio, title: zh ? "中等有氧" : "Moderate cardio", description: zh ? "恢复状态良好时进行 20-30 分钟轻松到中等的有氧运动。" : "20-30 minutes easy-to-moderate cardio if recovery feels okay.", intensity: .medium, duration: 25, metrics: ["exerciseMinutes", "restingHeartRate"])
        }
        if goals.contains(where: { $0.type == .fatLoss }), [1, 4].contains(offset) {
            return makePlan(date: date, type: .strength, title: zh ? "简单力量训练" : "Simple strength", description: zh ? "短时间力量训练，以舒适力度完成。" : "A short strength session with comfortable effort.", intensity: .medium, duration: 25, metrics: ["workouts", "activeEnergyKcal"])
        }
        if goals.contains(where: { $0.type == .improveSleep }), [0, 2, 4].contains(offset) {
            return sleepFocusPlan(date: date, zh: zh)
        }
        if goals.contains(where: { $0.type == .buildConsistency || $0.type == .improveEnergy }) {
            return makePlan(date: date, type: .lightActivity, title: zh ? "稳定习惯散步" : "Consistency walk", description: zh ? "10-20 分钟轻松活动。" : "10-20 minutes of easy movement.", intensity: .low, duration: 15, metrics: ["steps", "subjectiveEnergy"])
        }
        return offset == 6
            ? makePlan(date: date, type: .rest, title: zh ? "休息与复盘" : "Rest and review", description: zh ? "保持轻松活动并回顾本周。" : "Keep activity easy and review the week.", intensity: .veryLow, duration: 10, metrics: ["subjectiveEnergy"])
            : makePlan(date: date, type: .lightActivity, title: zh ? "轻松活动" : "Light activity", description: zh ? "一个低风险的小活动计划。" : "A small low-risk movement plan.", intensity: .low, duration: 15, metrics: ["steps"])
    }

    private func dataCoveragePlan(date: Date, reason: String, zh: Bool) -> DailyPlan {
        makePlan(date: date, type: .dataCoverage, title: zh ? "重建数据覆盖" : "Rebuild data coverage", description: zh ? "今晚佩戴 Apple Watch 并记录早晨精力状态。" : "Wear Apple Watch tonight and record morning energy.", intensity: .veryLow, duration: 5, metrics: ["sleepHours", "hrv", "subjectiveEnergy"], adjustmentReason: reason)
    }

    private func experimentPlan(date: Date, experiment: PersonalExperiment) -> DailyPlan {
        makePlan(date: date, type: .experimentFocus, title: experiment.title, description: experiment.intervention, intensity: .low, duration: 10, metrics: experiment.targetMetrics, linkedExperimentId: experiment.id.uuidString)
    }

    private func lightRecoveryPlan(date: Date, reason: String, zh: Bool) -> DailyPlan {
        makePlan(date: date, type: .lightActivity, title: zh ? "恢复友好活动" : "Recovery-friendly activity", description: zh ? "保持低强度；选择柔韧性训练或轻松散步。" : "Keep effort easy; choose mobility or an easy walk.", intensity: .low, duration: 15, metrics: ["hrv", "restingHeartRate", "subjectiveEnergy"], adjustmentReason: reason)
    }

    private func sleepFocusPlan(date: Date, zh: Bool) -> DailyPlan {
        makePlan(date: date, type: .sleepFocus, title: zh ? "睡眠优先" : "Sleep focus", description: zh ? "保护晚间习惯，保持低强度。" : "Protect the evening routine and keep intensity low.", intensity: .veryLow, duration: 10, metrics: ["sleepHours", "hrv"])
    }

    private func makePlan(date: Date, type: DailyPlanType, title: String, description: String, intensity: PlanIntensity, duration: Int, metrics: [String], linkedExperimentId: String? = nil, adjustmentReason: String? = nil) -> DailyPlan {
        DailyPlan(
            date: calendar.startOfDay(for: date),
            weekday: calendar.oheasWeekday(for: date),
            planType: type,
            title: title,
            description: description,
            intensity: intensity,
            estimatedDurationMinutes: duration,
            targetMetrics: metrics,
            linkedExperimentId: linkedExperimentId,
            adjustmentReason: adjustmentReason
        )
    }

    private func strategySummary(goals: [UserGoal], quality: DataQualityReport, experiment: PersonalExperiment?, zh: Bool) -> String {
        var parts = [zh ? "基于当前目标的小型可调节周计划。" : "Small, adjustable weekly plan based on active goals."]
        if quality.overallConfidence == .low { parts.append(zh ? "由于数据置信度低，优先确保数据覆盖。" : "Data coverage is prioritized because confidence is low.") }
        if experiment != nil { parts.append(zh ? "已包含活跃实验以避免建议冲突。" : "Active experiment is included to avoid conflicting advice.") }
        if goals.contains(where: { $0.type == .recoveryFirst }) { parts.append(zh ? "恢复优先目标降低了训练强度。" : "Recovery-first goal reduces intensity.") }
        return parts.joined(separator: " ")
    }
}

public typealias WeeklyPlanPlanner = RuleBasedWeeklyPlanGenerator
