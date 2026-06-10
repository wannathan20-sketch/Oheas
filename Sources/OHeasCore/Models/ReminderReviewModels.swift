//
//  ReminderReviewModels.swift
//  OHeas
//
//  Reminder and weekly review models.
//  提醒和周复盘模型。
//


import Foundation

public enum ReminderType: String, Codable, CaseIterable, Sendable {
    case dailyPlanReminder = "daily_plan_reminder"
    case experimentCheckin = "experiment_checkin"
    case feedbackReminder = "feedback_reminder"
    case dataCoverageReminder = "data_coverage_reminder"
    case weeklyReview = "weekly_review"
}

public struct Reminder: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: ReminderType
    public var title: String
    public var body: String
    public var scheduledAt: Date
    public var relatedEntityId: String?
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        type: ReminderType,
        title: String,
        body: String,
        scheduledAt: Date,
        relatedEntityId: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.scheduledAt = scheduledAt
        self.relatedEntityId = relatedEntityId
        self.isEnabled = isEnabled
    }
}

public struct WeeklyReview: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var weekStartDate: Date
    public var completionRate: Double
    public var adherenceSummary: String
    public var recoverySummary: String
    public var activitySummary: String
    public var experimentSummary: String
    public var usefulPatterns: [String]
    public var planAdjustmentsForNextWeek: [String]
    public var memoryUpdates: [String]
    public var confidence: ConfidenceLevel
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        weekStartDate: Date,
        completionRate: Double,
        adherenceSummary: String,
        recoverySummary: String,
        activitySummary: String,
        experimentSummary: String,
        usefulPatterns: [String],
        planAdjustmentsForNextWeek: [String],
        memoryUpdates: [String],
        confidence: ConfidenceLevel,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.completionRate = completionRate
        self.adherenceSummary = adherenceSummary
        self.recoverySummary = recoverySummary
        self.activitySummary = activitySummary
        self.experimentSummary = experimentSummary
        self.usefulPatterns = usefulPatterns
        self.planAdjustmentsForNextWeek = planAdjustmentsForNextWeek
        self.memoryUpdates = memoryUpdates
        self.confidence = confidence
        self.createdAt = createdAt
    }
}
