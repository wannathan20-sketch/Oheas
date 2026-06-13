//
//  AchievementsView.swift
//  OHeas
//
//  Full achievements page showing streak summary + badge collection.
//  Accessible from Settings.
//

import OHeasCore
import SwiftUI

struct AchievementsView: View {
    let snapshot: GamificationSnapshot?
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Streak summary
                    streakSummarySection

                    // Badges
                    badgeSection
                }
                .padding()
            }
            .background(OhColor.groupedBg)
            .navigationTitle(language.text(.achievementsTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(language.text(.doneAction)) { dismiss() }
                }
            }
        }
    }

    // MARK: - Streak Summary

    private var streakSummarySection: some View {
        VStack(spacing: 0) {
            Text(language.text(.streaksSectionTitle))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            if let snapshot {
                VStack(spacing: 0) {
                    streakRow(
                        icon: "flame.fill", color: .orange,
                        label: language.text(.currentStreak),
                        streak: snapshot.streaks[.checkIn],
                        type: .checkIn
                    )
                    Divider().padding(.leading, 44)
                    streakRow(
                        icon: "applewatch.radiowaves.left.and.right", color: OhColor.sleep,
                        label: "\(language.text(.badge7DayDataCoverage))",
                        streak: snapshot.streaks[.dataCoverage],
                        type: .dataCoverage
                    )
                    Divider().padding(.leading, 44)
                    streakRow(
                        icon: "checkmark.seal.fill", color: OhColor.success,
                        label: "\(language.text(.badge7DayPlanComplete))",
                        streak: snapshot.streaks[.planCompletion],
                        type: .planCompletion
                    )
                }
            } else {
                HStack {
                    Text(language.text(.noBadgesYet))
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                }
            }
        }
        .background(OhColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }

    private func streakRow(icon: String, color: Color, label: String, streak: StreakState?, type: StreakType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline)
                Text("\(language.text(.currentStreak)): \(streak?.currentStreak ?? 0) | \(language.text(.longestStreak)): \(streak?.longestStreak ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StreakFlameView(
                count: streak?.currentStreak ?? 0,
                language: language,
                reduceMotion: reduceMotion
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Badge Section

    private var badgeSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language.text(.badgesSectionTitle))
                    .font(.headline)
                Spacer()
                if let snapshot {
                    let earned = snapshot.earnedBadges.count
                    let total = BadgeRegistry.all.count
                    Text(String(format: language.text(.badgesCount), earned, total))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if let snapshot {
                ForEach(BadgeCategory.allCases, id: \.self) { category in
                    let badges = BadgeRegistry.all.filter { $0.category == category }
                    if !badges.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(categoryTitle(category))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(badges) { def in
                                    BadgeCard(
                                        definition: def,
                                        state: snapshot.earnedBadges.first { $0.badgeId == def.criteria.identifier },
                                        language: language,
                                        reduceMotion: reduceMotion
                                    )
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                        }

                        if category != BadgeCategory.allCases.last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(OhColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }

    private func categoryTitle(_ category: BadgeCategory) -> String {
        switch category {
        case .streaks: language.text(.streaksSectionTitle)
        case .milestones: "Milestones" // simplified
        case .health: "Health"
        case .exploration: "Exploration"
        }
    }
}

#Preview {
    AchievementsView(snapshot: nil, language: .chinese)
}
