//
//  GoalPlanModels.swift
//  OHeas
//
//  Goal, weekly plan, and adaptive reschedule models.
//  目标、周计划和自适应重调度模型。
//


import Foundation

public enum UserGoalType: String, Codable, CaseIterable, Sendable {
    case improveEnergy = "improve_energy"
    case fatLoss = "fat_loss"
    case buildConsistency = "build_consistency"
    case improveCardio = "improve_cardio"
    case improveSleep = "improve_sleep"
    case recoveryFirst = "recovery_first"
    case custom
}

public enum GoalPriority: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

public enum Weekday: String, Codable, CaseIterable, Sendable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

public struct UserGoal: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: UserGoalType
    public var title: String
    public var description: String
    public var priority: GoalPriority
    public var targetFrequencyPerWeek: Int?
    public var preferredDays: [Weekday]
    public var constraints: [String]
    public var createdAt: Date
    public var updatedAt: Date
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        type: UserGoalType,
        title: String,
        description: String,
        priority: GoalPriority,
        targetFrequencyPerWeek: Int? = nil,
        preferredDays: [Weekday] = [],
        constraints: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.priority = priority
        self.targetFrequencyPerWeek = targetFrequencyPerWeek
        self.preferredDays = preferredDays
        self.constraints = constraints
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }

#if DEBUG
    public static var mockDefault: UserGoal {
        UserGoal(
            type: .buildConsistency,
            title: "提升精力和稳定运动习惯",
            description: "用低风险、可持续的小计划提升日常精力和运动一致性。",
            priority: .high,
            targetFrequencyPerWeek: 5,
            preferredDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            constraints: ["Avoid excessive intensity", "Prefer conservative adjustments with low-confidence data"]
        )
    }
#endif
}

public enum WeeklyPlanStatus: String, Codable, CaseIterable, Sendable {
    case proposed
    case active
    case completed
    case archived
}

public enum DailyPlanType: String, Codable, CaseIterable, Sendable {
    case rest
    case lightActivity = "light_activity"
    case moderateCardio = "moderate_cardio"
    case strength
    case mobility
    case sleepFocus = "sleep_focus"
    case experimentFocus = "experiment_focus"
    case dataCoverage = "data_coverage"
}

public enum PlanIntensity: String, Codable, CaseIterable, Sendable {
    case veryLow = "very_low"
    case low
    case medium
    case high
}

public enum DailyPlanStatus: String, Codable, CaseIterable, Sendable {
    case planned
    case adjusted
    case completed
    case skipped
}

public struct DailyPlan: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var weekday: Weekday
    public var planType: DailyPlanType
    public var title: String
    public var description: String
    public var intensity: PlanIntensity
    public var estimatedDurationMinutes: Int
    public var targetMetrics: [String]
    public var linkedExperimentId: String?
    public var status: DailyPlanStatus
    public var adjustmentReason: String?
    public var safetyNote: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        weekday: Weekday,
        planType: DailyPlanType,
        title: String,
        description: String,
        intensity: PlanIntensity,
        estimatedDurationMinutes: Int,
        targetMetrics: [String],
        linkedExperimentId: String? = nil,
        status: DailyPlanStatus = .planned,
        adjustmentReason: String? = nil,
        safetyNote: String? = "Lifestyle guidance only. Not medical advice.",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.weekday = weekday
        self.planType = planType
        self.title = title
        self.description = description
        self.intensity = intensity
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.targetMetrics = targetMetrics
        self.linkedExperimentId = linkedExperimentId
        self.status = status
        self.adjustmentReason = adjustmentReason
        self.safetyNote = safetyNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct WeeklyPlan: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var weekStartDate: Date
    public var goals: [UserGoal]
    public var days: [DailyPlan]
    public var strategySummary: String
    public var generatedFromContextSummary: String
    public var status: WeeklyPlanStatus
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        weekStartDate: Date,
        goals: [UserGoal],
        days: [DailyPlan],
        strategySummary: String,
        generatedFromContextSummary: String,
        status: WeeklyPlanStatus = .proposed,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.goals = goals
        self.days = days
        self.strategySummary = strategySummary
        self.generatedFromContextSummary = generatedFromContextSummary
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct PlanAdjustment: Codable, Equatable, Sendable {
    public var date: Date
    public var beforeType: DailyPlanType
    public var afterType: DailyPlanType
    public var reason: String

    public init(date: Date, beforeType: DailyPlanType, afterType: DailyPlanType, reason: String) {
        self.date = date
        self.beforeType = beforeType
        self.afterType = afterType
        self.reason = reason
    }
}
