//
//  BackendAPIClient.swift
//  OHeas
//
//  Backend API client with local fallback.
//  后端 API 客户端，带本地降级。
//


import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum BackendClientError: Error, LocalizedError, Equatable, Sendable {
    case missingConfiguration
    case rawHealthSamplesRejected
    case httpStatus(Int)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration: "Backend URL or token is missing."
        case .rawHealthSamplesRejected: "Raw HealthKit samples are not allowed in sync payloads."
        case .httpStatus(let status): "Backend returned HTTP \(status)."
        }
    }
}

public struct BackendConfiguration: Codable, Equatable, Sendable {
    public var baseURL: URL?
    public var bearerToken: String?

    public init(baseURL: URL? = nil, bearerToken: String? = nil) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
    }

    public var isConfigured: Bool {
        baseURL != nil && bearerToken?.isEmpty == false
    }
}

public protocol BackendAPIClientProtocol: Sendable {
    func uploadDailySummary(_ metrics: DailyHealthMetrics, userId: UUID) async throws
    func uploadRecommendation(_ recommendation: CoachRecommendation, userId: UUID) async throws
    func uploadFeedback(_ feedback: DailyFeedback, userId: UUID) async throws
    func uploadVerificationReport(_ report: VerificationReport, userId: UUID) async throws
    func uploadMemory(_ memory: UserMemorySummary, userId: UUID) async throws
    func uploadExperiment(_ experiment: PersonalExperiment, userId: UUID) async throws
    func uploadWeeklyPlan(_ plan: WeeklyPlan, userId: UUID) async throws
    func uploadWeeklyReview(_ review: WeeklyReview, userId: UUID) async throws
    func uploadPrivacySettings(_ settings: PrivacySettings, userId: UUID) async throws
    func uploadSafetyAssessment(_ assessment: SafetyAssessment, userId: UUID) async throws
    func uploadAnalyticsEvent(_ event: BetaAnalyticsEvent, userId: UUID) async throws
    func uploadSyncRecord(_ record: SyncRecord, userId: UUID) async throws
    func fetchRemoteChanges(since: Date?, userId: UUID) async throws -> [SyncRecord]
    func markDeleted(entityType: SyncEntityType, id: String, userId: UUID) async throws
}

public struct LocalBackendAPIClient: BackendAPIClientProtocol {
    public init() {}

    public func uploadDailySummary(_ metrics: DailyHealthMetrics, userId: UUID) async throws {}
    public func uploadRecommendation(_ recommendation: CoachRecommendation, userId: UUID) async throws {}
    public func uploadFeedback(_ feedback: DailyFeedback, userId: UUID) async throws {}
    public func uploadVerificationReport(_ report: VerificationReport, userId: UUID) async throws {}
    public func uploadMemory(_ memory: UserMemorySummary, userId: UUID) async throws {}
    public func uploadExperiment(_ experiment: PersonalExperiment, userId: UUID) async throws {}
    public func uploadWeeklyPlan(_ plan: WeeklyPlan, userId: UUID) async throws {}
    public func uploadWeeklyReview(_ review: WeeklyReview, userId: UUID) async throws {}
    public func uploadPrivacySettings(_ settings: PrivacySettings, userId: UUID) async throws {}
    public func uploadSafetyAssessment(_ assessment: SafetyAssessment, userId: UUID) async throws {}
    public func uploadAnalyticsEvent(_ event: BetaAnalyticsEvent, userId: UUID) async throws {}
    public func uploadSyncRecord(_ record: SyncRecord, userId: UUID) async throws {}
    public func fetchRemoteChanges(since: Date?, userId: UUID) async throws -> [SyncRecord] { [] }
    public func markDeleted(entityType: SyncEntityType, id: String, userId: UUID) async throws {}
}

public final class HTTPBackendAPIClient: BackendAPIClientProtocol, @unchecked Sendable {
    private let configuration: BackendConfiguration
    private let session: URLSession

    public init(configuration: BackendConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func uploadDailySummary(_ metrics: DailyHealthMetrics, userId: UUID) async throws {
        try await upload(metrics, entityType: .dailyHealthMetrics, entityId: ISO8601DateFormatter.oheasString(from: metrics.date), userId: userId)
    }

    public func uploadRecommendation(_ recommendation: CoachRecommendation, userId: UUID) async throws {
        try await upload(recommendation, entityType: .coachRecommendation, entityId: recommendation.id.uuidString, userId: userId)
    }

    public func uploadFeedback(_ feedback: DailyFeedback, userId: UUID) async throws {
        try await upload(feedback, entityType: .dailyFeedback, entityId: feedback.id.uuidString, userId: userId)
    }

    public func uploadVerificationReport(_ report: VerificationReport, userId: UUID) async throws {
        try await upload(report, entityType: .verificationReport, entityId: report.id.uuidString, userId: userId)
    }

    public func uploadMemory(_ memory: UserMemorySummary, userId: UUID) async throws {
        try await upload(memory, entityType: .userMemory, entityId: userId.uuidString, userId: userId)
    }

    public func uploadExperiment(_ experiment: PersonalExperiment, userId: UUID) async throws {
        try await upload(experiment, entityType: .personalExperiment, entityId: experiment.id.uuidString, userId: userId)
    }

    public func uploadWeeklyPlan(_ plan: WeeklyPlan, userId: UUID) async throws {
        try await upload(plan, entityType: .weeklyPlan, entityId: plan.id.uuidString, userId: userId)
    }

    public func uploadWeeklyReview(_ review: WeeklyReview, userId: UUID) async throws {
        try await upload(review, entityType: .weeklyReview, entityId: review.id.uuidString, userId: userId)
    }

    public func uploadPrivacySettings(_ settings: PrivacySettings, userId: UUID) async throws {
        try await upload(settings, entityType: .privacySettings, entityId: userId.uuidString, userId: userId)
    }

    public func uploadSafetyAssessment(_ assessment: SafetyAssessment, userId: UUID) async throws {
        try await upload(assessment, entityType: .safetyAssessment, entityId: assessment.id.uuidString, userId: userId)
    }

    public func uploadAnalyticsEvent(_ event: BetaAnalyticsEvent, userId: UUID) async throws {
        try await upload(event, entityType: .betaAnalyticsEvent, entityId: event.id.uuidString, userId: userId)
    }

    public func uploadSyncRecord(_ record: SyncRecord, userId: UUID) async throws {
        try await upload(record, userId: userId)
    }

    public func fetchRemoteChanges(since: Date?, userId: UUID) async throws -> [SyncRecord] {
        guard let baseURL = configuration.baseURL, let token = configuration.bearerToken else {
            throw BackendClientError.missingConfiguration
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("/v1/sync/changes"), resolvingAgainstBaseURL: false)
        if let since {
            components?.queryItems = [URLQueryItem(name: "since", value: ISO8601DateFormatter.oheasString(from: since))]
        }
        guard let url = components?.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BackendClientError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return (try? JSONDecoder.oheas.decode(RemoteChangesEnvelope.self, from: data).records) ?? []
    }

    public func markDeleted(entityType: SyncEntityType, id: String, userId: UUID) async throws {
        guard let baseURL = configuration.baseURL, let token = configuration.bearerToken else {
            throw BackendClientError.missingConfiguration
        }
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/sync/\(entityType.rawValue)/\(id)"))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BackendClientError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    private func upload<T: Encodable>(_ value: T, entityType: SyncEntityType, entityId: String, userId: UUID) async throws {
        let record = try SyncRecord.make(entityType: entityType, entityId: entityId, operation: .upsert, payload: value)
        try await upload(record, userId: userId)
    }

    private func upload(_ record: SyncRecord, userId: UUID) async throws {
        guard let baseURL = configuration.baseURL, let token = configuration.bearerToken else {
            throw BackendClientError.missingConfiguration
        }
        guard !record.containsRawHealthSampleKeys else {
            throw BackendClientError.rawHealthSamplesRejected
        }
        let envelope = SyncUploadEnvelope(records: [record.withUserId(userId)])
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/sync/upload"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.oheasPretty.encode(envelope)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BackendClientError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}

private struct SyncUploadEnvelope: Codable, Sendable {
    var records: [SyncRecord]
}

private struct RemoteChangesEnvelope: Codable, Sendable {
    var records: [SyncRecord]
}
