//
//  CoachFollowUpChips.swift
//  OHeas
//
//  Horizontal scrolling chip buttons shown below the AI coach recommendation card.
//  Each chip triggers a follow-up question — either inline answer or navigate to Chat.
//

import OHeasCore
import SwiftUI

struct CoachFollowUpChips: View {
    let chips: [CoachFollowUpChip]
    let language: AppLanguage
    let reduceMotion: Bool
    let onChipTap: (CoachFollowUpChip) -> Void

    var body: some View {
        if chips.isEmpty { EmptyView() } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(chips) { chip in
                        ChipButton(chip: chip, language: language, reduceMotion: reduceMotion) {
                            onChipTap(chip)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

// MARK: - Chip Button

private struct ChipButton: View {
    let chip: CoachFollowUpChip
    let language: AppLanguage
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: iconForCategory(chip.category))
                    .font(.caption2)
                Text(language.text(rawKey: chip.labelKey))
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(OhColor.primaryBg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.large)
                    .strokeBorder(OhColor.primary.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .pressableScale()
    }

    private func iconForCategory(_ category: ChipCategory) -> String {
        switch category {
        case .recovery: "heart.text.square"
        case .tomorrowPlan: "calendar.badge.clock"
        case .details: "info.circle"
        case .historicalValidation: "clock.arrow.circlepath"
        case .general: "bubble.left"
        }
    }
}

// MARK: - AppLanguage TextKey Raw Key Lookup

private extension AppLanguage {
    /// Look up text using a raw TextKey string (for dynamically constructed chips).
    func text(rawKey: String) -> String {
        let key = stringToTextKey(rawKey)
        return text(key)
    }

    private func stringToTextKey(_ raw: String) -> TextKey {
        switch raw {
        case "askRecoveryMeaning": .askRecoveryMeaning
        case "askTomorrowPlan": .askTomorrowPlan
        case "askMoreDetails": .askMoreDetails
        case "askHistoricalValidation": .askHistoricalValidation
        case "chipDismissLabel": .chipDismissLabel
        case "thinkingBriefLabel": .thinkingBriefLabel
        case "inlineResponseTitle": .inlineResponseTitle
        case "askInChatLabel": .askInChatLabel
        default: .chatEmptyTitle
        }
    }
}
