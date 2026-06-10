//
//  BaselineEngine.swift
//  OHeas
//
//  Computes health baselines over 7/14/30 day windows.
//  计算 7/14/30 天窗口的健康基线。
//


import Foundation

public struct BaselineEngine: Sendable {
    public init() {}

    public func baseline(from metrics: [DailyHealthMetrics], endingBefore date: Date? = nil, windowDays: Int) -> HealthBaseline {
        let sorted = metrics.sorted { $0.date < $1.date }
        // 今日异常不应污染个人基线；调用方传入 endingBefore 时只使用今天之前的数据。
        let eligible = sorted.filter { metric in
            guard let date else { return true }
            return metric.date < date
        }
        let window = Array(eligible.suffix(windowDays))

        return HealthBaseline(
            windowDays: windowDays,
            averageSleepHours: average(window.compactMap(\.sleepHours)),
            averageHRV: average(window.compactMap(\.hrv)),
            averageRestingHeartRate: average(window.compactMap(\.restingHeartRate)),
            averageSteps: average(window.compactMap(\.steps)),
            averageActiveEnergy: average(window.compactMap(\.activeEnergyKcal)),
            averageExerciseMinutes: average(window.compactMap(\.exerciseMinutes)),
            sampleCounts: [
                .sleepHours: window.compactMap(\.sleepHours).count,
                .hrv: window.compactMap(\.hrv).count,
                .restingHeartRate: window.compactMap(\.restingHeartRate).count,
                .steps: window.compactMap(\.steps).count,
                .activeEnergyKcal: window.compactMap(\.activeEnergyKcal).count,
                .exerciseMinutes: window.compactMap(\.exerciseMinutes).count
            ]
        )
    }

    public func comparisons(today: DailyHealthMetrics, baseline: HealthBaseline) -> [MetricComparison] {
        [
            comparison(.sleepHours, today.sleepHours, baseline.averageSleepHours, unit: "h"),
            comparison(.hrv, today.hrv, baseline.averageHRV, unit: "ms"),
            comparison(.restingHeartRate, today.restingHeartRate, baseline.averageRestingHeartRate, unit: "bpm"),
            comparison(.steps, today.steps, baseline.averageSteps, unit: "steps"),
            comparison(.activeEnergyKcal, today.activeEnergyKcal, baseline.averageActiveEnergy, unit: "kcal"),
            comparison(.exerciseMinutes, today.exerciseMinutes, baseline.averageExerciseMinutes, unit: "min")
        ]
    }

    private func comparison(_ metric: HealthMetric, _ today: Double?, _ baseline: Double?, unit: String) -> MetricComparison {
        guard let today, let baseline, baseline != 0 else {
            return MetricComparison(metric: metric, todayValue: today, baselineValue: baseline, absoluteDelta: nil, percentageDelta: nil, unit: unit)
        }
        let absolute = today - baseline
        let percent = absolute / baseline * 100.0
        return MetricComparison(metric: metric, todayValue: today, baselineValue: baseline, absoluteDelta: absolute, percentageDelta: percent, unit: unit)
    }

    private func average(_ values: [Double]) -> Double? {
        // compactMap 已经剔除了 nil，因此平均值只来自真实存在的样本。
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
