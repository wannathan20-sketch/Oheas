//
//  HealthModels.swift
//  OHeas
//
//  Core health data models — daily metrics, baselines, signals, and agent context.
//  核心健康数据模型 — 每日指标、基线、信号和 Agent 上下文。
//

import Foundation

// MARK: - Health Metrics

/// The seven health metrics tracked from Apple Health / HealthKit.
/// 从 Apple Health / HealthKit 追踪的七项健康指标。
public enum HealthMetric: String, Codable, CaseIterable, Sendable {
    case sleepHours           // 睡眠时长
    case hrv                  // 心率变异性 (Heart Rate Variability)
    case restingHeartRate     // 静息心率 (Resting Heart Rate)
    case steps                // 步数
    case activeEnergyKcal     // 活动能量消耗 (Active Energy)
    case exerciseMinutes      // 运动分钟数
    case workouts             // 训练记录
}

// MARK: - Status & Confidence

/// Per-metric status indicating whether data is valid, missing, or partial.
/// 每项指标的状态：有效、缺失或部分数据。
public enum MetricStatus: String, Codable, Sendable {
    case valid
    case missing
    case partial  // <3 samples for HRV/RHR — unreliable to compute average
}

/// Overall confidence level for today's health assessment.
/// 今日健康评估的整体置信度。
public enum ConfidenceLevel: String, Codable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

// MARK: - Signals

/// Types of health signals the detector can identify.
/// 信号检测器可识别的健康信号类型。
public enum SignalType: String, Codable, Sendable {
    case sleepLow = "sleep_low"
    case hrvLow = "hrv_low"
    case restingHeartHigh = "resting_hr_high"
    case activityLow = "activity_low"
    case activityHigh = "activity_high"
    case recoveryUncertainDueToMissingData = "recovery_uncertain_due_to_missing_data"
}

/// Severity level for a detected health signal.
/// 检测到的健康信号的严重程度。
public enum SignalSeverity: String, Codable, Sendable {
    case low
    case medium
    case high
}

// MARK: - Sleep

/// Apple Health sleep analysis stages.
/// Apple Health 睡眠分析阶段。
public enum SleepStage: String, Codable, Sendable {
    case asleepCore
    case asleepDeep
    case asleepREM
    case asleepUnspecified
}

/// A single sleep segment with start/end time and sleep stage.
/// 单次睡眠段，包含起止时间和睡眠阶段。
public struct SleepSegment: Codable, Equatable, Sendable {
    public var startDate: Date
    public var endDate: Date
    public var stage: SleepStage

    public init(startDate: Date, endDate: Date, stage: SleepStage) {
        self.startDate = startDate
        self.endDate = endDate
        self.stage = stage
    }
}

// MARK: - Workouts

/// Summary of a single workout session from HealthKit.
/// HealthKit 中单次训练的摘要。
public struct WorkoutSummary: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: String
    public var startDate: Date
    public var durationMinutes: Double
    public var activeEnergyKcal: Double?

    public init(
        id: UUID = UUID(),
        type: String,
        startDate: Date,
        durationMinutes: Double,
        activeEnergyKcal: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.durationMinutes = durationMinutes
        self.activeEnergyKcal = activeEnergyKcal
    }
}

// MARK: - Raw & Aggregated Data

/// Raw daily health data as read from HealthKit (before aggregation).
/// 从 HealthKit 读取的原始每日健康数据（聚合前）。
public struct RawDailyHealthData: Codable, Equatable, Sendable {
    public var date: Date
    public var sleepSegments: [SleepSegment]
    public var hrvSamples: [Double]          // Raw sample values, not averaged
    public var restingHeartRateSamples: [Double]
    public var steps: Double?
    public var activeEnergyKcal: Double?
    public var exerciseMinutes: Double?
    public var workouts: [WorkoutSummary]
    public var workoutsQueried: Bool         // Tracks whether workout query succeeded

    public init(
        date: Date,
        sleepSegments: [SleepSegment] = [],
        hrvSamples: [Double] = [],
        restingHeartRateSamples: [Double] = [],
        steps: Double? = nil,
        activeEnergyKcal: Double? = nil,
        exerciseMinutes: Double? = nil,
        workouts: [WorkoutSummary] = [],
        workoutsQueried: Bool = true
    ) {
        self.date = date
        self.sleepSegments = sleepSegments
        self.hrvSamples = hrvSamples
        self.restingHeartRateSamples = restingHeartRateSamples
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
        self.exerciseMinutes = exerciseMinutes
        self.workouts = workouts
        self.workoutsQueried = workoutsQueried
    }
}

/// Aggregated daily health metrics with per-metric status tracking.
/// Metrics are computed from RawDailyHealthData: HRV/RHR use mean of samples,
/// sleep hours = total duration of sleep segments.
/// 聚合后的每日健康指标，带逐项状态追踪。缺失 ≠ 0。
public struct DailyHealthMetrics: Codable, Equatable, Identifiable, Sendable {
    public var id: Date { date }

    public var date: Date
    public var sleepHours: Double?
    public var hrv: Double?
    public var restingHeartRate: Double?
    public var steps: Double?
    public var activeEnergyKcal: Double?
    public var exerciseMinutes: Double?
    public var workouts: [WorkoutSummary]
    /// Per-metric validity status — missing data is tracked, not zeroed.
    /// 每项指标的状态 — 缺失数据被追踪，不会被当作 0。
    public var perMetricStatus: [HealthMetric: MetricStatus]

    public init(
        date: Date,
        sleepHours: Double? = nil,
        hrv: Double? = nil,
        restingHeartRate: Double? = nil,
        steps: Double? = nil,
        activeEnergyKcal: Double? = nil,
        exerciseMinutes: Double? = nil,
        workouts: [WorkoutSummary] = [],
        perMetricStatus: [HealthMetric: MetricStatus] = [:]
    ) {
        self.date = date
        self.sleepHours = sleepHours
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
        self.exerciseMinutes = exerciseMinutes
        self.workouts = workouts
        self.perMetricStatus = perMetricStatus
    }
}

// MARK: - Baseline & Comparison

/// Rolling baseline computed over a configurable window (7/14/30 days).
/// 基于可配置窗口（7/14/30 天）计算的滚动基线。
public struct HealthBaseline: Codable, Equatable, Sendable {
    public var windowDays: Int
    public var averageSleepHours: Double?
    public var averageHRV: Double?
    public var averageRestingHeartRate: Double?
    public var averageSteps: Double?
    public var averageActiveEnergy: Double?
    public var averageExerciseMinutes: Double?
    /// Number of valid samples per metric in the window.
    /// 窗口中每项指标的有效样本数。
    public var sampleCounts: [HealthMetric: Int]

    public init(
        windowDays: Int,
        averageSleepHours: Double? = nil,
        averageHRV: Double? = nil,
        averageRestingHeartRate: Double? = nil,
        averageSteps: Double? = nil,
        averageActiveEnergy: Double? = nil,
        averageExerciseMinutes: Double? = nil,
        sampleCounts: [HealthMetric: Int] = [:]
    ) {
        self.windowDays = windowDays
        self.averageSleepHours = averageSleepHours
        self.averageHRV = averageHRV
        self.averageRestingHeartRate = averageRestingHeartRate
        self.averageSteps = averageSteps
        self.averageActiveEnergy = averageActiveEnergy
        self.averageExerciseMinutes = averageExerciseMinutes
        self.sampleCounts = sampleCounts
    }
}

/// Today's metric value compared against the baseline.
/// 今日指标与基线的对比结果。
public struct MetricComparison: Codable, Equatable, Sendable {
    public var metric: HealthMetric
    public var todayValue: Double?
    public var baselineValue: Double?
    public var absoluteDelta: Double?
    public var percentageDelta: Double?
    public var unit: String

    public init(
        metric: HealthMetric,
        todayValue: Double?,
        baselineValue: Double?,
        absoluteDelta: Double?,
        percentageDelta: Double?,
        unit: String
    ) {
        self.metric = metric
        self.todayValue = todayValue
        self.baselineValue = baselineValue
        self.absoluteDelta = absoluteDelta
        self.percentageDelta = percentageDelta
        self.unit = unit
    }
}

// MARK: - Quality & Signals

/// Report on overall data quality — confidence, missing reasons, follow-up prompts.
/// 数据质量报告 — 置信度、缺失原因、是否需要追问用户。
public struct DataQualityReport: Codable, Equatable, Sendable {
    public var perMetricStatus: [HealthMetric: MetricStatus]
    public var overallConfidence: ConfidenceLevel
    public var missingReasons: [String]
    public var shouldAskUserFollowup: Bool
    public var suggestedFollowupQuestion: String?

    public init(
        perMetricStatus: [HealthMetric: MetricStatus],
        overallConfidence: ConfidenceLevel,
        missingReasons: [String],
        shouldAskUserFollowup: Bool,
        suggestedFollowupQuestion: String?
    ) {
        self.perMetricStatus = perMetricStatus
        self.overallConfidence = overallConfidence
        self.missingReasons = missingReasons
        self.shouldAskUserFollowup = shouldAskUserFollowup
        self.suggestedFollowupQuestion = suggestedFollowupQuestion
    }
}

/// A detected health signal with type, severity, evidence, and human-readable explanation.
/// 检测到的健康信号，包含类型、严重程度、证据和可读解释。
public struct HealthSignal: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: SignalType
    public var severity: SignalSeverity
    public var evidence: String
    public var explanation: String

    public init(
        id: UUID = UUID(),
        type: SignalType,
        severity: SignalSeverity,
        evidence: String,
        explanation: String
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.evidence = evidence
        self.explanation = explanation
    }
}

// MARK: - Agent Context

/// The complete context bundle sent to the LLM coach for generating recommendations.
/// Includes today's data, baselines, signals, memory, goals, plans, and experiments.
/// 发送给 LLM 教练的完整上下文包，用于生成建议。
/// 包含今日数据、基线、信号、记忆、目标、计划和实验。
public struct AgentContext: Codable, Equatable, Sendable {
    public var userGoal: String
    public var todayMetrics: DailyHealthMetrics
    public var baseline14d: HealthBaseline
    public var dataQuality: DataQualityReport
    public var detectedSignals: [HealthSignal]
    public var coachingConstraints: [String]
    public var recommendedDecisionFrame: String
    // Memory & Patterns — 记忆与模式
    public var userMemorySummary: UserMemorySummary?
    public var knownPatterns: [KnownPattern]
    public var successfulInterventions: [InterventionMemory]
    public var ineffectiveInterventions: [InterventionMemory]
    // Experiments — 实验
    public var activeExperiment: PersonalExperiment?
    public var recentExperimentResults: [ExperimentResult]
    // Goals & Plans — 目标与计划
    public var activeGoals: [UserGoal]
    public var currentWeeklyPlan: WeeklyPlan?
    public var todayDailyPlan: DailyPlan?
    public var recentPlanAdjustments: [PlanAdjustment]
    public var weeklyReviewSummary: String?
    public var remindersEnabled: Bool
    public var preferredLanguage: String

    public init(
        userGoal: String,
        todayMetrics: DailyHealthMetrics,
        baseline14d: HealthBaseline,
        dataQuality: DataQualityReport,
        detectedSignals: [HealthSignal],
        coachingConstraints: [String],
        recommendedDecisionFrame: String,
        userMemorySummary: UserMemorySummary? = nil,
        knownPatterns: [KnownPattern] = [],
        successfulInterventions: [InterventionMemory] = [],
        ineffectiveInterventions: [InterventionMemory] = [],
        activeExperiment: PersonalExperiment? = nil,
        recentExperimentResults: [ExperimentResult] = [],
        activeGoals: [UserGoal] = [],
        currentWeeklyPlan: WeeklyPlan? = nil,
        todayDailyPlan: DailyPlan? = nil,
        recentPlanAdjustments: [PlanAdjustment] = [],
        weeklyReviewSummary: String? = nil,
        remindersEnabled: Bool = false,
        preferredLanguage: String = "en"
    ) {
        self.userGoal = userGoal
        self.todayMetrics = todayMetrics
        self.baseline14d = baseline14d
        self.dataQuality = dataQuality
        self.detectedSignals = detectedSignals
        self.coachingConstraints = coachingConstraints
        self.recommendedDecisionFrame = recommendedDecisionFrame
        self.userMemorySummary = userMemorySummary
        self.knownPatterns = knownPatterns
        self.successfulInterventions = successfulInterventions
        self.ineffectiveInterventions = ineffectiveInterventions
        self.activeExperiment = activeExperiment
        self.recentExperimentResults = recentExperimentResults
        self.activeGoals = activeGoals
        self.currentWeeklyPlan = currentWeeklyPlan
        self.todayDailyPlan = todayDailyPlan
        self.recentPlanAdjustments = recentPlanAdjustments
        self.weeklyReviewSummary = weeklyReviewSummary
        self.remindersEnabled = remindersEnabled
        self.preferredLanguage = preferredLanguage
    }
}

// MARK: - Prompt Payload

/// The assembled LLM prompt: system prompt + user context JSON.
/// 组装好的 LLM 提示词：系统提示 + 用户上下文 JSON。
public struct CoachPromptPayload: Codable, Equatable, Sendable {
    public var systemPrompt: String
    public var userContextJSON: String

    public init(systemPrompt: String, userContextJSON: String) {
        self.systemPrompt = systemPrompt
        self.userContextJSON = userContextJSON
    }
}
