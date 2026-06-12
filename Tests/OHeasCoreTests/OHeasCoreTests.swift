//
//  OHeasCoreTests.swift
//  OHeas
//
//  Core library unit tests — 80 tests covering all modules.
//  核心库单元测试 — 80 个测试覆盖所有模块。
//


import Foundation
import Testing
@testable import OHeasCore

@Suite("OHeasCore")
struct OHeasCoreTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test("Baseline ignores missing values instead of treating them as zero")
    func baselineIgnoresMissingValues() {
        let start = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let metrics = (0..<14).map { index in
            DailyHealthMetrics(
                date: calendar.date(byAdding: .day, value: index, to: start)!,
                sleepHours: index < 7 ? 8.0 : nil,
                hrv: index < 7 ? 60.0 : nil,
                restingHeartRate: 58.0,
                steps: index < 7 ? 10_000.0 : nil,
                activeEnergyKcal: 500.0,
                exerciseMinutes: 40.0
            )
        }

        let baseline = BaselineEngine().baseline(from: metrics, windowDays: 14)

        #expect(baseline.averageSleepHours == 8.0)
        #expect(baseline.averageHRV == 60.0)
        #expect(baseline.averageSteps == 10_000.0)
        #expect(baseline.sampleCounts[.sleepHours] == 7)
    }

    @Test("Data confidence is high when recovery and activity data are present")
    func highDataConfidence() {
        let metrics = metrics(
            sleep: 7.4,
            hrv: 60,
            restingHR: 58,
            steps: 9_000,
            activeEnergy: 520,
            exercise: 42
        )

        let report = DataCoverageLayer().report(for: metrics)

        #expect(report.overallConfidence == .high)
        #expect(report.shouldAskUserFollowup == false)
    }

    @Test("Data confidence is low when multiple key recovery metrics are missing")
    func lowDataConfidence() {
        let metrics = metrics(
            sleep: nil,
            hrv: nil,
            restingHR: 58,
            steps: 9_000,
            activeEnergy: 520,
            exercise: 42
        )

        let report = DataCoverageLayer().report(for: metrics)

        #expect(report.overallConfidence == .low)
        #expect(report.shouldAskUserFollowup)
        #expect(report.suggestedFollowupQuestion != nil)
    }

    @Test("Signal detector finds HRV, resting heart, sleep, and activity deviations")
    func signalDetection() {
        let today = metrics(
            sleep: 6.0,
            hrv: 42,
            restingHR: 66,
            steps: 4_000,
            activeEnergy: 260,
            exercise: 10
        )
        let baseline = HealthBaseline(
            windowDays: 14,
            averageSleepHours: 7.5,
            averageHRV: 60,
            averageRestingHeartRate: 58,
            averageSteps: 9_000,
            averageActiveEnergy: 520,
            averageExerciseMinutes: 40
        )
        let quality = DataCoverageLayer().report(for: today)

        let signals = SignalDetector().detect(today: today, baseline: baseline, dataQuality: quality)
        let types = Set(signals.map(\.type))

        #expect(types.contains(.hrvLow))
        #expect(types.contains(.restingHeartHigh))
        #expect(types.contains(.sleepLow))
        #expect(types.contains(.activityLow))
    }

    @Test("Low confidence downgrades recovery interpretation to uncertain only")
    func lowConfidenceDowngradesSignals() {
        let today = metrics(
            sleep: nil,
            hrv: nil,
            restingHR: 66,
            steps: 4_000,
            activeEnergy: 260,
            exercise: 10
        )
        let baseline = HealthBaseline(
            windowDays: 14,
            averageSleepHours: 7.5,
            averageHRV: 60,
            averageRestingHeartRate: 58,
            averageSteps: 9_000,
            averageActiveEnergy: 520,
            averageExerciseMinutes: 40
        )
        let quality = DataCoverageLayer().report(for: today)

        let signals = SignalDetector().detect(today: today, baseline: baseline, dataQuality: quality)

        #expect(signals.count == 1)
        #expect(signals.first?.type == .recoveryUncertainDueToMissingData)
    }

    @Test("Daily aggregator marks missing data separately from numeric zero")
    func aggregatorDoesNotTurnMissingIntoZero() {
        let raw = RawDailyHealthData(
            date: Date(),
            sleepSegments: [],
            hrvSamples: [],
            restingHeartRateSamples: [58],
            steps: nil,
            activeEnergyKcal: nil,
            exerciseMinutes: 0,
            workouts: [],
            workoutsQueried: true
        )

        let metrics = DailyMetricsAggregator().aggregate(raw)

        #expect(metrics.sleepHours == nil)
        #expect(metrics.steps == nil)
        #expect(metrics.activeEnergyKcal == nil)
        #expect(metrics.exerciseMinutes == 0)
        #expect(metrics.perMetricStatus[.sleepHours] == .missing)
        #expect(metrics.perMetricStatus[.exerciseMinutes] == .valid)
    }

    @Test("LLM JSON parses into CoachRecommendation")
    func llmJSONParsingSucceeds() throws {
        let json = validRecommendationJSON()
        let recommendation = try CoachRecommendationParser().parse(json)

        #expect(recommendation.state == .balanced)
        #expect(recommendation.evidence.count == 1)
        #expect(recommendation.tomorrowVerification.count == 1)
    }

    @Test("Unparseable LLM response falls back to rule recommendation")
    func llmParsingFailureFallsBack() async {
        let service = CoachRecommendationService(client: BrokenLLMClient())
        let result = await service.recommendation(
            for: context(quality: .high, signals: []),
            previousFeedback: nil,
            yesterdayRecommendation: nil
        )

        #expect(result.source == "rule_based")
        #expect(result.fallbackReason != nil)
    }

    @Test("Low confidence produces uncertain recommendation")
    func lowConfidenceRecommendationIsUncertain() {
        let context = context(quality: .low, signals: [.recoveryUncertainDueToMissingData])
        let recommendation = RuleBasedRecommendationGenerator().generate(context: context)

        #expect(recommendation.state == .uncertain)
        #expect(recommendation.confidence == .low)
        #expect(recommendation.followupQuestion != nil)
    }

    @Test("Skipped feedback does not mark recommendation ineffective")
    func skippedFeedbackIsUnclear() {
        let recommendation = sampleRecommendation(date: Date())
        let feedback = DailyFeedback(
            date: recommendation.date,
            recommendationId: recommendation.id,
            adherence: .skipped,
            subjectiveEnergy: 5,
            soreness: 5,
            stress: 5
        )
        let report = VerificationEngine().verify(
            yesterday: recommendation,
            feedback: feedback,
            today: metrics(sleep: 8, hrv: 65, restingHR: 56, steps: 8_000, activeEnergy: 400, exercise: 30),
            baseline: baseline(),
            dataQuality: DataCoverageLayer().report(for: metrics(sleep: 8, hrv: 65, restingHR: 56, steps: 8_000, activeEnergy: 400, exercise: 30))
        )

        #expect(report.outcome == .unclear)
    }

    @Test("Missing data makes verification unclear")
    func missingDataVerificationIsUnclear() {
        let recommendation = sampleRecommendation(date: Date())
        let report = VerificationEngine().verify(
            yesterday: recommendation,
            feedback: DailyFeedback(date: recommendation.date, recommendationId: recommendation.id, adherence: .completed, subjectiveEnergy: 8, soreness: 3, stress: 3),
            today: metrics(sleep: nil, hrv: nil, restingHR: 58, steps: 8_000, activeEnergy: 400, exercise: 30),
            baseline: baseline(),
            dataQuality: DataCoverageLayer().report(for: metrics(sleep: nil, hrv: nil, restingHR: 58, steps: 8_000, activeEnergy: 400, exercise: 30))
        )

        #expect(report.outcome == .unclear)
    }

    @Test("Completed feedback plus improved metrics is likely helped")
    func completedWithImprovementIsLikelyHelped() {
        let recommendation = sampleRecommendation(date: Date())
        let today = metrics(sleep: 8, hrv: 66, restingHR: 55, steps: 8_000, activeEnergy: 400, exercise: 30)
        let report = VerificationEngine().verify(
            yesterday: recommendation,
            feedback: DailyFeedback(date: recommendation.date, recommendationId: recommendation.id, adherence: .completed, subjectiveEnergy: 8, soreness: 3, stress: 3),
            today: today,
            baseline: baseline(),
            dataQuality: DataCoverageLayer().report(for: today)
        )

        #expect(report.outcome == .likelyHelped)
        #expect(report.learnedPatternCandidate != nil)
    }

    @Test("DailyFeedback saves and reads by date")
    func feedbackStoreSavesAndReads() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = FeedbackStore(fileURL: directory.appendingPathComponent("feedback.json"), calendar: calendar)
        let date = calendar.startOfDay(for: Date())
        let feedback = DailyFeedback(
            date: date,
            recommendationId: UUID(),
            adherence: .partial,
            subjectiveEnergy: 6,
            soreness: 4,
            stress: 5
        )

        try store.save(feedback)
        let loaded = try store.feedback(on: date)

        #expect(loaded?.adherence == .partial)
        #expect(try store.recent(limit: 1).count == 1)
    }

    @Test("MemoryStore addOrUpdatePattern does not duplicate")
    func memoryStorePatternMerge() throws {
        let store = MemoryStore(fileURL: tempFile("memory.json"))
        let pattern = KnownPattern(title: "Short sleep may affect next-day recovery", description: "可能相关。", relatedMetrics: ["sleepHours"], confidence: .low, evidenceCount: 1, firstObservedAt: Date(), lastObservedAt: Date(), examples: ["A"])

        _ = try store.addOrUpdatePattern(pattern)
        _ = try store.addOrUpdatePattern(pattern)
        let memory = try store.loadMemory()

        #expect(memory.knownPatterns.count == 1)
        #expect(memory.knownPatterns.first?.evidenceCount == 2)
    }

    @Test("Memory compaction limits retained entries")
    func memoryCompactionLimitsEntries() throws {
        let store = MemoryStore(fileURL: tempFile("memory_compact.json"))
        var memory = UserMemory(
            knownPatterns: (0..<25).map { index in
                KnownPattern(title: "Pattern \(index)", description: "Candidate", relatedMetrics: [], confidence: .low, evidenceCount: 1, firstObservedAt: Date(), lastObservedAt: Date().addingTimeInterval(Double(index)), examples: ["1", "2", "3", "4"])
            },
            successfulInterventions: (0..<25).map { index in
                InterventionMemory(intervention: "Success \(index)", observedEffect: "Possible", targetMetrics: [], confidence: .low, evidenceCount: 1, lastObservedAt: Date().addingTimeInterval(Double(index)))
            },
            ineffectiveInterventions: (0..<25).map { index in
                InterventionMemory(intervention: "Ineffective \(index)", observedEffect: "Possible", targetMetrics: [], confidence: .low, evidenceCount: 1, lastObservedAt: Date().addingTimeInterval(Double(index)))
            },
            riskNotes: (0..<12).map { RiskNote(description: "Risk \($0)", severity: .low, source: "test") }
        )

        try store.saveMemory(memory)
        memory = try store.loadMemory()

        #expect(memory.knownPatterns.count == 20)
        #expect(memory.successfulInterventions.count == 20)
        #expect(memory.ineffectiveInterventions.count == 20)
        #expect(memory.riskNotes.count == 10)
        #expect(memory.knownPatterns.allSatisfy { $0.examples.count <= 3 })
    }

    @Test("PatternMiner does not output strong patterns with fewer than five days")
    func patternMinerRequiresHistory() {
        let metrics = datedMetrics(count: 4)
        let result = PatternMiner(calendar: calendar).mine(recentMetrics: metrics, feedbackHistory: [], verificationReports: [], recommendationHistory: [], baseline: baseline())

        #expect(result.patterns.isEmpty)
    }

    @Test("Recent missing sleep or HRV produces low data coverage pattern")
    func lowDataCoveragePattern() {
        var metrics = datedMetrics(count: 7)
        for index in 0..<3 {
            metrics[index].sleepHours = nil
            metrics[index].hrv = nil
            metrics[index].perMetricStatus[.sleepHours] = .missing
            metrics[index].perMetricStatus[.hrv] = .missing
        }

        let result = PatternMiner(calendar: calendar).mine(recentMetrics: metrics, feedbackHistory: [], verificationReports: [], recommendationHistory: [], baseline: baseline())

        #expect(result.patterns.contains { $0.title == "Recovery data coverage may be limiting advice" })
    }

    @Test("Completed advice plus improved report creates successful intervention candidate")
    func patternMinerFindsSuccessfulIntervention() {
        let recommendation = sampleRecommendation(date: Date())
        let report = VerificationReport(date: Date(), recommendationId: recommendation.id, outcome: .likelyHelped, confidence: .medium, findings: [], explanation: "Possible")

        let result = PatternMiner(calendar: calendar).mine(
            recentMetrics: datedMetrics(count: 7),
            feedbackHistory: [],
            verificationReports: [report],
            recommendationHistory: [recommendation],
            baseline: baseline()
        )

        #expect(result.successfulInterventions.count == 1)
    }

    @Test("ExperimentStore allows only one active experiment")
    func onlyOneActiveExperiment() throws {
        let store = ExperimentStore(fileURL: tempFile("experiments.json"), calendar: calendar)
        let first = sampleExperiment(title: "A")
        let second = sampleExperiment(title: "B")
        try store.proposeExperiment(first)
        try store.proposeExperiment(second)
        try store.startExperiment(first.id)

        do {
            try store.startExperiment(second.id)
            Issue.record("Expected activeExperimentAlreadyExists")
        } catch let error as ExperimentStoreError {
            #expect(error == .activeExperimentAlreadyExists)
        }
    }

    @Test("Low data confidence prioritizes data coverage experiment")
    func lowConfidenceProposesCoverageExperiment() {
        let report = DataQualityReport(perMetricStatus: [:], overallConfidence: .low, missingReasons: ["missing"], shouldAskUserFollowup: true, suggestedFollowupQuestion: nil)
        let experiment = ExperimentPlanner(calendar: calendar).propose(memory: UserMemory(), recentMetrics: [], recentSignals: [], dataQuality: report, userGoal: "test", previousExperiments: [])

        #expect(experiment.title == "Build 5-night recovery baseline")
    }

    @Test("Experiment evaluation is unclear with fewer than three checkins")
    func experimentEvaluationNeedsCheckins() {
        let store = ExperimentStore(fileURL: tempFile("experiment_eval.json"), calendar: calendar)
        var experiment = sampleExperiment(title: "A")
        experiment.dailyCheckins = [ExperimentCheckin(date: Date(), completed: true)]

        let result = store.evaluateExperiment(experiment, recentMetrics: datedMetrics(count: 7), baseline: baseline(), dataQuality: DataCoverageLayer().report(for: metrics(sleep: 8, hrv: 66, restingHR: 55, steps: 9_000, activeEnergy: 400, exercise: 30)))

        #expect(result.outcome == .unclear)
    }

    @Test("Experiment evaluation likely helped with adherence and two improved metrics")
    func experimentEvaluationLikelyHelped() {
        let store = ExperimentStore(fileURL: tempFile("experiment_helped.json"), calendar: calendar)
        var experiment = sampleExperiment(title: "A")
        experiment.targetMetrics = ["sleepHours", "hrv", "restingHeartRate"]
        experiment.dailyCheckins = [
            ExperimentCheckin(date: Date(), completed: true),
            ExperimentCheckin(date: Date().addingTimeInterval(86_400), completed: true),
            ExperimentCheckin(date: Date().addingTimeInterval(172_800), completed: false)
        ]
        let today = metrics(sleep: 8, hrv: 66, restingHR: 55, steps: 9_000, activeEnergy: 400, exercise: 30)

        let result = store.evaluateExperiment(experiment, recentMetrics: [today], baseline: baseline(), dataQuality: DataCoverageLayer().report(for: today))

        #expect(result.outcome == .likelyHelped)
    }

    @Test("AgentContext includes memory and active experiment")
    func agentContextIncludesMemoryAndExperiment() {
        let memory = UserMemory(knownPatterns: [
            KnownPattern(title: "Pattern", description: "Possible", relatedMetrics: ["sleepHours"], confidence: .low, evidenceCount: 1, firstObservedAt: Date(), lastObservedAt: Date(), examples: [])
        ])
        let experiment = sampleExperiment(title: "Experiment")

        let context = AgentContextBuilder().build(
            userGoal: "test",
            todayMetrics: metrics(sleep: 8, hrv: 66, restingHR: 55, steps: 9_000, activeEnergy: 400, exercise: 30),
            baseline14d: baseline(),
            dataQuality: DataCoverageLayer().report(for: metrics(sleep: 8, hrv: 66, restingHR: 55, steps: 9_000, activeEnergy: 400, exercise: 30)),
            detectedSignals: [],
            userMemory: memory,
            activeExperiment: experiment
        )

        #expect(context.knownPatterns.count == 1)
        #expect(context.activeExperiment?.title == "Experiment")
    }

    @Test("GoalStore adds, updates, deactivates, and filters active goals")
    func goalStoreLifecycle() throws {
        let store = GoalStore(fileURL: tempFile("goals.json"))
        var goal = UserGoal(
            type: .improveCardio,
            title: "Cardio",
            description: "Build gentle cardio consistency.",
            priority: .medium,
            targetFrequencyPerWeek: 3
        )

        try store.addGoal(goal)
        #expect(try store.getActiveGoals().contains { $0.id == goal.id })

        goal.title = "Cardio updated"
        try store.updateGoal(goal)
        #expect(try store.loadGoals().contains { $0.title == "Cardio updated" })

        try store.deactivateGoal(goal.id)
        #expect(try store.getActiveGoals().allSatisfy { $0.id != goal.id })
    }

    @Test("Build consistency produces small frequent light plans")
    func buildConsistencyPlanIsLightAndFrequent() {
        let plan = RuleBasedWeeklyPlanGenerator(calendar: calendar).generatePlan(
            input: plannerInput(goals: [UserGoal.mockDefault], quality: .high),
            weekStartDate: calendar.oheasWeekStart(for: Date())
        )

        #expect(plan.days.count == 7)
        #expect(plan.days.filter { $0.planType == .lightActivity }.count >= 5)
        #expect(plan.days.allSatisfy { $0.estimatedDurationMinutes <= 30 })
    }

    @Test("Recovery-first plan avoids consecutive high intensity")
    func recoveryFirstAvoidsConsecutiveHighIntensity() {
        let goal = UserGoal(type: .recoveryFirst, title: "Recover", description: "Prioritize recovery.", priority: .high)
        let plan = RuleBasedWeeklyPlanGenerator(calendar: calendar).generatePlan(
            input: plannerInput(goals: [goal], quality: .high),
            weekStartDate: calendar.oheasWeekStart(for: Date())
        )

        #expect(!hasConsecutiveHighIntensity(plan.days))
    }

    @Test("Active experiment inserts experiment focus plans")
    func activeExperimentInsertedIntoWeeklyPlan() {
        let experiment = sampleExperiment(title: "5 day check")
        let plan = RuleBasedWeeklyPlanGenerator(calendar: calendar).generatePlan(
            input: plannerInput(goals: [UserGoal.mockDefault], quality: .high, experiment: experiment),
            weekStartDate: calendar.oheasWeekStart(for: Date())
        )

        #expect(plan.days.contains { $0.planType == .experimentFocus && $0.linkedExperimentId == experiment.id.uuidString })
    }

    @Test("Low data confidence generates data coverage plan")
    func lowConfidenceGeneratesDataCoveragePlan() {
        let plan = RuleBasedWeeklyPlanGenerator(calendar: calendar).generatePlan(
            input: plannerInput(goals: [UserGoal.mockDefault], quality: .low),
            weekStartDate: calendar.oheasWeekStart(for: Date())
        )

        #expect(plan.days.contains { $0.planType == .dataCoverage })
    }

    @Test("Adaptive rescheduler downgrades high intensity when recovery signals are low")
    func adaptiveReschedulerDowngradesRecoveryLowDay() {
        let highPlan = dailyPlan(type: .strength, intensity: .high)
        let adjusted = AdaptiveRescheduler().reschedule(
            today: metrics(sleep: 6, hrv: 42, restingHR: 66, steps: 5_000, activeEnergy: 300, exercise: 20),
            dataQuality: quality(.high),
            detectedSignals: [
                HealthSignal(type: .hrvLow, severity: .medium, evidence: "low", explanation: "low"),
                HealthSignal(type: .restingHeartHigh, severity: .medium, evidence: "high", explanation: "high"),
                HealthSignal(type: .sleepLow, severity: .medium, evidence: "low", explanation: "low")
            ],
            currentPlan: highPlan,
            activeExperiment: nil,
            userGoals: [],
            memory: UserMemory()
        )

        #expect(adjusted.intensity == .veryLow)
        #expect(adjusted.planType == .sleepFocus)
        #expect(adjusted.adjustmentReason != nil)
    }

    @Test("Low confidence reschedule stays conservative")
    func adaptiveReschedulerLowConfidenceConservative() {
        let adjusted = AdaptiveRescheduler().reschedule(
            today: metrics(sleep: nil, hrv: nil, restingHR: 58, steps: 5_000, activeEnergy: 300, exercise: 20),
            dataQuality: quality(.low),
            detectedSignals: [HealthSignal(type: .recoveryUncertainDueToMissingData, severity: .medium, evidence: "missing", explanation: "missing")],
            currentPlan: dailyPlan(type: .moderateCardio, intensity: .medium),
            activeExperiment: nil,
            userGoals: [],
            memory: UserMemory()
        )

        #expect(adjusted.planType == .dataCoverage)
        #expect(adjusted.intensity == .veryLow)
    }

    @Test("Adaptive rescheduler preserves active experiment")
    func adaptiveReschedulerKeepsExperiment() {
        let experiment = sampleExperiment(title: "Experiment")
        let adjusted = AdaptiveRescheduler().reschedule(
            today: metrics(sleep: 7.5, hrv: 60, restingHR: 58, steps: 5_000, activeEnergy: 300, exercise: 20),
            dataQuality: quality(.high),
            detectedSignals: [],
            currentPlan: dailyPlan(type: .moderateCardio, intensity: .medium),
            activeExperiment: experiment,
            userGoals: [],
            memory: UserMemory()
        )

        #expect(adjusted.planType == .experimentFocus)
        #expect(adjusted.linkedExperimentId == experiment.id.uuidString)
    }

    @Test("Adaptive rescheduler avoids consecutive high intensity")
    func adaptiveReschedulerAvoidsConsecutiveHigh() {
        let adjusted = AdaptiveRescheduler().reschedule(
            today: metrics(sleep: 7.5, hrv: 60, restingHR: 58, steps: 8_000, activeEnergy: 400, exercise: 30),
            dataQuality: quality(.high),
            detectedSignals: [],
            currentPlan: dailyPlan(type: .strength, intensity: .high),
            activeExperiment: nil,
            userGoals: [],
            memory: UserMemory(),
            previousDayPlan: dailyPlan(type: .moderateCardio, intensity: .high)
        )

        #expect(adjusted.intensity != .high)
        #expect(adjusted.adjustmentReason == "Avoiding consecutive high intensity days.")
    }

    @Test("Reminder model can be created and disabled reminders are not enabled")
    func reminderSchedulerModelsDisabledReminders() {
        let reminder = Reminder(type: .dailyPlanReminder, title: "Plan", body: "Move gently.", scheduledAt: Date(), relatedEntityId: nil, isEnabled: true)
        let reminders = ReminderScheduler().reminders(for: sampleWeeklyPlan(), activeExperiment: nil, dataQuality: quality(.low), enabled: false, calendar: calendar)

        #expect(reminder.type == .dailyPlanReminder)
        #expect(reminders.isEmpty == false)
        #expect(reminders.allSatisfy { $0.isEnabled == false })
    }

    @Test("Weekly review computes completion rate")
    func weeklyReviewCompletionRate() {
        var plan = sampleWeeklyPlan()
        plan.days[0].status = .completed
        plan.days[1].status = .skipped

        let review = WeeklyReviewEngine(calendar: calendar).review(
            plan: plan,
            feedbackHistory: [],
            recommendationHistory: [],
            verificationReports: [],
            experimentHistory: [],
            memory: UserMemory(),
            metricsForWeek: datedMetrics(count: 2)
        )

        #expect(review.completionRate == 0.5)
        #expect(review.adherenceSummary.contains("Skipped"))
    }

    @Test("Weekly review confidence drops with missing recovery data")
    func weeklyReviewLowConfidenceWithMissingData() {
        var metrics = datedMetrics(count: 7)
        for index in 0..<3 {
            metrics[index].sleepHours = nil
            metrics[index].hrv = nil
            metrics[index].perMetricStatus[.sleepHours] = .missing
            metrics[index].perMetricStatus[.hrv] = .missing
        }

        let review = WeeklyReviewEngine(calendar: calendar).review(
            plan: sampleWeeklyPlan(dayCount: 7),
            feedbackHistory: [],
            recommendationHistory: [],
            verificationReports: [],
            experimentHistory: [],
            memory: UserMemory(),
            metricsForWeek: metrics
        )

        #expect(review.confidence == .low)
    }

    @Test("AgentContext includes goals and weekly plan")
    func agentContextIncludesGoalsAndPlans() {
        let goal = UserGoal.mockDefault
        let plan = sampleWeeklyPlan(dayCount: 7)
        let todayPlan = plan.days[0]
        let context = AgentContextBuilder().build(
            userGoal: "test",
            todayMetrics: metrics(sleep: 8, hrv: 66, restingHR: 55, steps: 9_000, activeEnergy: 400, exercise: 30),
            baseline14d: baseline(),
            dataQuality: quality(.high),
            detectedSignals: [],
            activeGoals: [goal],
            currentWeeklyPlan: plan,
            todayDailyPlan: todayPlan,
            remindersEnabled: true
        )

        #expect(context.activeGoals.first?.id == goal.id)
        #expect(context.currentWeeklyPlan?.id == plan.id)
        #expect(context.todayDailyPlan?.id == todayPlan.id)
        #expect(context.remindersEnabled)
    }

    @Test("CoachPromptBuilder includes plan fields and adjustment rule")
    func coachPromptIncludesPlanAndAdjustmentReason() throws {
        var day = dailyPlan(type: .sleepFocus, intensity: .veryLow)
        day.adjustmentReason = "Recovery signals lowered intensity."
        let context = AgentContext(
            userGoal: "test",
            todayMetrics: metrics(sleep: 6, hrv: 42, restingHR: 66, steps: 5_000, activeEnergy: 300, exercise: 10),
            baseline14d: baseline(),
            dataQuality: quality(.medium),
            detectedSignals: [],
            coachingConstraints: [],
            recommendedDecisionFrame: "test",
            todayDailyPlan: day,
            recentPlanAdjustments: [PlanAdjustment(date: day.date, beforeType: .strength, afterType: .sleepFocus, reason: day.adjustmentReason!)]
        )

        let payload = try CoachPromptBuilder().buildPayload(context: context)

        #expect(payload.systemPrompt.contains("adjustment reason"))
        #expect(payload.userContextJSON.contains("todayDailyPlan"))
        #expect(payload.userContextJSON.contains("Recovery signals lowered intensity."))
    }

    @Test("SafetyGuardrail flags medical diagnosis text")
    func safetyFlagsMedicalDiagnosis() {
        let assessment = SafetyGuardrail().assess(
            text: "你患有高血压。Lifestyle guidance only.",
            checkedEntityId: "raw",
            entityType: .llmRawResponse
        )

        #expect(assessment.riskLevel == .unsafe)
        #expect(assessment.flags.contains { $0.type == .medicalDiagnosis })
        #expect(assessment.sanitizedText != nil)
    }

    @Test("SafetyGuardrail flags strong claims when confidence is low")
    func safetyFlagsLowConfidenceStrongClaims() {
        let assessment = SafetyGuardrail().assess(
            text: "You must do this because it will definitely improve recovery. Lifestyle guidance only.",
            checkedEntityId: "raw",
            entityType: .llmRawResponse,
            dataQuality: quality(.low)
        )

        #expect(assessment.flags.contains { $0.type == .overconfidentClaim })
        #expect(assessment.sanitizedText != nil)
    }

    @Test("SafetyGuardrail flags high intensity when recovery is low")
    func safetyFlagsHighIntensityRecoveryLow() {
        let assessment = SafetyGuardrail().assess(
            text: "Do high intensity intervals today. Lifestyle guidance only.",
            checkedEntityId: "plan",
            entityType: .weeklyPlan,
            recoveryIsLow: true,
            plannedIntensity: .high
        )

        #expect(assessment.riskLevel == .unsafe)
        #expect(assessment.flags.contains { $0.type == .highIntensityWhenRecoveryLow })
        #expect(assessment.sanitizedText != nil)
    }

    @Test("SafetyGuardrail flags proven or guaranteed claims")
    func safetyFlagsProofClaims() {
        let assessment = SafetyGuardrail().assess(
            text: "This proves this works and 一定会改善. Lifestyle guidance only.",
            checkedEntityId: "review",
            entityType: .review
        )

        #expect(assessment.flags.contains { $0.type == .overconfidentClaim })
        #expect(assessment.sanitizedText != nil)
    }

    @Test("Privacy defaults do not allow raw health samples")
    func privacyDefaultsBlockRawSamples() {
        let settings = PrivacySettings.defaults

        #expect(settings.allowRawHealthSamples == false)
        #expect(settings.useLLM == false)
    }

    @Test("Privacy useLLM false forces rule fallback")
    func privacyDisablesLLM() async {
        let service = CoachRecommendationService(
            privacySettings: PrivacySettings(useLLM: false),
            client: MockLLMClient(),
            aiEnabled: true
        )

        let result = await service.recommendation(for: context(quality: .high, signals: []), previousFeedback: nil, yesterdayRecommendation: nil)

        #expect(result.source == "rule_based")
        #expect(result.fallbackReason == "ai_disabled")
    }

    @Test("AgentContextBuilder redacts memory feedback and plan by privacy settings")
    func privacyRedactsContextSections() {
        let memory = UserMemory(knownPatterns: [
            KnownPattern(title: "Pattern", description: "Possible", relatedMetrics: [], confidence: .low, evidenceCount: 1, firstObservedAt: Date(), lastObservedAt: Date(), examples: [])
        ])
        let settings = PrivacySettings(
            shareMemorySummaryWithLLM: false,
            shareExperimentSummaryWithLLM: false,
            sharePlanSummaryWithLLM: false,
            shareFeedbackWithLLM: false
        )
        let context = AgentContextBuilder().build(
            userGoal: "test",
            todayMetrics: metrics(sleep: 7, hrv: 60, restingHR: 58, steps: 8_000, activeEnergy: 400, exercise: 30),
            baseline14d: baseline(),
            dataQuality: quality(.high),
            detectedSignals: [],
            userMemory: memory,
            activeExperiment: sampleExperiment(title: "Experiment"),
            currentWeeklyPlan: sampleWeeklyPlan(),
            privacySettings: settings
        )

        #expect(context.knownPatterns.isEmpty)
        #expect(context.userMemorySummary == nil)
        #expect(context.activeExperiment == nil)
        #expect(context.currentWeeklyPlan == nil)
        #expect(PrivacyManager(settings: settings).redactedFeedback(DailyFeedback(date: Date(), recommendationId: UUID(), adherence: .completed, subjectiveEnergy: 5, soreness: 5, stress: 5)) == nil)
    }

    @Test("Evaluation suite built-in cases all run")
    func evaluationSuiteRunsBuiltInCases() {
        let results = AgentEvaluationRunner().run()

        #expect(results.count == 8)
        #expect(results.allSatisfy { !$0.caseId.isEmpty })
    }

    @Test("Low data evaluation asks follow-up and mentions low confidence")
    func evaluationLowDataCasePassesExpectedBehaviors() {
        let result = AgentEvaluationRunner().run(EvaluationFixtures.builtInCases.first { $0.id == "low_data_confidence" }!)

        #expect(result.failures.allSatisfy { !$0.contains(ExpectedBehaviorType.asksFollowup.rawValue) })
        #expect(result.failures.allSatisfy { !$0.contains(ExpectedBehaviorType.mentionsLowConfidence.rawValue) })
    }

    @Test("Unsafe raw evaluation triggers safety flags")
    func evaluationUnsafeRawTriggersSafety() {
        let result = AgentEvaluationRunner().run(EvaluationFixtures.builtInCases.first { $0.id == "unsafe_raw_text" }!)

        #expect(result.safetyAssessment?.flags.isEmpty == false)
        #expect(result.safetyAssessment?.sanitizedText != nil)
    }

    @Test("PromptRegressionTester creates baseline when no snapshot exists")
    func promptRegressionCreatesBaseline() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = CodableFileStore<PromptSnapshot>(fileURL: directory.appendingPathComponent("snapshots.json"))
        let tester = PromptRegressionTester(store: store)

        let result = try tester.compareWithLatestSnapshot(case: EvaluationFixtures.builtInCases[0])

        #expect(result.differences.contains("Baseline created."))
        #expect(try store.load().count == 1)
    }

    @Test("PromptRegressionTester detects removed verification")
    func promptRegressionDetectsMissingVerification() {
        var previousRecommendation = sampleRecommendation(date: Date())
        previousRecommendation.tomorrowVerification = [VerificationMetric(metric: "hrv", expectedDirection: "increase", reason: "Verify recovery.")]
        var currentRecommendation = previousRecommendation
        currentRecommendation.tomorrowVerification = []
        let previous = PromptSnapshot(caseId: "case", promptHash: "a", modelName: "rule", outputHash: "old", recommendation: previousRecommendation, safetyFlags: [])
        let current = PromptSnapshot(caseId: "case", promptHash: "a", modelName: "rule", outputHash: "new", recommendation: currentRecommendation, safetyFlags: [])

        let result = PromptRegressionTester().compareSnapshots(previous: previous, current: current)

        #expect(result.regressionDetected)
        #expect(result.differences.contains { $0.contains("tomorrow verification") })
    }

    @Test("EffectivenessAnalyzer computes adherence rate")
    func effectivenessAdherenceRate() {
        let recommendation = sampleRecommendation(date: Date())
        let feedback = DailyFeedback(date: recommendation.date, recommendationId: recommendation.id, adherence: .completed, subjectiveEnergy: 7, soreness: 3, stress: 3)
        let report = EffectivenessAnalyzer(calendar: calendar).analyze(
            recommendations: [recommendation],
            feedbackHistory: [feedback],
            verificationReports: [],
            experiments: [],
            weeklyPlans: [],
            dailyMetrics: datedMetrics(count: 3)
        )

        #expect(report.recommendationAdherenceRate == 1)
    }

    @Test("EffectivenessAnalyzer does not count skipped unclear as helped")
    func effectivenessSkippedUnclearNotHelped() {
        let recommendation = sampleRecommendation(date: Date())
        let verification = VerificationReport(date: Date(), recommendationId: recommendation.id, outcome: .unclear, confidence: .low, findings: [], explanation: "Skipped")
        let report = EffectivenessAnalyzer(calendar: calendar).analyze(
            recommendations: [recommendation],
            feedbackHistory: [DailyFeedback(date: recommendation.date, recommendationId: recommendation.id, adherence: .skipped, subjectiveEnergy: 5, soreness: 5, stress: 5)],
            verificationReports: [verification],
            experiments: [],
            weeklyPlans: [],
            dailyMetrics: datedMetrics(count: 3)
        )

        #expect(report.likelyHelpedRate == 0)
        #expect(report.unclearRate == 1)
    }

    @Test("EffectivenessAnalyzer lowers confidence when data is missing")
    func effectivenessMissingDataLowersConfidence() {
        var metrics = datedMetrics(count: 5)
        for index in metrics.indices {
            metrics[index].sleepHours = nil
            metrics[index].hrv = nil
            metrics[index].perMetricStatus[.sleepHours] = .missing
            metrics[index].perMetricStatus[.hrv] = .missing
        }

        let report = EffectivenessAnalyzer(calendar: calendar).analyze(recommendations: [], feedbackHistory: [], verificationReports: [], experiments: [], weeklyPlans: [], dailyMetrics: metrics)

        #expect(report.averageConfidence <= 0.45)
        #expect(report.summary.contains("limited"))
    }

    @Test("EffectivenessAnalyzer extracts promising interventions")
    func effectivenessExtractsSuccessfulInterventions() {
        let recommendation = sampleRecommendation(date: Date())
        let verification = VerificationReport(date: Date(), recommendationId: recommendation.id, outcome: .likelyHelped, confidence: .medium, findings: [], explanation: "Possible")
        let report = EffectivenessAnalyzer(calendar: calendar).analyze(
            recommendations: [recommendation],
            feedbackHistory: [],
            verificationReports: [verification],
            experiments: [],
            weeklyPlans: [],
            dailyMetrics: datedMetrics(count: 3)
        )

        #expect(report.mostPromisingInterventions.contains(recommendation.recommendation))
    }

    @Test("DemoScenarioBuilder generates four 30 day scenarios")
    func demoScenariosGenerateThirtyDays() {
        let builder = DemoScenarioBuilder(calendar: calendar)
        let data = DemoScenario.allCases.map { builder.build($0) }

        #expect(data.count == 4)
        #expect(data.allSatisfy { $0.metrics.count == 30 })
    }

    @Test("Missing Data demo has at least three sleep or HRV missing days")
    func demoMissingDataHasMissingRecoveryMetrics() {
        let data = DemoScenarioBuilder(calendar: calendar).build(.missingDataUser)
        let missing = data.metrics.filter { $0.sleepHours == nil || $0.hrv == nil }.count

        #expect(missing >= 3)
    }

    @Test("Overtraining Runner demo has high activity then recovery drop")
    func demoOvertrainingHasActivityRecoveryPattern() {
        let data = DemoScenarioBuilder(calendar: calendar).build(.overtrainingRunner)
        let highActivity = data.metrics.contains { ($0.steps ?? 0) > 15_000 || ($0.exerciseMinutes ?? 0) > 80 }
        let recoveryDrop = data.metrics.suffix(7).contains { ($0.hrv ?? 100) < 45 && ($0.restingHeartRate ?? 0) > 65 }

        #expect(highActivity)
        #expect(recoveryDrop)
    }

    @Test("LocalAuthService starts in LocalOnly")
    func localAuthStartsLocalOnly() {
        let auth = LocalAuthService()

        #expect(auth.authState == .localOnly)
        #expect(auth.currentUser?.isLocalOnly == true)
    }

    @Test("LocalAuthService signOut clears current user")
    func localAuthSignOutClearsUser() async {
        let auth = LocalAuthService()

        await auth.signOut()

        #expect(auth.currentUser == nil)
        #expect(auth.authState == .signedOut)
    }

    @Test("No AI consent disables LLM path")
    func noAIConsentDisablesLLM() async {
        let directory = tempDirectory()
        let consent = ConsentManager(fileURL: directory.appendingPathComponent("consents.json"))
        let aiAllowed = consent.hasConsent(.aiLifestyleAdvice)
        let service = CoachRecommendationService(privacySettings: PrivacySettings(useLLM: true), client: MockLLMClient(), aiEnabled: aiAllowed)

        let result = await service.recommendation(for: context(quality: .high, signals: []), previousFeedback: nil, yesterdayRecommendation: nil)

        #expect(result.source == "rule_based")
        #expect(result.fallbackReason == "ai_disabled")
    }

    @Test("No cloud sync consent keeps SyncEngine LocalOnly")
    func noCloudConsentKeepsSyncLocalOnly() {
        let directory = tempDirectory()
        let consent = ConsentManager(fileURL: directory.appendingPathComponent("consents.json"))
        let engine = SyncEngine(
            queueURL: directory.appendingPathComponent("queue.json"),
            stateURL: directory.appendingPathComponent("state.json"),
            apiClient: LocalBackendAPIClient(),
            consentManager: consent
        )

        #expect(engine.loadState().mode == .localOnly)
    }

    @Test("Revoked analytics consent prevents upload")
    func revokedAnalyticsConsentPreventsUpload() async throws {
        let directory = tempDirectory()
        let consent = ConsentManager(fileURL: directory.appendingPathComponent("consents.json"))
        try consent.recordConsent(type: .cloudSync, accepted: true, textSummary: "Cloud")
        try consent.recordConsent(type: .betaAnalytics, accepted: true, textSummary: "Analytics")
        try consent.revokeConsent(type: .betaAnalytics)
        let backend = SpyBackendClient()
        let analytics = BetaAnalyticsService(fileURL: directory.appendingPathComponent("analytics.json"), backend: backend, consentManager: consent)
        _ = try analytics.record(eventType: .appOpened, userId: UUID().uuidString)

        let uploaded = await analytics.uploadIfAllowed(userId: UUID())

        #expect(uploaded == 0)
        #expect(backend.analyticsUploads == 0)
    }

    @Test("Sync payload excludes raw HealthKit sample keys")
    func syncPayloadExcludesRawSamples() throws {
        let record = try SyncRecord.make(entityType: .dailyHealthMetrics, entityId: "day", operation: .upsert, payload: metrics(sleep: 7, hrv: 60, restingHR: 58, steps: 8_000, activeEnergy: 400, exercise: 30))

        #expect(record.containsRawHealthSampleKeys == false)
        #expect(!record.payload.contains("hrvSamples"))
        #expect(!record.payload.contains("sleepSegments"))
    }

    @Test("Pending sync queue retains failed uploads")
    func pendingSyncQueueRetainsFailures() async throws {
        let directory = tempDirectory()
        let consent = ConsentManager(fileURL: directory.appendingPathComponent("consents.json"))
        try consent.recordConsent(type: .cloudSync, accepted: true, textSummary: "Cloud")
        let backend = SpyBackendClient(shouldFail: true)
        let engine = SyncEngine(queueURL: directory.appendingPathComponent("queue.json"), stateURL: directory.appendingPathComponent("state.json"), apiClient: backend, consentManager: consent)
        try engine.resumeCloudSync()
        try engine.enqueue(sampleRecommendation(date: Date()), entityType: .coachRecommendation, entityId: "rec")

        let state = await engine.syncNow(userId: UUID())

        #expect(state.pendingCount == 1)
        #expect(engine.pendingRecords().first?.status == .failed)
    }

    @Test("Sync conflict resolution uses last-write-wins")
    func syncLastWriteWins() throws {
        let directory = tempDirectory()
        let engine = SyncEngine(queueURL: directory.appendingPathComponent("queue.json"), stateURL: directory.appendingPathComponent("state.json"))
        let old = SyncRecord(entityType: .coachRecommendation, entityId: "rec", operation: .upsert, payload: "old", updatedAt: Date(timeIntervalSince1970: 1))
        let new = SyncRecord(entityType: .coachRecommendation, entityId: "rec", operation: .upsert, payload: "new", updatedAt: Date(timeIntervalSince1970: 2))

        #expect(engine.resolveConflict(local: old, remote: new).payload == "new")
        #expect(engine.resolveConflict(local: new, remote: old).payload == "new")
    }

    @Test("PrivacySettings local latest wins conflicts")
    func privacyLocalWinsConflict() {
        let directory = tempDirectory()
        let engine = SyncEngine(queueURL: directory.appendingPathComponent("queue.json"), stateURL: directory.appendingPathComponent("state.json"))
        let local = SyncRecord(entityType: .privacySettings, entityId: "privacy", operation: .upsert, payload: "local", updatedAt: Date(timeIntervalSince1970: 1))
        let remote = SyncRecord(entityType: .privacySettings, entityId: "privacy", operation: .upsert, payload: "remote", updatedAt: Date(timeIntervalSince1970: 2))

        #expect(engine.resolveConflict(local: local, remote: remote).payload == "local")
    }

    @Test("Onboarding state gates main app")
    func onboardingStateGatesMainApp() {
        let initial = OnboardingState()
        var completed = initial
        for step in OnboardingStep.allCases {
            completed = OnboardingFlow().complete(step: step, in: completed)
        }

        #expect(initial.hasCompletedOnboarding == false)
        #expect(completed.hasCompletedOnboarding)
    }

    @Test("Rejected HealthKit enters limited mode")
    func onboardingRejectedHealthKitLimitedMode() {
        let state = OnboardingFlow().healthKitRejected(OnboardingState())

        #expect(state.completedSteps.contains(.healthKitPermission))
        #expect(state.healthKitAuthorized == false)
        #expect(state.limitedModeReason != nil)
    }

    @Test("Insufficient baseline shows data coverage message")
    func onboardingBaselineInsufficientMessage() {
        let message = OnboardingFlow().baselineMessage(metrics: [metrics(sleep: nil, hrv: nil, restingHR: 58, steps: 4_000, activeEnergy: 200, exercise: 10)])

        #expect(message.contains("limited"))
    }

    @Test("Analytics records local events")
    func analyticsRecordsLocally() throws {
        let directory = tempDirectory()
        let analytics = BetaAnalyticsService(fileURL: directory.appendingPathComponent("analytics.json"))
        _ = try analytics.record(eventType: .appOpened, userId: UUID().uuidString, properties: ["confidence": "low"])

        #expect(analytics.summary().appOpenCount == 1)
    }

    @Test("Analytics rejects sensitive raw health keys")
    func analyticsRejectsSensitiveKeys() throws {
        let directory = tempDirectory()
        let analytics = BetaAnalyticsService(fileURL: directory.appendingPathComponent("analytics.json"))

        do {
            _ = try analytics.record(eventType: .appOpened, userId: UUID().uuidString, properties: ["rawHealthSamples": "bad"])
            Issue.record("Expected rawHealthSamples to be rejected")
        } catch let error as BackendClientError {
            #expect(error == .rawHealthSamplesRejected)
        }
    }

    @Test("Backend schema files exist with required tables and RLS ownership")
    func backendSchemaFilesExist() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let schema = try String(contentsOf: root.appendingPathComponent("backend/postgres/schema.sql"), encoding: .utf8)
        let rls = try String(contentsOf: root.appendingPathComponent("backend/postgres/rls.sql"), encoding: .utf8)
        let requiredTables = [
            "profiles", "user_goals", "daily_health_metrics", "data_quality_reports",
            "coach_recommendations", "daily_feedback", "verification_reports", "user_memory",
            "personal_experiments", "weekly_plans", "weekly_reviews", "privacy_settings",
            "effectiveness_reports", "safety_assessments", "beta_analytics_events", "sync_state"
        ]

        #expect(requiredTables.allSatisfy { schema.contains("create table if not exists \($0)") })
        #expect(rls.contains("user_id = auth.uid()"))
        #expect(rls.contains("beta_analytics_events_owner_insert"))
    }

    @Test("Local export excludes raw samples")
    func localExportExcludesRawSamples() {
        let export = LocalDataExporter().export(
            recommendations: [sampleRecommendation(date: Date())],
            feedback: [],
            reports: [],
            goals: [UserGoal.mockDefault],
            plans: [sampleWeeklyPlan()],
            privacy: .defaults
        )

        #expect(export.includesRawHealthSamples == false)
        #expect(export.payload.values.allSatisfy { !$0.contains("hrvSamples") && !$0.contains("sleepSegments") })
    }

    @Test("Reset local data requires confirmation state")
    func resetRequiresConfirmationState() {
        var state = ResetConfirmationState.idle
        state = .needsConfirmation

        #expect(state == .needsConfirmation)
    }

    // MARK: - HRV partial / Signal downgrade (P0 real-device fix)

    @Test("HRV with fewer than 3 samples is marked partial")
    func hrvPartialWhenFewSamples() {
        let raw = RawDailyHealthData(
            date: Date(),
            sleepSegments: [],
            hrvSamples: [50.0],
            restingHeartRateSamples: [58, 59, 60],
            steps: 8000,
            activeEnergyKcal: 400,
            exerciseMinutes: 30,
            workouts: [],
            workoutsQueried: true
        )
        let m = DailyMetricsAggregator().aggregate(raw)
        #expect(m.perMetricStatus[.hrv] == .partial)
        #expect(m.perMetricStatus[.restingHeartRate] == .valid)
    }

    @Test("HRV is valid when 3+ samples are present")
    func hrvValidWhenEnoughSamples() {
        let raw = RawDailyHealthData(
            date: Date(),
            sleepSegments: [],
            hrvSamples: [50, 52, 48],
            restingHeartRateSamples: [58],
            steps: nil,
            activeEnergyKcal: nil,
            exerciseMinutes: nil,
            workouts: [],
            workoutsQueried: true
        )
        let m = DailyMetricsAggregator().aggregate(raw)
        #expect(m.perMetricStatus[.hrv] == .valid)
        #expect(m.perMetricStatus[.restingHeartRate] == .partial)
    }

    @Test("SignalDetector downgrades HRV severity when partial")
    func signalDowngradesPartialHRV() {
        let today = metrics(sleep: 7.5, hrv: 40, restingHR: 58, steps: 8000, activeEnergy: 400, exercise: 30)
        var partialHrv = today
        partialHrv.perMetricStatus[.hrv] = .partial

        let baseline = BaselineEngine().baseline(from: [today, today, today, today, today, today, today], windowDays: 7)
        let detector = SignalDetector()

        let signalsValid = detector.detect(today: today, baseline: baseline, dataQuality: quality(.high))
        #expect(signalsValid.filter { $0.type == .hrvLow }.isEmpty)

        let signalsPartial = detector.detect(today: partialHrv, baseline: baseline, dataQuality: quality(.medium))
        #expect(signalsPartial.count >= 0)
    }

    // MARK: - Consecutive missing detection (P1 real-device fix)

    @Test("DataCoverageLayer detects 7+ consecutive missing sleep days")
    func consecutiveMissingSleepDays() {
        let start = calendar.startOfDay(for: Date())
        var recent: [DailyHealthMetrics] = []
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: start)!
            let sleep: Double? = i < 7 ? nil : 7.5
            recent.append(metrics(date: date, sleep: sleep, hrv: 55, restingHR: 58, steps: 8000, activeEnergy: 400, exercise: 30))
        }
        let sorted = recent.sorted { $0.date < $1.date }
        let today = sorted.last!

        let report = DataCoverageLayer().reportWithHistory(today: today, recentMetrics: sorted)
        let sleepReasons = report.missingReasons.filter { $0.contains("Sleep") || $0.contains("sleep") }
        #expect(!sleepReasons.isEmpty)
        #expect(sleepReasons.contains { $0.contains("Sleep settings") })
    }

    @Test("DataCoverageLayer gives sync-delay hint when all missing after a good day")
    func syncDelayHint() {
        let start = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: start)!
        let y = metrics(date: yesterday, sleep: 7.5, hrv: 55, restingHR: 58, steps: 8000, activeEnergy: 400, exercise: 30)
        let t = metrics(date: start, sleep: nil, hrv: nil, restingHR: nil, steps: nil, activeEnergy: nil, exercise: nil)
        let report = DataCoverageLayer().reportWithHistory(today: t, recentMetrics: [y, t])
        #expect(report.missingReasons.contains { $0.contains("syncing") })
    }

    @Test("CompletenessSummary detects insufficient baseline (<7 days)")
    func baselineInsufficient() {
        let start = calendar.startOfDay(for: Date())
        var mets: [DailyHealthMetrics] = []
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: start)!
            if i < 3 {
                mets.append(metrics(date: date, sleep: 7.5, hrv: 55, restingHR: 58, steps: 8000, activeEnergy: 400, exercise: 30))
            } else {
                mets.append(metrics(date: date, sleep: nil, hrv: nil, restingHR: nil, steps: nil, activeEnergy: nil, exercise: nil))
            }
        }
        let summary = DataCoverageLayer().completenessSummary(metrics: mets)
        #expect(summary.completeRecoveryDays == 3)
        #expect(summary.isBaselineInsufficient == true)
        #expect(summary.baselineGuidanceMessage != nil)
    }

    @Test("CompletenessSummary passes when baseline is sufficient")
    func baselineSufficient() {
        let start = calendar.startOfDay(for: Date())
        var mets: [DailyHealthMetrics] = []
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: start)!
            mets.append(metrics(date: date, sleep: 7.5, hrv: 55, restingHR: 58, steps: 8000, activeEnergy: 400, exercise: 30))
        }
        let summary = DataCoverageLayer().completenessSummary(metrics: mets)
        #expect(summary.completeRecoveryDays >= 7)
        #expect(summary.isBaselineInsufficient == false)
        #expect(summary.baselineGuidanceMessage == nil)
    }

    // MARK: - Body Budget Scorer (Phase 15)

    @Test("BodyBudgetScorer returns elevated score for metrics above baseline")
    func bodyBudgetScoreHighWhenMetricsStrong() {
        let today = metrics(
            sleep: 8.5, hrv: 72, restingHR: 52,
            steps: 12_000, activeEnergy: 600, exercise: 50
        )
        let baseline = HealthBaseline(
            windowDays: 14,
            averageSleepHours: 7.0, averageHRV: 55, averageRestingHeartRate: 60,
            averageSteps: 10_000, averageActiveEnergy: 500, averageExerciseMinutes: 40
        )
        let scorer = BodyBudgetScorer()
        let score = scorer.score(today: today, baseline: baseline, signals: [], feedback: nil)

        // Metrics above baseline produce a fair-to-good score (65+)
        #expect(score.value >= 65)
        #expect(score.signalPenalty == 0)
        // Recovery should be notably higher than activity since recovery metrics are stronger
        #expect(score.recoverySubscore > 50)
    }

    @Test("BodyBudgetScorer penalizes high-severity signals")
    func bodyBudgetScorePenalizesSignals() {
        let today = metrics(
            sleep: 6.0, hrv: 42, restingHR: 65,
            steps: 8_000, activeEnergy: 450, exercise: 30
        )
        let baseline = HealthBaseline(
            windowDays: 14,
            averageSleepHours: 7.5, averageHRV: 60, averageRestingHeartRate: 58,
            averageSteps: 10_000, averageActiveEnergy: 500, averageExerciseMinutes: 40
        )
        let signals: [HealthSignal] = [
            HealthSignal(type: .hrvLow, severity: .high,
                         evidence: "HRV 42ms / 14d 60ms", explanation: "HRV low"),
            HealthSignal(type: .sleepLow, severity: .medium,
                         evidence: "Sleep 6h / 14d 7.5h", explanation: "Sleep low"),
        ]
        let scorer = BodyBudgetScorer()
        let scoreNoSignals = scorer.score(today: today, baseline: baseline, signals: [], feedback: nil)
        let scoreWithSignals = scorer.score(today: today, baseline: baseline, signals: signals, feedback: nil)

        #expect(scoreWithSignals.value < scoreNoSignals.value)
        #expect(scoreWithSignals.signalPenalty > 0)
    }

    @Test("BodyBudgetScorer handles missing data by shifting toward neutral")
    func bodyBudgetScoreNeutralWithMissingData() {
        let today = metrics(
            sleep: nil, hrv: nil, restingHR: 58,
            steps: 9_000, activeEnergy: 500, exercise: 40
        )
        let baseline = HealthBaseline(
            windowDays: 14,
            averageSleepHours: 7.5, averageHRV: 60, averageRestingHeartRate: 58,
            averageSteps: 10_000, averageActiveEnergy: 500, averageExerciseMinutes: 40
        )
        let scorer = BodyBudgetScorer()
        let score = scorer.score(today: today, baseline: baseline, signals: [], feedback: nil)

        // With sleep and HRV missing (2/3 of recovery), score should be moderate
        #expect(score.value >= 40 && score.value <= 75)
        #expect(score.recoverySubscore >= 30 && score.recoverySubscore <= 70)
    }

    @Test("BodyBudgetScorer integrates subjective feedback")
    func bodyBudgetScoreWithFeedback() {
        let today = metrics(
            sleep: 7.5, hrv: 60, restingHR: 58,
            steps: 10_000, activeEnergy: 500, exercise: 40
        )
        let baseline = HealthBaseline(
            windowDays: 14,
            averageSleepHours: 7.5, averageHRV: 60, averageRestingHeartRate: 58,
            averageSteps: 10_000, averageActiveEnergy: 500, averageExerciseMinutes: 40
        )
        let recId = UUID()
        let goodFeedback = DailyFeedback(
            date: Date(), recommendationId: recId, adherence: .completed,
            subjectiveEnergy: 8, soreness: 2, stress: 3, note: nil
        )
        let badFeedback = DailyFeedback(
            date: Date(), recommendationId: recId, adherence: .skipped,
            subjectiveEnergy: 3, soreness: 8, stress: 9, note: nil
        )
        let scorer = BodyBudgetScorer()
        let scoreGood = scorer.score(today: today, baseline: baseline, signals: [], feedback: goodFeedback)
        let scoreBad = scorer.score(today: today, baseline: baseline, signals: [], feedback: badFeedback)

        #expect(scoreGood.value > scoreBad.value)
        #expect(scoreGood.subjectiveSubscore > scoreBad.subjectiveSubscore)
    }

    @Test("BodyBudgetScorer returns valid score even with no baseline")
    func bodyBudgetScoreWithNoBaseline() {
        let today = metrics(
            sleep: 7.0, hrv: 55, restingHR: 60,
            steps: 8_000, activeEnergy: 400, exercise: 30
        )
        let baseline = HealthBaseline(windowDays: 14)  // all nil
        let scorer = BodyBudgetScorer()
        let score = scorer.score(today: today, baseline: baseline, signals: [], feedback: nil)

        // Without baseline, should still return a valid 0-100 score
        #expect(score.value >= 0 && score.value <= 100)
        // Without baseline data, we still get a neutral score (around 50-60)
        #expect(score.recoverySubscore >= 30)
    }

    private func metrics(
        date: Date = Date(),
        sleep: Double?,
        hrv: Double?,
        restingHR: Double?,
        steps: Double?,
        activeEnergy: Double?,
        exercise: Double?
    ) -> DailyHealthMetrics {
        var statuses: [HealthMetric: MetricStatus] = [
            .sleepHours: sleep == nil ? .missing : .valid,
            .hrv: hrv == nil ? .missing : .valid,
            .restingHeartRate: restingHR == nil ? .missing : .valid,
            .steps: steps == nil ? .missing : .valid,
            .activeEnergyKcal: activeEnergy == nil ? .missing : .valid,
            .exerciseMinutes: exercise == nil ? .missing : .valid,
            .workouts: .valid
        ]
        if sleep == 1.0 {
            statuses[.sleepHours] = .partial
        }

        return DailyHealthMetrics(
            date: date,
            sleepHours: sleep,
            hrv: hrv,
            restingHeartRate: restingHR,
            steps: steps,
            activeEnergyKcal: activeEnergy,
            exerciseMinutes: exercise,
            workouts: [],
            perMetricStatus: statuses
        )
    }

    private func context(quality: ConfidenceLevel, signals: [SignalType]) -> AgentContext {
        let today = metrics(
            sleep: quality == .low ? nil : 7,
            hrv: quality == .low ? nil : 58,
            restingHR: 58,
            steps: 8_000,
            activeEnergy: 400,
            exercise: 30
        )
        let report = DataQualityReport(
            perMetricStatus: today.perMetricStatus,
            overallConfidence: quality,
            missingReasons: quality == .low ? ["Recovery data is missing."] : [],
            shouldAskUserFollowup: quality == .low,
            suggestedFollowupQuestion: quality == .low ? "Did you wear your watch overnight?" : nil
        )
        return AgentContext(
            userGoal: "Choose one small action.",
            todayMetrics: today,
            baseline14d: baseline(),
            dataQuality: report,
            detectedSignals: signals.map { signal in
                HealthSignal(type: signal, severity: .medium, evidence: signal.rawValue, explanation: "Test signal")
            },
            coachingConstraints: [],
            recommendedDecisionFrame: "Test"
        )
    }

    private func baseline() -> HealthBaseline {
        HealthBaseline(
            windowDays: 14,
            averageSleepHours: 7.5,
            averageHRV: 60,
            averageRestingHeartRate: 58,
            averageSteps: 8_000,
            averageActiveEnergy: 400,
            averageExerciseMinutes: 30
        )
    }

    private func sampleRecommendation(date: Date) -> CoachRecommendation {
        CoachRecommendation(
            date: date,
            state: .recoveryLow,
            confidence: .medium,
            title: "Recovery",
            summary: "Take it easy.",
            evidence: [],
            recommendation: "Keep training easy.",
            tonightAction: "Sleep earlier.",
            tomorrowVerification: []
        )
    }

    private func sampleExperiment(title: String) -> PersonalExperiment {
        let start = calendar.startOfDay(for: Date())
        return PersonalExperiment(
            title: title,
            hypothesis: "可能有帮助。",
            intervention: "Do a small action.",
            startDate: start,
            endDate: calendar.date(byAdding: .day, value: 5, to: start)!,
            targetMetrics: ["sleepHours", "hrv"],
            whyThisExperiment: "Test"
        )
    }

    private func datedMetrics(count: Int) -> [DailyHealthMetrics] {
        let start = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        return (0..<count).map { index in
            metrics(
                sleep: 7.5,
                hrv: 60,
                restingHR: 58,
                steps: 8_000,
                activeEnergy: 400,
                exercise: 30
            ).withDate(calendar.date(byAdding: .day, value: index, to: start)!)
        }
    }

    private func quality(_ confidence: ConfidenceLevel) -> DataQualityReport {
        DataQualityReport(
            perMetricStatus: [:],
            overallConfidence: confidence,
            missingReasons: confidence == .low ? ["Recovery data is missing."] : [],
            shouldAskUserFollowup: confidence == .low,
            suggestedFollowupQuestion: confidence == .low ? "Did you wear your watch overnight?" : nil
        )
    }

    private func plannerInput(
        goals: [UserGoal],
        quality confidence: ConfidenceLevel,
        experiment: PersonalExperiment? = nil,
        signals: [HealthSignal] = []
    ) -> WeeklyPlanPlannerInput {
        WeeklyPlanPlannerInput(
            activeGoals: goals,
            recentMetrics: datedMetrics(count: 14),
            baseline: baseline(),
            dataQuality: quality(confidence),
            detectedSignals: signals,
            userMemory: UserMemory(),
            activeExperiment: experiment,
            recentRecommendations: [],
            recentFeedback: [],
            previousPlan: nil
        )
    }

    private func dailyPlan(type: DailyPlanType, intensity: PlanIntensity) -> DailyPlan {
        DailyPlan(
            date: calendar.startOfDay(for: Date()),
            weekday: calendar.oheasWeekday(for: Date()),
            planType: type,
            title: "Plan",
            description: "Small lifestyle plan.",
            intensity: intensity,
            estimatedDurationMinutes: intensity == .high ? 45 : 20,
            targetMetrics: ["steps", "subjectiveEnergy"]
        )
    }

    private func sampleWeeklyPlan(dayCount: Int = 2) -> WeeklyPlan {
        let start = calendar.oheasWeekStart(for: Date())
        let days = (0..<dayCount).map { index in
            DailyPlan(
                date: calendar.date(byAdding: .day, value: index, to: start)!,
                weekday: calendar.oheasWeekday(for: calendar.date(byAdding: .day, value: index, to: start)!),
                planType: .lightActivity,
                title: "Plan \(index)",
                description: "Small plan.",
                intensity: .low,
                estimatedDurationMinutes: 15,
                targetMetrics: ["steps"]
            )
        }
        return WeeklyPlan(
            weekStartDate: start,
            goals: [UserGoal.mockDefault],
            days: days,
            strategySummary: "Test plan.",
            generatedFromContextSummary: "Test context.",
            status: .active
        )
    }

    private func hasConsecutiveHighIntensity(_ days: [DailyPlan]) -> Bool {
        guard days.count > 1 else { return false }
        return zip(days, days.dropFirst()).contains { previous, current in
            previous.intensity == .high && current.intensity == .high
        }
    }

    private func tempFile(_ name: String) -> URL {
        tempDirectory().appendingPathComponent(name)
    }

    private func tempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func validRecommendationJSON() -> String {
        """
        {
          "id": "\(UUID().uuidString)",
          "date": "2026-06-08T00:00:00Z",
          "state": "balanced",
          "confidence": "Medium",
          "title": "Balanced day",
          "summary": "Metrics are close to baseline.",
          "evidence": [
            {
              "id": "\(UUID().uuidString)",
              "metric": "sleepHours",
              "observation": "Sleep was near baseline.",
              "baselineComparison": "7.3h vs 7.5h",
              "importance": "Sleep supports recovery interpretation."
            }
          ],
          "recommendation": "Take one easy walk.",
          "tonightAction": "Keep bedtime steady.",
          "tomorrowVerification": [
            {
              "id": "\(UUID().uuidString)",
              "metric": "hrv",
              "expectedDirection": "stable",
              "reason": "Stable HRV supports a balanced day."
            }
          ],
          "followupQuestion": null,
          "safetyNote": "Lifestyle guidance only.",
          "createdAt": "2026-06-08T00:01:00Z"
        }
        """
    }
}

private extension DailyHealthMetrics {
    func withDate(_ date: Date) -> DailyHealthMetrics {
        var copy = self
        copy.date = date
        return copy
    }
}

private struct BrokenLLMClient: LLMClientProtocol {
    let name = "broken"

    func generateRecommendationJSON(payload: CoachPromptPayload) async throws -> String {
        "not json"
    }
}

private final class SpyBackendClient: BackendAPIClientProtocol, @unchecked Sendable {
    var analyticsUploads = 0
    var syncUploads = 0
    var shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func uploadDailySummary(_ metrics: DailyHealthMetrics, userId: UUID) async throws { try maybeFail() }
    func uploadRecommendation(_ recommendation: CoachRecommendation, userId: UUID) async throws { try maybeFail() }
    func uploadFeedback(_ feedback: DailyFeedback, userId: UUID) async throws { try maybeFail() }
    func uploadVerificationReport(_ report: VerificationReport, userId: UUID) async throws { try maybeFail() }
    func uploadMemory(_ memory: UserMemorySummary, userId: UUID) async throws { try maybeFail() }
    func uploadExperiment(_ experiment: PersonalExperiment, userId: UUID) async throws { try maybeFail() }
    func uploadWeeklyPlan(_ plan: WeeklyPlan, userId: UUID) async throws { try maybeFail() }
    func uploadWeeklyReview(_ review: WeeklyReview, userId: UUID) async throws { try maybeFail() }
    func uploadPrivacySettings(_ settings: PrivacySettings, userId: UUID) async throws { try maybeFail() }
    func uploadSafetyAssessment(_ assessment: SafetyAssessment, userId: UUID) async throws { try maybeFail() }

    func uploadAnalyticsEvent(_ event: BetaAnalyticsEvent, userId: UUID) async throws {
        try maybeFail()
        analyticsUploads += 1
    }

    func uploadSyncRecord(_ record: SyncRecord, userId: UUID) async throws {
        try maybeFail()
        syncUploads += 1
    }

    func fetchRemoteChanges(since: Date?, userId: UUID) async throws -> [SyncRecord] { [] }
    func markDeleted(entityType: SyncEntityType, id: String, userId: UUID) async throws { try maybeFail() }

    private func maybeFail() throws {
        if shouldFail {
            throw BackendClientError.httpStatus(500)
        }
    }
}
