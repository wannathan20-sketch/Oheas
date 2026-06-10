//
//  MockHealthDataProvider.swift
//  OHeas
//
//  Generates 30 days of deterministic mock health data with edge cases.
//  生成 30 天确定性模拟健康数据，包含边缘情况。
//


import Foundation

#if DEBUG
public struct MockHealthDataProvider: HealthDataProvider {
    private let calendar: Calendar
    private let referenceDate: Date

    public init(calendar: Calendar = .current, referenceDate: Date = Date()) {
        self.calendar = calendar
        self.referenceDate = referenceDate
    }

    public func fetchRawDailyData(days: Int) async throws -> [RawDailyHealthData] {
        generate(days: days)
    }

    public func generate(days: Int = 30) -> [RawDailyHealthData] {
        let today = calendar.startOfDay(for: referenceDate)
        return (0..<days).compactMap { offsetFromStart in
            let daysAgo = days - 1 - offsetFromStart
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return nil
            }
            return makeDay(date: date, daysAgo: daysAgo)
        }
    }

    private func makeDay(date: Date, daysAgo: Int) -> RawDailyHealthData {
        let phase = Double((daysAgo * 7) % 11)
        var sleepHours = 7.35 + (phase - 5.0) * 0.08
        var hrv = 58.0 + (phase - 5.0) * 1.4
        var restingHR = 58.0 - (phase - 5.0) * 0.25
        var steps = 8_400.0 + Double((daysAgo * 631) % 2_400)
        var activeEnergy = 470.0 + Double((daysAgo * 47) % 160)
        var exercise = 34.0 + Double((daysAgo * 5) % 24)
        var workouts = workoutsFor(date: date, daysAgo: daysAgo)
        var missingRecovery = false

        // 用固定的异常日覆盖正常波动，让 demo 稳定展示低睡眠、低 HRV、未戴表和低活动场景。
        switch daysAgo {
        case 0:
            sleepHours = 6.25
            hrv = 43.0
            restingHR = 65.0
            steps = 5_200.0
            activeEnergy = 310.0
            exercise = 12.0
            workouts = []
        case 2, 16:
            sleepHours = 5.75
        case 5, 20:
            hrv = 41.0
            restingHR = 64.0
        case 7, 23:
            missingRecovery = true
            steps = 6_100.0
            activeEnergy = 330.0
            exercise = 8.0
            workouts = []
        case 10, 26:
            steps = 3_200.0
            activeEnergy = 210.0
            exercise = 4.0
            workouts = []
        case 13:
            steps = 15_400.0
            activeEnergy = 860.0
            exercise = 82.0
            workouts = [
                WorkoutSummary(
                    type: "Outdoor Run",
                    startDate: calendar.date(byAdding: .hour, value: 18, to: date) ?? date,
                    durationMinutes: 48,
                    activeEnergyKcal: 520
                )
            ]
        default:
            break
        }

        let sleepSegments = missingRecovery ? [] : makeSleepSegments(for: date, hours: sleepHours)

        return RawDailyHealthData(
            date: date,
            sleepSegments: sleepSegments,
            hrvSamples: missingRecovery ? [] : [hrv - 2.0, hrv, hrv + 1.5],
            restingHeartRateSamples: missingRecovery ? [] : [restingHR - 0.5, restingHR, restingHR + 0.8],
            steps: steps,
            activeEnergyKcal: activeEnergy,
            exerciseMinutes: exercise,
            workouts: workouts,
            workoutsQueried: true
        )
    }

    private func makeSleepSegments(for date: Date, hours: Double) -> [SleepSegment] {
        let end = calendar.date(byAdding: .hour, value: 7, to: date) ?? date
        let start = end.addingTimeInterval(-hours * 3_600)
        let deepEnd = start.addingTimeInterval(hours * 3_600 * 0.18)
        let coreEnd = start.addingTimeInterval(hours * 3_600 * 0.72)

        return [
            SleepSegment(startDate: start, endDate: deepEnd, stage: .asleepDeep),
            SleepSegment(startDate: deepEnd, endDate: coreEnd, stage: .asleepCore),
            SleepSegment(startDate: coreEnd, endDate: end, stage: .asleepREM)
        ]
    }

    private func workoutsFor(date: Date, daysAgo: Int) -> [WorkoutSummary] {
        guard daysAgo % 3 == 0 else { return [] }
        return [
            WorkoutSummary(
                type: daysAgo % 2 == 0 ? "Strength Training" : "Outdoor Walk",
                startDate: calendar.date(byAdding: .hour, value: 17, to: date) ?? date,
                durationMinutes: daysAgo % 2 == 0 ? 42 : 36,
                activeEnergyKcal: daysAgo % 2 == 0 ? 260 : 190
            )
        ]
    }
}
#endif
