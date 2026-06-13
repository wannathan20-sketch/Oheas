//
//  OHeasViewModel.swift
//  OHeas
//
//  OHeasViewModel.swift — OHeas UI component.
//  OHeasViewModel.swift — OHeas UI 组件。
//


import Combine
import Foundation
import SwiftUI
import OHeasCore
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/// Thin coordination layer that owns sub-ViewModels and orchestrates the daily pipeline.
/// Sub-ViewModels own their own published state; this VM exposes common properties
/// for backward compatibility during the gradual UI migration.
@MainActor
final class OHeasViewModel: ObservableObject {
    // MARK: - Sub-ViewModels

    let healthData: HealthDataViewModel
    let recommendation: RecommendationViewModel
    let plan: PlanViewModel
    let memory: MemoryViewModel
    let experiment: ExperimentViewModel
    let onboarding: OnboardingViewModel
    let sync: SyncViewModel
    let history: HistoryViewModel

    // MARK: - Language

    private var cancellables = Set<AnyCancellable>()

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var preferredLanguage: String {
        (AppLanguage(rawValue: languageRawValue) ?? .chinese).rawValue
    }

    // MARK: - Cross-cutting state (not yet moved to sub-VMs)

    @Published var agentContext: AgentContext?
    @Published var effectivenessReport: EffectivenessReport?
    @Published var evaluationResults: [EvaluationResult] = []
    @Published var regressionResults: [RegressionResult] = []

    // Follow-up chip state
    @Published var followUpChips: [CoachFollowUpChip] = []
    @Published var inlineResponse: CoachInlineResponse?
    @Published var isLoadingInlineResponse = false

    // Gamification state
    @Published var gamificationSnapshot: GamificationSnapshot?
    @Published var showCelebration = false
    @Published var celebrationBadgeName = ""

    // MARK: - Delegated properties (for UI backward compatibility)

    // HealthData delegations
    var isLoading: Bool { healthData.isLoading }
    var dataSource: HealthDataSource { healthData.dataSource }
    var healthKitError: String? { healthData.healthKitError }
    var todayMetrics: DailyHealthMetrics? { healthData.todayMetrics }
    var baseline14d: HealthBaseline? { healthData.baseline14d }
    var comparisons: [MetricComparison] { healthData.comparisons }
    var dataQuality: DataQualityReport? { healthData.dataQuality }
    var detectedSignals: [HealthSignal] { healthData.detectedSignals }
    var bodyBudgetScore: BodyBudgetScore? { healthData.bodyBudgetScore }
    var errorKey: TextKey? { healthData.errorKey }
#if DEBUG
    var selectedDemoScenario: DemoScenario {
        get { healthData.selectedDemoScenario }
        set { healthData.selectedDemoScenario = newValue }
    }
    var demoScenarioSummary: String? { healthData.demoScenarioSummary }
    var isDemoMode: Bool { healthData.isDemoMode }
#endif
    var recentDailyMetrics: [DailyHealthMetrics] { healthData.recentDailyMetrics }

    // Recommendation delegations
    var recommendationResult: RecommendationResult? { recommendation.recommendationResult }
    var safetyAssessments: [SafetyAssessment] { recommendation.safetyAssessments }
    var isStreaming: Bool { recommendation.isStreaming }
    var streamingDisplayText: String { recommendation.streamingDisplayText }
    var yesterdayRecommendation: CoachRecommendation? { recommendation.yesterdayRecommendation }
    var yesterdayFeedback: DailyFeedback? { recommendation.yesterdayFeedback }
    var verificationReport: VerificationReport? { recommendation.verificationReport }
    var promptPayload: CoachPromptPayload? { recommendation.promptPayload }
    var privacySettings: PrivacySettings { recommendation.privacySettings }
    var privacyPayloadPreview: String { recommendation.privacyPayloadPreview }
    var feedbackAdherence: FeedbackAdherence {
        get { recommendation.feedbackAdherence }
        set { recommendation.feedbackAdherence = newValue }
    }
    var feedbackEnergy: Double {
        get { recommendation.feedbackEnergy }
        set { recommendation.feedbackEnergy = newValue }
    }
    var feedbackSoreness: Double {
        get { recommendation.feedbackSoreness }
        set { recommendation.feedbackSoreness = newValue }
    }
    var feedbackStress: Double {
        get { recommendation.feedbackStress }
        set { recommendation.feedbackStress = newValue }
    }
    var feedbackNote: String {
        get { recommendation.feedbackNote }
        set { recommendation.feedbackNote = newValue }
    }

    // Plan delegations
    var activeGoals: [UserGoal] { plan.activeGoals }
    var currentWeeklyPlan: WeeklyPlan? { plan.currentWeeklyPlan }
    var todayDailyPlan: DailyPlan? { plan.todayDailyPlan }
    var recentPlanAdjustments: [PlanAdjustment] { plan.recentPlanAdjustments }
    var weeklyReview: WeeklyReview? { plan.weeklyReview }
    var newGoalTitle: String {
        get { plan.newGoalTitle }
        set { plan.newGoalTitle = newValue }
    }
    var newGoalDescription: String {
        get { plan.newGoalDescription }
        set { plan.newGoalDescription = newValue }
    }
    var newGoalType: UserGoalType {
        get { plan.newGoalType }
        set { plan.newGoalType = newValue }
    }
    var newGoalFrequency: Double {
        get { plan.newGoalFrequency }
        set { plan.newGoalFrequency = newValue }
    }
    var newGoalPriority: GoalPriority {
        get { plan.newGoalPriority }
        set { plan.newGoalPriority = newValue }
    }

    // Memory delegations
    var userMemory: UserMemory { memory.userMemory }
    var patternCandidates: PatternMiningResult { memory.patternCandidates }

    // Experiment delegations
    var activeExperiment: PersonalExperiment? { experiment.activeExperiment }
    var proposedExperiment: PersonalExperiment? { experiment.proposedExperiment }
    var experimentHistory: [PersonalExperiment] { experiment.experimentHistory }
    var experimentCheckinCompleted: Bool {
        get { experiment.experimentCheckinCompleted }
        set { experiment.experimentCheckinCompleted = newValue }
    }
    var experimentCheckinEnergy: Double {
        get { experiment.experimentCheckinEnergy }
        set { experiment.experimentCheckinEnergy = newValue }
    }
    var experimentCheckinNote: String {
        get { experiment.experimentCheckinNote }
        set { experiment.experimentCheckinNote = newValue }
    }

    // Onboarding delegations
    var onboardingState: OnboardingState { onboarding.onboardingState }

    // Sync delegations
    var currentUser: AuthenticatedUser? { sync.currentUser }
    var authState: AuthState { sync.authState }
    var currentUserId: UUID? { sync.currentUser?.id }
    var authError: String? { sync.authError }
    var accountEmail: String {
        get { sync.accountEmail }
        set { sync.accountEmail = newValue }
    }
    var accountPassword: String {
        get { sync.accountPassword }
        set { sync.accountPassword = newValue }
    }
    var accountNickname: String {
        get { sync.accountNickname }
        set { sync.accountNickname = newValue }
    }
    var syncState: SyncState { sync.syncState }
    var analyticsSummary: BetaAnalyticsSummary { sync.analyticsSummary }
    var recentErrors: [ErrorEvent] { sync.recentErrors }
    var betaReadinessReport: BetaReadinessReport? { sync.betaReadinessReport }
    var exportManifest: LocalDataExportManifest? { sync.exportManifest }
    var resetConfirmationState: ResetConfirmationState { sync.resetConfirmationState }
    var scheduledReminders: [Reminder] { sync.scheduledReminders }

    // MARK: - Private services

    private let calendar = Calendar.current
    private let contextBuilder = AgentContextBuilder()
    private let effectivenessAnalyzer = EffectivenessAnalyzer()
    private let coverageLayer = DataCoverageLayer()
    private let errorReporter: ErrorReporter
    private let consentManager: ConsentManager

    private lazy var syncEngine: SyncEngine = {
        SyncEngine(
            queueURL: OHeasStorageURLs.syncQueue,
            stateURL: OHeasStorageURLs.syncState,
            apiClient: BackendAppConfiguration.load().makeClient(),
            consentManager: consentManager
        )
    }()

    private lazy var analyticsService: BetaAnalyticsService = {
        BetaAnalyticsService(
            fileURL: OHeasStorageURLs.analyticsEvents,
            backend: BackendAppConfiguration.load().makeClient(),
            consentManager: consentManager
        )
    }()

    // MARK: - Init

    init() {
        let reporter = ErrorReporter(fileURL: OHeasStorageURLs.errors)
        let consent = ConsentManager(fileURL: OHeasStorageURLs.consents)
        self.errorReporter = reporter
        self.consentManager = consent

        self.healthData = HealthDataViewModel(errorReporter: reporter)
        self.recommendation = RecommendationViewModel(consentManager: consent, errorReporter: reporter)
        self.plan = PlanViewModel(errorReporter: reporter)
        self.memory = MemoryViewModel(errorReporter: reporter)
        self.experiment = ExperimentViewModel(errorReporter: reporter)
        self.onboarding = OnboardingViewModel(consentManager: consent, errorReporter: reporter)
        self.sync = SyncViewModel(consentManager: consent, errorReporter: reporter)
        self.history = HistoryViewModel()

        // Forward objectWillChange from sub-ViewModels so SwiftUI re-evaluates
        // computed delegation properties (e.g. onboardingState, authState, isLoading)
        // when the underlying @Published state changes.
        healthData.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        recommendation.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        plan.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        memory.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        experiment.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        onboarding.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        sync.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        history.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
    }

    /// Wire up services that reference each other (avoids circular init dependencies).
    private func configureSubViewModels() {
        let engine = syncEngine
        let analytics = analyticsService
        recommendation.configure(syncEngine: engine, analyticsService: analytics)
        plan.configure(syncEngine: engine, analyticsService: analytics)
        experiment.configure(syncEngine: engine, analyticsService: analytics)
        sync.configure(syncEngine: engine, analyticsService: analytics)
        onboarding.configure(analyticsService: analytics)
    }

    // MARK: - Main pipeline

    func load(aiEnabled: Bool = true, remindersEnabled: Bool = false) async {
        configureSubViewModels()

        // Restore onboarding state so completed users skip the welcome flow.
        onboarding.loadOnboardingState()

        await sync.refreshProductState()
        sync.recordAnalytics(.appOpened)
        recommendation.loadPrivacySettings()

        // Load health data
        guard let healthPackage = await healthData.loadHealthData(days: 30) else {
            return
        }

        // Load dependent state (sequential — all MainActor-bound)
        plan.loadGoals()
        memory.loadMemory()
        experiment.loadExperiments()

        // Build or adjust weekly plan
        plan.buildOrAdjustWeeklyPlan(
            today: healthPackage.todayMetrics,
            baseline: healthPackage.baseline14d,
            quality: healthPackage.dataQuality,
            signals: healthPackage.detectedSignals,
            userMemory: memory.userMemory,
            activeExperiment: experiment.activeExperiment
        )

        // Build weekly review
        plan.buildWeeklyReviewIfPossible(
            userMemory: memory.userMemory,
            experimentHistory: experiment.experimentHistory,
            metricsForWeek: healthPackage.recentDailyMetrics
        )

        // Reminders
        sync.buildReminders(
            plan: plan.currentWeeklyPlan,
            activeExperiment: experiment.activeExperiment,
            quality: healthPackage.dataQuality,
            enabled: remindersEnabled
        )

        // Build AgentContext
        let context = contextBuilder.build(
            userGoal: "Understand today's body state and choose one small lifestyle action.",
            todayMetrics: healthPackage.todayMetrics,
            baseline14d: healthPackage.baseline14d,
            dataQuality: healthPackage.dataQuality,
            detectedSignals: healthPackage.detectedSignals,
            userMemory: memory.userMemory,
            activeExperiment: experiment.activeExperiment,
            recentExperimentResults: experiment.experimentHistory.compactMap(\.result),
            activeGoals: plan.activeGoals,
            currentWeeklyPlan: plan.currentWeeklyPlan,
            todayDailyPlan: plan.todayDailyPlan,
            recentPlanAdjustments: plan.recentPlanAdjustments,
            weeklyReviewSummary: plan.weeklyReview?.adherenceSummary,
            remindersEnabled: remindersEnabled,
            privacySettings: recommendation.privacySettings,
            preferredLanguage: preferredLanguage
        )
        agentContext = context

        // Load yesterday loop (independent of context building)
        recommendation.loadYesterdayLoop(today: healthPackage.todayMetrics)

        // Build prompt payload
        recommendation.buildPromptPayload(
            context: context,
            previousFeedback: recommendation.yesterdayFeedback,
            yesterdayRecommendation: recommendation.yesterdayRecommendation
        )

        // Generate recommendation
        await recommendation.generateRecommendation(
            context: context,
            aiEnabled: aiEnabled,
            previousFeedback: recommendation.yesterdayFeedback,
            yesterdayRecommendation: recommendation.yesterdayRecommendation
        )

        // Generate follow-up chips from the recommendation
        if let result = recommendation.recommendationResult {
            followUpChips = recommendation.generateChips(from: result, quality: healthPackage.dataQuality)
        }

        // Update body budget score with yesterday's feedback
        healthData.refreshBodyBudgetScore(with: recommendation.yesterdayFeedback)

        // Update verification
        recommendation.updateVerification(
            today: healthPackage.todayMetrics,
            baseline: healthPackage.baseline14d,
            quality: healthPackage.dataQuality
        )

        // Update memory and propose experiments
        memory.updateMemory(
            recentMetrics: healthPackage.recentDailyMetrics,
            feedbackHistory: (try? FeedbackStore(fileURL: OHeasStorageURLs.feedback).all()) ?? [],
            verificationReports: (try? VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports).all()) ?? [],
            recommendationHistory: (try? RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations).all()) ?? [],
            baseline: healthPackage.baseline14d
        )
        experiment.proposeExperiment(
            memory: memory.userMemory,
            recentMetrics: healthPackage.recentDailyMetrics,
            recentSignals: healthPackage.detectedSignals,
            dataQuality: healthPackage.dataQuality,
            userGoal: "Improve daily body-state decisions."
        )

        // Compute historical day scores (rolling per-day baselines)
        history.load(
            metrics: healthPackage.recentDailyMetrics,
            preferredLanguage: preferredLanguage
        )

        // Compute gamification snapshot
        computeGamification()

        // Update effectiveness
        updateEffectiveness(healthPackage: healthPackage)

        // Run evaluation suite
#if DEBUG
        runEvaluationSuite()
#endif

        // Refresh beta readiness
        sync.refreshBetaReadiness(
            dataSource: healthPackage.dataSource,
            todayMetrics: healthPackage.todayMetrics,
            recentMetrics: healthPackage.recentDailyMetrics,
            baseline14d: healthPackage.baseline14d
        )
    }

    // MARK: - Bidirectional Sync Merge

    /// Merge records pulled from the backend into local stores.
    ///
    /// Called after `sync.syncNow()` completes to apply remote changes
    /// (e.g. from another device) to local persistence.
    func mergePulledRecords() {
        let records = sync.pulledRecords
        guard !records.isEmpty else { return }

        for record in records {
            do {
                try applyRemoteRecord(record)
            } catch {
                // Skip records that fail to decode or save — the next pull will retry.
            }
        }
        sync.clearPulledRecords()
    }

    private func applyRemoteRecord(_ record: SyncRecord) throws {
        let decoder = JSONDecoder.oheas
        guard let data = record.payload.data(using: .utf8) else { return }

        switch record.entityType {
        case .coachRecommendation:
            let obj = try decoder.decode(CoachRecommendation.self, from: data)
            try RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations).save(obj)

        case .dailyFeedback:
            let obj = try decoder.decode(DailyFeedback.self, from: data)
            try FeedbackStore(fileURL: OHeasStorageURLs.feedback).save(obj)

        case .verificationReport:
            let obj = try decoder.decode(VerificationReport.self, from: data)
            try VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports).save(obj)

        case .userMemory:
            // Memory is complex — only restore if local is empty (new device).
            let store = MemoryStore(fileURL: OHeasStorageURLs.memory)
            let localMemory = (try? store.loadMemory()) ?? UserMemory()
            if localMemory.knownPatterns.isEmpty && localMemory.interventionRecords.isEmpty {
                let obj = try decoder.decode(UserMemory.self, from: data)
                try store.saveMemory(obj)
            }

        case .personalExperiment:
            let obj = try decoder.decode(PersonalExperiment.self, from: data)
            var experiments = (try? ExperimentStore(fileURL: OHeasStorageURLs.experiments).loadExperiments()) ?? []
            if let idx = experiments.firstIndex(where: { $0.id == obj.id }) {
                // Keep the newer one (last-write-wins).
                if record.updatedAt > experiments[idx].updatedAt {
                    experiments[idx] = obj
                }
            } else {
                experiments.append(obj)
            }
            try ExperimentStore(fileURL: OHeasStorageURLs.experiments).saveExperiments(experiments)

        case .weeklyPlan:
            let obj = try decoder.decode(WeeklyPlan.self, from: data)
            try PlanStore(fileURL: OHeasStorageURLs.weeklyPlans).saveCurrentWeekPlan(obj)

        case .weeklyReview:
            let obj = try decoder.decode(WeeklyReview.self, from: data)
            let reviewStore = CodableFileStore<WeeklyReview>(fileURL: OHeasStorageURLs.weeklyReviews)
            var reviews = (try? reviewStore.load()) ?? []
            if let idx = reviews.firstIndex(where: { $0.id == obj.id }) {
                if record.updatedAt > reviews[idx].createdAt {
                    reviews[idx] = obj
                }
            } else {
                reviews.append(obj)
            }
            try reviewStore.save(reviews)

        case .userGoal:
            let obj = try decoder.decode(UserGoal.self, from: data)
            try GoalStore(fileURL: OHeasStorageURLs.goals).addGoal(obj)

        case .privacySettings:
            // Local privacy settings always win — skip.
            break

        case .dailyHealthMetrics, .dataQualityReport, .safetyAssessment,
             .effectivenessReport, .betaAnalyticsEvent:
            // Computed locally or ephemeral — skip.
            break
        }
    }

    func refreshRecommendation(aiEnabled: Bool) async {
        guard let context = agentContext else { return }
        await recommendation.generateRecommendation(
            context: context,
            aiEnabled: aiEnabled,
            previousFeedback: recommendation.yesterdayFeedback,
            yesterdayRecommendation: recommendation.yesterdayRecommendation
        )
    }

    // MARK: - Feedback

    func saveFeedback() {
        recommendation.saveFeedback()
        if let today = todayMetrics, let baseline = baseline14d, let quality = dataQuality {
            recommendation.updateVerification(today: today, baseline: baseline, quality: quality)
        }
    }

    // MARK: - Follow-Up Chips

    func handleChipTap(_ chip: CoachFollowUpChip, aiEnabled: Bool = true) {
        switch chip.action {
        case .askQuestion:
            Task {
                isLoadingInlineResponse = true
                inlineResponse = nil
                if let context = agentContext {
                    let response = await recommendation.fetchInlineResponse(
                        for: chip,
                        context: context,
                        aiEnabled: aiEnabled
                    )
                    await MainActor.run {
                        inlineResponse = response
                        isLoadingInlineResponse = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingInlineResponse = false
                    }
                }
            }
        case .navigateToChat:
            // Handled by TodayView -> RootTabView coordination
            break
        }
    }

    func dismissInlineResponse() {
        withAnimation(OhAnimation.appear()) {
            inlineResponse = nil
        }
    }

    // MARK: - Goals

    func addGoal() { plan.addGoal() }
    func deactivateGoal(_ goal: UserGoal) { plan.deactivateGoal(goal) }
    func updateGoal(_ goal: UserGoal) { plan.updateGoal(goal) }

    // MARK: - Weekly Plan

    func regenerateWeeklyPlan() {
        guard let today = healthData.todayMetrics, let baseline = healthData.baseline14d, let quality = healthData.dataQuality else { return }
        plan.regenerateWeeklyPlan(
            today: today,
            baseline: baseline,
            quality: quality,
            signals: healthData.detectedSignals,
            userMemory: memory.userMemory,
            activeExperiment: experiment.activeExperiment
        )
    }

    func updateDailyPlanStatus(_ day: DailyPlan, status: DailyPlanStatus) {
        plan.updateDailyPlanStatus(day, status: status)
        plan.buildWeeklyReviewIfPossible(
            userMemory: memory.userMemory,
            experimentHistory: experiment.experimentHistory,
            metricsForWeek: healthData.recentDailyMetrics
        )
    }

    func replaceDailyPlan(_ day: DailyPlan, type: DailyPlanType, duration: Int) {
        plan.replaceDailyPlan(day, type: type, duration: duration)
    }

    // MARK: - Privacy

    func updatePrivacySettings(_ settings: PrivacySettings) {
        recommendation.updatePrivacySettings(settings)
        if let context = agentContext {
            let redacted = PrivacyManager(settings: settings).redactedContext(context)
            agentContext = redacted
            recommendation.buildPromptPayload(
                context: redacted,
                previousFeedback: recommendation.yesterdayFeedback,
                yesterdayRecommendation: recommendation.yesterdayRecommendation
            )
        }
    }

    func resetPrivacySettings() {
        recommendation.resetPrivacySettings()
    }

    // MARK: - Experiments

    func startProposedExperiment() { experiment.startProposedExperiment() }
    func saveExperimentCheckin() { experiment.saveExperimentCheckin() }
    func pauseActiveExperiment() { experiment.pauseActiveExperiment() }
    func completeActiveExperiment() {
        guard let baseline = healthData.baseline14d, let quality = healthData.dataQuality else { return }
        experiment.completeActiveExperiment(
            baseline: baseline,
            dataQuality: quality,
            recentMetrics: healthData.recentDailyMetrics
        )
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        onboarding.completeOnboarding(
            dataSource: healthData.dataSource,
            activeGoals: plan.activeGoals,
            baselineSampleCount: healthData.baseline14d?.sampleCounts.values.reduce(0, +) ?? 0
        )
    }

    /// Mark auth page as done — won't show again on next launch.
    func completeAuthPage() { onboarding.completeAuthPage() }


    // MARK: - Auth

    func refreshProductState() async { await sync.refreshProductState() }
    func signIn() async { await sync.signIn() }
    func signUp() async { await sync.signUp() }
    func signOut() async { await sync.signOut() }

    // MARK: - Apple Sign In

    func configureBackend(baseURL: URL?) { sync.configureBackend(baseURL: baseURL) }

    func handleAppleSignIn(result: Result<ASAuthorization, any Error>) async {
        await sync.handleAppleSignIn(result: result)
    }

    func signOutOfApple() { sync.signOutOfApple() }

    func restoreAppleSession() { sync.restoreAppleSession() }
    func performDeviceAuth() async { await sync.performDeviceAuth() }
    func loginWithEmail() async { await sync.loginWithEmail() }
    func registerWithEmail() async { await sync.registerWithEmail() }
    func bindEmail() async { await sync.bindEmail() }
    func setNickname() async -> Bool { await sync.setNickname() }

    // MARK: - Consent

    func recordConsent(_ type: ConsentType, accepted: Bool) { sync.recordConsent(type, accepted: accepted) }
    func hasConsent(_ type: ConsentType) -> Bool { sync.hasConsent(type) }

    // MARK: - Sync

    func syncNow() async {
        await sync.syncNow()
        mergePulledRecords()
    }
    func pauseSync() { sync.pauseSync() }
    func resumeSync() { sync.resumeSync() }

    // MARK: - Diagnostics

    func refreshBetaReadiness() {
        sync.refreshBetaReadiness(
            dataSource: healthData.dataSource,
            todayMetrics: healthData.todayMetrics,
            recentMetrics: healthData.recentDailyMetrics,
            baseline14d: healthData.baseline14d
        )
    }

    func refreshAnalyticsSummary() { sync.refreshAnalyticsSummary() }

    func exportLocalData() {
        sync.exportLocalData(
            recommendations: (try? RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations).all()) ?? [],
            feedback: (try? FeedbackStore(fileURL: OHeasStorageURLs.feedback).all()) ?? [],
            reports: (try? VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports).all()) ?? [],
            goals: (try? GoalStore(fileURL: OHeasStorageURLs.goals).loadGoals()) ?? [],
            plans: (try? PlanStore(fileURL: OHeasStorageURLs.weeklyPlans).loadPlans()) ?? [],
            privacy: recommendation.privacySettings
        )
    }

    func requestResetLocalData() { sync.requestResetLocalData() }

    func confirmResetLocalData() {
        sync.confirmResetLocalData()
#if DEBUG
        healthData.resetDemoData()
#endif
        recommendation.resetAll()
        memory.resetMemory()
        experiment.resetExperiments()
        try? PrivacyStore(fileURL: OHeasStorageURLs.privacySettings).saveSettings(.defaults)
        try? OnboardingStore(fileURL: OHeasStorageURLs.onboarding).save(OnboardingState())
    }

    // MARK: - Demo

#if DEBUG
    func loadDemoScenario() {
        guard let healthPackage = healthData.loadDemoScenario() else { return }

        // Wire up dependent data
        memory.userMemory = (try? MemoryStore(fileURL: OHeasStorageURLs.memory).loadMemory()) ?? UserMemory()
        experiment.experimentHistory = (try? ExperimentStore(fileURL: OHeasStorageURLs.experiments).loadExperiments()) ?? []
        experiment.activeExperiment = experiment.experimentHistory.last { $0.status == .active }
        experiment.proposedExperiment = experiment.experimentHistory.last { $0.status == .proposed }

        let data = DemoScenarioBuilder().build(healthData.selectedDemoScenario)

        plan.activeGoals = data.weeklyPlan.goals
        plan.currentWeeklyPlan = data.weeklyPlan
        plan.todayDailyPlan = data.weeklyPlan.days.last
        recommendation.yesterdayRecommendation = data.recommendationHistory.last
        recommendation.yesterdayFeedback = data.feedbackHistory.last
        recommendation.verificationReport = data.verificationReports.last
        effectivenessReport = data.effectivenessReport

        let context = contextBuilder.build(
            userGoal: data.summary,
            todayMetrics: healthPackage.todayMetrics,
            baseline14d: healthPackage.baseline14d,
            dataQuality: healthPackage.dataQuality,
            detectedSignals: healthPackage.detectedSignals,
            userMemory: data.userMemory,
            activeExperiment: experiment.activeExperiment,
            recentExperimentResults: data.experiments.compactMap(\.result),
            activeGoals: data.weeklyPlan.goals,
            currentWeeklyPlan: data.weeklyPlan,
            todayDailyPlan: plan.todayDailyPlan,
            weeklyReviewSummary: plan.weeklyReview?.adherenceSummary,
            privacySettings: recommendation.privacySettings,
            preferredLanguage: preferredLanguage
        )
        agentContext = context

        recommendation.buildPromptPayload(
            context: context,
            previousFeedback: data.feedbackHistory.last,
            yesterdayRecommendation: data.recommendationHistory.last
        )

        if let recommendationItem = data.recommendationHistory.last {
            let safety = SafetyGuardrail().sanitize(recommendation: recommendationItem, context: context).1
            recommendation.recommendationResult = RecommendationResult(
                recommendation: recommendationItem,
                safetyAssessment: safety,
                source: "demo"
            )
            recommendation.safetyAssessments = [safety] + recommendation.safetyAssessments
        }

        plan.buildWeeklyReviewIfPossible(
            userMemory: data.userMemory,
            experimentHistory: data.experiments,
            metricsForWeek: Array(data.metrics.suffix(7))
        )

        persistDemoData(data)
        runEvaluationSuite()
        sync.refreshBetaReadiness(
            dataSource: .mock,
            todayMetrics: healthPackage.todayMetrics,
            recentMetrics: healthPackage.recentDailyMetrics,
            baseline14d: healthPackage.baseline14d
        )
    }

    func resetDemoData() {
        healthData.resetDemoData()
        try? RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations).replaceAll([])
        try? FeedbackStore(fileURL: OHeasStorageURLs.feedback).replaceAll([])
        try? VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports).replaceAll([])
        experiment.resetExperiments()
        memory.resetMemory()
        recommendation.recommendationResult = nil
        effectivenessReport = nil
    }

    func runEvaluationSuite() {
        evaluationResults = AgentEvaluationRunner().run()
        do {
            let tester = PromptRegressionTester(store: CodableFileStore<PromptSnapshot>(fileURL: OHeasStorageURLs.promptSnapshots))
            regressionResults = try tester.runRegressionSuite()
        } catch {
            regressionResults = [
                RegressionResult(caseId: "suite", changed: false, regressionDetected: true, differences: ["Regression suite failed: \(error.localizedDescription)"])
            ]
        }
    }
#endif

    // MARK: - Gamification

    private func computeGamification() {
        let badgeStore = BadgeStore(fileURL: OHeasStorageURLs.badges)
        let previouslyEarned = (try? badgeStore.loadBadges()) ?? []
        let feedbackHistory = (try? FeedbackStore(fileURL: OHeasStorageURLs.feedback).all()) ?? []
        let plans = currentWeeklyPlan?.days ?? []
        let chatMessages = ChatMessageStore(fileURL: OHeasStorageURLs.chatMessages)
        let sessions = (try? chatMessages.loadSessions()) ?? []
        let allMessages = sessions.flatMap(\.messages)
        let recommendations = (try? RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations).all()) ?? []
        let weeklyReviews = (try? CodableFileStore<WeeklyReview>(fileURL: OHeasStorageURLs.weeklyReviews).load()) ?? []

        // Build score history from recent metrics
        var scores: [(Date, BodyBudgetScore)] = []
        let scorer = BodyBudgetScorer()
        let baseline = healthData.baseline14d ?? HealthBaseline(windowDays: 14)
        for metric in healthData.recentDailyMetrics {
            let fb = feedbackHistory.first { Calendar.current.isDate($0.date, inSameDayAs: metric.date) }
            let score = scorer.score(
                today: metric,
                baseline: baseline,
                signals: [], // Historical signals not recomputed for gamification
                feedback: fb,
                preferredLanguage: preferredLanguage
            )
            scores.append((metric.date, score))
        }

        let evaluator = BadgeEvaluator()
        let snapshot = evaluator.computeSnapshot(
            metrics: healthData.recentDailyMetrics,
            feedback: feedbackHistory,
            plans: plans,
            chatMessages: allMessages,
            scores: scores,
            experiments: experiment.experimentHistory,
            recommendations: recommendations,
            weeklyReviews: weeklyReviews,
            previouslyEarned: previouslyEarned
        )

        gamificationSnapshot = snapshot

        // Trigger celebration for newly unlocked badges
        if let firstBadge = snapshot.newlyUnlocked.first {
            celebrationBadgeName = firstBadge.nameKey
            showCelebration = true
            // Persist newly earned badges
            var updated = previouslyEarned
            for def in snapshot.newlyUnlocked {
                let state = BadgeState(badgeId: def.criteria.identifier)
                updated.append(state)
            }
            try? badgeStore.saveAll(updated)
            gamificationSnapshot = GamificationSnapshot(
                streaks: snapshot.streaks,
                earnedBadges: updated,
                newlyUnlocked: []
            )
        }
    }

    func acknowledgeCelebration() {
        showCelebration = false
        celebrationBadgeName = ""
    }

    // MARK: - Private

    private func updateEffectiveness(healthPackage: HealthDataPackage) {
        effectivenessReport = effectivenessAnalyzer.analyze(
            recommendations: (try? RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations).all()) ?? [],
            feedbackHistory: (try? FeedbackStore(fileURL: OHeasStorageURLs.feedback).all()) ?? [],
            verificationReports: (try? VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports).all()) ?? [],
            experiments: experiment.experimentHistory,
            weeklyPlans: (try? PlanStore(fileURL: OHeasStorageURLs.weeklyPlans).loadPlans()) ?? [],
            dailyMetrics: healthPackage.recentDailyMetrics,
            dataQualityHistory: healthPackage.recentDailyMetrics.map { coverageLayer.report(for: $0) },
            preferredLanguage: preferredLanguage
        )
    }

#if DEBUG
    private func persistDemoData(_ data: DemoScenarioData) {
        let memoryStore = MemoryStore(fileURL: OHeasStorageURLs.memory)
        let experimentStore = ExperimentStore(fileURL: OHeasStorageURLs.experiments)
        let recommendationStore = RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations)
        let feedbackStore = FeedbackStore(fileURL: OHeasStorageURLs.feedback)
        let verificationStore = VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports)
        let planStore = PlanStore(fileURL: OHeasStorageURLs.weeklyPlans)
        let weeklyReviewStore = CodableFileStore<WeeklyReview>(fileURL: OHeasStorageURLs.weeklyReviews)

        try? memoryStore.saveMemory(data.userMemory)
        try? experimentStore.saveExperiments(data.experiments)
        try? planStore.saveCurrentWeekPlan(data.weeklyPlan)
        for recommendation in data.recommendationHistory { try? recommendationStore.save(recommendation) }
        for feedback in data.feedbackHistory { try? feedbackStore.save(feedback) }
        for report in data.verificationReports { try? verificationStore.save(report) }
        if let review = plan.weeklyReview {
            try? weeklyReviewStore.upsert(review) { $0.weekStartDate == review.weekStartDate }
        }
    }
#endif
}
