//
//  BetaReadinessReport.swift
//  OHeas
//
//  BetaReadinessReport.swift — OHeas UI component.
//  BetaReadinessReport.swift — OHeas UI 组件。
//


import Foundation
import OHeasCore

struct BetaReadinessReport: Codable {
    var generatedAt: Date
    var dataSource: String
    var healthKitPermissions: HealthKitPermissionSummary
    var perMetricCoverage: [String: String]
    var last7DaysComplete: Int
    var recoveryBaselineDays: Int
    var baselineReady: Bool
    var currentMode: String
    var overallReadiness: ReadinessLevel
    var missingMetrics: [String]
    var recommendations: [String]

    enum ReadinessLevel: String, Codable {
        case ready
        case needsMoreData
        case blocked
    }

    struct HealthKitPermissionSummary: Codable {
        var authorized: Bool
        var sleepGranted: Bool
        var hrvGranted: Bool
        var restingHeartRateGranted: Bool
        var stepsGranted: Bool
        var activeEnergyGranted: Bool
        var exerciseMinutesGranted: Bool
        var workoutsGranted: Bool
    }

    /// Builds a BetaReadinessReport from the current ViewModel state.
    /// Always produces a report — returns `.needsMoreData` when data is sparse.
    static func build(
        dataSource: HealthDataSource,
        todayMetrics: DailyHealthMetrics?,
        recentMetrics: [DailyHealthMetrics],
        baseline14d: HealthBaseline?
    ) -> BetaReadinessReport {
        // 1) Coverage per metric from today or most recent day
        var coverage: [String: String] = [:]
        if let today = todayMetrics {
            for metric in HealthMetric.allCases {
                let status = today.perMetricStatus[metric] ?? .missing
                coverage[metric.rawValue] = status.rawValue
            }
        } else {
            for metric in HealthMetric.allCases {
                coverage[metric.rawValue] = MetricStatus.missing.rawValue
            }
        }

        // 2) 7-day completeness
        let today = Calendar.current.startOfDay(for: Date())
        var completeDays = 0
        for dayOffset in 0..<7 {
            guard let target = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let found = recentMetrics.first { Calendar.current.isDate($0.date, inSameDayAs: target) }
            if let day = found {
                let validCount = HealthMetric.allCases.filter { day.perMetricStatus[$0] == .valid || day.perMetricStatus[$0] == .partial }.count
                if validCount >= 4 { completeDays += 1 }
            }
        }
        let sevenDayComplete = min(completeDays, 7)

        // 3) Recovery baseline days
        let recoveryDays = (baseline14d?.sampleCounts[.sleepHours] ?? 0)
        let baselineReady = recoveryDays >= 7

        // 4) Missing metrics
        let missing: [String] = coverage.compactMap { key, value in
            value == MetricStatus.missing.rawValue ? key : nil
        }

        // 5) Recommendations
        var recommendations: [String] = []
        if !baselineReady {
            recommendations.append("Wear Apple Watch overnight for at least 7 days to establish a recovery baseline.")
        }
#if DEBUG
        if dataSource == .mock {
            recommendations.append("Switch to a real device with HealthKit to validate data pipeline end-to-end.")
        }
#endif
        if missing.count >= 3 {
            recommendations.append("Several metrics are missing. Check Apple Watch pairing and Health permissions in Settings.")
        }
        if sevenDayComplete < 5 {
            recommendations.append("Less than 5 of the past 7 days have complete data. Ensure Apple Watch is worn daily and sleep tracking is enabled.")
        }
        if recommendations.isEmpty {
            recommendations.append("All readiness checks passed. The app is ready for real-device validation.")
        }

        // 6) Overall readiness
        let overall: ReadinessLevel
        var needsMore = false
#if DEBUG
        if dataSource == .mock { needsMore = true }
#endif
        if !baselineReady || missing.count >= 2 { needsMore = true }
        if needsMore {
            overall = .needsMoreData
        } else if recommendations.count <= 1 {
            overall = .ready
        } else {
            overall = .needsMoreData
        }

        let perm = HealthKitPermissionSummary(
            authorized: dataSource == .appleHealth,
            sleepGranted: coverage["sleepHours"] != MetricStatus.missing.rawValue,
            hrvGranted: coverage["hrv"] != MetricStatus.missing.rawValue,
            restingHeartRateGranted: coverage["restingHeartRate"] != MetricStatus.missing.rawValue,
            stepsGranted: coverage["steps"] != MetricStatus.missing.rawValue,
            activeEnergyGranted: coverage["activeEnergyKcal"] != MetricStatus.missing.rawValue,
            exerciseMinutesGranted: coverage["exerciseMinutes"] != MetricStatus.missing.rawValue,
            workoutsGranted: coverage["workouts"] != MetricStatus.missing.rawValue
        )

        return BetaReadinessReport(
            generatedAt: Date(),
            dataSource: dataSource == .appleHealth ? "appleHealth" : "mock",
            healthKitPermissions: perm,
            perMetricCoverage: coverage,
            last7DaysComplete: sevenDayComplete,
            recoveryBaselineDays: recoveryDays,
            baselineReady: baselineReady,
            currentMode: dataSource == .appleHealth ? "Real Device" : "Mock",
            overallReadiness: overall,
            missingMetrics: missing,
            recommendations: recommendations
        )
    }
}
