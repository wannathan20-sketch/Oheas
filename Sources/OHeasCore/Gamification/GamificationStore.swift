//
//  GamificationStore.swift
//  OHeas
//
//  Persistence for badge and streak state using CodableFileStore.
//

import Foundation

// MARK: - Badge Store

/// Persists earned badge state.
public final class BadgeStore {
    private let store: CodableFileStore<BadgeState>

    public init(fileURL: URL) {
        self.store = CodableFileStore(fileURL: fileURL)
    }

    public func loadBadges() throws -> [BadgeState] {
        try store.load()
    }

    public func save(_ badge: BadgeState) throws {
        var badges = (try? store.load()) ?? []
        if let existingIndex = badges.firstIndex(where: { $0.badgeId == badge.badgeId }) {
            badges[existingIndex] = BadgeState(
                badgeId: badge.badgeId,
                earnedAt: badge.earnedAt,
                timesEarned: badges[existingIndex].timesEarned + 1
            )
        } else {
            badges.append(badge)
        }
        try store.save(badges)
    }

    public func saveAll(_ badges: [BadgeState]) throws {
        try store.save(badges)
    }

    public func hasBadge(_ badgeId: String) -> Bool {
        (try? store.load().contains { $0.badgeId == badgeId }) ?? false
    }
}

// MARK: - Streak Store (optional persistence)

/// Persists streak history for display purposes (streaks are recomputable from source data).
public final class StreakStore {
    private let store: CodableFileStore<StreakRecord>

    public init(fileURL: URL) {
        self.store = CodableFileStore(fileURL: fileURL)
    }

    public func loadHistory() throws -> [StreakRecord] {
        try store.load()
    }

    public func record(_ record: StreakRecord) throws {
        var history = (try? store.load()) ?? []
        history.append(record)
        // Keep last 365 records max
        if history.count > 365 { history.removeFirst(history.count - 365) }
        try store.save(history)
    }
}

/// A single day's streak snapshot for historical tracking.
public struct StreakRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: Date { date }
    public var date: Date
    public var checkInStreak: Int
    public var dataCoverageStreak: Int

    public init(date: Date, checkInStreak: Int, dataCoverageStreak: Int) {
        self.date = date
        self.checkInStreak = checkInStreak
        self.dataCoverageStreak = dataCoverageStreak
    }
}
