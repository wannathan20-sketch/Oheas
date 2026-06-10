//
//  TodayView.swift
//  OHeas
//
//  TodayView.swift — OHeas UI component.
//

import OHeasCore
import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }

    private var greeting: String {
        let key: TextKey = switch hour {
        case 6..<12: .greetingMorning
        case 12..<18: .greetingAfternoon
        default: .greetingEvening
        }
        return language.text(key)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection

                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.isLoading {
                            SkeletonLoadingView(sections: [
                                (1, 200),  // gauge
                                (1, 100),  // signals
                                (1, 200),  // recommendation
                            ])
                        } else if let today = viewModel.todayMetrics, let quality = viewModel.dataQuality {
                            bodyBudgetGauge(today: today, quality: quality)
                            signalTags
                            aiCoachCard
                            weeklyPlanStrip
                            metricsGrid
                            collapsibleFeedback
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("OHeas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.mint.opacity(0.6), .teal.opacity(0.3), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Text(Date.now.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
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

    private var dataSourceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.dataSource == .appleHealth ? "applewatch" : "testtube.2")
                .font(.caption.weight(.semibold))
            Text(language.dataSource(viewModel.dataSource))
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(viewModel.dataSource == .appleHealth ? .green : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            language.text(.emptyTitle),
            systemImage: "heart.text.square",
            description: Text(language.text(.emptyDescription))
        )
        .padding(.vertical, 48)
    }

    // MARK: - Body Budget Gauge

    private func bodyBudgetGauge(today: DailyHealthMetrics, quality: DataQualityReport) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                // Circular gauge
                ZStack {
                    Circle()
                        .stroke(quality.overallConfidence == .high ? Color.green.opacity(0.15) :
                                quality.overallConfidence == .medium ? Color.orange.opacity(0.15) :
                                Color.red.opacity(0.15),
                                lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: gaugeFraction(quality))
                        .stroke(gaugeColor(quality),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: quality.overallConfidence)

                    VStack(spacing: 2) {
                        Text(bodyBudgetLabel(quality: quality))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(language.confidence(quality.overallConfidence))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(gaugeColor(quality))
                    }
                }
                .frame(width: 90, height: 90)

                // Three key metrics
                VStack(spacing: 10) {
                    gaugeMetricRow(
                        icon: "bed.double.fill", color: .blue,
                        label: language.metric(.sleepHours),
                        value: today.sleepHours.map { String(format: "%.1fh", $0) } ?? language.missing,
                        sparkline: viewModel.recentDailyMetrics.suffix(7).map(\.sleepHours)
                    )
                    gaugeMetricRow(
                        icon: "waveform.path.ecg", color: .green,
                        label: language.metric(.hrv),
                        value: today.hrv.map { String(format: "%.0fms", $0) } ?? language.missing,
                        sparkline: viewModel.recentDailyMetrics.suffix(7).map(\.hrv)
                    )
                    gaugeMetricRow(
                        icon: "heart.fill", color: .orange,
                        label: language.metric(.restingHeartRate),
                        value: today.restingHeartRate.map { String(format: "%.0fbpm", $0) } ?? language.missing,
                        sparkline: viewModel.recentDailyMetrics.suffix(7).map(\.restingHeartRate)
                    )
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func gaugeFraction(_ quality: DataQualityReport) -> CGFloat {
        switch quality.overallConfidence {
        case .high: 0.85
        case .medium: 0.55
        case .low: 0.25
        }
    }

    private func gaugeColor(_ quality: DataQualityReport) -> Color {
        switch quality.overallConfidence {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }

    private func bodyBudgetLabel(quality: DataQualityReport) -> String {
        if quality.overallConfidence == .low { return language.bodyBudgetTitleForLowConfidence }
        let hasHighSignal = viewModel.detectedSignals.contains(where: { $0.severity == .high })
        let hasSignals = !viewModel.detectedSignals.isEmpty
        return language.bodyBudgetTitle(hasHighSignal: hasHighSignal, hasSignals: hasSignals)
    }

    private func gaugeMetricRow(icon: String, color: Color, label: String, value: String, sparkline: [Double?]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            Text(value)
                .font(.subheadline.weight(.semibold))

            Spacer()

            SparklineView(values: sparkline, color: color)
                .frame(width: 50)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Signal Tags

    @ViewBuilder
    private var signalTags: some View {
        let signals = viewModel.detectedSignals
        if !signals.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.text(.keySignals))
                    .font(.subheadline.weight(.semibold))
                    .padding(.leading, 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(signals) { signal in
                            HStack(spacing: 4) {
                                Image(systemName: signal.severity == .high ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                    .font(.caption2)
                                Text(language.signal(signal.type))
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(signal.severity == .high ? .red : .orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(signal.severity == .high ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    // MARK: - AI Coach Card

    @ViewBuilder
    private var aiCoachCard: some View {
        if let result = viewModel.recommendationResult {
            if viewModel.isStreaming {
                streamingCoachCard
            } else {
                stableCoachCard(result: result)
            }
        } else if let quality = viewModel.dataQuality {
            fallbackCoachCard(quality: quality)
        }
    }

    private var streamingCoachCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // Accent line
            Rectangle()
                .fill(Color.indigo.opacity(0.4))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(language.text(.generatingRecommendation))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !viewModel.streamingDisplayText.isEmpty {
                    Text(viewModel.streamingDisplayText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    + Text("|").foregroundStyle(.indigo).font(.subheadline.weight(.bold))
                }
            }
            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stableCoachCard(result: RecommendationResult) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Accent line
            Rectangle()
                .fill(Color.indigo)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 14) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.recommendation.title)
                            .font(.headline)
                        Text(language.coachState(result.recommendation.state))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ConfidenceBadge(level: result.recommendation.confidence, language: language)
                }

                Text(result.recommendation.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let fallback = result.fallbackReason {
                    Label(fallback, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Small action
                VStack(alignment: .leading, spacing: 4) {
                    Label(language.text(.smallAction), systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(result.recommendation.recommendation)
                        .font(.subheadline)
                        .padding(.leading, 22)
                }

                // Tonight action
                VStack(alignment: .leading, spacing: 4) {
                    Label(language.text(.tonightAction), systemImage: "moon.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.indigo)
                    Text(result.recommendation.tonightAction)
                        .font(.subheadline)
                        .padding(.leading, 22)
                }

                // Tomorrow verification
                if !result.recommendation.tomorrowVerification.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(language.text(.tomorrowMetrics), systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(result.recommendation.tomorrowVerification) { metric in
                            Text("• \(metric.metric): \(metric.expectedDirection)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 22)
                        }
                    }
                }

                if let question = result.recommendation.followupQuestion {
                    Text(question)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.indigo)
                        .padding(.top, 2)
                }

                if result.originalRecommendation != nil || result.safetyAssessment?.riskLevel != .safe {
                    Label(language.text(.safetyAdjustedLabel), systemImage: "shield.lefthalf.filled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .indigo.opacity(0.06), radius: 6, y: 2)
    }

    private func fallbackCoachCard(quality: DataQualityReport) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.indigo.opacity(0.3))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 10) {
                Label(language.text(.smallAction), systemImage: "checkmark.circle")
                    .font(.headline)
                Text(language.recommendation(quality: quality, signals: viewModel.detectedSignals))
                    .font(.subheadline)
                if let question = language.followupQuestion(for: quality) {
                    Text(question)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.indigo)
                }
            }
            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Plan Strip

    @ViewBuilder
    private var weeklyPlanStrip: some View {
        if let plan = viewModel.currentWeeklyPlan, !plan.days.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(language.text(.weeklyPlan), systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(plan.days.count) \(language == .chinese ? "天" : "days")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(plan.days.prefix(7).enumerated()), id: \.element.id) { idx, day in
                            let isToday = Calendar.current.isDateInToday(day.date)
                            VStack(spacing: 6) {
                                Text(dayOfWeek(day.date))
                                    .font(.caption2.weight(isToday ? .bold : .medium))
                                    .foregroundStyle(isToday ? .white : .secondary)
                                    .frame(width: 32, height: 32)
                                    .background(isToday ? Color.accentColor : Color(.systemGray6))
                                    .clipShape(Circle())

                                Text(day.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 64)

                                Text(language.planType(day.planType))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .frame(width: 72)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - Metrics Grid

    @ViewBuilder
    private var metricsGrid: some View {
        if !viewModel.comparisons.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(language.text(.metricsTab), systemImage: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(viewModel.comparisons, id: \.metric) { comparison in
                        metricTile(
                            comparison: comparison,
                            status: viewModel.todayMetrics?.perMetricStatus[comparison.metric] ?? .missing
                        )
                    }
                }

                if let workouts = viewModel.todayMetrics?.workouts, !workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(language.text(.workouts))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(workouts) { workout in
                            HStack {
                                Image(systemName: "figure.run")
                                    .foregroundStyle(.pink)
                                Text(workout.type)
                                    .font(.caption)
                                Spacer()
                                Text("\(workout.durationMinutes.formatted()) \(language.minuteUnit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func metricTile(comparison: MetricComparison, status: MetricStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: metricIcon(comparison.metric))
                    .font(.caption2)
                    .foregroundStyle(metricColor(comparison.metric))
                Text(language.metric(comparison.metric))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if status != .valid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(metricValue(comparison.todayValue, metric: comparison.metric))
                    .font(.title3.weight(.semibold))
                Text(comparison.unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                if let delta = comparison.absoluteDelta {
                    Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text(metricDelta(comparison))
                        .font(.caption2.weight(.medium))
                } else {
                    Text(language.text(.deltaUnavailable))
                        .font(.caption2)
                }
            }
            .foregroundStyle(metricDeltaColor(comparison))
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Collapsible Feedback & Yesterday

    @ViewBuilder
    private var collapsibleFeedback: some View {
        let hasFeedback = viewModel.yesterdayRecommendation != nil
        let hasYesterday = viewModel.yesterdayRecommendation != nil || viewModel.verificationReport != nil

        if hasFeedback || hasYesterday {
            VStack(spacing: 12) {
                if hasFeedback {
                    DisclosureGroup {
                        feedbackContent
                            .padding(.top, 8)
                    } label: {
                        Label(language.text(.feedbackTitle), systemImage: "square.and.pencil")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                if hasYesterday {
                    DisclosureGroup {
                        yesterdayContent
                            .padding(.top, 8)
                    } label: {
                        Label(language.text(.yesterdaySection), systemImage: "clock.arrow.circlepath")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var feedbackContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(language.text(.adherence), selection: $viewModel.feedbackAdherence) {
                ForEach(FeedbackAdherence.allCases, id: \.self) { a in
                    Text(language.adherence(a)).tag(a)
                }
            }
            .pickerStyle(.segmented)

            ScoreSlider(title: language.text(.energy), value: $viewModel.feedbackEnergy)
            ScoreSlider(title: language.text(.soreness), value: $viewModel.feedbackSoreness)
            ScoreSlider(title: language.text(.stress), value: $viewModel.feedbackStress)

            TextField(language.text(.note), text: $viewModel.feedbackNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            Button {
                viewModel.saveFeedback()
            } label: {
                Label(language.text(.saveFeedback), systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var yesterdayContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let rec = viewModel.yesterdayRecommendation {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text(.yesterdayRecommendation))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(rec.title)
                        .font(.subheadline.weight(.semibold))
                    Text(rec.recommendation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let fb = viewModel.yesterdayFeedback {
                        Text("\(language.text(.adherence)): \(language.adherence(fb.adherence))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let report = viewModel.verificationReport {
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
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func reportBadgeColor(_ outcome: VerificationOutcome) -> Color {
        switch outcome {
        case .likelyHelped: .green
        case .neutral: .blue
        case .unclear: .orange
        case .likelyNotHelped: .red
        }
    }

    // MARK: - Metric Helpers

    private func metricIcon(_ metric: HealthMetric) -> String {
        switch metric {
        case .sleepHours: "bed.double.fill"
        case .hrv: "waveform.path.ecg"
        case .restingHeartRate: "heart.fill"
        case .steps: "figure.walk"
        case .activeEnergyKcal: "flame.fill"
        case .exerciseMinutes: "timer"
        case .workouts: "figure.run"
        }
    }

    private func metricColor(_ metric: HealthMetric) -> Color {
        switch metric {
        case .sleepHours: .blue
        case .hrv: .green
        case .restingHeartRate: .orange
        case .steps: .pink
        case .activeEnergyKcal: .red
        case .exerciseMinutes: .mint
        case .workouts: .purple
        }
    }

    private func metricValue(_ val: Double?, metric: HealthMetric) -> String {
        guard let val else { return language.missing }
        if metric == .steps {
            return val.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
        }
        return val.formatted(.number.precision(.fractionLength(1)))
    }

    private func metricDelta(_ comparison: MetricComparison) -> String {
        guard let abs = comparison.absoluteDelta else { return "--" }
        if comparison.metric == .restingHeartRate {
            return "\(abs >= 0 ? "+" : "")\(abs.formatted(.number.precision(.fractionLength(1)))) bpm"
        }
        if let pct = comparison.percentageDelta {
            return "\(pct >= 0 ? "+" : "")\(pct.formatted(.number.precision(.fractionLength(0))))%"
        }
        return "\(abs >= 0 ? "+" : "")\(abs.formatted(.number.precision(.fractionLength(1))))"
    }

    private func metricDeltaColor(_ comparison: MetricComparison) -> Color {
        guard let delta = comparison.absoluteDelta else { return .secondary }
        switch comparison.metric {
        case .sleepHours, .hrv, .steps, .activeEnergyKcal, .exerciseMinutes:
            return delta < 0 ? .orange : .green
        case .restingHeartRate:
            return delta > 0 ? .orange : .green
        case .workouts: return .secondary
        }
    }
}

// MARK: - Confidence Badge

private struct ConfidenceBadge: View {
    let level: ConfidenceLevel
    let language: AppLanguage

    var body: some View {
        Text(language.confidence(level))
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch level {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }
}

// MARK: - Score Slider

struct ScoreSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(value.rounded()))/10")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 1...10, step: 1)
        }
    }
}

#Preview {
    let vm = OHeasViewModel()
    TodayView(viewModel: vm, language: .chinese)
        .task { await vm.load() }
}
