//
//  DayCard.swift
//  OHeas
//
//  Compact row card for one historical day in the timeline list.
//  Shows mini score ring, date, category badge, key metrics, and signal preview.
//  紧凑行卡片：mini 评分环 + 日期 + 分类徽章 + 关键指标 + 信号预览。
//

import SwiftUI
import OHeasCore

// MARK: - DayCard

/// Tappable compact card representing one historical day.
struct DayCard: View {
    let day: HistoricalDayDetail
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Mini score ring
            BodyBudgetRing(
                score: day.score,
                language: language,
                size: 44,
                lineWidth: 5,
                reduceMotion: reduceMotion
            )

            // Center content
            VStack(alignment: .leading, spacing: 4) {
                // Date + category badge
                HStack(spacing: 6) {
                    Text(language.formatDate(day.date, dateStyle: .medium, timeStyle: .none))
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    if let score = day.score {
                        ScoreCategoryBadge(category: score.category, language: language)
                    }
                }

                // Key metrics row
                HStack(spacing: 10) {
                    metricPill(
                        icon: "bed.double.fill",
                        value: day.metrics.sleepHours,
                        unit: "h",
                        color: OhColor.sleep
                    )
                    metricPill(
                        icon: "waveform.path.ecg",
                        value: day.metrics.hrv,
                        unit: "ms",
                        color: OhColor.hrv
                    )
                    metricPill(
                        icon: "figure.walk",
                        value: day.metrics.steps,
                        unit: "",
                        color: OhColor.steps
                    )
                }

                // Signal preview (if any)
                if !day.signals.isEmpty {
                    signalPreview
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(OhColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }

    // MARK: - Metric Pill

    private func metricPill(icon: String, value: Double?, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color.opacity(0.8))
            if let v = value {
                Text(formatValue(v, unit: unit))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary)
            } else {
                Text("--")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }

    private func formatValue(_ value: Double, unit: String) -> String {
        if unit == "" {
            // Steps — format with thousands
            if value >= 1000 {
                return String(format: "%.1fk", value / 1000)
            }
            return String(format: "%.0f", value)
        }
        // Sleep hours / HRV
        return String(format: "%.0f%@", value, unit)
    }

    // MARK: - Signal Preview

    private var signalPreview: some View {
        HStack(spacing: 4) {
            ForEach(Array(day.signals.prefix(2))) { signal in
                Text(language.signal(signal.type))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(signal.severity == .high ? .red : .orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        (signal.severity == .high ? Color.red : Color.orange)
                            .opacity(0.08)
                    )
                    .clipShape(Capsule())
            }
            if day.signals.count > 2 {
                Text(String(format: language.text(.dayCardMoreSignals), day.signals.count - 2))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
