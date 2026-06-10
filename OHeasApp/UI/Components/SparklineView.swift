//
//  SparklineView.swift
//  OHeas
//
//  SparklineView.swift — OHeas UI component.
//  SparklineView.swift — OHeas UI 组件。
//


import SwiftUI

/// A minimal sparkline chart drawn with native SwiftUI Path.
/// Shows a 7-day trend line with a highlighted dot for the latest data point.
struct SparklineView: View {
    let values: [Double?]
    let color: Color
    var highlightLast: Bool = true

    private let chartHeight: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                let count = values.count
                let validPairs = values.enumerated().compactMap { (i, v) -> (Int, Double)? in
                    v.map { (i, $0) }
                }

                // Draw sparkline when we have enough data points
                if count > 1, validPairs.count > 1 {
                    let rawMin = validPairs.map(\.1).min() ?? 0
                    let rawMax = validPairs.map(\.1).max() ?? 1
                    let range = rawMax - rawMin
                    let pad = max(range * 0.15, 0.5)
                    let minY = rawMin - pad
                    let maxY = rawMax + pad
                    let yRange = maxY - minY
                    let xStep = geo.size.width / CGFloat(count - 1)

                    linePath(values: values, count: count, xStep: xStep, minY: minY, yRange: yRange)
                        .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    if highlightLast, let (lastIdx, lastVal) = validPairs.last {
                        let dotX = xStep * CGFloat(lastIdx)
                        let dotY = chartHeight * CGFloat(1 - (lastVal - minY) / yRange)
                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                            .position(x: dotX, y: dotY)
                    }
                } else if let _ = validPairs.first {
                    // Single value: centered dot
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .position(x: geo.size.width / 2, y: chartHeight / 2)
                }
            }
        }
        .frame(height: chartHeight)
    }

    private func linePath(values: [Double?], count: Int, xStep: CGFloat, minY: Double, yRange: Double) -> Path {
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

#Preview("Normal trend") {
    VStack(spacing: 20) {
        SparklineView(
            values: [7.1, 6.8, 7.3, 7.0, 6.5, 7.2, 7.4],
            color: .blue
        )
        .frame(width: 120)

        SparklineView(
            values: [52, 48, 45, 50, 55, 49, 48],
            color: .green
        )
        .frame(width: 120)

        SparklineView(
            values: [58, 60, 57, 59, 62, 58, 56],
            color: .orange
        )
        .frame(width: 120)
    }
    .padding()
}

#Preview("With missing data") {
    SparklineView(
        values: [7.1, nil, 7.3, 7.0, nil, 7.2, 7.4],
        color: .blue
    )
    .frame(width: 120)
    .padding()
}

#Preview("Single value") {
    SparklineView(
        values: [7.2],
        color: .blue
    )
    .frame(width: 120)
    .padding()
}
