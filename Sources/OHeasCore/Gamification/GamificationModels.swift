//
//  GamificationModels.swift
//  OHeas
//
//  Streak and badge data models for the gamification layer.
//  Streaks track consecutive days of healthy behaviors; badges reward milestones.
//

import Foundation

// MARK: - Streak Types

/// Types of streaks tracked by the app.
public enum StreakType: String, Codable, CaseIterable, Sendable {
    /// Consecutive days with >=3 of 7 health metrics having valid data.
    case dataCoverage
    /// Consecutive days of submitting feedback.
    case feedback
    /// Consecutive days of completing daily plans.
    case planCompletion
    /// Consecutive days of any interaction (chat message or feedback).
    case checkIn
}

/// Computed streak state for a single streak type.
public struct StreakState: Codable, Equatable, Sendable {
    public var currentStreak: Int
    public var longestStreak: Int
    public var todayMaintained: Bool
    public var lastActiveDate: Date?

    public init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        todayMaintained: Bool = false,
        lastActiveDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.todayMaintained = todayMaintained
        self.lastActiveDate = lastActiveDate
    }
}

// MARK: - Badge Types

/// Categories of badges for grouping in the UI.
public enum BadgeCategory: String, Codable, CaseIterable, Sendable {
    case streaks
    case milestones
    case health
    case exploration
}

/// Criteria for earning a badge. All criteria are evaluated from existing data only.
public enum BadgeCriteria: Codable, Equatable, Sendable {
    /// Maintain a streak of N consecutive days for a specific streak type.
    case streak(type: StreakType, days: Int)
    /// Submit N total feedback entries.
    case totalFeedback(count: Int)
    /// Complete N total daily plans.
    case totalPlansCompleted(count: Int)
    /// Complete N total experiments.
    case totalExperiments(count: Int)
    /// Body Budget Score stays above threshold for N consecutive days.
    case scoreStreak(days: Int, minScore: Int)
    /// Have at least N days of valid data for a specific metric.
    case metricCoverage(metric: String, days: Int)
    /// First-time achievements.
    case firstRecommendation
    case firstExperiment
    case firstChatMessage
    case firstWeeklyReview

    /// Human-readable identifier for the criteria.
    public var identifier: String {
        switch self {
        case .streak(let t, let d): "streak_\(t.rawValue)_\(d)"
        case .totalFeedback(let c): "totalFeedback_\(c)"
        case .totalPlansCompleted(let c): "totalPlans_\(c)"
        case .totalExperiments(let c): "totalExperiments_\(c)"
        case .scoreStreak(let d, let s): "scoreStreak_\(d)_\(s)"
        case .metricCoverage(let m, let d): "metricCoverage_\(m)_\(d)"
        case .firstRecommendation: "firstRecommendation"
        case .firstExperiment: "firstExperiment"
        case .firstChatMessage: "firstChatMessage"
        case .firstWeeklyReview: "firstWeeklyReview"
        }
    }
}

/// A badge definition — the template for an achievement.
public struct BadgeDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String { criteria.identifier }
    /// AppLanguage TextKey raw string for the badge name.
    public var nameKey: String
    /// AppLanguage TextKey raw string for the badge description.
    public var descriptionKey: String
    /// SF Symbol name for the badge icon.
    public var iconSystemName: String
    /// Category for grouping in the UI.
    public var category: BadgeCategory
    /// What needs to happen to earn this badge.
    public var criteria: BadgeCriteria

    public init(
        nameKey: String,
        descriptionKey: String,
        iconSystemName: String,
        category: BadgeCategory,
        criteria: BadgeCriteria
    ) {
        self.nameKey = nameKey
        self.descriptionKey = descriptionKey
        self.iconSystemName = iconSystemName
        self.category = category
        self.criteria = criteria
    }
}

/// Records when a badge was earned.
public struct BadgeState: Codable, Equatable, Identifiable, Sendable {
    public var id: String { badgeId }
    public var badgeId: String
    public var earnedAt: Date
    public var timesEarned: Int

    public init(badgeId: String, earnedAt: Date = Date(), timesEarned: Int = 1) {
        self.badgeId = badgeId
        self.earnedAt = earnedAt
        self.timesEarned = timesEarned
    }
}

// MARK: - Snapshot

/// Aggregate gamification state for the UI layer.
public struct GamificationSnapshot: Codable, Equatable, Sendable {
    public var streaks: [StreakType: StreakState]
    public var earnedBadges: [BadgeState]
    /// Badges that were just unlocked in this evaluation (not persisted yet).
    public var newlyUnlocked: [BadgeDefinition]

    public init(
        streaks: [StreakType: StreakState] = [:],
        earnedBadges: [BadgeState] = [],
        newlyUnlocked: [BadgeDefinition] = []
    ) {
        self.streaks = streaks
        self.earnedBadges = earnedBadges
        self.newlyUnlocked = newlyUnlocked
    }
}
