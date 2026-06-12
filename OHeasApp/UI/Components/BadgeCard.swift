//
//  BadgeCard.swift
//  OHeas
//
//  Individual badge tile for the badge collection grid.
//  Earned badges show full color; unearned are dimmed with a lock icon.
//

import OHeasCore
import SwiftUI

struct BadgeCard: View {
    let definition: BadgeDefinition
    let state: BadgeState?
    let language: AppLanguage
    let reduceMotion: Bool

    @State private var sparkle = false

    var isEarned: Bool { state != nil }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isEarned ? OhColor.primaryBg : Color(.systemGray6))
                    .frame(width: 52, height: 52)

                Image(systemName: isEarned ? definition.iconSystemName : "lock.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isEarned ? OhColor.primary : .secondary.opacity(0.4))
                    .scaleEffect(sparkle ? 1.25 : 1.0)
            }
            .overlay(alignment: .topTrailing) {
                if sparkle {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                        .offset(x: 6, y: -4)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Text(language.text(rawKey: definition.nameKey))
                .font(.caption2.weight(.medium))
                .foregroundStyle(isEarned ? .primary : .tertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let earnedDate = state?.earnedAt {
                Text(earnedDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isEarned ? OhColor.cardBg : Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
        .opacity(isEarned ? 1.0 : 0.55)
        .onAppear {
            // Sparkle on first display of an earned badge
            if isEarned && !reduceMotion {
                sparkle = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.3)) { sparkle = false }
                }
            }
        }
    }
}

// MARK: - AppLanguage TextKey Raw Key Lookup

private extension AppLanguage {
    func text(rawKey: String) -> String {
        switch rawKey {
        // Streak badges
        case "badge7DayCheckIn": return text(.badge7DayCheckIn)
        case "badge30DayCheckIn": return text(.badge30DayCheckIn)
        case "badge7DayDataCoverage": return text(.badge7DayDataCoverage)
        case "badge7DayPlanComplete": return text(.badge7DayPlanComplete)
        // Milestone badges
        case "badgeFirstRecommendation": return text(.badgeFirstRecommendation)
        case "badgeFirstExperiment": return text(.badgeFirstExperiment)
        case "badgeFirstChat": return text(.badgeFirstChat)
        case "badge10Feedbacks": return text(.badge10Feedbacks)
        case "badge30Plans": return text(.badge30Plans)
        case "badge3Experiments": return text(.badge3Experiments)
        // Health badges
        case "badgeScoreWeekExcellent": return text(.badgeScoreWeekExcellent)
        case "badgeSleepConsistency": return text(.badgeSleepConsistency)
        case "badgeHRVImprovement": return text(.badgeHRVImprovement)
        // Exploration badges
        case "badgeAllMetricsViewed": return text(.badgeAllMetricsViewed)
        case "badgeWeeklyReviewDone": return text(.badgeWeeklyReviewDone)
        default: return rawKey
        }
    }
}
