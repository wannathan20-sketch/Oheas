//
//  PlanStore.swift
//  OHeas
//
//  Persists weekly plans.
//  持久化周计划。
//


import Foundation

public struct PlanStore: Sendable {
    private let store: CodableFileStore<WeeklyPlan>
    private let calendar: Calendar

    public init(fileURL: URL, calendar: Calendar = .current) {
        self.store = CodableFileStore(fileURL: fileURL)
        self.calendar = calendar
    }

    public func loadPlans() throws -> [WeeklyPlan] {
        try store.load().sorted { $0.weekStartDate < $1.weekStartDate }
    }

    public func savePlans(_ plans: [WeeklyPlan]) throws {
        try store.save(plans)
    }

    public func getCurrentWeekPlan(for date: Date = Date()) throws -> WeeklyPlan? {
        let weekStart = calendar.oheasWeekStart(for: date)
        return try loadPlans().last { calendar.isDate($0.weekStartDate, inSameDayAs: weekStart) && $0.status != .archived }
    }

    public func saveCurrentWeekPlan(_ plan: WeeklyPlan) throws {
        var plans = try loadPlans()
        if let index = plans.firstIndex(where: { calendar.isDate($0.weekStartDate, inSameDayAs: plan.weekStartDate) }) {
            plans[index] = plan
        } else {
            plans.append(plan)
        }
        try savePlans(plans)
    }

    public func updateDailyPlanStatus(planId: UUID, dayId: UUID, status: DailyPlanStatus) throws {
        try update(planId: planId) { plan in
            guard let index = plan.days.firstIndex(where: { $0.id == dayId }) else { return }
            plan.days[index].status = status
            plan.days[index].updatedAt = Date()
            plan.updatedAt = Date()
        }
    }

    public func replaceDailyPlan(planId: UUID, dailyPlan: DailyPlan) throws {
        try update(planId: planId) { plan in
            if let index = plan.days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: dailyPlan.date) }) {
                plan.days[index] = dailyPlan
            } else {
                plan.days.append(dailyPlan)
                plan.days.sort { $0.date < $1.date }
            }
            plan.updatedAt = Date()
        }
    }

    public func archiveOldPlans(before date: Date = Date()) throws {
        var plans = try loadPlans()
        let currentStart = calendar.oheasWeekStart(for: date)
        for index in plans.indices where plans[index].weekStartDate < currentStart {
            plans[index].status = .archived
            plans[index].updatedAt = Date()
        }
        try savePlans(plans)
    }

    private func update(planId: UUID, mutate: (inout WeeklyPlan) -> Void) throws {
        var plans = try loadPlans()
        guard let index = plans.firstIndex(where: { $0.id == planId }) else { return }
        mutate(&plans[index])
        try savePlans(plans)
    }
}

public extension Calendar {
    func oheasWeekStart(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components).map(startOfDay(for:)) ?? startOfDay(for: date)
    }

    func oheasWeekday(for date: Date) -> Weekday {
        switch component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
}
