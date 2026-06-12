//
//  TrendIndicator.swift
//  OHeas
//
//  Trend direction indicator — arrow + percentage change + color coding.
//  趋势方向指示器 — 箭头 + 百分比变化 + 颜色编码。
//
//  Market reference: Whoop trend arrows, Apple Health trend indicators.
//

import SwiftUI

// MARK: - Trend model

/// A computed trend from a series of values.
struct Trend: Equatable {
    enum Direction: Equatable {
        case up      // improving
        case flat    // stable
        case down    // declining
    }

    let direction: Direction
    /// Percentage change (0.0-1.0), nil if not computable.
    let percentage: Double?

    /// Compute trend from a series of optional values using simple linear regression.
    /// Returns nil if fewer than 3 valid data points.
    static func compute(from values: [Double?]) -> Trend? {
        let valid = values.enumerated().compactMap { (i, v) -> (Double, Double)? in
            v.map { (Double(i), $0) }
        }
        guard valid.count >= 3 else { return nil }

        let n = Double(valid.count)
        let sumX = valid.map(\.0).reduce(0, +)
        let sumY = valid.map(\.1).reduce(0, +)
        let sumXY = valid.map { $0.0 * $0.1 }.reduce(0, +)
        let sumX2 = valid.map { $0.0 * $0.0 }.reduce(0, +)

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let avgY = sumY / n

        guard avgY != 0 else { return nil }

        // Percentage change is slope * (count-1) relative to average
        let totalChange = slope * (n - 1)
        let pct = totalChange / avgY

        let direction: Direction
        if pct > 0.03 {
            direction = .up
        } else if pct < -0.03 {
            direction = .down
        } else {
            direction = .flat
        }

        return Trend(direction: direction, percentage: abs(pct))
    }

    /// Compute trend for metrics where lower is better (e.g., resting heart rate).
    /// Flips the direction interpretation.
    static func computeInverted(from values: [Double?]) -> Trend? {
        guard let trend = compute(from: values) else { return nil }
        let flipped: Direction = switch trend.direction {
        case .up:   .down
        case .down: .up
        case .flat: .flat
        }
        return Trend(direction: flipped, percentage: trend.percentage)
    }
}

// MARK: - TrendIndicator view

/// A compact trend indicator showing direction arrow + percentage.
///
/// Uses semantic colors: green for improving, orange for declining, gray for flat.
/// Respects accessibility by showing text alongside the arrow.
struct TrendIndicator: View {
    let trend: Trend?
    /// When true, "up" = good (default). When false, "down" = good (e.g., RHR).
    var higherIsBetter: Bool = true

    var body: some View {
        if let trend = trend {
            HStack(spacing: 2) {
                Image(systemName: arrowName(for: trend.direction))
                    .font(.system(size: 9, weight: .bold))
                if let pct = trend.percentage {
                    Text(formatPercentage(pct))
                        .font(.caption2.weight(.medium))
                }
            }
            .foregroundStyle(trendColor(for: trend.direction))
        } else {
            // Insufficient data — show dash
            Text("--")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Helpers

    private func arrowName(for direction: Trend.Direction) -> String {
        let effective = higherIsBetter ? direction : direction.flipped
        return switch effective {
        case .up:   "arrow.up"
        case .flat: "arrow.right"
        case .down: "arrow.down"
        }
    }

    private func trendColor(for direction: Trend.Direction) -> Color {
        let effective = higherIsBetter ? direction : direction.flipped
        return switch effective {
        case .up:   OhColor.success
        case .flat: .secondary
        case .down: OhColor.warning
        }
    }

    private func formatPercentage(_ pct: Double) -> String {
        if pct < 0.01 {
            return "<1%"
        }
        return String(format: "%.0f%%", pct * 100)
    }
}

// MARK: - Convenience

extension Trend.Direction {
    var flipped: Trend.Direction {
        switch self {
        case .up:   .down
        case .down: .up
        case .flat: .flat
        }
    }
}

// MARK: - Previews

#Preview("Trend variations") {
    VStack(spacing: 16) {
        TrendIndicator(trend: Trend(direction: .up, percentage: 0.12))
        TrendIndicator(trend: Trend(direction: .down, percentage: 0.08))
        TrendIndicator(trend: Trend(direction: .flat, percentage: 0.01))
        TrendIndicator(trend: nil)
        TrendIndicator(trend: Trend(direction: .down, percentage: 0.10), higherIsBetter: false)
        Text("(RHR: down arrow = good)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
