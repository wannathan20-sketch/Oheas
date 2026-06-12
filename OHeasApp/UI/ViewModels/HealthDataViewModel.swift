//
//  HealthDataViewModel.swift
//  OHeas
//
//  Loads health data, computes baselines, detects signals.
//  加载健康数据、计算基线、检测信号。
//


import Foundation
import HealthKit
import SwiftUI
import OHeasCore

/// Aggregated output from the health data pipeline, consumed by other ViewModels.
struct HealthDataPackage: Sendable {
    var todayMetrics: DailyHealthMetrics
    var baseline14d: HealthBaseline
    var comparisons: [MetricComparison]
    var dataQuality: DataQualityReport
    var detectedSignals: [HealthSignal]
    var recentDailyMetrics: [DailyHealthMetrics]
    var dataSource: HealthDataSource
    var bodyBudgetScore: BodyBudgetScore?

    init(
        todayMetrics: DailyHealthMetrics,
        baseline14d: HealthBaseline,
        comparisons: [MetricComparison],
        dataQuality: DataQualityReport,
        detectedSignals: [HealthSignal],
        recentDailyMetrics: [DailyHealthMetrics],
        dataSource: HealthDataSource,
        bodyBudgetScore: BodyBudgetScore? = nil
    ) {
        self.todayMetrics = todayMetrics
        self.baseline14d = baseline14d
        self.comparisons = comparisons
        self.dataQuality = dataQuality
        self.detectedSignals = detectedSignals
        self.recentDailyMetrics = recentDailyMetrics
        self.dataSource = dataSource
        self.bodyBudgetScore = bodyBudgetScore
    }
}

@MainActor
final class HealthDataViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var dataSource: HealthDataSource = .appleHealth
    @Published var todayMetrics: DailyHealthMetrics?
    @Published var baseline14d: HealthBaseline?
    @Published var comparisons: [MetricComparison] = []
    @Published var dataQuality: DataQualityReport?
    @Published var detectedSignals: [HealthSignal] = []
    @Published var bodyBudgetScore: BodyBudgetScore?
    @Published var errorKey: TextKey?
#if DEBUG
    @Published var selectedDemoScenario: DemoScenario = .overworkedProfessional
    @Published var demoScenarioSummary: String?
    @Published var isDemoMode = false
#endif

    @Published var healthKitError: String?

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var preferredLanguage: String {
        (AppLanguage(rawValue: languageRawValue) ?? .chinese).rawValue
    }

    private let calendar = Calendar.current
    private let aggregator = DailyMetricsAggregator()
    private let baselineEngine = BaselineEngine()
    private let coverageLayer = DataCoverageLayer()
    private let signalDetector = SignalDetector()
    private let budgetScorer = BodyBudgetScorer()
#if DEBUG
    private let demoBuilder = DemoScenarioBuilder()
#endif
    private let errorReporter: ErrorReporter

    /// Single shared HKHealthStore – Apple requires apps use one store for all interactions.
    private let healthStore = HKHealthStore()

    private(set) var recentDailyMetrics: [DailyHealthMetrics] = []

    init(errorReporter: ErrorReporter, fileURL: URL? = nil) {
        self.errorReporter = errorReporter
    }

    /// Load health data from HealthKit (or fall back to mock). Returns the pipeline output.
    func loadHealthData(days: Int = 30) async -> HealthDataPackage? {
        isLoading = true
        defer { isLoading = false }

        // Pre-authorize HealthKit with the shared store (retained, main-thread).
        // This must happen before fetching data so the system dialog appears
        // at the right time and the store's authorization state is consistent.
        let types: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType()
        ]
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
        } catch {
            print("[OHeas] HealthKit authorization error: \(error.localizedDescription)")
            healthKitError = error.localizedDescription
            // Fall through to try HealthKitReader anyway – it will re-attempt auth
        }

        let provider: HealthDataProvider = HealthKitReader(healthStore: healthStore)
        do {
            let raw = try await provider.fetchRawDailyData(days: days)
            dataSource = .appleHealth
            return await buildPipeline(rawDays: raw)
        } catch {
            let errorMessage = error.localizedDescription
            print("[OHeas] HealthKit error: \(errorMessage) — falling back to mock")
            healthKitError = errorMessage
            errorReporter.record(category: .healthKit, message: errorMessage, context: ["mode": "mockFallback"])

            let mock = MockHealthDataProvider()
            do {
                let raw = try await mock.fetchRawDailyData(days: days)
                dataSource = .mock
                errorKey = .mockFallback
                return await buildPipeline(rawDays: raw)
            } catch {
                errorReporter.record(category: .healthKit, message: error.localizedDescription)
                errorKey = .noMetrics
                return nil
            }
        }
    }

    /// Run the aggregation → baseline → quality → signals pipeline.
    private func buildPipeline(rawDays: [RawDailyHealthData]) async -> HealthDataPackage? {
        let daily = aggregator.aggregate(rawDays)
        guard let today = daily.last else {
            errorKey = .noMetrics
            return nil
        }
        recentDailyMetrics = daily

        let baseline = baselineEngine.baseline(from: daily, endingBefore: today.date, windowDays: 14)
        let quality = coverageLayer.report(for: today)
        let signals = signalDetector.detect(today: today, baseline: baseline, dataQuality: quality, preferredLanguage: preferredLanguage)

        todayMetrics = today
        baseline14d = baseline
        comparisons = baselineEngine.comparisons(today: today, baseline: baseline)
        dataQuality = quality
        detectedSignals = signals

        // Compute Body Budget Score (Phase 15 north-star metric)
        let budgetScore = budgetScorer.score(
            today: today,
            baseline: baseline,
            signals: signals,
            feedback: nil,  // feedback loaded separately after pipeline
            preferredLanguage: preferredLanguage
        )
        bodyBudgetScore = budgetScore

        return HealthDataPackage(
            todayMetrics: today,
            baseline14d: baseline,
            comparisons: comparisons,
            dataQuality: quality,
            detectedSignals: signals,
            recentDailyMetrics: daily,
            dataSource: dataSource,
            bodyBudgetScore: budgetScore
        )
    }

    /// Load a demo scenario with pre-built data.
#if DEBUG
    func loadDemoScenario() -> HealthDataPackage? {
        let data = demoBuilder.build(selectedDemoScenario)
        isDemoMode = true
        demoScenarioSummary = data.summary
        recentDailyMetrics = data.metrics
        todayMetrics = data.metrics.last
        baseline14d = baselineEngine.baseline(from: data.metrics, windowDays: 14)
        dataQuality = todayMetrics.map { coverageLayer.report(for: $0) }
        if let todayMetrics, let baseline14d, let dataQuality {
            detectedSignals = signalDetector.detect(today: todayMetrics, baseline: baseline14d, dataQuality: dataQuality, preferredLanguage: preferredLanguage)
        }

        guard let today = todayMetrics, let baseline = baseline14d, let quality = dataQuality else {
            return nil
        }
        let budgetScore = budgetScorer.score(
            today: today,
            baseline: baseline,
            signals: detectedSignals,
            feedback: nil,
            preferredLanguage: preferredLanguage
        )
        bodyBudgetScore = budgetScore
        return HealthDataPackage(
            todayMetrics: today,
            baseline14d: baseline,
            comparisons: baselineEngine.comparisons(today: today, baseline: baseline),
            dataQuality: quality,
            detectedSignals: detectedSignals,
            recentDailyMetrics: recentDailyMetrics,
            dataSource: .mock,
            bodyBudgetScore: budgetScore
        )
    }

    func resetDemoData() {
        isDemoMode = false
        demoScenarioSummary = nil
        // Clear pipeline state so UI returns to empty/loading state
        todayMetrics = nil
        baseline14d = nil
        comparisons = []
        dataQuality = nil
        detectedSignals = []
        bodyBudgetScore = nil
        recentDailyMetrics = []
        errorKey = nil
    }
#endif

    /// Refresh the baseline and quality report without reloading raw data.
    func refreshDerivedMetrics() {
        guard let today = todayMetrics else { return }
        let baseline = baselineEngine.baseline(from: recentDailyMetrics, endingBefore: today.date, windowDays: 14)
        let quality = coverageLayer.report(for: today)
        baseline14d = baseline
        dataQuality = quality
        comparisons = baselineEngine.comparisons(today: today, baseline: baseline)
    }

    /// Recompute the Body Budget Score with subjective feedback (after feedback is loaded).
    func refreshBodyBudgetScore(with feedback: DailyFeedback?) {
        guard let today = todayMetrics, let baseline = baseline14d else { return }
        bodyBudgetScore = budgetScorer.score(
            today: today,
            baseline: baseline,
            signals: detectedSignals,
            feedback: feedback,
            preferredLanguage: preferredLanguage
        )
    }
}
