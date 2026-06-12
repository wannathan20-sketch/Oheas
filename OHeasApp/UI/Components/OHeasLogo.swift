//
//  OHeasLogo.swift
//  OHeas
//
//  A reusable ring‑based brand mark — gradient ring + centred "O" letter.
//  Designed to work from app‑icon scale (60 pt) up to splash scale (120 pt).
//  可复用环形品牌标识：渐变圆环 + 中心 "O" 字母。
//

import SwiftUI

/// Scalable OHeas brand logo: a gradient ring wrapped around a rounded‑bold "H".
struct OHeasLogo: View {
    let size: CGFloat

    /// Whether to draw a faint filled circle behind the ring for contrast.
    var showBackground: Bool = false

    private var lineWidth: CGFloat { size * 0.10 }
    private var fontSize: CGFloat  { size * 0.38 }

    var body: some View {
        ZStack {
            // Optional backdrop — helps on light / hero gradients
            if showBackground {
                Circle()
                    .fill(Color(.systemBackground).opacity(0.55))
            }

            // Gradient ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.mint, Color.teal, Color.indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Centred "H" — for Health
            Text("H")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.teal, Color.indigo],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(width: size, height: size)
    }
}
