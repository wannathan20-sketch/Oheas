//
//  TodayMetricsGrid.swift
//  OHeas
//
//  TodayMetricsGrid.swift — 2-column metrics comparison grid with workouts list.
//  Phase 17: upgraded to MetricTrendCard with interactive sparklines + trend indicators.
//

import OHeasCore
import SwiftUI

/// LazyVGrid of metric trend cards plus workouts list.
struct TodayMetricsGrid: View {
    let comparisons: [MetricComparison]
    let todayMetrics: DailyHealthMetrics?
    let recentDailyMetrics: [DailyHealthMetrics]
    let language: AppLanguage

    var body: some View {
        if !comparisons.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(language.text(.metricsTab), systemImage: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(comparisons, id: \.metric) { comparison in
                        MetricTrendCard(
                            metric: comparison.metric,
                            todayValue: comparison.todayValue,
                            unit: comparison.unit,
                            recentValues: recentValues(for: comparison.metric),
                            recentDates: recentDates,
                            status: todayMetrics?.perMetricStatus[comparison.metric] ?? .missing,
                            comparison: comparison,
                            language: language
                        )
                    }
                }

                if let workouts = todayMetrics?.workouts, !workouts.isEmpty {
                    workoutsList(workouts)
                }
            }
            .padding()
            .background(OhColor.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        }
    }

    // MARK: - Data extraction

    private var recentDates: [Date] {
        recentDailyMetrics.map(\.date)
    }

    private func recentValues(for metric: HealthMetric) -> [Double?] {
        recentDailyMetrics.map { metrics -> Double? in
            switch metric {
            case .sleepHours:        metrics.sleepHours
            case .hrv:              metrics.hrv
            case .restingHeartRate:  metrics.restingHeartRate
            case .steps:             metrics.steps
            case .activeEnergyKcal:  metrics.activeEnergyKcal
            case .exerciseMinutes:   metrics.exerciseMinutes
            case .workouts:          Double(metrics.workouts.count)
            }
        }
    }

    // MARK: - Workouts list

    private func workoutsList(_ workouts: [WorkoutSummary]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(language.text(.workouts))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(workouts) { workout in
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundStyle(.pink)
                    Text(workout.type)
                        .font(.caption)
                    Spacer()
                    Text("\(workout.durationMinutes.formatted()) \(language.minuteUnit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }
}
