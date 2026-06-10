//
//  CoachPromptBuilder.swift
//  OHeas
//
//  Assembles the LLM system prompt and user context JSON payload.
//  组装 LLM 系统提示词和用户上下文 JSON。
//


import Foundation

public struct CoachPromptBuilder: Sendable {
    private let encoder: JSONEncoder
    private let templateResolver: CoachPromptTemplateResolver

    public init(
        encoder: JSONEncoder = .oheasPretty,
        promptVersion: CoachPromptVersion = .v1
    ) {
        self.encoder = encoder
        self.templateResolver = CoachPromptTemplateResolver(version: promptVersion)
    }

    public func buildPayload(context: AgentContext) throws -> CoachPromptPayload {
        try buildPayload(context: context, previousFeedback: nil, yesterdayRecommendation: nil, privacySettings: .defaults)
    }

    public func buildPayload(
        context: AgentContext,
        previousFeedback: DailyFeedback?,
        yesterdayRecommendation: CoachRecommendation?,
        privacySettings: PrivacySettings = .defaults
    ) throws -> CoachPromptPayload {
        let privacyManager = PrivacyManager(settings: privacySettings)
        let redactedContext = privacyManager.redactedContext(context)
        let request = CoachPromptRequest(
            agentContext: redactedContext,
            detectedSignals: redactedContext.detectedSignals,
            dataQuality: redactedContext.dataQuality,
            userGoal: redactedContext.userGoal,
            previousFeedback: privacyManager.redactedFeedback(previousFeedback),
            yesterdayRecommendation: yesterdayRecommendation
        )
        let data = try encoder.encode(redactedContext)
        let requestData = try encoder.encode(request)
        let json = String(data: requestData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? "{}"
        // Only send aggregated AgentContext and feedback summary; never expose raw HealthKit details.
        return CoachPromptPayload(
            systemPrompt: templateResolver.resolve(context: redactedContext),
            userContextJSON: json
        )
    }

    /// The system prompt for the current version, resolved without context (V1 compatible).
    public var systemPrompt: String {
        templateResolver.resolve(context: AgentContext(
            userGoal: "", todayMetrics: DailyHealthMetrics(date: Date()), baseline14d: HealthBaseline(windowDays: 14),
            dataQuality: DataQualityReport(perMetricStatus: [:], overallConfidence: .high, missingReasons: [], shouldAskUserFollowup: false, suggestedFollowupQuestion: nil),
            detectedSignals: [], coachingConstraints: [], recommendedDecisionFrame: ""
        ))
    }
}

private struct CoachPromptRequest: Codable, Sendable {
    var agentContext: AgentContext
    var detectedSignals: [HealthSignal]
    var dataQuality: DataQualityReport
    var userGoal: String
    var previousFeedback: DailyFeedback?
    var yesterdayRecommendation: CoachRecommendation?
}

public extension JSONEncoder {
    static var oheasPretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
