//
//  FeedbackStore.swift
//  OHeas
//
//  Stores and retrieves daily user feedback on recommendations.
//  存储和检索用户对建议的每日反馈。
//


import Foundation

public struct FeedbackStore: Sendable {
    private let store: CodableFileStore<DailyFeedback>
    private let calendar: Calendar

    public init(fileURL: URL, calendar: Calendar = .current) {
        self.store = CodableFileStore(fileURL: fileURL)
        self.calendar = calendar
    }

    public func save(_ feedback: DailyFeedback) throws {
        try store.upsert(feedback) { existing in
            existing.recommendationId == feedback.recommendationId || calendar.isDate(existing.date, inSameDayAs: feedback.date)
        }
    }

    public func all() throws -> [DailyFeedback] {
        try store.load().sorted { $0.date < $1.date }
    }

    public func replaceAll(_ feedback: [DailyFeedback]) throws {
        try store.save(feedback)
    }

    public func recent(limit: Int = 7) throws -> [DailyFeedback] {
        Array(try all().suffix(limit))
    }

    public func feedback(on date: Date) throws -> DailyFeedback? {
        try all().last { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

public struct RecommendationHistoryStore: Sendable {
    private let store: CodableFileStore<CoachRecommendation>
    private let calendar: Calendar

    public init(fileURL: URL, calendar: Calendar = .current) {
        self.store = CodableFileStore(fileURL: fileURL)
        self.calendar = calendar
    }

    public func save(_ recommendation: CoachRecommendation) throws {
        try store.upsert(recommendation) { existing in
            existing.id == recommendation.id || calendar.isDate(existing.date, inSameDayAs: recommendation.date)
        }
    }

    public func all() throws -> [CoachRecommendation] {
        try store.load().sorted { $0.date < $1.date }
    }

    public func replaceAll(_ recommendations: [CoachRecommendation]) throws {
        try store.save(recommendations)
    }

    public func recommendation(on date: Date) throws -> CoachRecommendation? {
        try all().last { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

public struct VerificationReportStore: Sendable {
    private let store: CodableFileStore<VerificationReport>
    private let calendar: Calendar

    public init(fileURL: URL, calendar: Calendar = .current) {
        self.store = CodableFileStore(fileURL: fileURL)
        self.calendar = calendar
    }

    public func save(_ report: VerificationReport) throws {
        try store.upsert(report) { existing in
            existing.recommendationId == report.recommendationId || calendar.isDate(existing.date, inSameDayAs: report.date)
        }
    }

    public func all() throws -> [VerificationReport] {
        try store.load().sorted { $0.date < $1.date }
    }

    public func replaceAll(_ reports: [VerificationReport]) throws {
        try store.save(reports)
    }

    public func report(on date: Date) throws -> VerificationReport? {
        try all().last { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
