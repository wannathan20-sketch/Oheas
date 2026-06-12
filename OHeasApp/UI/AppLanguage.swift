//
//  AppLanguage.swift
//  OHeas
//
//  AppLanguage.swift — OHeas UI component.
//  AppLanguage.swift — OHeas UI 组件。
//


import Foundation
import OHeasCore

enum AppLanguage: String, CaseIterable, Identifiable, Equatable {
    case chinese = "zh"
    case english = "en"

    var id: String { rawValue }

    var settingsName: String {
        switch self {
        case .chinese: "中文"
        case .english: "English"
        }
    }

    func text(_ key: TextKey) -> String {
        if let pair = Self.translations[key] {
            return self == .chinese ? pair.zh : pair.en
        }
        return "\(key)"
    }

    // MARK: - Static translation dictionary (avoids Swift compiler exhaustion on large switches)

    private static let translations: [TextKey: (zh: String, en: String)] = _buildTranslations()

    private static func _buildTranslations() -> [TextKey: (zh: String, en: String)] {
        var dict: [TextKey: (zh: String, en: String)] = [:]
        // ---- Tab & Navigation ----
        dict[.todayTab] = ("今日", "Today")
                dict[.accountLabel] = ("账户", "Account")
        dict[.accountSection] = ("账户与同步", "Account & Sync")
        dict[.achievementsTitle] = ("成就", "Achievements")
        dict[.actionDurationLabel] = ("时长", "Duration")
        dict[.actionVerifyLabel] = ("明天验证", "Verify tomorrow")
        dict[.actionWhatLabel] = ("做什么", "What to do")
        dict[.actionWhyLabel] = ("为什么", "Why")
        dict[.activeEnergyName] = ("活动能量", "Active Energy")
        dict[.activeExperiment] = ("进行中的实验", "Active Experiment")
        dict[.activeGoals] = ("当前目标", "Active Goals")
        dict[.activitySection] = ("活动", "Activity")
        dict[.addGoal] = ("添加目标", "Add Goal")
        dict[.adherence] = ("执行情况", "Adherence")
        dict[.adjustLabel] = ("调整", "Adjust")
        dict[.adjusted] = ("已调整", "Adjusted")
        dict[.agentContextLabel] = ("智能体上下文", "Agent Context")
        dict[.agentTab] = ("智能体", "Agent")
        dict[.aiConsentLabel] = ("AI 生活方式建议授权", "AI lifestyle advice consent")
        dict[.aiEnabled] = ("启用 AI", "Enable OpenAI")
        dict[.aiFooter] = ("未配置 API 密钥、关闭 AI 或网络失败时，会使用本地规则建议。", "When the API key is missing, AI is disabled, or networking fails, local rule-based recommendations are used.")
        dict[.aiOnlineShort] = ("AI 在线", "AI Online")
        dict[.aiSection] = ("AI", "AI")
        dict[.allowRawHealthSamplesToggle] = ("允许原始健康样本", "Allow raw Health samples")
        dict[.analyticsDescription] = ("分析属性仅限于非敏感产品摘要，绝不包含原始健康样本。", "Analytics properties are limited to non-sensitive product summaries, never raw health samples.")
        dict[.appDisclaimer] = ("基于 Apple Watch 数据的个人生活方式健康助手。不能替代医疗诊断和专业医疗护理。", "A lifestyle health agent for Apple Watch summaries. It does not diagnose disease and should not replace qualified medical care.")
        dict[.appOpens] = ("应用打开次数", "App opens")
        dict[.appSection] = ("关于", "App")
        dict[.appSubtitle] = ("BodyLoop for OHeas", "BodyLoop for OHeas")
        dict[.askHistoricalValidation] = ("这个建议之前对我有效吗？", "Did this work for me before?")
        dict[.askInChatLabel] = ("在对话中讨论", "Discuss in Chat")
        dict[.askMoreDetails] = ("告诉我更多细节", "Tell me more details")
        dict[.askRecoveryMeaning] = ("这对我的恢复意味着什么？", "What does this mean for my recovery?")
        dict[.askTomorrowPlan] = ("明天我应该做什么？", "What should I do tomorrow?")
        dict[.badge10Feedbacks] = ("积极反馈", "Engaged")
        dict[.badge10FeedbacksDesc] = ("提交了 10 次健康反馈", "Submitted 10 feedback entries")
        dict[.badge30DayCheckIn] = ("月度签到", "Monthly Streak")
        dict[.badge30DayCheckInDesc] = ("连续 30 天使用 OHeas", "Used OHeas 30 days in a row")
        dict[.badge30Plans] = ("计划达人", "Planner")
        dict[.badge30PlansDesc] = ("完成了 30 个每日计划", "Completed 30 daily plans")
        dict[.badge3Experiments] = ("科学家", "Scientist")
        dict[.badge3ExperimentsDesc] = ("完成了 3 个个人实验", "Completed 3 personal experiments")
        dict[.badge7DayCheckIn] = ("一周签到", "Week Streak")
        dict[.badge7DayCheckInDesc] = ("连续 7 天使用 OHeas", "Used OHeas 7 days in a row")
        dict[.badge7DayDataCoverage] = ("数据守护者", "Data Keeper")
        dict[.badge7DayDataCoverageDesc] = ("连续 7 天完整佩戴记录数据", "7 consecutive days of complete wearable data")
        dict[.badge7DayPlanComplete] = ("行动派", "Doer")
        dict[.badge7DayPlanCompleteDesc] = ("连续 7 天完成每日计划", "Completed daily plans 7 days in a row")
        dict[.badgeAllMetricsViewed] = ("新手探索", "Explorer")
        dict[.badgeAllMetricsViewedDesc] = ("首次提交健康反馈", "Submitted your first feedback")
        dict[.badgeFirstChat] = ("初次对话", "First Chat")
        dict[.badgeFirstChatDesc] = ("首次与 AI 健康教练对话", "Had your first chat with the AI coach")
        dict[.badgeFirstExperiment] = ("实验者", "Experimenter")
        dict[.badgeFirstExperimentDesc] = ("完成第一个个人实验", "Completed your first personal experiment")
        dict[.badgeFirstRecommendation] = ("初次建议", "First Advice")
        dict[.badgeFirstRecommendationDesc] = ("收到第一条 AI 健康建议", "Received your first AI health recommendation")
        dict[.badgeHRVImprovement] = ("心率洞察", "Heart Reader")
        dict[.badgeHRVImprovementDesc] = ("21 天完整 HRV 数据记录", "21 days of complete HRV data")
        dict[.badgeScoreWeekExcellent] = ("满分周", "Perfect Week")
        dict[.badgeScoreWeekExcellentDesc] = ("身体预算评分连续 7 天保持优秀（85+）", "Body Budget Score stayed excellent (85+) for 7 days")
        dict[.badgeSleepConsistency] = ("规律睡眠", "Sleep Steady")
        dict[.badgeSleepConsistencyDesc] = ("14 天持续记录睡眠数据", "14 days of consistent sleep tracking")
        dict[.badgeUnlockedToast] = ("新徽章解锁！", "New Badge Unlocked!")
        dict[.badgeWeeklyReviewDone] = ("回顾者", "Reviewer")
        dict[.badgeWeeklyReviewDoneDesc] = ("完成了第一次每周回顾", "Completed your first weekly review")
        dict[.badgesCount] = ("%d/%d 徽章", "%d/%d badges")
        dict[.badgesSectionTitle] = ("徽章", "Badges")
        dict[.baseline] = ("基线", "Baseline")
        dict[.baselineLimited] = ("基线仍在积累中。请佩戴 Apple Watch 睡觉几天，以提高数据可信度。", "Baseline is still limited. Wear Apple Watch overnight for a few more days to improve confidence.")
        dict[.baselineReady] = ("基线已从近期聚合指标初始化完成。", "Baseline initialized from recent aggregate metrics.")
        dict[.baselineLabel] = ("基线", "Baseline")
        dict[.betaAnalyticsConsentLabel] = ("测试分析授权", "Beta analytics consent")
        dict[.betaAnalyticsLabel] = ("测试分析", "Beta Analytics")
        dict[.betaAnalyticsNavTitle] = ("测试分析", "Beta Analytics")
        dict[.betaFeedbackFreeTextPlaceholder] = ("还有什么想分享的吗？（选填）", "Anything else you'd like to share? (optional)")
        dict[.betaFeedbackHelpfulQuestion] = ("今天的建议对你有帮助吗？", "Was today's recommendation helpful?")
        dict[.betaFeedbackIntrusiveQuestion] = ("今天应用是否打扰到你了？", "Did the app feel overly intrusive today?")
        dict[.betaFeedbackLabel] = ("测试反馈", "Beta Feedback")
        dict[.betaFeedbackNavTitle] = ("测试反馈", "Beta Feedback")
        dict[.betaFeedbackOK] = ("好的", "OK")
        dict[.betaFeedbackPrivacyQuestion] = ("你有隐私方面的顾虑吗？", "Do you have any privacy concerns?")
        dict[.betaFeedbackSubmit] = ("提交测试反馈", "Submit Beta Feedback")
        dict[.betaFeedbackSubmittedTitle] = ("已提交", "Submitted")
        dict[.betaFeedbackThanks] = ("感谢你的反馈", "Thanks for your feedback")
        dict[.betaFeedbackUnderstandableQuestion] = ("建议是否容易理解？", "Was the advice easy to understand?")
        dict[.betaLabel] = ("测试版", "Beta")
        dict[.betaSection] = ("测试工具", "Beta Tools")
        dict[.bodyBudgetExplanationHigh] = ("今天的数据完整度较高，建议可以作为主要参考。", "Today's data coverage is high enough to use this as your main read.")
        dict[.bodyBudgetExplanationLow] = ("数据不足，先看主观感受，再决定是否调整训练或作息。", "Data is limited, so check how you feel before changing training or routines.")
        dict[.bodyBudgetExplanationMedium] = ("部分数据缺失，建议把今日建议当作保守提醒。", "Some data is missing, so treat today's guidance as a conservative nudge.")
        dict[.budgetScoreDepleted] = ("多个指标提示需要恢复，今天请以休息为主。", "Multiple signals suggest you need recovery — make rest the priority today.")
        dict[.budgetScoreExcellent] = ("身体状态良好，各项指标都在正常范围。", "Your body is in great shape — all key metrics look strong.")
        dict[.budgetScoreFactorsLabel] = ("评分依据", "What drives this score")
        dict[.budgetScoreFair] = ("部分指标偏离基线，今天可以稍微保守一些。", "Some metrics are off baseline — consider a slightly conservative approach today.")
        dict[.budgetScoreGood] = ("整体状态不错，保持现有节奏即可。", "Things look good overall — keep your current rhythm.")
        dict[.budgetScoreStrained] = ("身体可能处于恢复状态，建议优先休息和睡眠。", "Your body may be in recovery mode — prioritize rest and sleep.")
        dict[.buildLabel] = ("构建号", "Build")
        dict[.cancelButton] = ("取消", "Cancel")
        dict[.changedLabel] = ("已变更", "Changed")
        dict[.chartNoDataPoint] = ("无数据", "No data")
        dict[.chartScoreUnit] = ("分", "pts")
        dict[.chartTrendLine] = ("5日移动平均", "5-Day Moving Avg")
        dict[.chatAskCoach] = ("问教练", "Ask Coach")
        dict[.chatCoachName] = ("健康教练", "Coach")
        dict[.chatContextEmptyHint] = ("选择一个话题，或者直接告诉我你的感受", "Pick a topic or tell me how you're feeling")
        dict[.chatContextEmptyTitle] = ("聊聊今天的身体状态", "Let's talk about today")
        dict[.chatEmptyDescription] = ("可以问你的健康数据、恢复策略、运动计划，或者任何生活方式相关的问题。", "Ask about your health data, recovery, activity plans, or any lifestyle question.")
        dict[.chatEmptyTitle] = ("和你的健康教练聊一聊", "Chat with your health coach")
        dict[.chatHistoryTitle] = ("对话历史", "Chat History")
        dict[.chatOfflineDescription] = ("本地模式可以回答基础健康问题。\\n连接 AI 后可获得个性化建议和深度分析。", "Local mode can handle basic health questions.\\nConnect AI for personalized advice and deeper analysis.")
        dict[.chatOfflineTitle] = ("基础问答可用", "Basic Q&A Available")
        dict[.chatPlaceholder] = ("问问教练...", "Ask your coach...")
        dict[.chatTab] = ("对话", "Chat")
        dict[.checkingPermissions] = ("正在检查权限...", "Checking permissions...")
        dict[.chipDismissLabel] = ("关闭", "Dismiss")
        dict[.cloudConsentLabel] = ("云端同步授权", "Cloud sync consent")
        dict[.cloudSyncModeLabel] = ("云同步", "Cloud Sync")
        dict[.coachSubtitle] = ("基于你的健康数据的个人 AI 教练", "Your personal AI coach powered by health data")
        dict[.completeExperiment] = ("结束并评估", "Complete & Evaluate")
        dict[.completedToday] = ("今天已执行", "Completed Today")
        dict[.completionRate] = ("完成率", "Completion Rate")
        dict[.contextNotReady] = ("上下文尚未生成。", "Context is not ready.")
        dict[.continueButton] = ("继续", "Continue")
        dict[.readyButton] = ("准备好了", "Ready")
        dict[.continueLimitedMode] = ("以受限模式继续", "Continue with limited mode")
        dict[.currentDemo] = ("当前演示", "Current Demo")
        dict[.currentStreak] = ("当前连续", "Current streak")
        dict[.dataConfidence] = ("数据可信度", "Data confidence")
        dict[.dayCardHRV] = ("HRV", "HRV")
        dict[.dayCardMoreSignals] = ("另有%d个信号", "%d more signals")
        dict[.dayCardSleep] = ("睡眠", "Sleep")
        dict[.dayCardSteps] = ("步数", "Steps")
        dict[.dayDetailEnergy] = ("精力", "Energy")
        dict[.dayDetailFactors] = ("影响因素", "Contributing Factors")
        dict[.dayDetailFeedback] = ("当日反馈", "Daily Feedback")
        dict[.dayDetailMetrics] = ("指标概览", "Metrics Overview")
        dict[.dayDetailNoFeedback] = ("当日未提交反馈", "No feedback submitted this day")
        dict[.dayDetailScore] = ("身体预算评分", "Body Budget Score")
        dict[.dayDetailSignals] = ("检测到的信号", "Detected Signals")
        dict[.dayDetailSoreness] = ("酸痛", "Soreness")
        dict[.dayDetailStress] = ("压力", "Stress")
        dict[.dayDetailTitle] = ("详情", "Details")
        dict[.daysCount] = ("%d 天", "%d days")
        dict[.daysUnit] = ("天", "days")
        dict[.deactivate] = ("停用", "Deactivate")
        dict[.debugPicker] = ("调试", "Debug")
        dict[.debugSection] = ("调试", "Debug")
        dict[.deleteAction] = ("删除", "Delete")
        dict[.deltaUnavailable] = ("暂无差异", "Delta unavailable")
        dict[.demoDescription] = ("演示模式将明确生成的本地数据写入 OHeas 存储。不会修改健康数据。", "Demo mode writes clearly generated local data to OHeas stores. It does not modify Apple Health.")
        dict[.demoModeLabel] = ("演示模式", "Demo Mode")
        dict[.demoNavTitle] = ("演示", "Demo")
        dict[.demoScenarioBuilder] = ("演示场景构建器", "Demo Scenario Builder")
        dict[.demoValue] = ("演示", "Demo")
        dict[.denied] = ("已拒绝", "Denied")
        dict[.descriptionPlaceholder] = ("描述", "Description")
        dict[.doneAction] = ("完成", "Done")
        dict[.effectivenessTitle] = ("效果分析", "Effectiveness")
        dict[.email] = ("邮箱", "Email")
        dict[.emptyDescription] = ("请检查健康权限或连接 Apple Watch", "Check Apple Health permissions or connect your Apple Watch")
        dict[.emptyPlanDescription] = ("加载健康数据或启用演示模式以生成周计划", "Load health data or enable demo mode to generate a weekly plan")
        dict[.emptyPlanTitle] = ("暂无计划", "No Plan Yet")
        dict[.emptyTitle] = ("暂无健康数据", "No Health Data")
        dict[.enableCloudSyncToggle] = ("启用云端同步", "Enable cloud sync")
        dict[.energy] = ("今日精力", "Energy")
        dict[.errorModeLabel] = ("错误", "Error")
        dict[.evaluationLabel] = ("评测", "Evaluation")
        dict[.evaluationNavTitle] = ("评测", "Evaluation")
        dict[.evaluationResults] = ("评测结果", "Evaluation Results")
        dict[.exerciseMinutesName] = ("运动分钟", "Exercise Minutes")
        dict[.experimentCheckins] = ("实验签到", "Experiment check-ins")
        dict[.experimentHistory] = ("实验历史", "Experiment History")
        dict[.experimentSection] = ("实验", "Experiment")
        dict[.experimentsLabel] = ("实验", "Experiments")
        dict[.experimentsTab] = ("实验", "Experiments")
        dict[.exportLabel] = ("导出本地数据", "Export Local Data JSON")
        dict[.exportReadyNo] = ("导出就绪: 包含原始样本 = 否", "Export ready: raw samples included = no")
        dict[.exportReadyYes] = ("导出就绪: 包含原始样本 = 是", "Export ready: raw samples included = yes")
        dict[.failLabel] = ("失败", "Fail")
        dict[.fallbackLabel] = ("降级方案", "Fallback")
        dict[.fallbacksLabel] = ("降级次数", "Fallbacks")
        dict[.feedbackALittle] = ("有一点", "A little")
        dict[.feedbackConfusing] = ("令人困惑", "Confusing")
        dict[.feedbackDescription] = ("这些问题帮助我们了解 OHeas 是否在有用性、清晰度和尊重你的注意力之间找到了合适的平衡。", "These questions help us understand if OHeas is hitting the right balance between helpfulness, clarity, and respect for your attention.")
        dict[.feedbackDidNotApply] = ("没有按建议做", "Didn't follow advice")
        dict[.feedbackEasy] = ("容易理解", "Easy to understand")
        dict[.feedbackMildConcern] = ("轻微顾虑", "Mild concern")
        dict[.feedbackNoConcerns] = ("没有顾虑", "No concerns")
        dict[.feedbackNotAtAll] = ("完全没有", "Not at all")
        dict[.feedbackNotHelpful] = ("没有帮助", "Not helpful")
        dict[.feedbackOkay] = ("一般", "Okay")
        dict[.feedbackRate] = ("反馈率", "Feedback rate")
        dict[.feedbackResubmitNote] = ("你可以再次提交以更新回复。", "You can submit again if you'd like to update your responses.")
        dict[.feedbackSavedMessage] = ("反馈已保存", "Feedback saved")
        dict[.feedbackSignificantConcern] = ("明显顾虑", "Significant concern")
        dict[.feedbackSomewhatHelpful] = ("有些帮助", "Somewhat helpful")
        dict[.feedbackStorageNote] = ("测试反馈存储在本地。如果启用了分析同意，会记录一条非敏感事件。绝不上传原始健康数据。", "Beta feedback is stored locally. If analytics consent is enabled, a non-sensitive event is recorded. No raw health data is ever uploaded.")
        dict[.feedbackThankYou] = ("你的反馈帮助塑造 OHeas。谢谢！", "Your feedback helps shape OHeas. Thank you.")
        dict[.feedbackTitle] = ("昨天的建议你做了吗？", "Did you follow yesterday's recommendation?")
        dict[.feedbackTooMuch] = ("太过了", "Too much")
        dict[.feedbackVeryHelpful] = ("非常有帮助", "Very helpful")
        dict[.firstRecommendationFallback] = ("设置完成后将生成第一条本地建议。", "A first local recommendation will be generated after setup.")
        dict[.firstRecommendationLabel] = ("首次建议", "First recommendation")
        dict[.generatingRecommendation] = ("正在生成建议...", "Generating recommendation...")
        dict[.goalLabel] = ("目标", "Goal")
        dict[.goalSetup] = ("目标设定", "Goal setup")
        dict[.goalType] = ("目标类型", "Goal Type")
        dict[.goalsTab] = ("目标", "Goals")
        dict[.granted] = ("已授权", "Granted")
        dict[.greetingAfternoon] = ("下午好", "Good Afternoon")
        dict[.greetingEvening] = ("晚上好", "Good Evening")
        dict[.greetingMorning] = ("早上好", "Good Morning")
        dict[.healthKitPermission] = ("健康权限", "HealthKit permission")
        dict[.healthPermissionsLabel] = ("健康权限", "Health Permissions")
        dict[.healthPermissionsNavTitle] = ("健康权限", "Health Permissions")
        dict[.heroSubtitleConnect] = ("连接 Apple Health 后，我会把睡眠、HRV 和心率整理成今日建议。", "Connect Apple Health to turn sleep, HRV, and heart rate into today's guidance.")
        dict[.heroSubtitleLow] = ("数据不足时，先参考主观感受，不要过度解读单日波动。", "With limited data, rely more on how you feel and avoid over-reading one-day changes.")
        dict[.heroSubtitleMedium] = ("部分指标缺失，建议按保守版本理解今日状态。", "Some metrics are missing, so treat today's state conservatively.")
        dict[.heroSubtitleStrongNoSignals] = ("数据完整，可以直接参考今日建议和计划。", "Data coverage is strong, so today's guidance is ready to use.")
        dict[.heroSubtitleStrongWithSignals] = ("数据完整，但有信号值得留意，建议按低风险计划执行。", "Data coverage is strong, with signals worth watching. Keep the plan low-risk.")
        dict[.trendsDayStripLabel] = ("选择日期", "Select Date")
        dict[.trendsDoneAction] = ("完成", "Done")
        dict[.trendsEmptyDescription] = ("使用几天后，这里将显示你的身体预算评分趋势。", "After a few days of use, your Body Budget Score trends will appear here.")
        dict[.trendsEmptyTitle] = ("暂无趋势数据", "No Trends Yet")
        dict[.trendsLoadingLabel] = ("正在加载趋势数据...", "Loading trends...")
        dict[.trendsNoScore] = ("无评分", "No score")
        dict[.trendsTab] = ("趋势", "Trends")
        dict[.hkEnergyDescription] = ("活动能量消耗基线，用于活动解读。", "Caloric expenditure baseline for activity interpretation.")
        dict[.hkExerciseDescription] = ("每日运动时长。", "Time spent exercising per day.")
        dict[.hkHRVDescription] = ("核心恢复信号。没有它，恢复状态不确定。", "Core recovery signal. Without it, recovery state is uncertain.")
        dict[.hkRHRDescription] = ("与 HRV 一起用于解读恢复和负荷。", "Used alongside HRV to interpret recovery and strain.")
        dict[.hkSleepDescription] = ("用于恢复基线和睡眠不足检测。", "Needed for recovery baseline and sleep deficit detection.")
        dict[.hkStepsDescription] = ("每日活动基线和低活动检测。", "Daily activity baseline and low-activity detection.")
        dict[.hkWorkoutsDescription] = ("训练历史，用于活动模式挖掘。", "Workout history for activity pattern mining.")
        dict[.howToFix] = ("如何修复", "How to Fix")
        dict[.hrvName] = ("心率变异性（HRV）", "Heart Rate Variability (HRV)")
        dict[.hypothesis] = ("假设", "Hypothesis")
        dict[.inlineResponseTitle] = ("快速回答", "Quick Answer")
        dict[.insightsTab] = ("洞察", "Insights")
        dict[.intervention] = ("干预", "Intervention")
        dict[.keySignals] = ("关键信号", "Key Signals")
        dict[.languageFooter] = ("界面语言会立即切换；内部提示词会保持结构化格式。", "The UI switches immediately. Agent JSON and prompts stay structured in English for LLM integration.")
        dict[.languageSection] = ("语言", "Language")
        dict[.languageSetting] = ("界面语言", "Language")
        dict[.lastSyncedLabel] = ("上次同步", "Last synced")
        dict[.learnedPattern] = ("可能模式", "Learned Pattern Candidate")
        dict[.liveMockValue] = ("真实或模拟", "Live or mock")
        dict[.llmDataControls] = ("模型数据控制", "LLM Data Controls")
        dict[.llmPayloadPreview] = ("模型载荷预览", "LLM Payload Preview")
        dict[.loadDemoScenario] = ("加载演示场景", "Load Demo Scenario")
        dict[.loading] = ("正在加载健康上下文", "Loading health context")
        dict[.loadingLabel] = ("加载中...", "Loading...")
        dict[.splashTagline] = ("身体状态 Agent", "Your Body State Agent")
        dict[.splashWakingUp] = ("正在唤醒…", "Waking up…")
        dict[.stepPillData] = ("数据", "Data")
        dict[.stepPillReady] = ("就绪", "Ready")
        dict[.localAnonymousLabel] = ("本地匿名", "Local anonymous")
        dict[.localBetaAnalytics] = ("本地测试分析", "Local Beta Analytics")
        dict[.localModeShort] = ("本地模式", "Local Mode")
        dict[.localOnlyModeLabel] = ("仅本地", "LocalOnly")
        dict[.longestStreak] = ("最长连续", "Longest streak")
        dict[.markCompleted] = ("标记完成", "Mark Completed")
        dict[.markSkipped] = ("标记跳过", "Mark Skipped")
        dict[.metricAdherence] = ("建议完成率", "Recommendation adherence")
        dict[.metricConfidence] = ("置信度", "Confidence")
        dict[.metricDataCoverage] = ("数据覆盖率", "Data coverage")
        dict[.metricDays] = ("指标天数", "Metric days")
        dict[.metricExperimentCompletion] = ("实验完成率", "Experiment completion")
        dict[.metricLikelyHelped] = ("可能有效", "Likely helped")
        dict[.metricPlanCompletion] = ("计划完成率", "Plan completion")
        dict[.metricsTab] = ("指标", "Metrics")
        dict[.minUnit] = ("分钟", "min")
        dict[.mockDevice] = ("模拟", "Mock")
        dict[.mockFallback] = ("由于健康数据不可用、未授权或暂无数据，当前使用模拟数据。", "Using mock data because HealthKit is unavailable, unauthorized, or empty.")
        dict[.mode] = ("模式", "Mode")
        dict[.modeLabel] = ("模式", "Mode")
        dict[.moreDetailsCount] = ("%d 项", "%d items")
        dict[.moreDetailsLabel] = ("更多详情", "More Details")
        dict[.moreDetailsReview] = ("复盘", "Review")
        dict[.mostPromising] = ("最有效干预", "Most Promising")
        dict[.neverLabel] = ("从未", "Never")
        dict[.newChatAction] = ("新对话", "New Chat")
        dict[.nextWeekSection] = ("下周", "Next Week")
        dict[.noBadgesYet] = ("继续使用，解锁更多成就！", "Keep going to unlock achievements!")
        dict[.noEffectivenessDescription] = ("请先加载数据或选择一个演示场景。", "Load data or a demo scenario first.")
        dict[.noEffectivenessReport] = ("暂无效果分析报告", "No effectiveness report")
        dict[.noExperiments] = ("暂无实验历史。", "No experiment history yet.")
        dict[.noMetrics] = ("暂无每日健康指标。", "No daily metrics available.")
        dict[.noRecentChats] = ("暂无历史对话", "No recent chats")
        dict[.noReview] = ("暂无昨日建议复盘。保存反馈并等待下一天数据后即可验证。", "No review is available yet. Save feedback and verify after the next day of data.")
        dict[.noStrongSignals] = ("没有发现明显偏离当前基线的强信号。", "No strong deviations from your current baseline.")
        dict[.noYesterdayRecommendation] = ("还没有可反馈的昨日建议。", "No yesterday recommendation is available for feedback.")
        dict[.notAsked] = ("未询问", "Not Asked")
        dict[.note] = ("备注", "Note")
        dict[.offlineBannerText] = ("本地模式 · 基础健康问题仍可回答。如需 AI 建议，请在设置中配置 API 密钥。", "Local mode · Basic health questions still work. Set up an API key in Settings for AI advice.")
        dict[.onboardingAINote] = ("AI 建议仅限于生活方式。未经同意，OHeas 使用本地规则。", "AI advice is lifestyle-only. Without consent, OHeas uses local rules.")
        dict[.onboardingRawSamplesNote] = ("原始健康样本默认关闭，不会上传。", "Raw HealthKit samples are off by default and are not uploaded.")
        dict[.openHealthSettings] = ("打开健康设置", "Open Health Settings")
        dict[.passLabel] = ("通过", "Pass")
        dict[.passwordLabel] = ("密码", "Password")
        dict[.pauseExperiment] = ("暂停", "Pause")
        dict[.pauseSync] = ("暂停同步", "Pause Sync")
        dict[.pendingLabel] = ("待同步", "Pending")
        dict[.permissionFixDescription] = ("在 设置 → 健康 → 数据访问与设备 → OHeas 中，启用所有读取类别。", "In Settings → Health → Data Access & Devices → OHeas, enable all read categories.")
        dict[.permissionMissingMessage] = ("项权限未授权。恢复基线至少需要睡眠、HRV 和静息心率数据。", "permission types are not granted. Recovery baseline requires at least sleep, HRV, and resting heart rate data.")
        dict[.permissionStatusTitle] = ("当前权限状态", "Current Permission Status")
        dict[.permissionWhyDescription] = ("OHeas 从健康数据读取聚合的睡眠、恢复和活动数据。没有权限，智能体无法建立你的个人基线、检测恢复信号或生成个性化建议。", "OHeas reads aggregate sleep, recovery, and activity data from Apple Health. Without permission, the agent cannot build your personal baseline, detect recovery signals, or generate personalized recommendations.")
        dict[.planDays] = ("计划天数", "Plan days")
        dict[.planStatusAdjusted] = ("已调整", "Adjusted")
        dict[.planStatusCompleted] = ("已完成", "Completed")
        dict[.planStatusPlanned] = ("待执行", "Planned")
        dict[.planStatusSkipped] = ("已跳过", "Skipped")
        dict[.planTab] = ("计划", "Plan")
        dict[.policyLabel] = ("政策", "Policy")
        dict[.privacyControlsLabel] = ("隐私控制", "Privacy Controls")
        dict[.privacyLLMDescription] = ("默认行为仅发送聚合摘要。原始健康样本保留在本地，除非显式启用。", "Default behavior sends only aggregate summaries. Raw HealthKit samples stay local unless explicitly enabled.")
        dict[.privacyLabel] = ("隐私", "Privacy")
        dict[.privacyNavTitle] = ("隐私", "Privacy")
        dict[.privacyPolicyDescription] = ("OHeas 是一款生活方式教练演示应用。它避免医疗诊断，不强制使用 AI，除非用户主动开启，否则不会将原始健康样本放入提示词中。", "OHeas is a lifestyle coaching demo. It avoids medical diagnosis, does not require LLM use, and keeps HealthKit raw samples out of prompts unless the user turns that on.")
        dict[.preferencesSection] = ("偏好", "Preferences")
        dict[.privacySection] = ("隐私与授权", "Privacy & Consent")
        dict[.promptNotReady] = ("提示词尚未生成。", "Prompt is not ready.")
        dict[.promptRegression] = ("提示词回归", "Prompt Regression")
        dict[.proposedExperiment] = ("智能体推荐实验", "Proposed Experiment")
        dict[.quickFeedback] = ("快速反馈", "Quick Feedback")
        dict[.realDevice] = ("真实设备", "Real Device")
        dict[.recentHeader] = ("最近", "Recent")
        dict[.recommendationLabel] = ("建议", "Recommendation")
        dict[.recommendationsLabel] = ("建议数", "Recommendations")
        dict[.recoverySection] = ("恢复", "Recovery")
        dict[.refresh] = ("刷新", "Refresh")
        dict[.regeneratePlan] = ("重新生成计划", "Regenerate Plan")
        dict[.regressionLabel] = ("回归", "Regression")
        dict[.remindersEnabled] = ("启用提醒", "Enable Reminders")
        dict[.resetConfirmButton] = ("重置本地数据", "Reset Local Data")
        dict[.resetDefaults] = ("恢复默认", "Reset Defaults")
        dict[.resetDemoData] = ("重置演示数据", "Reset Demo Data")
        dict[.resetDialogMessage] = ("这将清除本地智能体状态、演示数据、隐私设置和初始设置状态。不会修改健康数据。", "This clears local agent state, demo data, privacy settings, and onboarding state. It does not modify Apple Health.")
        dict[.resetDialogTitle] = ("重置 OHeas 本地数据？", "Reset local OHeas data?")
        dict[.resetLabel] = ("重置本地数据", "Reset Local Data")
        dict[.restingHeartRateName] = ("静息心率", "Resting Heart Rate")
        dict[.resumeSync] = ("恢复同步", "Resume Sync")
        dict[.retryAction] = ("重试", "Retry")
        dict[.reviewTab] = ("复盘", "Review")
        dict[.safetyAdjustedLabel] = ("已根据安全边界调整表达", "Adjusted for safety")
        dict[.safetyFlags] = ("安全标记", "Safety flags")
        dict[.saveCheckin] = ("保存今日打卡", "Save Today's Check-in")
        dict[.saveFeedback] = ("保存反馈", "Save Feedback")
        dict[.saveFeedbackAction] = ("保存反馈", "Save Feedback")
        dict[.saveLabel] = ("保存", "Save")
        dict[.savePrivacySettings] = ("保存隐私设置", "Save Privacy Settings")
        dict[.scenario] = ("场景", "Scenario")
        dict[.scoreFormat] = ("评分", "Score")
        dict[.scoreHistoryTitle] = ("30 天身体预算评分", "30-Day Body Budget Score")
        dict[.settingsDone] = ("完成", "Done")
        dict[.settingsTab] = ("设置", "Settings")
        dict[.settingsTitle] = ("设置", "Settings")
        dict[.shareAggregatedMetricsToggle] = ("共享聚合指标", "Share aggregated metrics")
        dict[.shareBetaAnalyticsToggle] = ("共享测试分析", "Share beta analytics")
        dict[.shareExperimentSummaryToggle] = ("共享实验摘要", "Share experiment summary")
        dict[.shareFeedbackSummaryToggle] = ("共享反馈摘要", "Share feedback summary")
        dict[.shareMemorySummaryToggle] = ("共享记忆摘要", "Share memory summary")
        dict[.sharePlanSummaryToggle] = ("共享计划摘要", "Share plan summary")
        dict[.signInFooter] = ("使用 Apple ID 登录以同步数据到云端", "Sign in with Apple ID to sync your data to the cloud")
        dict[.signInLabel] = ("登录", "Sign In")
        dict[.signOut] = ("退出登录", "Sign Out")
        dict[.signUpLabel] = ("注册", "Sign Up")
        dict[.signalSummaryGeneral] = ("检测到 %d 个提醒信号，可在更多详情中查看。", "%d signal(s) detected. See details below.")
        dict[.signalSummaryHigh] = ("检测到 %d 个高优先级信号，今天建议降低强度。", "%d high-priority signal(s) detected. Lower intensity today.")
        dict[.signedOutModeLabel] = ("已登出", "Signed out")
        dict[.sleepName] = ("睡眠", "Sleep")
        dict[.smallAction] = ("最小行动", "Small Action")
        dict[.soreness] = ("酸痛", "Soreness")
        dict[.stableLabel] = ("稳定", "Stable")
        dict[.startButton] = ("开始使用 OHeas", "Start OHeas")
        dict[.startExperiment] = ("开始实验", "Start Experiment")
        dict[.stepsName] = ("步数", "Steps")
        dict[.streaksSectionTitle] = ("连续记录", "Streaks")
        dict[.stress] = ("压力", "Stress")
        dict[.submitLabel] = ("提交", "Submit")
        dict[.syncFailures] = ("同步失败", "Sync failures")
        dict[.syncNavTitle] = ("同步", "Sync")
        dict[.syncNow] = ("立即同步", "Sync Now")
        dict[.syncStatusDescription] = ("云同步需要同步同意和后端配置。仅本地模式会将所有数据保留在设备上。", "Cloud sync requires cloud_sync consent and backend configuration. LocalOnly keeps all data on device.")
        dict[.syncStatusLabel] = ("同步状态", "Sync Status")
        dict[.syncStatusSection] = ("同步状态", "Sync Status")
        dict[.targetFrequency] = ("每周频率", "Weekly Frequency")
        dict[.targetMetrics] = ("目标指标", "Target Metrics")
        dict[.testingToolsFooter] = ("这些工具用于调试和测试，普通用户不需要关注。", "These tools are for debugging and testing. Regular users can ignore them.")
        dict[.testingToolsSection] = ("测试工具", "Testing Tools")
        dict[.dataManagementSection] = ("数据管理", "Data Management")
        dict[.developerMode] = ("开发者模式", "Developer Mode")
        dict[.thinkingBriefLabel] = ("正在思考...", "Thinking...")
        dict[.thinkingLabel] = ("正在思考", "Thinking")
        dict[.titlePlaceholder] = ("标题", "Title")
        dict[.todayBadge] = ("今天", "Today")
        dict[.todayConclusionConservative] = ("今天适合保守一点", "Take a Conservative Day")
        dict[.todayConclusionFillGaps] = ("先补齐身体信号", "Start by Filling Data Gaps")
        dict[.todayConclusionReady] = ("准备查看今日状态", "Ready for Today's Check-in")
        dict[.todayConclusionSteady] = ("今天状态比较稳定", "Today Looks Steady")
        dict[.todayConclusionWatchSignals] = ("留意几个身体信号", "Watch a Few Body Signals")
        dict[.todayPlan] = ("今日计划", "Today Plan")
        dict[.todayPlanHighlight] = ("今日计划", "Today's Plan")
        dict[.todayStatusLabel] = ("今日状态", "Today's Status")
        dict[.todayVsBaseline] = ("今日 vs 14 天基线", "Today vs 14-day baseline")
        dict[.tomorrowMetrics] = ("明日验证", "Tomorrow Verification")
        dict[.tomorrowVerification] = ("明天：验证睡眠时长、HRV、静息心率，以及活动量是否回到 14 天基线附近。", "Tomorrow: verify sleep duration, HRV, resting heart rate, and whether activity returns toward your 14-day baseline.")
        dict[.tonightAction] = ("今晚行动", "Tonight")
        dict[.unknown] = ("未知", "Unknown")
        dict[.updateAction] = ("更新建议", "Update")
        dict[.updatingAction] = ("更新中", "Updating")
        dict[.useLLMToggle] = ("使用 AI", "Use LLM")
        dict[.userLabel] = ("用户", "User")
        dict[.verificationResult] = ("验证结论", "Verification Result")
        dict[.versionLabel] = ("版本", "Version")
        dict[.viewDetailsAction] = ("看详情", "Details")
        dict[.weakestAreas] = ("最薄弱区域", "Weakest Areas")
        dict[.weeklyFrequency] = ("每周频率", "Weekly frequency")
        dict[.weeklyPlan] = ("本周计划", "Weekly Plan")
        dict[.weeklyReviewTab] = ("周复盘", "Weekly Review")
        dict[.welcomeTitle] = ("欢迎", "Welcome")
        dict[.whyExperiment] = ("为什么做这个实验", "Why This Experiment")
        dict[.whyHealthKitTitle] = ("为什么需要健康权限", "Why HealthKit Permissions Matter")
        dict[.workouts] = ("训练记录", "Workouts")
        dict[.workoutsName] = ("训练记录", "Workouts")
        dict[.yesterdayLabel] = ("昨天", "Yesterday")
        dict[.yesterdayRecommendation] = ("昨日建议", "Yesterday Recommendation")
        dict[.yesterdaySection] = ("昨日验证", "Yesterday")

        // HealthKit data-coverage view
        dict[.healthKitConnected] = ("已连接 Apple Health", "Connected to Apple Health")
        dict[.healthKitNotConnected] = ("未连接 HealthKit", "Not Connected to HealthKit")
        dict[.metricsHaveData] = ("项指标有数据", "metrics have data")
        dict[.dataAvailable] = ("有数据", "Data")
        dict[.dataPartial] = ("部分数据", "Partial")
        dict[.noData] = ("无数据", "No Data")
        return dict
    }

    func confidence(_ level: ConfidenceLevel) -> String {
        switch (self, level) {
        case (.chinese, .high): "高"
        case (.chinese, .medium): "中"
        case (.chinese, .low): "低"
        case (.english, _): level.rawValue
        }
    }

    func budgetCategory(_ category: BudgetCategory) -> String {
        switch (self, category) {
        case (.chinese, .excellent): "优秀"
        case (.chinese, .good): "良好"
        case (.chinese, .fair): "一般"
        case (.chinese, .strained): "偏低"
        case (.chinese, .depleted): "不足"
        case (.english, .excellent): "Excellent"
        case (.english, .good): "Good"
        case (.english, .fair): "Fair"
        case (.english, .strained): "Strained"
        case (.english, .depleted): "Depleted"
        }
    }

    func budgetScoreExplanation(_ category: BudgetCategory) -> String {
        switch category {
        case .excellent: text(.budgetScoreExcellent)
        case .good:      text(.budgetScoreGood)
        case .fair:      text(.budgetScoreFair)
        case .strained:  text(.budgetScoreStrained)
        case .depleted:  text(.budgetScoreDepleted)
        }
    }

    func status(_ status: MetricStatus) -> String {
        switch (self, status) {
        case (.chinese, .valid): "有效"
        case (.chinese, .missing): "缺失"
        case (.chinese, .partial): "部分"
        case (.english, _): status.rawValue.capitalized
        }
    }

    func metric(_ metric: HealthMetric) -> String {
        switch (self, metric) {
        case (.chinese, .sleepHours): "睡眠"
        case (.chinese, .hrv): "HRV"
        case (.chinese, .restingHeartRate): "静息心率"
        case (.chinese, .steps): "步数"
        case (.chinese, .activeEnergyKcal): "活动能量"
        case (.chinese, .exerciseMinutes): "运动分钟"
        case (.chinese, .workouts): "训练记录"
        case (.english, .sleepHours): "Sleep"
        case (.english, .hrv): "HRV"
        case (.english, .restingHeartRate): "Resting HR"
        case (.english, .steps): "Steps"
        case (.english, .activeEnergyKcal): "Active Energy"
        case (.english, .exerciseMinutes): "Exercise"
        case (.english, .workouts): "Workouts"
        }
    }

    func signal(_ type: SignalType) -> String {
        switch (self, type) {
        case (.chinese, .sleepLow): "睡眠偏低"
        case (.chinese, .hrvLow): "HRV 偏低"
        case (.chinese, .restingHeartHigh): "静息心率偏高"
        case (.chinese, .activityLow): "活动量偏低"
        case (.chinese, .activityHigh): "活动量偏高"
        case (.chinese, .recoveryUncertainDueToMissingData): "恢复判断不确定"
        case (.english, _): type.rawValue.replacingOccurrences(of: "_", with: " ")
        }
    }

    func signalExplanation(_ type: SignalType) -> String {
        switch (self, type) {
        case (.chinese, .sleepLow): "睡眠明显低于个人基线，今天更适合保护精力，避免过度消耗。"
        case (.chinese, .hrvLow): "HRV 明显低于个人基线，可能代表近期压力或恢复不足。这里不是医学诊断。"
        case (.chinese, .restingHeartHigh): "静息心率高于个人基线，今天建议降低强度，优先恢复。"
        case (.chinese, .activityLow): "活动量低于个人基线，可以用很小的轻活动目标重新建立节奏。"
        case (.chinese, .activityHigh): "活动量高于个人基线，今晚更需要支持恢复和稳定睡眠。"
        case (.chinese, .recoveryUncertainDueToMissingData): "多个关键恢复指标缺失，因此只给保守判断，不输出强恢复结论。"
        case (.english, _): ""
        }
    }

    func followupQuestion(for quality: DataQualityReport) -> String? {
        guard quality.shouldAskUserFollowup else { return nil }
        if self == .english {
            return quality.suggestedFollowupQuestion
        }

        let missingCritical = quality.perMetricStatus.filter { metric, status in
            [.sleepHours, .hrv, .restingHeartRate].contains(metric) && status == .missing
        }.map(\.key)

        if missingCritical.contains(.sleepHours) && missingCritical.contains(.hrv) {
            return "昨晚睡觉时有正常佩戴 Apple Watch 吗？"
        }
        if missingCritical.contains(.sleepHours) {
            return "昨晚是否有影响睡眠记录的特殊情况？"
        }
        if missingCritical.contains(.hrv) || missingCritical.contains(.restingHeartRate) {
            return "昨晚和今早 Apple Watch 是否正常佩戴？"
        }
        return "Apple 健康里是否有活动或训练相关权限未开启？"
    }

    func verificationMetric(_ metric: String) -> String {
        switch (self, metric) {
        case (.chinese, "sleepHours"): "睡眠时长"
        case (.chinese, "hrv"): "HRV"
        case (.chinese, "restingHeartRate"): "静息心率"
        case (.chinese, "subjectiveEnergy"): "主观精力"
        case (.chinese, "steps"): "步数"
        case (.chinese, "activeEnergyKcal"): "活动能量"
        case (.chinese, "exerciseMinutes"): "运动分钟数"
        case (.english, "sleepHours"): "Sleep"
        case (.english, "hrv"): "HRV"
        case (.english, "restingHeartRate"): "Resting HR"
        case (.english, "subjectiveEnergy"): "Energy"
        case (.english, "steps"): "Steps"
        case (.english, "activeEnergyKcal"): "Active energy"
        case (.english, "exerciseMinutes"): "Exercise minutes"
        default: metric
        }
    }

    func verificationDirection(_ direction: String) -> String {
        switch (self, direction) {
        case (.chinese, "increase_or_stable"): "上升或稳定"
        case (.chinese, "decrease_or_stable"): "下降或稳定"
        case (.chinese, "increase"): "上升"
        case (.chinese, "decrease"): "下降"
        case (.chinese, "stable"): "稳定"
        case (.english, "increase_or_stable"): "increase or stay stable"
        case (.english, "decrease_or_stable"): "decrease or stay stable"
        default: direction.replacingOccurrences(of: "_", with: " ")
        }
    }

    func severity(_ severity: SignalSeverity) -> String {
        switch (self, severity) {
        case (.chinese, .low): "低"
        case (.chinese, .medium): "中"
        case (.chinese, .high): "高"
        case (.english, _): severity.rawValue.capitalized
        }
    }

    func dataSource(_ source: HealthDataSource) -> String {
        switch (self, source) {
        case (.chinese, .appleHealth): "Apple 健康"
        case (.english, .appleHealth): "Apple Health"
#if DEBUG
        case (.chinese, .mock): "模拟演示"
        case (.english, .mock): "Mock demo"
#endif
        }
    }

    var missing: String {
        switch self {
        case .chinese: "缺失"
        case .english: "Missing"
        }
    }

    var minuteUnit: String {
        switch self {
        case .chinese: "分钟"
        case .english: "min"
        }
    }

    var bodyBudgetTitleForLowConfidence: String {
        switch self {
        case .chinese: "恢复判断不确定"
        case .english: "Recovery unclear"
        }
    }

    func bodyBudgetTitle(hasHighSignal: Bool, hasSignals: Bool) -> String {
        if hasHighSignal {
            switch self {
            case .chinese: return "身体预算偏低"
            case .english: return "Low body budget"
            }
        }
        if !hasSignals {
            switch self {
            case .chinese: return "身体预算平稳"
            case .english: return "Steady body budget"
            }
        }
        switch self {
        case .chinese: return "身体预算中等"
        case .english: return "Moderate body budget"
        }
    }

    func recommendation(quality: DataQualityReport, signals: [HealthSignal]) -> String {
        if quality.overallConfidence == .low {
            switch self {
            case .chinese: return "今天先保守处理：轻松散步、补水，不要把缺失的恢复数据解读成强趋势。"
            case .english: return "Keep the recommendation conservative today: take a short easy walk, hydrate, and avoid interpreting missing recovery data as a strong trend."
            }
        }
        if signals.contains(where: { $0.type == .sleepLow || $0.type == .hrvLow || $0.type == .restingHeartHigh }) {
            switch self {
            case .chinese: return "今晚只选一个支持恢复的小动作：早点收尾高强度任务、训练放轻，并尽量保持固定入睡窗口。"
            case .english: return "Choose one recovery-supporting move tonight: finish intense work earlier, keep training easy, and aim for a consistent sleep window."
            }
        }
        if signals.contains(where: { $0.type == .activityLow }) {
            switch self {
            case .chinese: return "用一个小活动目标即可：如果身体感觉还可以，轻松走 10 到 20 分钟。"
            case .english: return "Use a small movement target: 10 to 20 minutes of easy walking if you feel well."
            }
        }
        switch self {
        case .chinese: return "保持正常节奏，选一个简单锚点：日光、轻活动，或稳定的睡前时间。"
        case .english: return "Maintain normal routines and pick one simple anchor: daylight, easy movement, or a steady bedtime."
        }
    }
}

enum TextKey {
    case todayTab
    case planTab
    case goalsTab
    case metricsTab
    case agentTab
    case settingsTab
    case reviewTab
    case experimentsTab
    case settingsTitle
    case languageSection
    case languageFooter
    case aiSection
    case aiEnabled
    case remindersEnabled
    case aiFooter
    case loading
    case dataConfidence
    case keySignals
    case noStrongSignals
    case smallAction
    case tonightAction
    case tomorrowMetrics
    case feedbackTitle
    case adherence
    case energy
    case soreness
    case stress
    case note
    case saveFeedback
    case noYesterdayRecommendation
    case yesterdayRecommendation
    case verificationResult
    case learnedPattern
    case noReview
    case activeExperiment
    case proposedExperiment
    case experimentHistory
    case hypothesis
    case intervention
    case whyExperiment
    case targetMetrics
    case startExperiment
    case saveCheckin
    case pauseExperiment
    case completeExperiment
    case completedToday
    case noExperiments
    case weeklyPlan
    case todayPlan
    case adjusted
    case markCompleted
    case markSkipped
    case regeneratePlan
    case weeklyReviewTab
    case completionRate
    case addGoal
    case activeGoals
    case goalType
    case targetFrequency
    case deactivate
    case tomorrowVerification
    case mockFallback
    case noMetrics
    case todayVsBaseline
    case workouts
    case baseline
    case deltaUnavailable
    case contextNotReady
    case promptNotReady
    case debugPicker
    case insightsTab
    case yesterdaySection
    case debugSection
    case emptyTitle
    case emptyDescription
    case emptyPlanTitle
    case emptyPlanDescription
    case chatTab
    case chatPlaceholder
    case chatEmptyTitle
    case chatEmptyDescription
    // Settings
    case settingsDone
    case accountSection
    case accountLabel
    case syncStatusLabel
    case preferencesSection
    case privacySection
    case aiConsentLabel
    case cloudConsentLabel
    case betaAnalyticsConsentLabel
    case privacyControlsLabel
    case healthPermissionsLabel
    case betaSection
    case betaFeedbackLabel
    case betaAnalyticsLabel
    case demoModeLabel
    case evaluationLabel
    case agentContextLabel
    case exportLabel
    case exportReadyYes
    case exportReadyNo
    case resetLabel
    case resetDialogTitle
    case resetDialogMessage
    case resetConfirmButton
    case cancelButton
    case appSection
    case versionLabel
    case buildLabel
    case languageSetting
    // Chat
    case chatCoachName
    // Effectiveness
    case effectivenessTitle
    case noEffectivenessReport
    case mostPromising
    case weakestAreas
    // Onboarding
    case welcomeTitle
    case appSubtitle
    case appDisclaimer
    case startButton
    // Common
    case refresh
    case signOut
    case mode
    case email
    case granted
    case denied
    case notAsked
    case unknown
    // Navigation titles
    case betaAnalyticsNavTitle
    case betaFeedbackNavTitle
    case demoNavTitle
    case evaluationNavTitle
    case healthPermissionsNavTitle
    case privacyNavTitle
    case syncNavTitle
    // Section headers
    case localBetaAnalytics
    case quickFeedback
    case demoScenarioBuilder
    case currentDemo
    case evaluationResults
    case promptRegression
    case whyHealthKitTitle
    case permissionStatusTitle
    case howToFix
    case llmDataControls
    case llmPayloadPreview
    case policyLabel
    case syncStatusSection
    case recoverySection
    case activitySection
    case experimentSection
    case nextWeekSection
    // Metric tiles
    case metricAdherence
    case metricPlanCompletion
    case metricExperimentCompletion
    case metricLikelyHelped
    case metricDataCoverage
    case metricConfidence
    // Status labels
    case passLabel
    case failLabel
    case regressionLabel
    case changedLabel
    case stableLabel
    // Descriptions
    case analyticsDescription
    case feedbackResubmitNote
    case feedbackDescription
    case feedbackStorageNote
    case feedbackThankYou
    case demoDescription
    case noEffectivenessDescription
    case permissionWhyDescription
    case permissionFixDescription
    case privacyLLMDescription
    case privacyPolicyDescription
    case syncStatusDescription
    case generatingRecommendation
    case fallbackLabel
    case onboardingRawSamplesNote
    case onboardingAINote
    // HealthKit permission descriptions
    case hkSleepDescription
    case hkHRVDescription
    case hkRHRDescription
    case hkStepsDescription
    case hkEnergyDescription
    case hkExerciseDescription
    case hkWorkoutsDescription
    // Chat
    case coachSubtitle
    // Common
    case saveLabel
    case submitLabel
    case loadingLabel
    case recommendationLabel
    // Account
    case userLabel
    case localAnonymousLabel
    case passwordLabel
    case signInLabel
    case signUpLabel
    case signInFooter
    case localOnlyModeLabel
    case cloudSyncModeLabel
    case signedOutModeLabel
    case errorModeLabel
    // Score
    case scoreFormat
    // Privacy toggles
    case useLLMToggle
    case shareAggregatedMetricsToggle
    case shareMemorySummaryToggle
    case shareExperimentSummaryToggle
    case sharePlanSummaryToggle
    case shareFeedbackSummaryToggle
    case allowRawHealthSamplesToggle
    case savePrivacySettings
    case resetDefaults
    // Demo
    case scenario
    case loadDemoScenario
    case resetDemoData
    case modeLabel
    case demoValue
    case liveMockValue
    case metricDays
    case experimentsLabel
    case planDays
    // Sync
    case pendingLabel
    case lastSyncedLabel
    case neverLabel
    case syncNow
    case pauseSync
    case resumeSync
    // Analytics
    case appOpens
    case recommendationsLabel
    case feedbackRate
    case experimentCheckins
    case safetyFlags
    case fallbacksLabel
    case syncFailures
    // Permission names
    case sleepName
    case hrvName
    case restingHeartRateName
    case stepsName
    case activeEnergyName
    case exerciseMinutesName
    case workoutsName
    case permissionMissingMessage
    case openHealthSettings
    case checkingPermissions
    // Placeholders
    case titlePlaceholder
    case descriptionPlaceholder
    // Adjust
    case adjustLabel
    // Beta Readiness
    case realDevice
    case mockDevice
    // Onboarding cards
    case goalSetup
    case goalLabel
    case weeklyFrequency
    case healthKitPermission
    case continueLimitedMode
    case privacyLabel
    case continueButton
    case readyButton
    case baselineLimited
    case baselineReady
    case baselineLabel
    case firstRecommendationLabel
    case firstRecommendationFallback
    case enableCloudSyncToggle
    case shareBetaAnalyticsToggle
    // Beta feedback
    case betaFeedbackThanks
    case betaFeedbackHelpfulQuestion
    case betaFeedbackUnderstandableQuestion
    case betaFeedbackIntrusiveQuestion
    case betaFeedbackPrivacyQuestion
    case betaFeedbackFreeTextPlaceholder
    case betaFeedbackSubmit
    case betaFeedbackSubmittedTitle
    case betaFeedbackOK
    case feedbackVeryHelpful
    case feedbackSomewhatHelpful
    case feedbackNotHelpful
    case feedbackDidNotApply
    case feedbackEasy
    case feedbackOkay
    case feedbackConfusing
    case feedbackNotAtAll
    case feedbackALittle
    case feedbackTooMuch
    case feedbackNoConcerns
    case feedbackMildConcern
    case feedbackSignificantConcern
    // Units
    case minUnit
    case safetyAdjustedLabel
    // Greetings
    case greetingMorning
    case greetingAfternoon
    case greetingEvening
    // Phase 14 — TestFlight UX Polish
    case testingToolsSection
    case testingToolsFooter
    case dataManagementSection
    case developerMode
    case moreDetailsLabel
    case actionWhatLabel
    case actionWhyLabel
    case actionVerifyLabel
    case actionDurationLabel
    case saveFeedbackAction
    case feedbackSavedMessage
    case todayStatusLabel
    case todayPlanHighlight
    case chatContextEmptyTitle
    case chatContextEmptyHint
    case chatAskCoach
    case localModeShort
    case aiOnlineShort
    case planStatusCompleted
    case planStatusAdjusted
    case planStatusSkipped
    case planStatusPlanned
    // Phase 15 — Ternary migration
    case todayConclusionReady
    case todayConclusionFillGaps
    case todayConclusionConservative
    case todayConclusionWatchSignals
    case todayConclusionSteady
    case heroSubtitleConnect
    case heroSubtitleStrongNoSignals
    case heroSubtitleStrongWithSignals
    case heroSubtitleMedium
    case heroSubtitleLow
    case bodyBudgetExplanationHigh
    case bodyBudgetExplanationMedium
    case bodyBudgetExplanationLow
    case signalSummaryHigh
    case signalSummaryGeneral
    case updatingAction
    case updateAction
    case viewDetailsAction
    case moreDetailsReview
    case moreDetailsCount
    case daysCount
    case newChatAction
    case noRecentChats
    case deleteAction
    case recentHeader
    case chatHistoryTitle
    case doneAction
    case yesterdayLabel
    case retryAction
    case offlineBannerText
    case chatOfflineTitle
    case chatOfflineDescription
    case thinkingLabel
    case todayBadge
    case betaLabel
    // Phase 15 — Body Budget Score
    case budgetScoreExcellent
    case budgetScoreGood
    case budgetScoreFair
    case budgetScoreStrained
    case budgetScoreDepleted
    case budgetScoreFactorsLabel
    // Phase 19 — Follow-Up Chips
    case askRecoveryMeaning
    case askTomorrowPlan
    case askMoreDetails
    case askHistoricalValidation
    case chipDismissLabel
    case thinkingBriefLabel
    case inlineResponseTitle
    case askInChatLabel
    // Phase 20 — Gamification
    case achievementsTitle
    case streaksSectionTitle
    case badgesSectionTitle
    case currentStreak
    case longestStreak
    case daysUnit
    case badgeUnlockedToast
    case badgesCount
    case noBadgesYet
    // Badge names
    case badge7DayCheckIn
    case badge7DayCheckInDesc
    case badge30DayCheckIn
    case badge30DayCheckInDesc
    case badge7DayDataCoverage
    case badge7DayDataCoverageDesc
    case badge7DayPlanComplete
    case badge7DayPlanCompleteDesc
    case badgeFirstRecommendation
    case badgeFirstRecommendationDesc
    case badgeFirstExperiment
    case badgeFirstExperimentDesc
    case badgeFirstChat
    case badgeFirstChatDesc
    case badge10Feedbacks
    case badge10FeedbacksDesc
    case badge30Plans
    case badge30PlansDesc
    case badge3Experiments
    case badge3ExperimentsDesc
    case badgeScoreWeekExcellent
    case badgeScoreWeekExcellentDesc
    case badgeSleepConsistency
    case badgeSleepConsistencyDesc
    case badgeHRVImprovement
    case badgeHRVImprovementDesc
    case badgeAllMetricsViewed
    case badgeAllMetricsViewedDesc
    case badgeWeeklyReviewDone
    case badgeWeeklyReviewDoneDesc
    // Phase 21 — Trends / Timeline
    case trendsTab
    case scoreHistoryTitle
    case trendsEmptyTitle
    case trendsEmptyDescription
    case trendsLoadingLabel
    case trendsDayStripLabel
    case trendsNoScore
    case dayDetailTitle
    case dayDetailMetrics
    case dayDetailSignals
    case dayDetailFeedback
    case dayDetailNoFeedback
    case dayDetailScore
    case dayDetailFactors
    case dayCardSleep
    case dayCardHRV
    case dayCardSteps
    case dayCardMoreSignals
    case chartTrendLine
    case chartNoDataPoint
    case chartScoreUnit
    case dayDetailEnergy
    case dayDetailSoreness
    case dayDetailStress
    case trendsDoneAction

    // Splash
    case splashTagline
    case splashWakingUp
    case stepPillData
    case stepPillReady

    // HealthKit data-coverage view (replaces unreliable authorizationStatus(for:))
    case healthKitConnected
    case healthKitNotConnected
    case metricsHaveData
    case dataAvailable
    case dataPartial
    case noData
}

extension AppLanguage {
    var locale: Locale {
        switch self {
        case .chinese: Locale(identifier: "zh_CN")
        case .english: Locale(identifier: "en_US")
        }
    }

    func formatDate(_ date: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }

    func planIntensity(_ intensity: PlanIntensity) -> String {
        switch (self, intensity) {
        case (.chinese, .veryLow): "很低"
        case (.chinese, .low): "低"
        case (.chinese, .medium): "中等"
        case (.chinese, .high): "高"
        case (.english, .veryLow): "Very low"
        case (.english, .low): "Low"
        case (.english, .medium): "Medium"
        case (.english, .high): "High"
        }
    }

    func syncMode(_ mode: SyncMode) -> String {
        switch (self, mode) {
        case (.chinese, .localOnly): "仅本地"
        case (.chinese, .cloudEnabled): "云同步"
        case (.chinese, .paused): "已暂停"
        case (.english, .localOnly): "Local only"
        case (.english, .cloudEnabled): "Cloud enabled"
        case (.english, .paused): "Paused"
        }
    }

    var userIDLabel: String {
        switch self {
        case .chinese: "用户 ID"
        case .english: "User ID"
        }
    }

    var signInWithAppleLabel: String {
        switch self {
        case .chinese: "通过 Apple 登录"
        case .english: "Sign in with Apple"
        }
    }

    func coachState(_ state: CoachState) -> String {
        switch (self, state) {
        case (.chinese, .ready): "可行动"
        case (.chinese, .balanced): "平稳"
        case (.chinese, .recoveryLow): "恢复偏低"
        case (.chinese, .overloaded): "可能过载"
        case (.chinese, .uncertain): "不确定"
        case (.english, _): state.rawValue.replacingOccurrences(of: "_", with: " ")
        }
    }

    func adherence(_ adherence: FeedbackAdherence) -> String {
        switch (self, adherence) {
        case (.chinese, .completed): "完成"
        case (.chinese, .partial): "部分"
        case (.chinese, .skipped): "跳过"
        case (.english, _): adherence.rawValue.capitalized
        }
    }

    func verificationOutcome(_ outcome: VerificationOutcome) -> String {
        switch (self, outcome) {
        case (.chinese, .likelyHelped): "可能有效"
        case (.chinese, .neutral): "中性"
        case (.chinese, .unclear): "无法判断"
        case (.chinese, .likelyNotHelped): "可能未帮助"
        case (.english, _): outcome.rawValue.replacingOccurrences(of: "_", with: " ")
        }
    }

    func planType(_ type: DailyPlanType) -> String {
        switch (self, type) {
        case (.chinese, .rest): "休息"
        case (.chinese, .lightActivity): "轻活动"
        case (.chinese, .moderateCardio): "中等有氧"
        case (.chinese, .strength): "力量"
        case (.chinese, .mobility): "灵活性"
        case (.chinese, .sleepFocus): "睡眠优先"
        case (.chinese, .experimentFocus): "实验优先"
        case (.chinese, .dataCoverage): "数据覆盖"
        case (.english, _): type.rawValue.replacingOccurrences(of: "_", with: " ")
        }
    }

    func goalType(_ type: UserGoalType) -> String {
        switch (self, type) {
        case (.chinese, .improveEnergy): "提升精力"
        case (.chinese, .fatLoss): "减脂"
        case (.chinese, .buildConsistency): "建立稳定习惯"
        case (.chinese, .improveCardio): "提升心肺"
        case (.chinese, .improveSleep): "改善睡眠"
        case (.chinese, .recoveryFirst): "恢复优先"
        case (.chinese, .custom): "自定义"
        case (.english, _): type.rawValue.replacingOccurrences(of: "_", with: " ")
        }
    }
}

enum HealthDataSource: Equatable {
    case appleHealth
#if DEBUG
    case mock
#endif
}
