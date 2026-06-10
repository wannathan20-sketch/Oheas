//
//  ReminderScheduler.swift
//  OHeas
//
//  Schedules local notifications for plans, feedback, and reviews.
//  为计划、反馈和周复盘安排本地通知。
//


import Foundation

#if canImport(UserNotifications) && os(iOS)
import UserNotifications
#endif

public protocol ReminderScheduling: Sendable {
    func requestAuthorization() async -> Bool
    func schedule(_ reminder: Reminder) async
    func cancel(_ reminder: Reminder) async
}

public struct ReminderScheduler: ReminderScheduling {
    public init() {}

    public func requestAuthorization() async -> Bool {
        #if canImport(UserNotifications) && os(iOS)
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    public func schedule(_ reminder: Reminder) async {
        guard reminder.isEnabled else { return }
        #if canImport(UserNotifications) && os(iOS)
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        let interval = max(1, reminder.scheduledAt.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
        #endif
    }

    public func cancel(_ reminder: Reminder) async {
        #if canImport(UserNotifications) && os(iOS)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        #endif
    }

    public func reminders(for plan: WeeklyPlan, activeExperiment: PersonalExperiment?, dataQuality: DataQualityReport, enabled: Bool, calendar: Calendar = .current) -> [Reminder] {
        var reminders: [Reminder] = []
        for day in plan.days {
            reminders.append(
                Reminder(
                    type: .dailyPlanReminder,
                    title: "Today's OHeas plan",
                    body: day.title,
                    scheduledAt: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: day.date) ?? day.date,
                    relatedEntityId: day.id.uuidString,
                    isEnabled: enabled
                )
            )
        }

        if let activeExperiment {
            reminders.append(
                Reminder(
                    type: .experimentCheckin,
                    title: "Experiment check-in",
                    body: activeExperiment.title,
                    scheduledAt: calendar.date(bySettingHour: 20, minute: 30, second: 0, of: Date()) ?? Date(),
                    relatedEntityId: activeExperiment.id.uuidString,
                    isEnabled: enabled
                )
            )
        }

        reminders.append(
            Reminder(
                type: .feedbackReminder,
                title: "OHeas feedback",
                body: "Record energy, soreness, stress, and whether yesterday's plan happened.",
                scheduledAt: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
                isEnabled: enabled
            )
        )

        if dataQuality.overallConfidence == .low {
            reminders.append(
                Reminder(
                    type: .dataCoverageReminder,
                    title: "Improve recovery data",
                    body: "Wear Apple Watch tonight to improve sleep and HRV coverage.",
                    scheduledAt: calendar.date(bySettingHour: 21, minute: 30, second: 0, of: Date()) ?? Date(),
                    isEnabled: enabled
                )
            )
        }

        if let sunday = plan.days.last?.date {
            reminders.append(
                Reminder(
                    type: .weeklyReview,
                    title: "Weekly OHeas review",
                    body: "Review completion, recovery, experiments, and next week adjustments.",
                    scheduledAt: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: sunday) ?? sunday,
                    relatedEntityId: plan.id.uuidString,
                    isEnabled: enabled
                )
            )
        }

        return reminders
    }
}

public struct DisabledReminderScheduler: ReminderScheduling {
    public init() {}
    public func requestAuthorization() async -> Bool { false }
    public func schedule(_ reminder: Reminder) async {}
    public func cancel(_ reminder: Reminder) async {}
}
