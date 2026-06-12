//
//  BadgeSystem.swift
//  OHeas
//
//  Badge registry, evaluator, and snapshot computation.
//  Defines all badges and checks whether they've been earned.
//

import Foundation

// MARK: - Badge Registry

/// Static registry of all earnable badges (v1: ~15 badges across 4 categories).
public enum BadgeRegistry {
    public static let all: [BadgeDefinition] = [
        // ── Streaks ──
        BadgeDefinition(
            nameKey: "badge7DayCheckIn", descriptionKey: "badge7DayCheckInDesc",
            iconSystemName: "flame.fill", category: .streaks,
            criteria: .streak(type: .checkIn, days: 7)
        ),
        BadgeDefinition(
            nameKey: "badge30DayCheckIn", descriptionKey: "badge30DayCheckInDesc",
            iconSystemName: "flame.circle.fill", category: .streaks,
            criteria: .streak(type: .checkIn, days: 30)
        ),
        BadgeDefinition(
            nameKey: "badge7DayDataCoverage", descriptionKey: "badge7DayDataCoverageDesc",
            iconSystemName: "applewatch.radiowaves.left.and.right", category: .streaks,
            criteria: .streak(type: .dataCoverage, days: 7)
        ),
        BadgeDefinition(
            nameKey: "badge7DayPlanComplete", descriptionKey: "badge7DayPlanCompleteDesc",
            iconSystemName: "checkmark.seal.fill", category: .streaks,
            criteria: .streak(type: .planCompletion, days: 7)
        ),

        // ── Milestones ──
        BadgeDefinition(
            nameKey: "badgeFirstRecommendation", descriptionKey: "badgeFirstRecommendationDesc",
            iconSystemName: "lightbulb.fill", category: .milestones,
            criteria: .firstRecommendation
        ),
        BadgeDefinition(
            nameKey: "badgeFirstExperiment", descriptionKey: "badgeFirstExperimentDesc",
            iconSystemName: "testtube.2", category: .milestones,
            criteria: .firstExperiment
        ),
        BadgeDefinition(
            nameKey: "badgeFirstChat", descriptionKey: "badgeFirstChatDesc",
            iconSystemName: "bubble.left.fill", category: .milestones,
            criteria: .firstChatMessage
        ),
        BadgeDefinition(
            nameKey: "badge10Feedbacks", descriptionKey: "badge10FeedbacksDesc",
            iconSystemName: "text.badge.checkmark", category: .milestones,
            criteria: .totalFeedback(count: 10)
        ),
        BadgeDefinition(
            nameKey: "badge30Plans", descriptionKey: "badge30PlansDesc",
            iconSystemName: "calendar.badge.checkmark", category: .milestones,
            criteria: .totalPlansCompleted(count: 30)
        ),
        BadgeDefinition(
            nameKey: "badge3Experiments", descriptionKey: "badge3ExperimentsDesc",
            iconSystemName: "chart.line.uptrend.xyaxis", category: .milestones,
            criteria: .totalExperiments(count: 3)
        ),

        // ── Health ──
        BadgeDefinition(
            nameKey: "badgeScoreWeekExcellent", descriptionKey: "badgeScoreWeekExcellentDesc",
            iconSystemName: "star.fill", category: .health,
            criteria: .scoreStreak(days: 7, minScore: 85)
        ),
        BadgeDefinition(
            nameKey: "badgeSleepConsistency", descriptionKey: "badgeSleepConsistencyDesc",
            iconSystemName: "moon.zzz.fill", category: .health,
            criteria: .metricCoverage(metric: "sleepHours", days: 14)
        ),
        BadgeDefinition(
            nameKey: "badgeHRVImprovement", descriptionKey: "badgeHRVImprovementDesc",
            iconSystemName: "heart.text.square.fill", category: .health,
            criteria: .metricCoverage(metric: "hrv", days: 21)
        ),

        // ── Exploration ──
        BadgeDefinition(
            nameKey: "badgeAllMetricsViewed", descriptionKey: "badgeAllMetricsViewedDesc",
            iconSystemName: "eye.fill", category: .exploration,
            criteria: .totalFeedback(count: 1) // Proxy: submitted at least one feedback (means they explored the feedback form)
        ),
        BadgeDefinition(
            nameKey: "badgeWeeklyReviewDone", descriptionKey: "badgeWeeklyReviewDoneDesc",
            iconSystemName: "doc.text.magnifyingglass", category: .exploration,
            criteria: .firstWeeklyReview
        ),
    ]

    /// Lookup a badge definition by criteria identifier.
    public static func definition(for id: String) -> BadgeDefinition? {
        all.first { $0.criteria.identifier == id }
    }
}

// MARK: - Badge Evaluator

/// Evaluates whether badges have been earned based on current gamification snapshot data.
public struct BadgeEvaluator {

    public init() {}

    // MARK: - Full Snapshot Computation

    /// Compute the complete gamification snapshot: streaks + earned badges + newly unlocked badges.
    public func computeSnapshot(
        metrics: [DailyHealthMetrics],
        feedback: [DailyFeedback],
        plans: [DailyPlan],
        chatMessages: [ChatMessage],
        scores: [(Date, BodyBudgetScore)],
        experiments: [PersonalExperiment],
        recommendations: [CoachRecommendation],
        weeklyReviews: [WeeklyReview],
        previouslyEarned: [BadgeState],
        today: Date = Date()
    ) -> GamificationSnapshot {
        let engine = StreakEngine()

        // Compute all streaks
        let streaks: [StreakType: StreakState] = [
            .checkIn: engine.computeCheckInStreak(chatMessages: chatMessages, feedback: feedback, today: today),
            .dataCoverage: engine.computeDataCoverageStreak(metrics: metrics, today: today),
            .feedback: engine.computeFeedbackStreak(feedback: feedback, today: today),
            .planCompletion: engine.computePlanCompletionStreak(plans: plans, today: today),
        ]

        // Evaluate all badge definitions
        let earnedSet = Set(previouslyEarned.map(\.badgeId))
        var newlyUnlocked: [BadgeDefinition] = []

        for def in BadgeRegistry.all {
            let alreadyEarned = earnedSet.contains(def.criteria.identifier)
            let justEarned = evaluate(definition: def, streaks: streaks, metrics: metrics, feedback: feedback, plans: plans, chatMessages: chatMessages, scores: scores, experiments: experiments, recommendations: recommendations, weeklyReviews: weeklyReviews, today: today)

            if justEarned && !alreadyEarned {
                newlyUnlocked.append(def)
            }
        }

        return GamificationSnapshot(
            streaks: streaks,
            earnedBadges: previouslyEarned,
            newlyUnlocked: newlyUnlocked
        )
    }

    // MARK: - Single Badge Evaluation

    public func evaluate(
        definition: BadgeDefinition,
        streaks: [StreakType: StreakState],
        metrics: [DailyHealthMetrics],
        feedback: [DailyFeedback],
        plans: [DailyPlan],
        chatMessages: [ChatMessage],
        scores: [(Date, BodyBudgetScore)],
        experiments: [PersonalExperiment],
        recommendations: [CoachRecommendation],
        weeklyReviews: [WeeklyReview],
        today: Date = Date()
    ) -> Bool {
        switch definition.criteria {
        case .streak(let type, let requiredDays):
            return streaks[type]?.currentStreak ?? 0 >= requiredDays
                || streaks[type]?.longestStreak ?? 0 >= requiredDays

        case .totalFeedback(let count):
            return feedback.count >= count

        case .totalPlansCompleted(let count):
            return plans.filter { $0.status == .completed }.count >= count

        case .totalExperiments(let count):
            return experiments.filter { $0.status == .completed }.count >= count

        case .scoreStreak(let days, let minScore):
            let engine = StreakEngine()
            let streak = engine.computeScoreStreak(scores: scores, minScore: minScore, today: today)
            return streak.longestStreak >= days

        case .metricCoverage(let metric, let requiredDays):
            let validDays = metrics.filter { daily in
                switch metric {
                case "sleepHours": return daily.sleepHours != nil
                case "hrv": return daily.hrv != nil
                case "restingHeartRate": return daily.restingHeartRate != nil
                case "steps": return daily.steps != nil
                default: return false
                }
            }.count
            return validDays >= requiredDays

        case .firstRecommendation:
            return !recommendations.isEmpty

        case .firstExperiment:
            return experiments.contains { $0.status == .completed || $0.status == .active }

        case .firstChatMessage:
            return chatMessages.contains { $0.role == .user }

        case .firstWeeklyReview:
            return !weeklyReviews.isEmpty
        }
    }
}
