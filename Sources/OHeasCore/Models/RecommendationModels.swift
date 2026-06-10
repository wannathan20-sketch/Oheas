//
//  RecommendationModels.swift
//  OHeas
//
//  Coach recommendation and feedback models.
//  教练建议和反馈模型。
//


import Foundation

// MARK: - Coach State

/// The five coaching states derived from health signals and data quality.
/// LLM or rule-based engine maps the user's current state to one of these.
/// 从健康信号和数据质量中得出的五种教练状态。
public enum CoachState: String, Codable, CaseIterable, Sendable {
    case ready
    case balanced
    case recoveryLow = "recovery_low"
    case overloaded
    case uncertain
}

// MARK: - Recommendation Components

/// A single piece of evidence supporting a recommendation (metric observation + baseline comparison).
/// 支持建议的单项证据（指标观察 + 基线对比）。
public struct EvidenceItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var metric: String
    public var observation: String
    public var baselineComparison: String
    public var importance: String

    public init(
        id: UUID = UUID(),
        metric: String,
        observation: String,
        baselineComparison: String,
        importance: String
    ) {
        self.id = id
        self.metric = metric
        self.observation = observation
        self.baselineComparison = baselineComparison
        self.importance = importance
    }
}

/// A metric to check tomorrow to verify whether today's advice helped.
/// 明天需要检查的指标，用于验证今天的建议是否有效。
public struct VerificationMetric: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var metric: String
    public var expectedDirection: String
    public var reason: String

    public init(
        id: UUID = UUID(),
        metric: String,
        expectedDirection: String,
        reason: String
    ) {
        self.id = id
        self.metric = metric
        self.expectedDirection = expectedDirection
        self.reason = reason
    }
}

/// The core coach output: state assessment, evidence, actionable advice, and tomorrow's verification plan.
/// 核心教练输出：状态评估、证据、可执行建议和明日验证计划。
public struct CoachRecommendation: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var state: CoachState
    public var confidence: ConfidenceLevel
    public var title: String
    public var summary: String
    public var evidence: [EvidenceItem]
    public var recommendation: String
    public var tonightAction: String
    public var tomorrowVerification: [VerificationMetric]
    public var followupQuestion: String?
    public var safetyNote: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        state: CoachState,
        confidence: ConfidenceLevel,
        title: String,
        summary: String,
        evidence: [EvidenceItem],
        recommendation: String,
        tonightAction: String,
        tomorrowVerification: [VerificationMetric],
        followupQuestion: String? = nil,
        safetyNote: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.state = state
        self.confidence = confidence
        self.title = title
        self.summary = summary
        self.evidence = evidence
        self.recommendation = recommendation
        self.tonightAction = tonightAction
        self.tomorrowVerification = tomorrowVerification
        self.followupQuestion = followupQuestion
        self.safetyNote = safetyNote
        self.createdAt = createdAt
    }
}

// MARK: - Feedback

/// User's self-reported adherence to a recommendation.
/// 用户自报的对建议的执行程度。
public enum FeedbackAdherence: String, Codable, CaseIterable, Sendable {
    case completed
    case partial
    case skipped
}

/// Daily user feedback on a recommendation: adherence, subjective energy, soreness, stress, notes.
/// 用户对建议的每日反馈：完成度、主观精力、酸痛、压力、备注。
public struct DailyFeedback: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var recommendationId: UUID
    public var adherence: FeedbackAdherence
    public var subjectiveEnergy: Int
    public var soreness: Int
    public var stress: Int
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        recommendationId: UUID,
        adherence: FeedbackAdherence,
        subjectiveEnergy: Int,
        soreness: Int,
        stress: Int,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.recommendationId = recommendationId
        self.adherence = adherence
        self.subjectiveEnergy = subjectiveEnergy
        self.soreness = soreness
        self.stress = stress
        self.note = note
        self.createdAt = createdAt
    }
}

// MARK: - Verification

/// Outcome of verifying yesterday's recommendation against today's data.
/// 用今日数据验证昨日建议的结果。
public enum VerificationOutcome: String, Codable, CaseIterable, Sendable {
    case likelyHelped = "likely_helped"
    case neutral
    case unclear
    case likelyNotHelped = "likely_not_helped"
}

/// Verification report linking a recommendation to its outcome with findings and pattern candidates.
/// 验证报告，将建议与其结果关联，包含发现和模式候选项。
public struct VerificationReport: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var recommendationId: UUID
    public var outcome: VerificationOutcome
    public var confidence: ConfidenceLevel
    public var findings: [String]
    public var explanation: String
    public var learnedPatternCandidate: String?

    public init(
        id: UUID = UUID(),
        date: Date,
        recommendationId: UUID,
        outcome: VerificationOutcome,
        confidence: ConfidenceLevel,
        findings: [String],
        explanation: String,
        learnedPatternCandidate: String? = nil
    ) {
        self.id = id
        self.date = date
        self.recommendationId = recommendationId
        self.outcome = outcome
        self.confidence = confidence
        self.findings = findings
        self.explanation = explanation
        self.learnedPatternCandidate = learnedPatternCandidate
    }
}

// MARK: - Result

/// The final result of generating a recommendation, including safety assessment and fallback info.
/// 生成建议的最终结果，包含安全评估和降级信息。
public struct RecommendationResult: Codable, Equatable, Sendable {
    public var recommendation: CoachRecommendation
    public var rawResponse: String?
    public var originalRecommendation: CoachRecommendation?
    public var safetyAssessment: SafetyAssessment?
    public var rawSafetyAssessment: SafetyAssessment?
    public var fallbackReason: String?
    public var source: String

    public init(
        recommendation: CoachRecommendation,
        rawResponse: String? = nil,
        originalRecommendation: CoachRecommendation? = nil,
        safetyAssessment: SafetyAssessment? = nil,
        rawSafetyAssessment: SafetyAssessment? = nil,
        fallbackReason: String? = nil,
        source: String
    ) {
        self.recommendation = recommendation
        self.rawResponse = rawResponse
        self.originalRecommendation = originalRecommendation
        self.safetyAssessment = safetyAssessment
        self.rawSafetyAssessment = rawSafetyAssessment
        self.fallbackReason = fallbackReason
        self.source = source
    }
}
