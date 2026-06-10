//
//  EvaluationModels.swift
//  OHeas
//
//  Evaluation result and regression test models.
//  评估结果和回归测试模型。
//


import Foundation

public enum ExpectedBehaviorType: String, Codable, CaseIterable, Sendable {
    case recommendsRecovery = "recommends_recovery"
    case recommendsLightActivity = "recommends_light_activity"
    case asksFollowup = "asks_followup"
    case mentionsLowConfidence = "mentions_low_confidence"
    case explainsEvidence = "explains_evidence"
    case includesTomorrowVerification = "includes_tomorrow_verification"
    case avoidsMedicalDiagnosis = "avoids_medical_diagnosis"
    case avoidsHighIntensity = "avoids_high_intensity"
}

public enum DisallowedBehaviorType: String, Codable, CaseIterable, Sendable {
    case medicalDiagnosis = "medical_diagnosis"
    case highIntensityWhenRecoveryLow = "high_intensity_when_recovery_low"
    case strongClaimWithLowConfidence = "strong_claim_with_low_confidence"
    case ignoresMissingData = "ignores_missing_data"
    case noEvidence = "no_evidence"
    case noVerification = "no_verification"
}

public struct ExpectedBehavior: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: ExpectedBehaviorType
    public var description: String

    public init(id: UUID = UUID(), type: ExpectedBehaviorType, description: String) {
        self.id = id
        self.type = type
        self.description = description
    }
}

public struct DisallowedBehavior: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: DisallowedBehaviorType
    public var description: String

    public init(id: UUID = UUID(), type: DisallowedBehaviorType, description: String) {
        self.id = id
        self.type = type
        self.description = description
    }
}

public struct EvaluationCase: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var description: String
    public var inputContext: AgentContext
    public var previousFeedback: DailyFeedback?
    public var yesterdayRecommendation: CoachRecommendation?
    public var rawTextFixture: String?
    public var expectedBehaviors: [ExpectedBehavior]
    public var disallowedBehaviors: [DisallowedBehavior]
    public var tags: [String]

    public init(
        id: String,
        title: String,
        description: String,
        inputContext: AgentContext,
        previousFeedback: DailyFeedback? = nil,
        yesterdayRecommendation: CoachRecommendation? = nil,
        rawTextFixture: String? = nil,
        expectedBehaviors: [ExpectedBehavior],
        disallowedBehaviors: [DisallowedBehavior],
        tags: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.inputContext = inputContext
        self.previousFeedback = previousFeedback
        self.yesterdayRecommendation = yesterdayRecommendation
        self.rawTextFixture = rawTextFixture
        self.expectedBehaviors = expectedBehaviors
        self.disallowedBehaviors = disallowedBehaviors
        self.tags = tags
    }
}

public struct EvaluationResult: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var caseId: String
    public var passed: Bool
    public var score: Double
    public var failures: [String]
    public var recommendation: CoachRecommendation?
    public var safetyAssessment: SafetyAssessment?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        caseId: String,
        passed: Bool,
        score: Double,
        failures: [String],
        recommendation: CoachRecommendation? = nil,
        safetyAssessment: SafetyAssessment? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.caseId = caseId
        self.passed = passed
        self.score = score
        self.failures = failures
        self.recommendation = recommendation
        self.safetyAssessment = safetyAssessment
        self.createdAt = createdAt
    }
}
