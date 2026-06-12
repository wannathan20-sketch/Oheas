//
//  ConfidenceBadge.swift
//  OHeas
//
//  ConfidenceBadge.swift — shared confidence level badge component.
//

import OHeasCore
import SwiftUI

/// A colored capsule badge showing confidence level.
struct ConfidenceBadge: View {
    let level: ConfidenceLevel
    let language: AppLanguage

    var body: some View {
        Text(language.confidence(level))
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch level {
        case .high: OhColor.success
        case .medium: .blue
        case .low: OhColor.danger
        }
    }
}
