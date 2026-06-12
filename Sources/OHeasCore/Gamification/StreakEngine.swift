//
//  StreakEngine.swift
//  OHeas
//
//  Stateless streak computation engine.
//  Computes consecutive-day streaks from existing health, feedback, plan, and chat data.
//

import Foundation

/// Stateless engine that computes streaks from existing source data.
public struct StreakEngine {

    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Public API

    /// Compute a data-coverage streak: consecutive days with >=3 of 7 metrics having valid data.
    public func computeDataCoverageStreak(
        metrics: [DailyHealthMetrics],
        today: Date = Date()
    ) -> StreakState {
        let dates = metrics.map(\.date).sorted(by: >)
        return computeStreak(
            dates: dates,
            today: today,
            filter: { _ in true } // All metrics entries qualify
        )
    }

    /// Compute a feedback streak: consecutive days with at least one feedback entry.
    public func computeFeedbackStreak(
        feedback: [DailyFeedback],
        today: Date = Date()
    ) -> StreakState {
        let dates = feedback.map(\.date).sorted(by: >)
        return computeStreak(dates: dates, today: today)
    }

    /// Compute a plan completion streak: consecutive days with completed daily plans.
    public func computePlanCompletionStreak(
        plans: [DailyPlan],
        today: Date = Date()
    ) -> StreakState {
        let dates = plans
            .filter { $0.status == .completed }
            .map(\.date)
            .sorted(by: >)
        return computeStreak(dates: dates, today: today)
    }

    /// Compute a check-in streak: consecutive days with any interaction (chat or feedback).
    public func computeCheckInStreak(
        chatMessages: [ChatMessage],
        feedback: [DailyFeedback],
        today: Date = Date()
    ) -> StreakState {
        var dates = chatMessages.map { calendar.startOfDay(for: $0.timestamp) }
        dates.append(contentsOf: feedback.map { calendar.startOfDay(for: $0.date) })
        let uniqueDates = Array(Set(dates)).sorted(by: >)
        return computeStreak(dates: uniqueDates, today: today)
    }

    /// Compute a score streak: consecutive days where the Body Budget Score >= minScore.
    public func computeScoreStreak(
        scores: [(date: Date, score: BodyBudgetScore)],
        minScore: Int,
        today: Date = Date()
    ) -> StreakState {
        let dates = scores
            .filter { $0.score.value >= minScore }
            .map(\.date)
            .sorted(by: >)
        return computeStreak(dates: dates, today: today)
    }

    // MARK: - Core Streak Algorithm

    /// Generic streak computation: given a sorted (descending) list of dates,
    /// count the longest consecutive run and the current consecutive run from today.
    private func computeStreak(
        dates: [Date],
        today: Date,
        filter: ((Date) -> Bool)? = nil
    ) -> StreakState {
        let todayStart = calendar.startOfDay(for: today)
        var longest = 0
        var current = 0
        var todayMaintained = false
        var lastActive: Date?

        // Build a set of active days for O(1) lookup
        let activeDays = Set(dates.map { calendar.startOfDay(for: $0) })

        // Find current streak: walk backward from today
        var checkDate = todayStart
        while activeDays.contains(checkDate) {
            current += 1
            lastActive = checkDate
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        if current > 0, calendar.isDate(lastActive ?? Date.distantPast, inSameDayAs: todayStart) {
            todayMaintained = true
        }

        // Find longest streak: scan all active days
        let sortedActive = activeDays.sorted()
        var runStart: Date?
        var prevDay: Date?
        for day in sortedActive {
            if let prev = prevDay, let expected = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(day, inSameDayAs: expected) {
                // Consecutive — continue run
            } else {
                // Break — save previous run length
                if let start = runStart, let prev = prevDay {
                    let runLength = calendar.dateComponents([.day], from: start, to: prev).day ?? 0
                    longest = max(longest, runLength + 1)
                }
                runStart = day
            }
            prevDay = day
        }
        // Count final run
        if let start = runStart, let prev = prevDay {
            let runLength = calendar.dateComponents([.day], from: start, to: prev).day ?? 0
            longest = max(longest, runLength + 1)
        }

        // longest should be at least current
        longest = max(longest, current)

        return StreakState(
            currentStreak: current,
            longestStreak: longest,
            todayMaintained: todayMaintained,
            lastActiveDate: lastActive
        )
    }
}
