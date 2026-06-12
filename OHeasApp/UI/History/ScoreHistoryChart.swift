//
//  ScoreHistoryChart.swift
//  OHeas
//
//  Interactive 30-day Body Budget Score timeline chart.
//  Shows color-coded daily dots, 5-day moving average, and drag-to-inspect.
//  可交互的 30 天身体预算评分时间轴图表。
//

import SwiftUI
import OHeasCore

// MARK: - ScoreHistoryChart

/// Interactive chart showing Body Budget Score over ~30 days.
///
/// The chart renders:
/// - Horizontal category bands (red/orange/yellow/green background zones)
/// - One dot per day, color-coded by score range
/// - A 5-day simple moving average trend line in indigo
/// - Drag gesture to inspect a single day (tooltip with date + score + category)
/// - Date axis labels every ~5 days
/// - A compact legend row
struct ScoreHistoryChart: View {
    let days: [HistoricalDayDetail]
    let language: AppLanguage

    @State private var dragIndex: Int?
    @State private var isDragging = false

    private let chartHeight: CGFloat = 150
    private let dotRadius: CGFloat = 4
    private let categoryThresholds: [(CGFloat, BudgetCategory)] = [
        (85, .excellent),
        (70, .good),
        (55, .fair),
        (35, .strained)
    ]

    var body: some View {
        let sorted = days.sorted { $0.date < $1.date }

        VStack(alignment: .leading, spacing: 8) {
            // Title
            Label(language.text(.scoreHistoryTitle), systemImage: "chart.xyaxis.line")
                .font(.subheadline.weight(.semibold))

            if sorted.isEmpty {
                emptyChart
            } else {
                chartArea(sorted)
                dateAxis(sorted)
                legendRow
            }
        }
    }

    // MARK: - Chart Area

    private func chartArea(_ sorted: [HistoricalDayDetail]) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = chartHeight

            ZStack(alignment: .topLeading) {
                // Background bands
                categoryBands(width: width, height: height)

                // 5-day moving average trend line
                trendLine(sorted, width: width, height: height)

                // Day dots
                ForEach(Array(sorted.enumerated()), id: \.element.id) { i, day in
                    let x = xPosition(i, count: sorted.count, width: width)
                    let y = yPosition(day.score?.value, height: height)
                    Circle()
                        .fill(scoreColor(day.score?.value))
                        .frame(width: dotRadius * 2, height: dotRadius * 2)
                        .position(x: x, y: y)
                }

                // Drag indicator
                if let idx = dragIndex, idx < sorted.count {
                    let day = sorted[idx]
                    let x = xPosition(idx, count: sorted.count, width: width)
                    let y = yPosition(day.score?.value, height: height)

                    // Vertical indicator line
                    Rectangle()
                        .fill(Color.indigo.opacity(0.5))
                        .frame(width: 1)
                        .position(x: x, y: height / 2)

                    // Highlighted dot
                    Circle()
                        .fill(scoreColor(day.score?.value))
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)

                    // Tooltip
                    tooltipView(day)
                        .position(
                            x: tooltipX(x, width: width, tooltipWidth: 120),
                            y: max(28, y - 40)
                        )
                }
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        isDragging = true
                        let idx = indexForX(value.location.x, count: sorted.count, width: width)
                        dragIndex = idx
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            isDragging = false
                            dragIndex = nil
                        }
                    }
            )
            .animation(.easeOut(duration: 0.15), value: dragIndex)
        }
        .frame(height: chartHeight)
    }

    // MARK: - Background Category Bands

    private func categoryBands(width: CGFloat, height: CGFloat) -> some View {
        // Y = 0 is top (score 100), Y = height is bottom (score 0)
        // Bands from top to bottom: excellent (green) → good → fair → strained → depleted (red)
        let bands: [(CGFloat, CGFloat, Color)] = [
            (0, 0.15 * height, Color.green.opacity(0.06)),             // 85-100 Excellent
            (0.15 * height, 0.30 * height, Color.mint.opacity(0.06)),   // 70-84 Good
            (0.30 * height, 0.45 * height, Color.yellow.opacity(0.06)), // 55-69 Fair
            (0.45 * height, 0.65 * height, Color.orange.opacity(0.06)), // 35-54 Strained
            (0.65 * height, height, Color.red.opacity(0.06)),           // 0-34 Depleted
        ]

        return ZStack(alignment: .topLeading) {
            ForEach(0..<bands.count, id: \.self) { i in
                let (top, bottom, color) = bands[i]
                Rectangle()
                    .fill(color)
                    .frame(width: width, height: bottom - top)
                    .position(x: width / 2, y: (top + bottom) / 2)
            }
        }
    }

    // MARK: - 5-Day Moving Average Trend Line

    private func trendLine(_ sorted: [HistoricalDayDetail], width: CGFloat, height: CGFloat) -> some View {
        let values: [(Int, Double?)] = sorted.enumerated().map { i, day in
            let doubleValue: Double? = if let score = day.score {
                Double(score.value)
            } else { nil }
            return (i, doubleValue)
        }

        // Compute 5-day simple moving average (centered)
        let sma = computeSMA(values: values, window: 5)

        guard !sma.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            Path { path in
                var first = true
                for (i, avg) in sma {
                    let x = xPosition(i, count: sorted.count, width: width)
                    let y = yPosition(Int(avg.rounded()), height: height)
                    if first {
                        path.move(to: CGPoint(x: x, y: y))
                        first = false
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.indigo, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        )
    }

    /// Compute simple moving average for a window centered on each point.
    private func computeSMA(values: [(Int, Double?)], window: Int) -> [(Int, Double)] {
        let half = window / 2
        var result: [(Int, Double)] = []
        for (i, _) in values {
            let start = max(0, i - half)
            let end = min(values.count - 1, i + half)
            let slice = values[start...end].compactMap(\.1)
            if slice.count >= max(3, window / 2) {
                let avg = slice.reduce(0, +) / Double(slice.count)
                result.append((i, avg))
            }
        }
        return result
    }

    // MARK: - Date Axis

    private func dateAxis(_ sorted: [HistoricalDayDetail]) -> some View {
        let step = max(1, sorted.count / 5)
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = "M/d"

        return HStack(spacing: 0) {
            ForEach(0..<sorted.count, id: \.self) { i in
                if i % step == 0 {
                    Text(formatter.string(from: sorted[i].date))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: i == 0 ? .leading : i >= sorted.count - step ? .trailing : .center)
                        .lineLimit(1)
                } else {
                    Spacer().frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        let categories: [(String, Color)] = [
            (language.budgetCategory(.excellent), scoreColor(90)),
            (language.budgetCategory(.good), scoreColor(78)),
            (language.budgetCategory(.fair), scoreColor(62)),
            (language.budgetCategory(.strained), scoreColor(45)),
            (language.budgetCategory(.depleted), scoreColor(25))
        ]

        return HStack(spacing: 10) {
            ForEach(categories, id: \.0) { (label, color) in
                HStack(spacing: 3) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            // Trend line indicator
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.indigo)
                    .frame(width: 10, height: 2)
                Text(language.text(.chartTrendLine))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyChart: some View {
        Rectangle()
            .fill(OhColor.cardBg)
            .frame(height: chartHeight)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text(language.text(.trendsEmptyDescription))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.small))
    }

    // MARK: - Tooltip

    private func tooltipView(_ day: HistoricalDayDetail) -> some View {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = "M/d EEE"

        return HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatter.string(from: day.date))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                if let score = day.score {
                    HStack(spacing: 4) {
                        Text("\(score.value)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(scoreColor(score.value))
                        Text(language.text(.chartScoreUnit))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(language.budgetCategory(score.category))
                            .font(.caption2)
                            .foregroundStyle(scoreColor(score.value).opacity(0.8))
                    }
                } else {
                    Text(language.text(.trendsNoScore))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    // MARK: - Coordinate Helpers

    /// X position for a data point index.
    private func xPosition(_ index: Int, count: Int, width: CGFloat) -> CGFloat {
        guard count > 1 else { return width / 2 }
        let margin: CGFloat = dotRadius + 4
        let available = width - margin * 2
        return margin + (CGFloat(index) / CGFloat(count - 1)) * available
    }

    /// Y position for a score value (0-100). Score 100 = top, 0 = bottom.
    private func yPosition(_ scoreValue: Int?, height: CGFloat) -> CGFloat {
        guard let score = scoreValue else { return height / 2 }
        let clamped = max(0, min(100, score))
        let topMargin: CGFloat = 10
        let bottomMargin: CGFloat = 10
        let available = height - topMargin - bottomMargin
        let fraction = CGFloat(100 - clamped) / 100.0
        return topMargin + fraction * available
    }

    /// Snap X coordinate to the nearest data point index.
    private func indexForX(_ x: CGFloat, count: Int, width: CGFloat) -> Int {
        guard count > 1 else { return 0 }
        let margin: CGFloat = dotRadius + 4
        let available = width - margin * 2
        let raw = (x - margin) / available * CGFloat(count - 1)
        return max(0, min(count - 1, Int(raw.rounded())))
    }

    /// Keep tooltip within chart bounds horizontally.
    private func tooltipX(_ dotX: CGFloat, width: CGFloat, tooltipWidth: CGFloat) -> CGFloat {
        let half = tooltipWidth / 2
        if dotX - half < 0 { return half }
        if dotX + half > width { return width - half }
        return dotX
    }

    /// Color for a given score value.
    private func scoreColor(_ scoreValue: Int?) -> Color {
        guard let score = scoreValue else { return Color.secondary.opacity(0.4) }
        switch score {
        case 85...: return Color.green
        case 70..<85: return Color.mint
        case 55..<70: return Color.yellow
        case 35..<55: return Color.orange
        default: return Color.red
        }
    }
}
