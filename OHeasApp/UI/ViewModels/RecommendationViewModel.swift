//
//  RecommendationViewModel.swift
//  OHeas
//
//  Manages LLM recommendations, safety, feedback, verification, streaming.
//  管理 LLM 建议、安全、反馈、验证、流式输出。
//


import Foundation
import OHeasCore

@MainActor
final class RecommendationViewModel: ObservableObject {
    @Published var recommendationResult: RecommendationResult?
    @Published var safetyAssessments: [SafetyAssessment] = []
    @Published var yesterdayRecommendation: CoachRecommendation?
    @Published var yesterdayFeedback: DailyFeedback?
    @Published var verificationReport: VerificationReport?
    @Published var promptPayload: CoachPromptPayload?
    @Published var privacySettings: PrivacySettings = .defaults
    @Published var privacyPayloadPreview: String = "{}"
    @Published var feedbackAdherence: FeedbackAdherence = .completed
    @Published var feedbackEnergy: Double = 6
    @Published var feedbackSoreness: Double = 4
    @Published var feedbackStress: Double = 4
    @Published var feedbackNote: String = ""

    // Streaming state
    @Published var isStreaming: Bool = false
    @Published var streamingDisplayText: String = ""
    private var streamingTask: Task<Void, Never>?

    private let calendar = Calendar.current
    private let promptBuilder = CoachPromptBuilder()
    private let verificationEngine = VerificationEngine()
    private let recommendationStore = RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations)
    private let feedbackStore = FeedbackStore(fileURL: OHeasStorageURLs.feedback)
    private let verificationStore = VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports)
    private let privacyStore = PrivacyStore(fileURL: OHeasStorageURLs.privacySettings)
    private let consentManager: ConsentManager
    private let errorReporter: ErrorReporter
    private var syncEngine: SyncEngine?
    private var analyticsService: BetaAnalyticsService?

    init(
        consentManager: ConsentManager,
        errorReporter: ErrorReporter
    ) {
        self.consentManager = consentManager
        self.errorReporter = errorReporter
    }

    /// Inject services that may not be ready at init time.
    func configure(
        syncEngine: SyncEngine,
        analyticsService: BetaAnalyticsService
    ) {
        self.syncEngine = syncEngine
        self.analyticsService = analyticsService
    }

    // MARK: - Privacy

    func loadPrivacySettings() {
        do {
            privacySettings = try privacyStore.loadSettings()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to load privacy settings: \(error.localizedDescription)")
            privacySettings = .defaults
        }
    }

    func updatePrivacySettings(_ settings: PrivacySettings) {
        privacySettings = settings
        do {
            try privacyStore.saveSettings(settings)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save privacy settings: \(error.localizedDescription)")
        }
        do {
            try syncEngine?.enqueue(settings, entityType: .privacySettings, entityId: "local")
        } catch {
            errorReporter.record(category: .sync, message: "Failed to enqueue privacy settings: \(error.localizedDescription)")
        }
    }

    func resetPrivacySettings() {
        do {
            privacySettings = try privacyStore.resetDefaults()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to reset privacy settings: \(error.localizedDescription)")
            privacySettings = .defaults
        }
    }

    // MARK: - Recommendation

    func generateRecommendation(
        context: AgentContext,
        aiEnabled: Bool,
        previousFeedback: DailyFeedback?,
        yesterdayRecommendation: CoachRecommendation?
    ) async {
        // Cancel any in-flight streaming
        streamingTask?.cancel()
        isStreaming = true
        streamingDisplayText = ""

        let client = OpenAIAppConfiguration.load().makeClient()
        let allowedAI = aiEnabled && consentManager.hasConsent(.aiLifestyleAdvice)
        let service = CoachRecommendationService(
            privacySettings: privacySettings,
            client: client,
            aiEnabled: allowedAI
        )

        let stream = service.streamRecommendation(
            for: context,
            previousFeedback: previousFeedback,
            yesterdayRecommendation: yesterdayRecommendation
        )

        var receivedResult: RecommendationResult?
        do {
            for try await event in stream {
                if let text = event.partialDisplayText, !text.isEmpty {
                    streamingDisplayText = text
                }
                if event.isComplete, let result = event.result {
                    receivedResult = result
                    break
                }
            }
        } catch {
            // Stream failed; fallback result may have been yielded, otherwise rule-based
            if receivedResult == nil {
                let fallbackService = CoachRecommendationService(
                    privacySettings: privacySettings,
                    client: nil,
                    aiEnabled: false
                )
                receivedResult = await fallbackService.recommendation(
                    for: context,
                    previousFeedback: previousFeedback,
                    yesterdayRecommendation: yesterdayRecommendation
                )
            }
        }

        // Apply typewriter effect for the final display text if not already streamed
        if let result = receivedResult {
            if streamingDisplayText.isEmpty {
                // No streaming tokens arrived — use typewriter animation
                let displayString = [
                    result.recommendation.recommendation,
                    result.recommendation.tonightAction,
                    result.recommendation.summary
                ].joined(separator: "\n\n")
                await typewriteDisplay(displayString)
            }
            finalizeRecommendation(result)
        }

        isStreaming = false
    }

    private func typewriteDisplay(_ text: String) async {
        streamingDisplayText = ""
        for char in text {
            streamingDisplayText.append(char)
            try? await Task.sleep(nanoseconds: 25_000_000) // 25ms per character
        }
    }

    private func finalizeRecommendation(_ result: RecommendationResult) {
        recommendationResult = result
        safetyAssessments = [result.rawSafetyAssessment, result.safetyAssessment].compactMap { $0 } + safetyAssessments

        do {
            try recommendationStore.save(result.recommendation)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save recommendation: \(error.localizedDescription)")
        }

        do {
            try syncEngine?.enqueue(result.recommendation, entityType: .coachRecommendation, entityId: result.recommendation.id.uuidString)
        } catch {
            errorReporter.record(category: .sync, message: "Failed to enqueue recommendation: \(error.localizedDescription)")
        }

        recordAnalytics(.recommendationGenerated, properties: ["source": result.source, "confidence": result.recommendation.confidence.rawValue])

        if let fallback = result.fallbackReason {
            recordAnalytics(.llmFallbackUsed, properties: ["reason": fallback])
            errorReporter.record(category: .llm, message: fallback)
        }
        if let assessment = result.safetyAssessment, assessment.riskLevel != .safe {
            recordAnalytics(.safetyFlagTriggered, properties: ["riskLevel": assessment.riskLevel.rawValue])
            do {
                try syncEngine?.enqueue(assessment, entityType: .safetyAssessment, entityId: assessment.id.uuidString)
            } catch {
                errorReporter.record(category: .sync, message: "Failed to enqueue safety assessment: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Yesterday loop

    func loadYesterdayLoop(today: DailyHealthMetrics) {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today.date) else { return }
        do {
            yesterdayRecommendation = try recommendationStore.recommendation(on: yesterday)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to load yesterday recommendation: \(error.localizedDescription)")
        }
        do {
            yesterdayFeedback = try feedbackStore.feedback(on: yesterday)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to load yesterday feedback: \(error.localizedDescription)")
        }

        if let feedback = yesterdayFeedback {
            feedbackAdherence = feedback.adherence
            feedbackEnergy = Double(feedback.subjectiveEnergy)
            feedbackSoreness = Double(feedback.soreness)
            feedbackStress = Double(feedback.stress)
            feedbackNote = feedback.note ?? ""
        }
    }

    // MARK: - Feedback

    func saveFeedback() {
        guard let recommendation = yesterdayRecommendation else { return }
        let feedback = DailyFeedback(
            date: recommendation.date,
            recommendationId: recommendation.id,
            adherence: feedbackAdherence,
            subjectiveEnergy: Int(feedbackEnergy.rounded()),
            soreness: Int(feedbackSoreness.rounded()),
            stress: Int(feedbackStress.rounded()),
            note: feedbackNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : feedbackNote
        )
        do {
            try feedbackStore.save(feedback)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save feedback: \(error.localizedDescription)")
        }
        do {
            try syncEngine?.enqueue(feedback, entityType: .dailyFeedback, entityId: feedback.id.uuidString)
        } catch {
            errorReporter.record(category: .sync, message: "Failed to enqueue feedback: \(error.localizedDescription)")
        }
        recordAnalytics(feedback.adherence == .skipped ? .recommendationSkipped : .recommendationCompleted)
        recordAnalytics(.feedbackSaved, properties: ["adherence": feedback.adherence.rawValue])
        yesterdayFeedback = feedback
    }

    // MARK: - Verification

    func updateVerification(
        today: DailyHealthMetrics,
        baseline: HealthBaseline,
        quality: DataQualityReport
    ) {
        guard let recommendation = yesterdayRecommendation else {
            verificationReport = nil
            return
        }
        let report = verificationEngine.verify(
            yesterday: recommendation,
            feedback: yesterdayFeedback,
            today: today,
            baseline: baseline,
            dataQuality: quality
        )
        verificationReport = report
        do {
            try verificationStore.save(report)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save verification report: \(error.localizedDescription)")
        }
    }

    func buildPromptPayload(
        context: AgentContext,
        previousFeedback: DailyFeedback?,
        yesterdayRecommendation: CoachRecommendation?
    ) {
        do {
            promptPayload = try promptBuilder.buildPayload(
                context: context,
                previousFeedback: previousFeedback,
                yesterdayRecommendation: yesterdayRecommendation,
                privacySettings: privacySettings
            )
        } catch {
            errorReporter.record(category: .llm, message: "Failed to build prompt payload: \(error.localizedDescription)")
        }
        updatePrivacyPreview(context: context)
    }

    // MARK: - Private

    private func updatePrivacyPreview(context: AgentContext) {
        privacyPayloadPreview = PrivacyManager(settings: privacySettings).payloadPreview(for: context)
    }

    private func recordAnalytics(_ type: BetaAnalyticsEventType, properties: [String: String] = [:]) {
        let userId = "local"
        do {
            _ = try analyticsService?.record(eventType: type, userId: userId, properties: properties)
        } catch {
            // Analytics failures are non-critical.
        }
    }

    // MARK: - Lifecycle

    func resetAll() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
        streamingDisplayText = ""
        recommendationResult = nil
        yesterdayRecommendation = nil
        yesterdayFeedback = nil
        verificationReport = nil
        safetyAssessments = []
        promptPayload = nil
        privacyPayloadPreview = "{}"
    }
}
