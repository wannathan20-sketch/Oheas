//
//  DailyMetricsAggregator.swift
//  OHeas
//
//  Aggregates raw HealthKit samples into DailyHealthMetrics.
//  将原始 HealthKit 采样聚合为 DailyHealthMetrics。
//


import Foundation

public struct DailyMetricsAggregator: Sendable {
    public init() {}

    public func aggregate(_ rawDays: [RawDailyHealthData]) -> [DailyHealthMetrics] {
        rawDays
            .sorted { $0.date < $1.date }
            .map(aggregate)
    }

    public func aggregate(_ raw: RawDailyHealthData) -> DailyHealthMetrics {
        let sleepHours = totalSleepHours(raw.sleepSegments)
        let hrv = average(raw.hrvSamples)
        let restingHeartRate = average(raw.restingHeartRateSamples)

        // 缺失值必须保持 nil，并通过 status 表达；不要把“没有数据”折算成 0。
        var statuses: [HealthMetric: MetricStatus] = [:]
        statuses[.sleepHours] = sleepStatus(hours: sleepHours)
        statuses[.hrv] = raw.hrvSamples.isEmpty ? .missing
            : (raw.hrvSamples.count < 3 ? .partial : .valid)
        statuses[.restingHeartRate] = raw.restingHeartRateSamples.isEmpty ? .missing
            : (raw.restingHeartRateSamples.count < 3 ? .partial : .valid)
        statuses[.steps] = raw.steps == nil ? .missing : .valid
        statuses[.activeEnergyKcal] = raw.activeEnergyKcal == nil ? .missing : .valid
        statuses[.exerciseMinutes] = raw.exerciseMinutes == nil ? .missing : .valid
        statuses[.workouts] = raw.workoutsQueried ? .valid : .missing

        return DailyHealthMetrics(
            date: raw.date,
            sleepHours: sleepHours,
            hrv: hrv,
            restingHeartRate: restingHeartRate,
            steps: raw.steps,
            activeEnergyKcal: raw.activeEnergyKcal,
            exerciseMinutes: raw.exerciseMinutes,
            workouts: raw.workouts,
            perMetricStatus: statuses
        )
    }

    private func totalSleepHours(_ segments: [SleepSegment]) -> Double? {
        let seconds = segments.reduce(0.0) { total, segment in
            total + max(0, segment.endDate.timeIntervalSince(segment.startDate))
        }
        return seconds > 0 ? seconds / 3_600.0 : nil
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func sleepStatus(hours: Double?) -> MetricStatus {
        guard let hours else { return .missing }
        // 极短睡眠通常意味着只记录到片段，保留数值但标记为 partial。
        return hours < 2.0 ? .partial : .valid
    }
}
