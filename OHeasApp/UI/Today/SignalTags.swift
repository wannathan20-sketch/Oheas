//
//  SignalTags.swift
//  OHeas
//
//  SignalTags.swift — horizontal scroll of detected signal capsule tags.
//

import OHeasCore
import SwiftUI

/// Horizontal scrolling row of signal capsules.
struct SignalTags: View {
    let signals: [HealthSignal]
    let language: AppLanguage
    let reduceMotion: Bool

    var body: some View {
        if !signals.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.text(.keySignals))
                    .font(.subheadline.weight(.semibold))
                    .padding(.leading, 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(signals.enumerated()), id: \.element.id) { index, signal in
                            HStack(spacing: 4) {
                                Image(systemName: signal.severity == .high ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                    .font(.caption2)
                                Text(language.signal(signal.type))
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(signal.severity == .high ? .red : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(signal.severity == .high ? OhColor.dangerBg : Color.secondary.opacity(0.08))
                            .clipShape(Capsule())
                            .softAppear(true, delay: Double(index) * 0.04, yOffset: 6, reduceMotion: reduceMotion)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
}
