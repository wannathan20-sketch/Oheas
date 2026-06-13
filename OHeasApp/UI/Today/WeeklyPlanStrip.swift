//
//  WeeklyPlanStrip.swift
//  OHeas
//
//  WeeklyPlanStrip.swift — today's plan card + weekly day-scroll strip.
//

import OHeasCore
import SwiftUI

/// Horizontal scrolling weekly plan strip with today's plan highlight.
struct WeeklyPlanStrip: View {
    let currentWeeklyPlan: WeeklyPlan?
    let todayDailyPlan: DailyPlan?
    let language: AppLanguage

    var body: some View {
        if let plan = currentWeeklyPlan, !plan.days.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                if let today = todayDailyPlan {
                    todayPlanCard(today)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(plan.days.prefix(7).enumerated()), id: \.element.id) { _, day in
                            dayCircle(day)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding()
            .background(OhColor.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        }
    }

    private func todayPlanCard(_ today: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(today.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(today.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(language.planType(today.planType))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.10))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                Label("\(today.estimatedDurationMinutes) \(language.text(.minUnit))", systemImage: "timer")
                Label(language.planIntensity(today.intensity), systemImage: "gauge")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
    }

    private func dayCircle(_ day: DailyPlan) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        return VStack(spacing: 6) {
            Text(dayOfWeek(day.date))
                .font(.caption2.weight(isToday ? .bold : .medium))
                .foregroundStyle(isToday ? .white : .secondary)
                .frame(width: isToday ? 36 : 32, height: isToday ? 36 : 32)
                .background(isToday ? Color.accentColor : OhColor.coachBubbleBg)
                .clipShape(Circle())

            Text(day.title)
                .font(.caption)
                .lineLimit(isToday ? 2 : 1)
                .multilineTextAlignment(.center)
                .frame(width: isToday ? 96 : 64)

            Text(language.planType(day.planType))
                .font(.caption2)
                .foregroundStyle(isToday ? Color.accentColor : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isToday ? Color.accentColor.opacity(0.10) : OhColor.coachBubbleBg)
                .clipShape(Capsule())
        }
        .frame(width: isToday ? 108 : 72, height: 92)
        .background(isToday ? Color.accentColor.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = Self.dayOfWeekFormatter(locale: language.locale)
        return formatter.string(from: date)
    }

    private static func dayOfWeekFormatter(locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEE"
        return formatter
    }
}
