//
//  TodayFeedbackPanel.swift
//  OHeas
//
//  TodayFeedbackPanel.swift — inline quick-feedback row + yesterday verification.
//
//  Phase 18: Feedback form moved out of DisclosureGroup into a compact inline row.
//  Yesterday section stays as a directly visible panel (no 2-deep DisclosureGroup).
//

import OHeasCore
import SwiftUI

/// Quick-feedback form and yesterday's verification, directly visible on the Today page.
struct TodayFeedbackPanel: View {
    let yesterdayRecommendation: CoachRecommendation?
    let yesterdayFeedback: DailyFeedback?
    let verificationReport: VerificationReport?
    let language: AppLanguage
    let feedbackJustSaved: Bool

    @Binding var feedbackAdherence: FeedbackAdherence
    @Binding var feedbackEnergy: Double
    @Binding var feedbackSoreness: Double
    @Binding var feedbackStress: Double
    @Binding var feedbackNote: String

    var onSaveFeedback: () -> Void

    private var hasYesterday: Bool { yesterdayRecommendation != nil || verificationReport != nil }

    var body: some View {
        VStack(spacing: 12) {
            // Quick-feedback row — always visible inline
            quickFeedbackSection

            // Yesterday verification — directly visible, no DisclosureGroup nesting
            if hasYesterday {
                yesterdaySection
            }
        }
        .padding()
        .background(OhColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }

    // MARK: - Quick Feedback

    private var quickFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(language.text(.feedbackTitle), systemImage: "square.and.pencil")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            // Adherence picker
            Picker(language.text(.adherence), selection: $feedbackAdherence) {
                ForEach(FeedbackAdherence.allCases, id: \.self) { a in
                    Text(language.adherence(a)).tag(a)
                }
            }
            .pickerStyle(.segmented)
            .font(.caption2)

            // Three compact sliders in a row
            HStack(spacing: 12) {
                compactSlider(title: language.text(.energy), value: $feedbackEnergy, color: .green)
                compactSlider(title: language.text(.soreness), value: $feedbackSoreness, color: .orange)
                compactSlider(title: language.text(.stress), value: $feedbackStress, color: .indigo)
            }

            // Note field + save button
            HStack(spacing: 8) {
                TextField(language.text(.note), text: $feedbackNote, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...2)
                    .font(.caption)

                Button { onSaveFeedback() } label: {
                    Label(
                        feedbackJustSaved
                            ? language.text(.feedbackSavedMessage)
                            : language.text(.saveFeedback),
                        systemImage: feedbackJustSaved ? "checkmark" : "square.and.arrow.down"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 36, height: 32)
                }
                .buttonStyle(.borderedProminent)
                .tint(feedbackJustSaved ? .green : nil)
                .pressableScale()
            }
        }
    }

    private func compactSlider(title: String, value: Binding<Double>, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("\(Int(value.wrappedValue))")
                .font(.caption2.weight(.medium))
                .foregroundStyle(color)
            Slider(value: value, in: 1...10, step: 1)
                .tint(color)
        }
    }

    // MARK: - Yesterday Section

    private var yesterdaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Label(language.text(.yesterdaySection), systemImage: "clock.arrow.circlepath")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let rec = yesterdayRecommendation {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text(.yesterdayRecommendation))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(rec.title)
                        .font(.subheadline.weight(.semibold))
                    Text(rec.recommendation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let fb = yesterdayFeedback {
                        Text("\(language.text(.adherence)): \(language.adherence(fb.adherence))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(OhColor.secondaryGroupedBg)
                .clipShape(RoundedRectangle(cornerRadius: Radius.small))
            }

            if let report = verificationReport {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(language.text(.verificationResult))
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(language.verificationOutcome(report.outcome))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(reportBadgeColor(report.outcome))
                            .clipShape(Capsule())
                    }
                    Text(report.explanation)
                        .font(.caption)
                    ForEach(report.findings, id: \.self) { f in
                        Text("• \(f)").font(.caption2).foregroundStyle(.secondary)
                    }
                    if let pattern = report.learnedPatternCandidate {
                        Divider()
                        Text(pattern)
                            .font(.caption2)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(OhColor.secondaryGroupedBg)
                .clipShape(RoundedRectangle(cornerRadius: Radius.small))
            }
        }
    }

    private func reportBadgeColor(_ outcome: VerificationOutcome) -> Color {
        switch outcome {
        case .likelyHelped: OhColor.success
        case .neutral: OhColor.info
        case .unclear: OhColor.warning
        case .likelyNotHelped: OhColor.danger
        }
    }
}
