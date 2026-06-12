//
//  HistoryViewModel.swift
//  OHeas
//
//  Computes per-day Body Budget Scores with rolling 14-day baselines
//  for the History timeline tab.
//  为历史时间轴标签页计算每日身体预算评分（使用滚动 14 天基线）。
//

import Foundation
import OHeasCore

// MARK: - HistoricalDayDetail

/// All health data for a single historical day, including a freshly computed
/// score against a rolling baseline ending before that day.
public struct HistoricalDayDetail: Identifiable, Sendable {
    public var id: Date { date }
    public let date: Date
    public let metrics: DailyHealthMetrics
    public let score: BodyBudgetScore?
    public let comparisons: [MetricComparison]
    public let baseline: HealthBaseline?
    public let signals: [HealthSignal]
    public let feedback: DailyFeedback?
    public let dataQuality: DataQualityReport?
}

// MARK: - HistoryViewModel

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var historicalDays: [HistoricalDayDetail] = []
    @Published var isLoading = false

    private let baselineEngine = BaselineEngine()
    private let scorer = BodyBudgetScorer()
    private let signalDetector = SignalDetector()
    private let coverageLayer = DataCoverageLayer()
    private let calendar = Calendar.current

    // MARK: - Load

    /// Compute historical scores with rolling per-day 14-day baselines.
    /// Called after HealthDataViewModel.loadHealthData() completes.
    /// - Parameters:
    ///   - metrics: 30 days of DailyHealthMetrics (sorted arbitrarily).
    ///   - preferredLanguage: "zh" or "en" for factor explanations.
    func load(
        metrics: [DailyHealthMetrics],
        preferredLanguage: String
    ) {
        isLoading = true
        defer { isLoading = false }

        let sorted = metrics.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return }

        let feedbackStore = FeedbackStore(fileURL: OHeasStorageURLs.feedback)
        let allFeedback = (try? feedbackStore.all()) ?? []

        var results: [HistoricalDayDetail] = []

        for day in sorted {
            // 1. Rolling 14-day baseline ending before this day
            let rollingBaseline = baselineEngine.baseline(
                from: sorted,
                endingBefore: day.date,
                windowDays: 14
            )

            // 2. Data quality for this day
            let quality = coverageLayer.report(for: day)

            // 3. Detect signals for this day
            let signals = signalDetector.detect(
                today: day,
                baseline: rollingBaseline,
                dataQuality: quality,
                preferredLanguage: preferredLanguage
            )

            // 4. Match feedback for this day
            let fb = allFeedback.first {
                calendar.isDate($0.date, inSameDayAs: day.date)
            }

            // 5. Score against rolling baseline
            let score = scorer.score(
                today: day,
                baseline: rollingBaseline,
                signals: signals,
                feedback: fb,
                preferredLanguage: preferredLanguage
            )

            // 6. Comparisons against rolling baseline
            let comparisons = baselineEngine.comparisons(
                today: day,
                baseline: rollingBaseline
            )

            results.append(HistoricalDayDetail(
                date: day.date,
                metrics: day,
                score: score,
                comparisons: comparisons,
                baseline: rollingBaseline,
                signals: signals,
                feedback: fb,
                dataQuality: quality
            ))
        }

        // Display newest first
        historicalDays = results.reversed()
    }

    /// Reset state (e.g. on sign-out).
    func reset() {
        historicalDays = []
        isLoading = false
    }

    // MARK: - Helpers

    /// Find the historical day matching a given date, if loaded.
    func day(for date: Date) -> HistoricalDayDetail? {
        historicalDays.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
