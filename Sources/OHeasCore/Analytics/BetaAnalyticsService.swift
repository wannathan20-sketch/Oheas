//
//  BetaAnalyticsService.swift
//  OHeas
//
//  Beta analytics event recording with privacy filtering.
//  Beta 分析事件记录，带隐私过滤。
//


import Foundation

public enum BetaAnalyticsEventType: String, Codable, CaseIterable, Sendable {
    case appOpened = "app_opened"
    case recommendationGenerated = "recommendation_generated"
    case recommendationCompleted = "recommendation_completed"
    case recommendationSkipped = "recommendation_skipped"
    case feedbackSaved = "feedback_saved"
    case experimentStarted = "experiment_started"
    case experimentCheckin = "experiment_checkin"
    case weeklyPlanGenerated = "weekly_plan_generated"
    case weeklyPlanAdjusted = "weekly_plan_adjusted"
    case safetyFlagTriggered = "safety_flag_triggered"
    case llmFallbackUsed = "llm_fallback_used"
    case syncFailed = "sync_failed"
    case onboardingCompleted = "onboarding_completed"
    case syncRecordUploaded = "sync_record_uploaded"
}

public struct BetaAnalyticsEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var userId: String
    public var eventType: BetaAnalyticsEventType
    public var properties: [String: String]
    public var createdAt: Date

    public init(id: UUID = UUID(), userId: String, eventType: BetaAnalyticsEventType, properties: [String: String] = [:], createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.eventType = eventType
        self.properties = properties
        self.createdAt = createdAt
    }
}

public struct BetaAnalyticsSummary: Codable, Equatable, Sendable {
    public var appOpenCount: Int
    public var recommendationGeneratedCount: Int
    public var feedbackRate: Double
    public var experimentCheckinCount: Int
    public var safetyFlagCount: Int
    public var fallbackCount: Int
    public var syncFailureCount: Int

    public init(appOpenCount: Int, recommendationGeneratedCount: Int, feedbackRate: Double, experimentCheckinCount: Int, safetyFlagCount: Int, fallbackCount: Int, syncFailureCount: Int) {
        self.appOpenCount = appOpenCount
        self.recommendationGeneratedCount = recommendationGeneratedCount
        self.feedbackRate = feedbackRate
        self.experimentCheckinCount = experimentCheckinCount
        self.safetyFlagCount = safetyFlagCount
        self.fallbackCount = fallbackCount
        self.syncFailureCount = syncFailureCount
    }
}

public struct BetaAnalyticsService: Sendable {
    private let store: CodableFileStore<BetaAnalyticsEvent>
    private let backend: BackendAPIClientProtocol
    private let consentManager: ConsentManager?

    public init(fileURL: URL, backend: BackendAPIClientProtocol = LocalBackendAPIClient(), consentManager: ConsentManager? = nil) {
        self.store = CodableFileStore(fileURL: fileURL)
        self.backend = backend
        self.consentManager = consentManager
    }

    @discardableResult
    public func record(eventType: BetaAnalyticsEventType, userId: String, properties: [String: String] = [:]) throws -> BetaAnalyticsEvent {
        let sanitized = try sanitizedProperties(properties)
        let event = BetaAnalyticsEvent(userId: userId, eventType: eventType, properties: sanitized)
        var events = try store.load()
        events.append(event)
        try store.save(events)
        return event
    }

    public func uploadIfAllowed(userId: UUID) async -> Int {
        guard consentManager?.hasConsent(.betaAnalytics) == true, consentManager?.hasConsent(.cloudSync) == true else {
            return 0
        }
        let events = (try? store.load()) ?? []
        var uploaded = 0
        for event in events {
            do {
                try await backend.uploadAnalyticsEvent(event, userId: userId)
                uploaded += 1
            } catch {
                break
            }
        }
        return uploaded
    }

    public func events() -> [BetaAnalyticsEvent] {
        (try? store.load()) ?? []
    }

    public func summary() -> BetaAnalyticsSummary {
        let events = events()
        let generated = events.filter { $0.eventType == .recommendationGenerated }.count
        let feedback = events.filter { $0.eventType == .feedbackSaved || $0.eventType == .recommendationCompleted || $0.eventType == .recommendationSkipped }.count
        return BetaAnalyticsSummary(
            appOpenCount: events.filter { $0.eventType == .appOpened }.count,
            recommendationGeneratedCount: generated,
            feedbackRate: generated == 0 ? 0 : Double(feedback) / Double(generated),
            experimentCheckinCount: events.filter { $0.eventType == .experimentCheckin }.count,
            safetyFlagCount: events.filter { $0.eventType == .safetyFlagTriggered }.count,
            fallbackCount: events.filter { $0.eventType == .llmFallbackUsed }.count,
            syncFailureCount: events.filter { $0.eventType == .syncFailed }.count
        )
    }

    private func sanitizedProperties(_ properties: [String: String]) throws -> [String: String] {
        let forbidden = ["raw", "sample", "sleepsegment", "hrvsample", "heartratesample", "route"]
        for key in properties.keys {
            let normalized = key.lowercased()
            if forbidden.contains(where: { normalized.contains($0) }) {
                throw BackendClientError.rawHealthSamplesRejected
            }
        }
        return properties
    }
}
