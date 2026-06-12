//
//  InteractiveSparklineView.swift
//  OHeas
//
//  Interactive sparkline chart — drag to inspect individual data points.
//  交互式迷你折线图 — 拖动查看各数据点详情。
//
//  Builds on SparklineView but adds DragGesture, a vertical indicator line,
//  and a floating tooltip showing date + value at the dragged position.
//

import SwiftUI

// MARK: - InteractiveSparklineView

/// An enhanced sparkline that responds to drag gestures.
///
/// Drag horizontally across the chart to see a vertical indicator line and
/// a tooltip showing the date and value at that point. Missing (nil) values
/// are skipped during drag — the indicator snaps to the nearest valid point.
struct InteractiveSparklineView: View {
    let values: [Double?]
    let dates: [Date]
    let color: Color
    var highlightLast: Bool = true
    var valueFormatter: (Double) -> String = { String(format: "%.1f", $0) }
    var dateFormatter: (Date) -> String = { date in
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }

    private let chartHeight: CGFloat = 36
    private let tooltipHeight: CGFloat = 22

    @State private var dragIndex: Int? = nil
    @State private var isDragging: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            // Tooltip area
            tooltipOverlay
                .frame(height: tooltipHeight)

            // Chart area
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    let validPairs = values.enumerated().compactMap { (i, v) -> (Int, Double)? in
                        v.map { (i, $0) }
                    }
                    let count = values.count

                    // Draw the sparkline
                    if count > 1, validPairs.count > 1 {
                        let (minY, maxY, yRange, xStep) = computeScale(
                            validPairs: validPairs, count: count, width: geo.size.width
                        )

                        linePath(values: values, count: count, xStep: xStep,
                                 minY: minY, yRange: yRange, chartHeight: chartHeight)
                            .stroke(color, style: StrokeStyle(lineWidth: 2,
                                                              lineCap: .round, lineJoin: .round))

                        // Last point dot (hidden during drag)
                        if highlightLast, !isDragging, let (lastIdx, lastVal) = validPairs.last {
                            let dotX = xStep * CGFloat(lastIdx)
                            let dotY = yPosition(value: lastVal, minY: minY, yRange: yRange)
                            Circle()
                                .fill(color)
                                .frame(width: 5, height: 5)
                                .position(x: dotX, y: dotY)
                        }

                        // Drag indicator line + dot
                        if let idx = dragIndex, let value = values[idx] {
                            let indicatorX = xStep * CGFloat(idx)
                            let indicatorY = yPosition(value: value, minY: minY, yRange: yRange)

                            // Vertical line
                            Rectangle()
                                .fill(color.opacity(0.4))
                                .frame(width: 1)
                                .position(x: indicatorX, y: chartHeight / 2)
                                .frame(height: chartHeight)

                            // Highlight dot
                            Circle()
                                .fill(color)
                                .frame(width: 7, height: 7)
                                .position(x: indicatorX, y: indicatorY)
                                .shadow(color: color.opacity(0.5), radius: 2)
                        }
                    } else if let first = validPairs.first {
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                            .position(x: geo.size.width / 2, y: chartHeight / 2)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            let count = values.count
                            guard count > 1 else { return }
                            let xStep = geo.size.width / CGFloat(count - 1)
                            let idx = Int((gesture.location.x / xStep).rounded())
                            let clamped = min(max(idx, 0), count - 1)
                            dragIndex = values[clamped] != nil ? clamped : dragIndex
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragIndex = nil
                        }
                )
            }
            .frame(height: chartHeight)
        }
        .frame(height: chartHeight + tooltipHeight + 2)
    }

    // MARK: - Tooltip

    @ViewBuilder
    private var tooltipOverlay: some View {
        if isDragging, let idx = dragIndex,
           idx < values.count, idx < dates.count,
           let value = values[idx] {
            HStack(spacing: 4) {
                Text(dateFormatter(dates[idx]))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(valueFormatter(value))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial)
            )
            .transition(.opacity.animation(.easeOut(duration: 0.15)))
        } else {
            // Empty placeholder to maintain height
            Color.clear
        }
    }

    // MARK: - Drawing helpers

    private func computeScale(
        validPairs: [(Int, Double)],
        count: Int,
        width: CGFloat
    ) -> (Double, Double, Double, CGFloat) {
        let rawMin = validPairs.map(\.1).min() ?? 0
        let rawMax = validPairs.map(\.1).max() ?? 1
        let range = rawMax - rawMin
        let pad = max(range * 0.15, 0.5)
        let minY = rawMin - pad
        let maxY = rawMax + pad
        let yRange = maxY - minY
        let xStep = count > 1 ? width / CGFloat(count - 1) : width
        return (minY, maxY, yRange, xStep)
    }

    private func yPosition(value: Double, minY: Double, yRange: Double) -> CGFloat {
        chartHeight * CGFloat(1 - (value - minY) / yRange)
    }

    private func linePath(values: [Double?], count: Int, xStep: CGFloat,
                          minY: Double, yRange: Double, chartHeight: CGFloat) -> Path {
        Path { path in
            var isFirst = true
            for i in 0..<count {
                guard let value = values[i] else {
                    isFirst = true
                    continue
                }
                let x = xStep * CGFloat(i)
                let y = chartHeight * CGFloat(1 - (value - minY) / yRange)
                if isFirst {
                    path.move(to: CGPoint(x: x, y: y))
                    isFirst = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Interactive sparkline") {
    VStack(spacing: 20) {
        InteractiveSparklineView(
            values: [7.1, 6.8, 7.3, 7.0, 6.5, 7.2, 7.4],
            dates: (0..<7).map { Calendar.current.date(byAdding: .day, value: -6 + $0, to: Date())! },
            color: .blue
        )
        .frame(width: 200)

        InteractiveSparklineView(
            values: [52, nil, 48, 50, 55, nil, 48],
            dates: (0..<7).map { Calendar.current.date(byAdding: .day, value: -6 + $0, to: Date())! },
            color: .green
        )
        .frame(width: 200)
    }
    .padding()
}
