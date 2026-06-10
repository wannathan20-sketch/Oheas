//
//  GoalStore.swift
//  OHeas
//
//  CRUD operations for user health and lifestyle goals.
//  用户健康和生活目标的 CRUD 操作。
//


import Foundation

public struct GoalStore: Sendable {
    private let store: CodableFileStore<UserGoal>

    public init(fileURL: URL) {
        self.store = CodableFileStore(fileURL: fileURL)
    }

    public func loadGoals() throws -> [UserGoal] {
        let goals = try store.load().sorted { $0.createdAt < $1.createdAt }
        return goals
    }

    public func saveGoals(_ goals: [UserGoal]) throws {
        try store.save(goals)
    }

    public func getActiveGoals() throws -> [UserGoal] {
        try loadGoals().filter(\.isActive)
    }

    public func addGoal(_ goal: UserGoal) throws {
        var goals = try loadGoals()
        goals.append(goal)
        try saveGoals(goals)
    }

    public func updateGoal(_ goal: UserGoal) throws {
        var goals = try loadGoals()
        var updated = goal
        updated.updatedAt = Date()
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = updated
        } else {
            goals.append(updated)
        }
        try saveGoals(goals)
    }

    public func deactivateGoal(_ id: UUID) throws {
        var goals = try loadGoals()
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[index].isActive = false
        goals[index].updatedAt = Date()
        try saveGoals(goals)
    }
}
