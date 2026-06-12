//
//  TrendsTabView.swift
//  OHeas
//
//  Main Trends tab: score chart + day strip + scrollable day cards.
//  Tapping a day card opens DayDetailSheet.
//  趋势标签页主视图：评分图表 + 日期条 + 可滚动日卡片。
//

import SwiftUI
import OHeasCore

// MARK: - TrendsTabView

struct TrendsTabView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    @State private var selectedDayForSheet: HistoricalDayDetail?
    @State private var highlightedDate: Date?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.history.isLoading {
                    loadingState
                } else if viewModel.history.historicalDays.isEmpty {
                    emptyState
                } else {
                    contentView
                }
            }
            .navigationTitle(language.text(.trendsTab))
            .sheet(item: $selectedDayForSheet) { day in
                DayDetailSheet(day: day, language: language)
            }
        }
    }

    // MARK: - Content

    private var contentView: some View {
        let days = viewModel.history.historicalDays
        let sortedForChart = Array(days.reversed()) // oldest first for chart

        return ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    // Score history chart
                    ScoreHistoryChart(days: sortedForChart, language: language)
                        .padding()
                        .background(OhColor.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

                    // Horizontal day strip
                    dayStrip(days)

                    // Day cards list
                    LazyVStack(spacing: 10) {
                        ForEach(days) { day in
                            DayCard(day: day, language: language)
                                .id(day.date)
                                .onTapGesture {
                                    selectedDayForSheet = day
                                }
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Day Strip

    private func dayStrip(_ days: [HistoricalDayDetail]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(days) { day in
                    dayStripCircle(day)
                        .onTapGesture {
                            withAnimation {
                                selectedDayForSheet = day
                            }
                        }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func dayStripCircle(_ day: HistoricalDayDetail) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        let dayNumber = Calendar.current.component(.day, from: day.date)
        let weekday = shortWeekday(day.date)

        return VStack(spacing: 3) {
            Text(weekday)
                .font(.system(size: 9, weight: isToday ? .bold : .medium))
                .foregroundStyle(isToday ? .white : .secondary)
            ZStack {
                Circle()
                    .fill(isToday ? Color.accentColor : scoreColor(day.score?.value).opacity(0.18))
                    .frame(width: 32, height: 32)

                if let score = day.score {
                    Text("\(score.value)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(scoreColor(score.value))
                } else {
                    Text("--")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Text("\(dayNumber)")
                .font(.system(size: 9))
                .foregroundStyle(isToday ? .primary : .secondary)
        }
        .frame(width: 44)
    }

    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = "E"
        let full = formatter.string(from: date)
        // Trim to 1-2 chars for compactness
        return String(full.prefix(2))
    }

    // MARK: - Loading State

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: 16) {
                SkeletonSection(cardCount: 1, cardHeight: 180)
                SkeletonSection(cardCount: 5, cardHeight: 72)
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            language.text(.trendsEmptyTitle),
            systemImage: "clock.arrow.circlepath",
            description: Text(language.text(.trendsEmptyDescription))
        )
    }

    // MARK: - Helpers

    private func scoreColor(_ scoreValue: Int?) -> Color {
        guard let score = scoreValue else { return .secondary.opacity(0.3) }
        switch score {
        case 85...: return .green
        case 70..<85: return .mint
        case 55..<70: return .yellow
        case 35..<55: return .orange
        default: return .red
        }
    }
}

// MARK: - HistoricalDayDetail + Identifiable

// Conformance is defined in HistoryViewModel.swift;
// this extension ensures SwiftUI can use it with .sheet(item:).
extension HistoricalDayDetail: Equatable {
    public static func == (lhs: HistoricalDayDetail, rhs: HistoricalDayDetail) -> Bool {
        lhs.date == rhs.date
    }
}
