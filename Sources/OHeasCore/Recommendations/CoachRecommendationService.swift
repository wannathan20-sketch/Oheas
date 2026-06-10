//
//  CoachRecommendationService.swift
//  OHeas
//
//  Orchestrates LLM recommendation with safety filtering and streaming.
//  编排 LLM 建议，带安全过滤和流式输出。
//


import Foundation

// MARK: - Streaming event

public struct RecommendationStreamEvent: Sendable {
    public let partialDisplayText: String?
    public let result: RecommendationResult?
    public let isComplete: Bool

    public init(partialDisplayText: String?, result: RecommendationResult?, isComplete: Bool) {
        self.partialDisplayText = partialDisplayText
        self.result = result
        self.isComplete = isComplete
    }
}

public struct CoachRecommendationService: Sendable {
    private let promptBuilder: CoachPromptBuilder
    private let parser: CoachRecommendationParser
    private let ruleGenerator: RuleBasedRecommendationGenerator
    private let safetyGuardrail: SafetyGuardrail
    private let privacySettings: PrivacySettings
    private let client: (any LLMClientProtocol)?
    private let aiEnabled: Bool

    public init(
        promptBuilder: CoachPromptBuilder = CoachPromptBuilder(),
        parser: CoachRecommendationParser = CoachRecommendationParser(),
        ruleGenerator: RuleBasedRecommendationGenerator = RuleBasedRecommendationGenerator(),
        safetyGuardrail: SafetyGuardrail = SafetyGuardrail(),
        privacySettings: PrivacySettings = .defaults,
        client: (any LLMClientProtocol)? = nil,
        aiEnabled: Bool = true
    ) {
        self.promptBuilder = promptBuilder
        self.parser = parser
        self.ruleGenerator = ruleGenerator
        self.safetyGuardrail = safetyGuardrail
        self.privacySettings = privacySettings
        self.client = client
        self.aiEnabled = aiEnabled
    }

    public func recommendation(
        for context: AgentContext,
        previousFeedback: DailyFeedback?,
        yesterdayRecommendation: CoachRecommendation?
    ) async -> RecommendationResult {
        guard aiEnabled, privacySettings.useLLM else {
            return fallback(context: context, reason: "ai_disabled", previousFeedback: previousFeedback, yesterdayRecommendation: yesterdayRecommendation)
        }

        guard let client else {
            return fallback(context: context, reason: "missing_api_key", previousFeedback: previousFeedback, yesterdayRecommendation: yesterdayRecommendation)
        }

        do {
            let payload = try promptBuilder.buildPayload(
                context: context,
                previousFeedback: previousFeedback,
                yesterdayRecommendation: yesterdayRecommendation,
                privacySettings: privacySettings
            )
            let raw = try await client.generateRecommendationJSON(payload: payload)
            return try processRawResponse(raw, context: context, source: client.name)
        } catch {
            return fallback(
                context: context,
                reason: "llm_failed_or_unparseable: \(error.localizedDescription)",
                previousFeedback: previousFeedback,
                yesterdayRecommendation: yesterdayRecommendation
            )
        }
    }

    // MARK: - Streaming recommendation

    public func streamRecommendation(
        for context: AgentContext,
        previousFeedback: DailyFeedback?,
        yesterdayRecommendation: CoachRecommendation?
    ) -> AsyncThrowingStream<RecommendationStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                guard aiEnabled, privacySettings.useLLM else {
                    let result = fallback(context: context, reason: "ai_disabled", previousFeedback: previousFeedback, yesterdayRecommendation: yesterdayRecommendation)
                    continuation.yield(RecommendationStreamEvent(partialDisplayText: nil, result: result, isComplete: true))
                    continuation.finish()
                    return
                }

                guard let client else {
                    let result = fallback(context: context, reason: "missing_api_key", previousFeedback: previousFeedback, yesterdayRecommendation: yesterdayRecommendation)
                    continuation.yield(RecommendationStreamEvent(partialDisplayText: nil, result: result, isComplete: true))
                    continuation.finish()
                    return
                }

                do {
                    let payload = try promptBuilder.buildPayload(
                        context: context,
                        previousFeedback: previousFeedback,
                        yesterdayRecommendation: yesterdayRecommendation,
                        privacySettings: privacySettings
                    )

                    // Try streaming if supported
                    if let streamingClient = client as? (any LLMStreaming) {
                        let stream = streamingClient.streamRecommendation(payload: payload)
                        var lastDisplayText = ""
                        for try await event in stream {
                            if event.isComplete {
                                let result = try processRawResponse(event.accumulatedText, context: context, source: client.name)
                                continuation.yield(RecommendationStreamEvent(partialDisplayText: nil, result: result, isComplete: true))
                                continuation.finish()
                                return
                            } else {
                                // Extract readable text from accumulated JSON
                                let displayText = extractDisplayableText(from: event.accumulatedText)
                                if displayText != lastDisplayText {
                                    lastDisplayText = displayText
                                    continuation.yield(RecommendationStreamEvent(partialDisplayText: displayText, result: nil, isComplete: false))
                                }
                            }
                        }
                    }

                    // Fallback: one-shot with typewriter effect handled by ViewModel
                    let raw = try await client.generateRecommendationJSON(payload: payload)
                    let result = try processRawResponse(raw, context: context, source: client.name)
                    continuation.yield(RecommendationStreamEvent(partialDisplayText: nil, result: result, isComplete: true))
                    continuation.finish()
                } catch {
                    let result = fallback(
                        context: context,
                        reason: "llm_failed_or_unparseable: \(error.localizedDescription)",
                        previousFeedback: previousFeedback,
                        yesterdayRecommendation: yesterdayRecommendation
                    )
                    continuation.yield(RecommendationStreamEvent(partialDisplayText: nil, result: result, isComplete: true))
                    continuation.finish()
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private helpers

    private func processRawResponse(_ raw: String, context: AgentContext, source: String) throws -> RecommendationResult {
        let rawAssessment = safetyGuardrail.assess(
            text: raw,
            checkedEntityId: UUID().uuidString,
            entityType: .llmRawResponse,
            dataQuality: context.dataQuality,
            recoveryIsLow: context.detectedSignals.contains { [.sleepLow, .hrvLow, .restingHeartHigh].contains($0.type) }
        )
        let parsed = try parser.parse(raw)
        let sanitized = safetyGuardrail.sanitize(recommendation: parsed, context: context)
        return RecommendationResult(
            recommendation: sanitized.0,
            rawResponse: raw,
            originalRecommendation: sanitized.1.riskLevel == .safe ? nil : parsed,
            safetyAssessment: sanitized.1,
            rawSafetyAssessment: rawAssessment,
            fallbackReason: nil,
            source: source
        )
    }

    /// Extract user-readable text from partial JSON during streaming.
    /// Looks for the "recommendation" field value as it's being built.
    private func extractDisplayableText(from accumulatedJSON: String) -> String {
        // Try to extract the recommendation field value
        let pattern = #""recommendation"\s*:\s*"([^"]*)"#
        if let match = accumulatedJSON.range(of: pattern, options: .regularExpression) {
            let text = accumulatedJSON[match]
            if let valueStart = text.range(of: #":"#) {
                let afterColon = text[valueStart.upperBound...].trimmingCharacters(in: .whitespaces)
                if afterColon.hasPrefix("\"") {
                    var content = String(afterColon.dropFirst())
                    if content.hasSuffix("\"") { content = String(content.dropLast()) }
                    return content
                }
            }
        }

        // Fallback: show last 100 chars of accumulation (stripped of JSON syntax)
        let cleaned = accumulatedJSON
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
        let trimmed = String(cleaned.suffix(100)).trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))
        return trimmed
    }

    private func fallback(
        context: AgentContext,
        reason: String,
        previousFeedback: DailyFeedback?,
        yesterdayRecommendation: CoachRecommendation?
    ) -> RecommendationResult {
        let generated = ruleGenerator.generate(
            context: context,
            previousFeedback: previousFeedback,
            yesterdayRecommendation: yesterdayRecommendation
        )
        let sanitized = safetyGuardrail.sanitize(recommendation: generated, context: context)
        return RecommendationResult(
            recommendation: sanitized.0,
            rawResponse: nil,
            originalRecommendation: sanitized.1.riskLevel == .safe ? nil : generated,
            safetyAssessment: sanitized.1,
            fallbackReason: reason,
            source: "rule_based"
        )
    }
}

public struct CoachRecommendationParser: Sendable {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = .oheas) {
        self.decoder = decoder
    }

    public func parse(_ raw: String) throws -> CoachRecommendation {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Raw response is not UTF-8."))
        }
        return try decoder.decode(CoachRecommendation.self, from: data)
    }
}
