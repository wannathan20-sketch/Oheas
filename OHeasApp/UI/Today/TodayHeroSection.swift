//
//  TodayHeroSection.swift
//  OHeas
//
//  TodayHeroSection.swift — hero gradient header for TodayView.
//

import OHeasCore
import SwiftUI

/// The top hero section of TodayView showing a gradient header,
/// greeting, conclusion title/subtitle, and data source badge.
struct TodayHeroSection: View {
    let dataQuality: DataQualityReport?
    let detectedSignals: [HealthSignal]
    let dataSource: HealthDataSource
    let language: AppLanguage
    let heroGlow: Bool
    let reduceMotion: Bool

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: heroGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .animation(OhAnimation.pulse, value: dataQuality?.overallConfidence ?? .low)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(conclusionTitle)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Text(conclusionSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text(language.formatDate(Date.now, dateStyle: .long))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    dataSourceBadge
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Gradient Colors

    private var heroGradientColors: [Color] {
        let glow = heroGlow
        guard let quality = dataQuality else {
            return [.mint.opacity(glow ? 0.60 : 0.42), .teal.opacity(glow ? 0.28 : 0.18), OhColor.groupedBg]
        }
        let hasSignals = !detectedSignals.isEmpty
        let hasHighSignal = detectedSignals.contains(where: { $0.severity == .high })

        switch quality.overallConfidence {
        case .high where hasHighSignal:
            return [.orange.opacity(glow ? 0.55 : 0.38), .yellow.opacity(glow ? 0.26 : 0.16), OhColor.groupedBg]
        case .high where hasSignals:
            return [.indigo.opacity(glow ? 0.50 : 0.34), .mint.opacity(glow ? 0.24 : 0.15), OhColor.groupedBg]
        case .high:
            return [.mint.opacity(glow ? 0.72 : 0.52), .teal.opacity(glow ? 0.34 : 0.22), OhColor.groupedBg]
        case .medium:
            return [.orange.opacity(glow ? 0.42 : 0.28), .yellow.opacity(glow ? 0.20 : 0.12), OhColor.groupedBg]
        case .low:
            return [.gray.opacity(glow ? 0.38 : 0.26), .indigo.opacity(glow ? 0.20 : 0.12), OhColor.groupedBg]
        }
    }

    // MARK: - Conclusion Text

    private var conclusionTitle: String {
        guard let quality = dataQuality else {
            return language.text(.todayConclusionReady)
        }
        if quality.overallConfidence == .low {
            return language.text(.todayConclusionFillGaps)
        }
        if detectedSignals.contains(where: { $0.severity == .high }) {
            return language.text(.todayConclusionConservative)
        }
        if !detectedSignals.isEmpty {
            return language.text(.todayConclusionWatchSignals)
        }
        return language.text(.todayConclusionSteady)
    }

    private var conclusionSubtitle: String {
        guard let quality = dataQuality else {
            return language.text(.heroSubtitleConnect)
        }
        switch quality.overallConfidence {
        case .high:
            return detectedSignals.isEmpty
                ? language.text(.heroSubtitleStrongNoSignals)
                : language.text(.heroSubtitleStrongWithSignals)
        case .medium:
            return language.text(.heroSubtitleMedium)
        case .low:
            return language.text(.heroSubtitleLow)
        }
    }

    // MARK: - Data Source Badge

    private var dataSourceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: dataSource == .appleHealth ? "applewatch" : "testtube.2")
                .font(.caption.weight(.semibold))
            Text(language.dataSource(dataSource))
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(dataSource == .appleHealth ? .green : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .scaleEffect(heroGlow && !reduceMotion ? 1.03 : 1)
        .animation(OhAnimation.glow, value: heroGlow)
    }
}
