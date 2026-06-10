//
//  DemoScenarioBuilder.swift
//  OHeas
//
//  Builds demo scenarios (normal, overtraining, missing data, recovery).
//  构建演示场景（正常、过度训练、数据缺失、恢复）。
//


import Foundation

#if DEBUG
public enum DemoScenario: String, Codable, CaseIterable, Identifiable, Sendable {
    case overworkedProfessional = "overworked_professional"
    case overtrainingRunner = "overtraining_runner"
    case missingDataUser = "missing_data_user"
    case habitBuilder = "habit_builder"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .overworkedProfessional: "Overworked Professional"
        case .overtrainingRunner: "Overtraining Runner"
        case .missingDataUser: "Missing Data User"
        case .habitBuilder: "Habit Builder"
        }
    }

    public var summary: String {
        switch self {
        case .overworkedProfessional:
            "Sleep debt, HRV decline, higher resting heart rate, and recovery-first coaching."
        case .overtrainingRunner:
            "High activity followed by recovery drop and plan downgrade."
        case .missingDataUser:
            "Missing sleep and HRV coverage with a data coverage experiment."
        case .habitBuilder:
            "Stable recovery, low activity, and a consistency-building plan."
        }
    }
}

public struct DemoScenarioData: Codable, Equatable, Sendable {
    public var scenario: DemoScenario
    public var summary: String
    public var metrics: [DailyHealthMetrics]
    public var feedbackHistory: [DailyFeedback]
    public var recommendationHistory: [CoachRecommendation]
    public var verificationReports: [VerificationReport]
    public var userMemory: UserMemory
    public var experiments: [PersonalExperiment]
    public var weeklyPlan: WeeklyPlan
    public var effectivenessReport: EffectivenessReport

    public init(
        scenario: DemoScenario,
        summary: String,
        metrics: [DailyHealthMetrics],
        feedbackHistory: [DailyFeedback],
        recommendationHistory: [CoachRecommendation],
        verificationReports: [VerificationReport],
        userMemory: UserMemory,
        experiments: [PersonalExperiment],
        weeklyPlan: WeeklyPlan,
        effectivenessReport: EffectivenessReport
    ) {
        self.scenario = scenario
        self.summary = summary
        self.metrics = metrics
        self.feedbackHistory = feedbackHistory
        self.recommendationHistory = recommendationHistory
        self.verificationReports = verificationReports
        self.userMemory = userMemory
        self.experiments = experiments
        self.weeklyPlan = weeklyPlan
        self.effectivenessReport = effectivenessReport
    }
}

public struct DemoScenarioBuilder: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func build(_ scenario: DemoScenario, endingOn endDate: Date = Date()) -> DemoScenarioData {
        let start = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: endDate)) ?? endDate
        let metrics = makeMetrics(for: scenario, start: start)
        let memory = makeMemory(for: scenario, date: endDate)
        let experiment = makeExperiment(for: scenario, start: calendar.date(byAdding: .day, value: -5, to: endDate) ?? endDate)
        let recommendations = makeRecommendations(for: scenario, metrics: metrics)
        let feedback = makeFeedback(for: recommendations)
        let reports = makeVerificationReports(recommendations: recommendations, feedback: feedback)
        let plan = makeWeeklyPlan(for: scenario, metrics: metrics, experiment: experiment)
        let experiments = [experiment]
        let effectiveness = EffectivenessAnalyzer(calendar: calendar).analyze(
            recommendations: recommendations,
            feedbackHistory: feedback,
            verificationReports: reports,
            experiments: experiments,
            weeklyPlans: [plan],
            dailyMetrics: metrics,
            dataQualityHistory: metrics.map { DataCoverageLayer().report(for: $0) }
        )
        return DemoScenarioData(
            scenario: scenario,
            summary: scenario.summary,
            metrics: metrics,
            feedbackHistory: feedback,
            recommendationHistory: recommendations,
            verificationReports: reports,
            userMemory: memory,
            experiments: experiments,
            weeklyPlan: plan,
            effectivenessReport: effectiveness
        )
    }

    private func makeMetrics(for scenario: DemoScenario, start: Date) -> [DailyHealthMetrics] {
        (0..<30).map { day in
            let date = calendar.date(byAdding: .day, value: day, to: start) ?? start
            var sleep = 7.4
            var hrv = 58.0
            var rhr = 58.0
            var steps = 7_500.0
            var exercise = 28.0

            switch scenario {
            case .overworkedProfessional:
                sleep = day > 21 ? 5.7 + Double(day % 2) * 0.2 : 6.8
                hrv = day > 21 ? 42 - Double(day % 3) : 56
                rhr = day > 21 ? 66 + Double(day % 2) : 59
                steps = 5_000
                exercise = 12
            case .overtrainingRunner:
                steps = day > 19 ? 16_000 + Double(day % 4) * 1_500 : 9_000
                exercise = day > 19 ? 85 : 45
                hrv = day > 23 ? 39 : 60
                rhr = day > 23 ? 68 : 57
                sleep = day > 23 ? 6.2 : 7.4
            case .missingDataUser:
                if [4, 5, 11, 12, 18, 24].contains(day) {
                    sleep = .nan
                    hrv = .nan
                } else {
                    sleep = 7.0
                    hrv = 55
                }
                steps = 6_000
                exercise = 20
            case .habitBuilder:
                sleep = 7.6
                hrv = 61
                rhr = 57
                steps = day > 22 ? 4_000 : 3_000
                exercise = day > 22 ? 14 : 8
            }

            let sleepValue = sleep.isNaN ? nil : sleep
            let hrvValue = hrv.isNaN ? nil : hrv
            return DailyHealthMetrics(
                date: date,
                sleepHours: sleepValue,
                hrv: hrvValue,
                restingHeartRate: rhr,
                steps: steps,
                activeEnergyKcal: steps / 20,
                exerciseMinutes: exercise,
                workouts: [],
                perMetricStatus: [
                    .sleepHours: sleepValue == nil ? .missing : .valid,
                    .hrv: hrvValue == nil ? .missing : .valid,
                    .restingHeartRate: .valid,
                    .steps: .valid,
                    .activeEnergyKcal: .valid,
                    .exerciseMinutes: .valid,
                    .workouts: .valid
                ]
            )
        }
    }

    private func makeMemory(for scenario: DemoScenario, date: Date) -> UserMemory {
        UserMemory(
            knownPatterns: [
                KnownPattern(
                    title: scenario.title,
                    description: scenario.summary,
                    relatedMetrics: ["sleepHours", "hrv", "restingHeartRate", "steps"],
                    confidence: .medium,
                    evidenceCount: 4,
                    firstObservedAt: date.addingTimeInterval(-20 * 86_400),
                    lastObservedAt: date,
                    examples: [scenario.summary]
                )
            ],
            successfulInterventions: [
                InterventionMemory(
                    intervention: "Easy walk plus earlier wind-down",
                    observedEffect: "Possibly supported better next-day subjective energy.",
                    targetMetrics: ["subjectiveEnergy", "sleepHours"],
                    confidence: .medium,
                    evidenceCount: 2,
                    lastObservedAt: date
                )
            ]
        )
    }

    private func makeExperiment(for scenario: DemoScenario, start: Date) -> PersonalExperiment {
        let title: String
        let intervention: String
        switch scenario {
        case .overworkedProfessional:
            title = "Earlier wind-down experiment"
            intervention = "Start wind-down 30 minutes earlier for five nights."
        case .overtrainingRunner:
            title = "Recovery day after hard run"
            intervention = "Use low-intensity mobility the day after high running load."
        case .missingDataUser:
            title = "Recovery data coverage experiment"
            intervention = "Wear Apple Watch overnight and log morning energy for five days."
        case .habitBuilder:
            title = "Lunch walk consistency experiment"
            intervention = "Take a 15-minute walk after lunch for five workdays."
        }
        var experiment = PersonalExperiment(
            title: title,
            hypothesis: "This small lifestyle change may help clarify a useful pattern.",
            intervention: intervention,
            startDate: start,
            endDate: calendar.date(byAdding: .day, value: 5, to: start) ?? start,
            targetMetrics: ["sleepHours", "hrv", "restingHeartRate", "subjectiveEnergy"],
            status: scenario == .missingDataUser ? .active : .completed,
            whyThisExperiment: scenario.summary
        )
        experiment.dailyCheckins = (0..<5).map { offset in
            ExperimentCheckin(date: calendar.date(byAdding: .day, value: offset, to: start) ?? start, completed: offset != 3, note: nil, subjectiveEnergy: 6 + min(offset, 2))
        }
        if experiment.status == .completed {
            experiment.result = ExperimentResult(outcome: .likelyHelped, confidence: .medium, summary: "Possibly helpful in this demo trajectory; not proof of effect.", evidence: ["Completed most check-ins.", "Next-day energy trended stable or better."])
        }
        return experiment
    }

    private func makeRecommendations(for scenario: DemoScenario, metrics: [DailyHealthMetrics]) -> [CoachRecommendation] {
        metrics.suffix(10).map { metric in
            let quality = DataCoverageLayer().report(for: metric)
            let baseline = HealthBaseline(windowDays: 14, averageSleepHours: 7.3, averageHRV: 58, averageRestingHeartRate: 58, averageSteps: 8_000, averageActiveEnergy: 400, averageExerciseMinutes: 30)
            let signals = SignalDetector().detect(today: metric, baseline: baseline, dataQuality: quality)
            let context = AgentContextBuilder().build(
                userGoal: scenario.summary,
                todayMetrics: metric,
                baseline14d: baseline,
                dataQuality: quality,
                detectedSignals: signals,
                privacySettings: .defaults
            )
            return RuleBasedRecommendationGenerator().generate(context: context)
        }
    }

    private func makeFeedback(for recommendations: [CoachRecommendation]) -> [DailyFeedback] {
        recommendations.enumerated().map { index, recommendation in
            DailyFeedback(
                date: recommendation.date,
                recommendationId: recommendation.id,
                adherence: index % 5 == 0 ? .skipped : (index % 3 == 0 ? .partial : .completed),
                subjectiveEnergy: 5 + min(index % 4, 3),
                soreness: 5 - min(index % 3, 2),
                stress: 5,
                note: index % 5 == 0 ? "Skipped due to schedule." : nil
            )
        }
    }

    private func makeVerificationReports(recommendations: [CoachRecommendation], feedback: [DailyFeedback]) -> [VerificationReport] {
        zip(recommendations, feedback).map { recommendation, feedback in
            let outcome: VerificationOutcome = feedback.adherence == .skipped ? .unclear : (feedback.subjectiveEnergy >= 7 ? .likelyHelped : .neutral)
            return VerificationReport(
                date: recommendation.date.addingTimeInterval(86_400),
                recommendationId: recommendation.id,
                outcome: outcome,
                confidence: outcome == .unclear ? .low : .medium,
                findings: outcome == .likelyHelped ? ["Subjective energy was stable or higher."] : ["No strong next-day signal."],
                explanation: outcome == .likelyHelped ? "May have helped; observational only." : "Unable to draw a strong conclusion.",
                learnedPatternCandidate: outcome == .likelyHelped ? recommendation.recommendation : nil
            )
        }
    }

    private func makeWeeklyPlan(for scenario: DemoScenario, metrics: [DailyHealthMetrics], experiment: PersonalExperiment) -> WeeklyPlan {
        let today = metrics.last ?? DailyHealthMetrics(date: Date())
        let quality = DataCoverageLayer().report(for: today)
        let baseline = HealthBaseline(windowDays: 14, averageSleepHours: 7.3, averageHRV: 58, averageRestingHeartRate: 58, averageSteps: 8_000, averageActiveEnergy: 400, averageExerciseMinutes: 30)
        let signals = SignalDetector().detect(today: today, baseline: baseline, dataQuality: quality)
        let goalType: UserGoalType = scenario == .habitBuilder ? .buildConsistency : (scenario == .overtrainingRunner ? .improveCardio : .recoveryFirst)
        let goal = UserGoal(type: goalType, title: scenario.title, description: scenario.summary, priority: .high)
        let input = WeeklyPlanPlannerInput(
            activeGoals: [goal],
            recentMetrics: metrics,
            baseline: baseline,
            dataQuality: quality,
            detectedSignals: signals,
            userMemory: makeMemory(for: scenario, date: today.date),
            activeExperiment: experiment.status == .active ? experiment : nil,
            recentRecommendations: [],
            recentFeedback: [],
            previousPlan: nil
        )
        return RuleBasedWeeklyPlanGenerator(calendar: calendar).generatePlan(input: input, weekStartDate: calendar.oheasWeekStart(for: today.date))
    }
}
#endif
