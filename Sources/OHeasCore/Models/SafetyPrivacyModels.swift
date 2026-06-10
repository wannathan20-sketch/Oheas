//
//  SafetyPrivacyModels.swift
//  OHeas
//
//  Safety guardrail, privacy, and consent models.
//  安全护栏、隐私和同意模型。
//


import Foundation

public enum SafetyEntityType: String, Codable, CaseIterable, Sendable {
    case recommendation
    case weeklyPlan = "weekly_plan"
    case experiment
    case review
    case llmRawResponse = "llm_raw_response"
}

public enum SafetyRiskLevel: String, Codable, CaseIterable, Sendable {
    case safe
    case caution
    case unsafe
}

public enum SafetyFlagType: String, Codable, CaseIterable, Sendable {
    case medicalDiagnosis = "medical_diagnosis"
    case emergencySymptom = "emergency_symptom"
    case overconfidentClaim = "overconfident_claim"
    case highIntensityWhenRecoveryLow = "high_intensity_when_recovery_low"
    case unsafeWeightLossAdvice = "unsafe_weight_loss_advice"
    case supplementOrMedicationAdvice = "supplement_or_medication_advice"
    case missingDisclaimer = "missing_disclaimer"
    case unsupportedCausalClaim = "unsupported_causal_claim"
}

public struct SafetyFlag: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: SafetyFlagType
    public var excerpt: String
    public var explanation: String
    public var suggestedRewrite: String

    public init(
        id: UUID = UUID(),
        type: SafetyFlagType,
        excerpt: String,
        explanation: String,
        suggestedRewrite: String
    ) {
        self.id = id
        self.type = type
        self.excerpt = excerpt
        self.explanation = explanation
        self.suggestedRewrite = suggestedRewrite
    }
}

public struct SafetyAssessment: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var checkedEntityId: String
    public var entityType: SafetyEntityType
    public var riskLevel: SafetyRiskLevel
    public var flags: [SafetyFlag]
    public var sanitizedText: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        checkedEntityId: String,
        entityType: SafetyEntityType,
        riskLevel: SafetyRiskLevel,
        flags: [SafetyFlag],
        sanitizedText: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.checkedEntityId = checkedEntityId
        self.entityType = entityType
        self.riskLevel = riskLevel
        self.flags = flags
        self.sanitizedText = sanitizedText
        self.createdAt = createdAt
    }
}

public struct PrivacySettings: Codable, Equatable, Sendable {
    public var shareAggregatedMetricsWithLLM: Bool
    public var shareMemorySummaryWithLLM: Bool
    public var shareExperimentSummaryWithLLM: Bool
    public var sharePlanSummaryWithLLM: Bool
    public var shareFeedbackWithLLM: Bool
    public var allowRawHealthSamples: Bool
    public var useLLM: Bool
    public var updatedAt: Date

    public init(
        shareAggregatedMetricsWithLLM: Bool = true,
        shareMemorySummaryWithLLM: Bool = true,
        shareExperimentSummaryWithLLM: Bool = true,
        sharePlanSummaryWithLLM: Bool = true,
        shareFeedbackWithLLM: Bool = true,
        allowRawHealthSamples: Bool = false,
        useLLM: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.shareAggregatedMetricsWithLLM = shareAggregatedMetricsWithLLM
        self.shareMemorySummaryWithLLM = shareMemorySummaryWithLLM
        self.shareExperimentSummaryWithLLM = shareExperimentSummaryWithLLM
        self.sharePlanSummaryWithLLM = sharePlanSummaryWithLLM
        self.shareFeedbackWithLLM = shareFeedbackWithLLM
        self.allowRawHealthSamples = allowRawHealthSamples
        self.useLLM = useLLM
        self.updatedAt = updatedAt
    }

    public static var defaults: PrivacySettings {
        PrivacySettings()
    }
}
