//
//  MetricTrendCard.swift
//  OHeas
//
//  Composite metric card — icon + value + trend indicator + interactive sparkline.
//  复合指标卡片 — 图标 + 数值 + 趋势指示器 + 交互式迷你图。
//
//  Market reference: Bevel health metric cards, Apple Health metric tiles with trends.
//

import OHeasCore
import SwiftUI

// MARK: - MetricTrendCard

/// A self-contained metric card that shows the current value, unit, 7-day trend
/// indicator, and an interactive sparkline for drag-to-inspect.
///
/// Use this in grid layouts (2-column LazyVGrid) or in vertical stacks.
struct MetricTrendCard: View {
    let metric: HealthMetric
    let todayValue: Double?
    let unit: String
    let recentValues: [Double?]
    let recentDates: [Date]
    let status: MetricStatus
    let comparison: MetricComparison?
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: icon + name + trend
            headerRow

            // Value display
            valueRow

            // Interactive sparkline
            sparklineSection
        }
        .padding(10)
        .background(OhColor.secondaryGroupedBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 4) {
            Image(systemName: metricIcon(metric))
                .font(.caption2)
                .foregroundStyle(metricColor(metric))

            Text(language.metric(metric))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Status badge
            if status != .valid {
                Image(systemName: statusIcon)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }

            // Trend indicator
            if let trend = Trend.compute(
                from: metric == .restingHeartRate
                    ? recentValues  // TrendIndicator handles inversion via higherIsBetter
                    : recentValues
            ) {
                TrendIndicator(
                    trend: trend,
                    higherIsBetter: metric != .restingHeartRate
                )
            }
        }
    }

    private var valueRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(formattedValue)
                .font(.title3.weight(.semibold))
                .foregroundStyle(valueColor)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // Delta vs baseline
            if let comp = comparison, let delta = comp.absoluteDelta {
                HStack(spacing: 2) {
                    Image(systemName: deltaText(comp).hasPrefix("+") ? "arrow.up" : "arrow.down")
                        .font(.system(size: 7, weight: .bold))
                    Text(deltaText(comp))
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(deltaColor(comp))
            }
        }
    }

    @ViewBuilder
    private var sparklineSection: some View {
        let validCount = recentValues.compactMap { $0 }.count
        if validCount >= 2 {
            InteractiveSparklineView(
                values: recentValues,
                dates: recentDates,
                color: metricColor(metric),
                valueFormatter: { formatSparklineValue($0) },
                dateFormatter: { formatSparklineDate($0) }
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private var formattedValue: String {
        guard let val = todayValue else { return language.missing }
        if metric == .steps {
            return val.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
        }
        return val.formatted(.number.precision(.fractionLength(1)))
    }

    private var valueColor: Color {
        todayValue != nil ? .primary : .secondary
    }

    private var statusIcon: String {
        status == .partial ? "info.circle" : "questionmark.circle.fill"
    }

    private var statusColor: Color {
        status == .partial ? .secondary : .secondary
    }

    private func deltaText(_ comp: MetricComparison) -> String {
        guard let abs = comp.absoluteDelta else { return "--" }
        if comp.metric == .restingHeartRate {
            return "\(abs >= 0 ? "+" : "")\(abs.formatted(.number.precision(.fractionLength(1))))"
        }
        if let pct = comp.percentageDelta {
            return "\(pct >= 0 ? "+" : "")\(pct.formatted(.number.precision(.fractionLength(0))))%"
        }
        return "\(abs >= 0 ? "+" : "")\(abs.formatted(.number.precision(.fractionLength(1))))"
    }

    private func deltaColor(_ comp: MetricComparison) -> Color {
        guard let delta = comp.absoluteDelta else { return .secondary }
        switch comp.metric {
        case .sleepHours, .hrv, .steps, .activeEnergyKcal, .exerciseMinutes:
            return delta < 0 ? OhColor.warning : OhColor.success
        case .restingHeartRate:
            return delta > 0 ? OhColor.warning : OhColor.success
        case .workouts: return .secondary
        }
    }

    private func formatSparklineValue(_ value: Double) -> String {
        if metric == .steps {
            return value.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
        }
        return String(format: "%.1f", value)
    }

    private func formatSparklineDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}

// MARK: - Previews

#Preview("Metric trend cards grid") {
    let calendar = Calendar.current
    let today = Date()
    let dates = (0..<7).map { calendar.date(byAdding: .day, value: -6 + $0, to: today)! }

    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
        MetricTrendCard(
            metric: .sleepHours,
            todayValue: 7.2,
            unit: "h",
            recentValues: [6.8, 7.1, 6.5, 7.3, 7.0, 6.9, 7.2],
            recentDates: dates,
            status: .valid,
            comparison: MetricComparison(metric: .sleepHours, todayValue: 7.2, baselineValue: 6.8, absoluteDelta: 0.4, percentageDelta: 0.059, unit: "h"),
            language: .english
        )
        MetricTrendCard(
            metric: .hrv,
            todayValue: 48,
            unit: "ms",
            recentValues: [52, 50, 45, 48, 55, 49, 48],
            recentDates: dates,
            status: .valid,
            comparison: MetricComparison(metric: .hrv, todayValue: 48, baselineValue: 52, absoluteDelta: -4, percentageDelta: -0.077, unit: "ms"),
            language: .english
        )
        MetricTrendCard(
            metric: .restingHeartRate,
            todayValue: 62,
            unit: "bpm",
            recentValues: [58, 60, 57, 59, 62, 58, 62],
            recentDates: dates,
            status: .valid,
            comparison: MetricComparison(metric: .restingHeartRate, todayValue: 62, baselineValue: 58, absoluteDelta: 4, percentageDelta: 0.069, unit: "bpm"),
            language: .english
        )
        MetricTrendCard(
            metric: .steps,
            todayValue: 8500,
            unit: "steps",
            recentValues: [7200, 8100, 6500, 9000, 7800, 8300, 8500],
            recentDates: dates,
            status: .valid,
            comparison: MetricComparison(metric: .steps, todayValue: 8500, baselineValue: 7200, absoluteDelta: 1300, percentageDelta: 0.181, unit: "steps"),
            language: .english
        )
    }
    .padding()
}
