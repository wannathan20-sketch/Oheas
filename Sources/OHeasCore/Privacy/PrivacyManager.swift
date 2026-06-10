//
//  PrivacyManager.swift
//  OHeas
//
//  Redacts sensitive context fields per privacy settings.
//  根据隐私设置脱敏敏感上下文字段。
//


import Foundation

public struct PrivacyStore: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL,
        encoder: JSONEncoder = .oheasPretty,
        decoder: JSONDecoder = .oheas
    ) {
        self.fileURL = fileURL
        self.encoder = encoder
        self.decoder = decoder
    }

    public func loadSettings() throws -> PrivacySettings {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .defaults
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(PrivacySettings.self, from: data)
    }

    public func saveSettings(_ settings: PrivacySettings) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var copy = settings
        copy.updatedAt = Date()
        let data = try encoder.encode(copy)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func resetDefaults() throws -> PrivacySettings {
        let defaults = PrivacySettings.defaults
        try saveSettings(defaults)
        return defaults
    }
}

public struct PrivacyManager: Sendable {
    public var settings: PrivacySettings

    public init(settings: PrivacySettings = .defaults) {
        self.settings = settings
    }

    public func redactedContext(_ context: AgentContext) -> AgentContext {
        var copy = context

        if !settings.shareAggregatedMetricsWithLLM {
            copy.todayMetrics = DailyHealthMetrics(date: context.todayMetrics.date)
            copy.baseline14d = HealthBaseline(windowDays: context.baseline14d.windowDays)
            copy.detectedSignals = []
            copy.dataQuality = DataQualityReport(
                perMetricStatus: [:],
                overallConfidence: .low,
                missingReasons: ["Aggregated metrics hidden by privacy settings."],
                shouldAskUserFollowup: false,
                suggestedFollowupQuestion: nil
            )
            copy.recommendedDecisionFrame = "Metrics are hidden by privacy settings. Use only conservative, local-rule guidance."
        }

        if !settings.shareMemorySummaryWithLLM {
            copy.userMemorySummary = nil
            copy.knownPatterns = []
            copy.successfulInterventions = []
            copy.ineffectiveInterventions = []
        }

        if !settings.shareExperimentSummaryWithLLM {
            copy.activeExperiment = nil
            copy.recentExperimentResults = []
        }

        if !settings.sharePlanSummaryWithLLM {
            copy.currentWeeklyPlan = nil
            copy.todayDailyPlan = nil
            copy.recentPlanAdjustments = []
            copy.weeklyReviewSummary = nil
        }

        var constraints = copy.coachingConstraints
        constraints.append("Privacy settings prohibit raw HealthKit sample sharing unless explicitly enabled.")
        if !settings.allowRawHealthSamples {
            constraints.append("Do not request or include raw HealthKit samples; use aggregate summaries only.")
        }
        copy.coachingConstraints = unique(constraints)
        return copy
    }

    public func redactedFeedback(_ feedback: DailyFeedback?) -> DailyFeedback? {
        settings.shareFeedbackWithLLM ? feedback : nil
    }

    public func payloadPreview(for context: AgentContext, encoder: JSONEncoder = .oheasPretty) -> String {
        let redacted = redactedContext(context)
        guard let data = try? encoder.encode(redacted) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var output: [String] = []
        for value in values where seen.insert(value).inserted {
            output.append(value)
        }
        return output
    }
}
