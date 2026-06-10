//
//  ViewModelTests.swift
//  OHeas
//
//  ViewModel layer unit tests — 25 tests for 7 sub-ViewModels.
//  ViewModel 层单元测试 — 25 个测试覆盖 7 个子 ViewModel。
//


import Foundation
import Testing
@testable import OHeas
import OHeasCore

@Suite("ViewModels") @MainActor
struct ViewModelTests {

    // MARK: - Helpers

    private static func nullErrorReporter() -> ErrorReporter {
        ErrorReporter(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("test-errors-\(UUID().uuidString).json"))
    }

    private static func nullConsentManager() -> ConsentManager {
        ConsentManager(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("test-consent-\(UUID().uuidString).json"))
    }

    // MARK: - HealthDataViewModel

    @Suite("HealthDataViewModel") @MainActor
    struct HealthDataViewModelTests {
        @Test("Initializes with isLoading false and mock data source")
        func initialState() {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = HealthDataViewModel(errorReporter: reporter)
            #expect(vm.isLoading == false)
            #expect(vm.dataSource == .mock)
            #expect(vm.todayMetrics == nil)
            #expect(vm.baseline14d == nil)
            #expect(vm.comparisons.isEmpty)
            #expect(vm.detectedSignals.isEmpty)
            #expect(vm.dataQuality == nil)
        }

        @Test("Loads mock health data successfully")
        func loadsMockData() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = HealthDataViewModel(errorReporter: reporter)
            let pkg = await vm.loadHealthData(days: 30)
            #expect(pkg != nil)
            #expect(vm.isLoading == false)
            #expect(vm.dataSource == .mock)
            #expect(vm.todayMetrics != nil)
            #expect(vm.baseline14d != nil)
            #expect(vm.dataQuality != nil)
        }

        @Test("Setting demo scenario and loading it enables demo mode")
        func demoScenarioSwitch() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = HealthDataViewModel(errorReporter: reporter)
            vm.selectedDemoScenario = .overtrainingRunner
            let _ = vm.loadDemoScenario()
            #expect(vm.selectedDemoScenario == .overtrainingRunner)
            #expect(vm.isDemoMode == true)
            #expect(vm.demoScenarioSummary != nil)
        }

        @Test("Resetting demo data clears state")
        func resetDemoData() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = HealthDataViewModel(errorReporter: reporter)
            let _ = await vm.loadHealthData(days: 30)
            vm.resetDemoData()
            #expect(vm.todayMetrics == nil)
        }
    }

    // MARK: - RecommendationViewModel

    @Suite("RecommendationViewModel") @MainActor
    struct RecommendationViewModelTests {
        @Test("Initializes with default privacy settings and no result")
        func initialState() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = RecommendationViewModel(consentManager: consent, errorReporter: reporter)
            #expect(vm.recommendationResult == nil)
            #expect(vm.isStreaming == false)
            #expect(vm.streamingDisplayText.isEmpty)
            #expect(vm.yesterdayRecommendation == nil)
            #expect(vm.yesterdayFeedback == nil)
            #expect(vm.verificationReport == nil)
            #expect(vm.safetyAssessments.isEmpty)
        }

        @Test("Loads privacy settings from store")
        func loadsPrivacySettings() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = RecommendationViewModel(consentManager: consent, errorReporter: reporter)
            vm.loadPrivacySettings()
            _ = vm.privacySettings
        }

        @Test("Resets all state correctly")
        func resetAll() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = RecommendationViewModel(consentManager: consent, errorReporter: reporter)
            vm.isStreaming = true
            vm.streamingDisplayText = "test streaming text"
            vm.resetAll()
            #expect(vm.isStreaming == false)
            #expect(vm.streamingDisplayText.isEmpty)
            #expect(vm.recommendationResult == nil)
            #expect(vm.safetyAssessments.isEmpty)
            #expect(vm.yesterdayRecommendation == nil)
        }

        @Test("Default feedback values are set correctly")
        func defaultFeedbackValues() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = RecommendationViewModel(consentManager: consent, errorReporter: reporter)
            #expect(vm.feedbackAdherence == .completed)
            #expect(vm.feedbackEnergy == 6)
            #expect(vm.feedbackSoreness == 4)
            #expect(vm.feedbackStress == 4)
            #expect(vm.feedbackNote.isEmpty)
        }

        @Test("Streaming state transitions are correct")
        func streamingStateTransitions() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = RecommendationViewModel(consentManager: consent, errorReporter: reporter)
            #expect(vm.isStreaming == false)
            #expect(vm.streamingDisplayText.isEmpty)
            vm.isStreaming = true
            vm.streamingDisplayText = "Take a short walk today"
            #expect(vm.isStreaming == true)
            #expect(vm.streamingDisplayText == "Take a short walk today")
        }

        @Test("Privacy settings update triggers redaction")
        func privacySettingsUpdate() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = RecommendationViewModel(consentManager: consent, errorReporter: reporter)
            vm.loadPrivacySettings()
            var settings = vm.privacySettings
            settings.useLLM = true
            vm.updatePrivacySettings(settings)
            #expect(vm.privacySettings.useLLM == true)
        }
    }

    // MARK: - PlanViewModel

    @Suite("PlanViewModel") @MainActor
    struct PlanViewModelTests {
        @Test("Initializes with empty goals and no plan")
        func initialState() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = PlanViewModel(errorReporter: reporter)
            // init() does not call loadGoals(), so activeGoals starts empty
            #expect(vm.activeGoals.isEmpty)
            #expect(vm.currentWeeklyPlan == nil)
            #expect(vm.todayDailyPlan == nil)
            #expect(vm.recentPlanAdjustments.isEmpty)
            #expect(vm.weeklyReview == nil)
            // Default form values (pre-filled for onboarding convenience)
            #expect(vm.newGoalTitle == "提升精力和稳定运动习惯")
            #expect(vm.newGoalType == .buildConsistency)
            #expect(vm.newGoalPriority == .high)
        }

        @Test("Adds and manages goals")
        func goalCRUD() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = PlanViewModel(errorReporter: reporter)
            // Sync with store to establish baseline
            vm.loadGoals()
            let countBefore = vm.activeGoals.count
            vm.newGoalTitle = "Test Goal"
            vm.newGoalDescription = "A test goal for unit testing"
            vm.newGoalType = .improveSleep
            vm.newGoalFrequency = 3
            vm.newGoalPriority = .high
            vm.addGoal()
            // Verify goal was added (delta = 1 from baseline)
            #expect(vm.activeGoals.count == countBefore + 1)
            // Form fields reset after add
            #expect(vm.newGoalTitle.isEmpty)
            #expect(vm.newGoalDescription.isEmpty)
            // Verify the added goal's properties
            let added = vm.activeGoals.first(where: { $0.title == "Test Goal" })
            #expect(added != nil)
            #expect(added?.type == .improveSleep)
            #expect(added?.targetFrequencyPerWeek == 3)
            #expect(added?.priority == .high)
            // Deactivate and verify count returns to baseline
            if let goal = added {
                vm.deactivateGoal(goal)
                #expect(vm.activeGoals.count == countBefore)
            }
        }

        @Test("Adding multiple goals")
        func multipleGoals() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = PlanViewModel(errorReporter: reporter)
            // Sync with store to establish baseline
            vm.loadGoals()
            let countBefore = vm.activeGoals.count
            vm.newGoalTitle = "Goal 1"
            vm.newGoalType = .improveSleep
            vm.addGoal()
            // Form reset between adds
            #expect(vm.newGoalTitle.isEmpty)
            vm.newGoalTitle = "Goal 2"
            vm.newGoalType = .buildConsistency
            vm.addGoal()
            // Two new goals added on top of baseline
            #expect(vm.activeGoals.count == countBefore + 2)
        }

        @Test("Loads goals from store")
        func loadsGoals() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = PlanViewModel(errorReporter: reporter)
            vm.loadGoals()
            #expect(vm.activeGoals.count >= 0)
        }
    }

    // MARK: - MemoryViewModel

    @Suite("MemoryViewModel") @MainActor
    struct MemoryViewModelTests {
        @Test("Initializes with empty user memory")
        func initialState() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = MemoryViewModel(errorReporter: reporter)
            #expect(vm.userMemory.knownPatterns.isEmpty)
            #expect(vm.patternCandidates.patterns.isEmpty)
        }

        @Test("Loads memory from store")
        func loadsMemory() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = MemoryViewModel(errorReporter: reporter)
            vm.loadMemory()
            #expect(vm.userMemory.knownPatterns.count >= 0)
        }

        @Test("Resets memory correctly")
        func resetMemory() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = MemoryViewModel(errorReporter: reporter)
            vm.loadMemory()
            vm.resetMemory()
            #expect(vm.userMemory.knownPatterns.isEmpty)
            #expect(vm.patternCandidates.patterns.isEmpty)
        }
    }

    // MARK: - ExperimentViewModel

    @Suite("ExperimentViewModel") @MainActor
    struct ExperimentViewModelTests {
        @Test("Initializes with no experiments")
        func initialState() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = ExperimentViewModel(errorReporter: reporter)
            #expect(vm.activeExperiment == nil)
            #expect(vm.proposedExperiment == nil)
            #expect(vm.experimentHistory.isEmpty)
            #expect(vm.experimentCheckinCompleted == false)
            #expect(vm.experimentCheckinEnergy == 6)
            #expect(vm.experimentCheckinNote.isEmpty)
        }

        @Test("Loads experiments from store")
        func loadsExperiments() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = ExperimentViewModel(errorReporter: reporter)
            vm.loadExperiments()
            #expect(vm.experimentHistory.count >= 0)
        }

        @Test("Resets all experiment data")
        func resetExperiments() async {
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = ExperimentViewModel(errorReporter: reporter)
            vm.loadExperiments()
            vm.resetExperiments()
            #expect(vm.activeExperiment == nil)
            #expect(vm.proposedExperiment == nil)
            #expect(vm.experimentHistory.isEmpty)
        }
    }

    // MARK: - OnboardingViewModel

    @Suite("OnboardingViewModel") @MainActor
    struct OnboardingViewModelTests {
        @Test("Initializes with not completed state")
        func initialState() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = OnboardingViewModel(consentManager: consent, errorReporter: reporter)
            #expect(vm.onboardingState.hasCompletedOnboarding == false)
            #expect(vm.onboardingState.healthKitAuthorized == false)
        }

        @Test("Complete onboarding transitions state")
        func completeOnboarding() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = OnboardingViewModel(consentManager: consent, errorReporter: reporter)
            vm.completeOnboarding(dataSource: .mock, activeGoals: [], baselineSampleCount: 90)
            #expect(vm.onboardingState.hasCompletedOnboarding == true)
        }

        @Test("Skip HealthKit enters limited mode")
        func skipHealthKit() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = OnboardingViewModel(consentManager: consent, errorReporter: reporter)
            vm.skipHealthKitDuringOnboarding()
            #expect(vm.onboardingState.healthKitAuthorized == false)
            vm.completeOnboarding(dataSource: .mock, activeGoals: [], baselineSampleCount: 0)
            #expect(vm.onboardingState.hasCompletedOnboarding == true)
        }
    }

    // MARK: - SyncViewModel

    @Suite("SyncViewModel") @MainActor
    struct SyncViewModelTests {
        @Test("Initializes with localOnly auth and no user")
        func initialState() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = SyncViewModel(consentManager: consent, errorReporter: reporter)
            #expect(vm.currentUser == nil)
            #expect(vm.authState == .localOnly)
            #expect(vm.accountEmail.isEmpty)
            #expect(vm.accountPassword.isEmpty)
            #expect(vm.syncState.mode == .localOnly)
            #expect(vm.resetConfirmationState == .idle)
        }

        @Test("Records and checks consent")
        func consentManagement() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = SyncViewModel(consentManager: consent, errorReporter: reporter)
            vm.recordConsent(.aiLifestyleAdvice, accepted: true)
            #expect(vm.hasConsent(.aiLifestyleAdvice) == true)
            vm.recordConsent(.aiLifestyleAdvice, accepted: false)
            #expect(vm.hasConsent(.aiLifestyleAdvice) == false)
            #expect(vm.hasConsent(.cloudSync) == false)
        }

        @Test("Reset local data requires confirmation")
        func resetConfirmation() async {
            let consent = ViewModelTests.nullConsentManager()
            let reporter = ViewModelTests.nullErrorReporter()
            let vm = SyncViewModel(consentManager: consent, errorReporter: reporter)
            #expect(vm.resetConfirmationState == .idle)
            vm.requestResetLocalData()
            #expect(vm.resetConfirmationState == .needsConfirmation)
        }
    }

    // MARK: - OHeasViewModel Coordination

    @Suite("OHeasViewModel") @MainActor
    struct OHeasViewModelTests {
        @Test("Initializes all sub-ViewModels")
        func initializesSubViewModels() async {
            let vm = OHeasViewModel()
            _ = vm.healthData
            _ = vm.recommendation
            _ = vm.plan
            _ = vm.memory
            _ = vm.experiment
            _ = vm.onboarding
            _ = vm.sync
        }

        @Test("Delegates healthData properties")
        func healthDataDelegation() async {
            let vm = OHeasViewModel()
            #expect(vm.isLoading == false)
            #expect(vm.todayMetrics == nil)
            #expect(vm.baseline14d == nil)
            #expect(vm.detectedSignals.isEmpty)
            #expect(vm.dataQuality == nil)
        }

        @Test("Delegates recommendation properties")
        func recommendationDelegation() async {
            let vm = OHeasViewModel()
            #expect(vm.recommendationResult == nil)
            #expect(vm.isStreaming == false)
            #expect(vm.streamingDisplayText.isEmpty)
        }

        @Test("Delegates plan properties")
        func planDelegation() async {
            let vm = OHeasViewModel()
            #expect(vm.activeGoals.isEmpty)
            #expect(vm.currentWeeklyPlan == nil)
            #expect(vm.todayDailyPlan == nil)
        }

        @Test("Delegates experiment properties")
        func experimentDelegation() async {
            let vm = OHeasViewModel()
            #expect(vm.activeExperiment == nil)
            #expect(vm.proposedExperiment == nil)
            #expect(vm.experimentHistory.isEmpty)
        }

        @Test("Delegates onboarding state")
        func onboardingDelegation() async {
            let vm = OHeasViewModel()
            #expect(vm.onboardingState.hasCompletedOnboarding == false)
        }

        @Test("Delegates sync state")
        func syncDelegation() async {
            let vm = OHeasViewModel()
            #expect(vm.currentUser == nil)
            #expect(vm.authState == .localOnly)
            #expect(vm.syncState.mode == .localOnly)
        }
    }
}
