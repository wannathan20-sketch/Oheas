//
//  LocalDataExporter.swift
//  OHeas
//
//  Exports aggregated local data (no raw HealthKit samples).
//  导出聚合本地数据（不含原始 HealthKit 采样）。
//


import Foundation

public struct LocalDataExportManifest: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var includesRawHealthSamples: Bool
    public var payload: [String: String]

    public init(generatedAt: Date = Date(), includesRawHealthSamples: Bool = false, payload: [String: String]) {
        self.generatedAt = generatedAt
        self.includesRawHealthSamples = includesRawHealthSamples
        self.payload = payload
    }
}

public enum ResetConfirmationState: Equatable, Sendable {
    case idle
    case needsConfirmation
    case confirmed
}

public struct LocalDataExporter: Sendable {
    private let encoder: JSONEncoder

    public init(encoder: JSONEncoder = .oheasPretty) {
        self.encoder = encoder
    }

    public func export(
        recommendations: [CoachRecommendation],
        feedback: [DailyFeedback],
        reports: [VerificationReport],
        goals: [UserGoal],
        plans: [WeeklyPlan],
        privacy: PrivacySettings
    ) -> LocalDataExportManifest {
        var payload: [String: String] = [:]
        payload["recommendations"] = encode(recommendations)
        payload["feedback"] = encode(feedback)
        payload["verificationReports"] = encode(reports)
        payload["goals"] = encode(goals)
        payload["weeklyPlans"] = encode(plans)
        payload["privacySettings"] = encode(privacy)
        return LocalDataExportManifest(payload: payload)
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? encoder.encode(value) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
