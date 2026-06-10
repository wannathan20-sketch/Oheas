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
        switch (self, key) {
        case (.chinese, .todayTab): "今日"
        case (.english, .todayTab): "Today"
        case (.chinese, .planTab): "计划"
        case (.english, .planTab): "Plan"
        case (.chinese, .goalsTab): "目标"
        case (.english, .goalsTab): "Goals"
        case (.chinese, .metricsTab): "指标"
        case (.english, .metricsTab): "Metrics"
        case (.chinese, .agentTab): "Agent"
        case (.english, .agentTab): "Agent"
        case (.chinese, .settingsTab): "设置"
        case (.english, .settingsTab): "Settings"
        case (.chinese, .chatTab): "对话"
        case (.english, .chatTab): "Chat"
        case (.chinese, .chatPlaceholder): "问问教练..."
        case (.english, .chatPlaceholder): "Ask your coach..."
        case (.chinese, .chatEmptyTitle): "和你的健康教练聊一聊"
        case (.english, .chatEmptyTitle): "Chat with your health coach"
        case (.chinese, .chatEmptyDescription): "可以问你的健康数据、恢复策略、运动计划，或者任何生活方式相关的问题。"
        case (.english, .chatEmptyDescription): "Ask about your health data, recovery, activity plans, or any lifestyle question."
        case (.chinese, .reviewTab): "复盘"
        case (.english, .reviewTab): "Review"
        case (.chinese, .experimentsTab): "实验"
        case (.english, .experimentsTab): "Experiments"
        case (.chinese, .settingsTitle): "设置"
        case (.english, .settingsTitle): "Settings"
        case (.chinese, .languageSection): "语言"
        case (.english, .languageSection): "Language"
        case (.chinese, .languageFooter): "界面语言会立即切换；Agent JSON 和 prompt 保持结构化英文，方便后续直接接入 LLM。"
        case (.english, .languageFooter): "The UI switches immediately. Agent JSON and prompts stay structured in English for LLM integration."
        case (.chinese, .aiSection): "AI"
        case (.english, .aiSection): "AI"
        case (.chinese, .aiEnabled): "启用 OpenAI"
        case (.english, .aiEnabled): "Enable OpenAI"
        case (.chinese, .remindersEnabled): "启用提醒"
        case (.english, .remindersEnabled): "Enable Reminders"
        case (.chinese, .aiFooter): "未配置 API key、关闭 AI 或网络失败时，会使用本地规则建议。"
        case (.english, .aiFooter): "When the API key is missing, AI is disabled, or networking fails, local rule-based recommendations are used."
        case (.chinese, .loading): "正在加载健康 context"
        case (.english, .loading): "Loading health context"
        case (.chinese, .dataConfidence): "数据可信度"
        case (.english, .dataConfidence): "Data confidence"
        case (.chinese, .keySignals): "关键信号"
        case (.english, .keySignals): "Key Signals"
        case (.chinese, .noStrongSignals): "没有发现明显偏离当前基线的强信号。"
        case (.english, .noStrongSignals): "No strong deviations from your current baseline."
        case (.chinese, .smallAction): "最小行动"
        case (.english, .smallAction): "Small Action"
        case (.chinese, .tonightAction): "今晚行动"
        case (.english, .tonightAction): "Tonight"
        case (.chinese, .tomorrowMetrics): "明日验证"
        case (.english, .tomorrowMetrics): "Tomorrow Verification"
        case (.chinese, .feedbackTitle): "昨天的建议你做了吗？"
        case (.english, .feedbackTitle): "Did you follow yesterday's recommendation?"
        case (.chinese, .adherence): "执行情况"
        case (.english, .adherence): "Adherence"
        case (.chinese, .energy): "今日精力"
        case (.english, .energy): "Energy"
        case (.chinese, .soreness): "酸痛"
        case (.english, .soreness): "Soreness"
        case (.chinese, .stress): "压力"
        case (.english, .stress): "Stress"
        case (.chinese, .note): "备注"
        case (.english, .note): "Note"
        case (.chinese, .saveFeedback): "保存反馈"
        case (.english, .saveFeedback): "Save Feedback"
        case (.chinese, .noYesterdayRecommendation): "还没有可反馈的昨日建议。"
        case (.english, .noYesterdayRecommendation): "No yesterday recommendation is available for feedback."
        case (.chinese, .yesterdayRecommendation): "昨日建议"
        case (.english, .yesterdayRecommendation): "Yesterday Recommendation"
        case (.chinese, .verificationResult): "验证结论"
        case (.english, .verificationResult): "Verification Result"
        case (.chinese, .learnedPattern): "可能模式"
        case (.english, .learnedPattern): "Learned Pattern Candidate"
        case (.chinese, .noReview): "暂无昨日建议复盘。保存反馈并等待下一天数据后即可验证。"
        case (.english, .noReview): "No review is available yet. Save feedback and verify after the next day of data."
        case (.chinese, .activeExperiment): "进行中的实验"
        case (.english, .activeExperiment): "Active Experiment"
        case (.chinese, .proposedExperiment): "Agent 推荐实验"
        case (.english, .proposedExperiment): "Proposed Experiment"
        case (.chinese, .experimentHistory): "实验历史"
        case (.english, .experimentHistory): "Experiment History"
        case (.chinese, .hypothesis): "假设"
        case (.english, .hypothesis): "Hypothesis"
        case (.chinese, .intervention): "干预"
        case (.english, .intervention): "Intervention"
        case (.chinese, .whyExperiment): "为什么做这个实验"
        case (.english, .whyExperiment): "Why This Experiment"
        case (.chinese, .targetMetrics): "目标指标"
        case (.english, .targetMetrics): "Target Metrics"
        case (.chinese, .startExperiment): "开始实验"
        case (.english, .startExperiment): "Start Experiment"
        case (.chinese, .saveCheckin): "保存今日 Check-in"
        case (.english, .saveCheckin): "Save Today's Check-in"
        case (.chinese, .pauseExperiment): "暂停"
        case (.english, .pauseExperiment): "Pause"
        case (.chinese, .completeExperiment): "结束并评估"
        case (.english, .completeExperiment): "Complete & Evaluate"
        case (.chinese, .completedToday): "今天已执行"
        case (.english, .completedToday): "Completed Today"
        case (.chinese, .noExperiments): "暂无实验历史。"
        case (.english, .noExperiments): "No experiment history yet."
        case (.chinese, .weeklyPlan): "本周计划"
        case (.english, .weeklyPlan): "Weekly Plan"
        case (.chinese, .todayPlan): "今日计划"
        case (.english, .todayPlan): "Today Plan"
        case (.chinese, .adjusted): "已调整"
        case (.english, .adjusted): "Adjusted"
        case (.chinese, .markCompleted): "标记完成"
        case (.english, .markCompleted): "Mark Completed"
        case (.chinese, .markSkipped): "标记跳过"
        case (.english, .markSkipped): "Mark Skipped"
        case (.chinese, .regeneratePlan): "重新生成计划"
        case (.english, .regeneratePlan): "Regenerate Plan"
        case (.chinese, .weeklyReviewTab): "周复盘"
        case (.english, .weeklyReviewTab): "Weekly Review"
        case (.chinese, .completionRate): "完成率"
        case (.english, .completionRate): "Completion Rate"
        case (.chinese, .addGoal): "添加目标"
        case (.english, .addGoal): "Add Goal"
        case (.chinese, .activeGoals): "当前目标"
        case (.english, .activeGoals): "Active Goals"
        case (.chinese, .goalType): "目标类型"
        case (.english, .goalType): "Goal Type"
        case (.chinese, .targetFrequency): "每周频率"
        case (.english, .targetFrequency): "Weekly Frequency"
        case (.chinese, .deactivate): "停用"
        case (.english, .deactivate): "Deactivate"
        case (.chinese, .tomorrowVerification): "明天：验证睡眠时长、HRV、静息心率，以及活动量是否回到 14 天基线附近。"
        case (.english, .tomorrowVerification): "Tomorrow: verify sleep duration, HRV, resting heart rate, and whether activity returns toward your 14-day baseline."
        case (.chinese, .mockFallback): "由于 HealthKit 不可用、未授权或暂无数据，当前使用 mock 数据。"
        case (.english, .mockFallback): "Using mock data because HealthKit is unavailable, unauthorized, or empty."
        case (.chinese, .noMetrics): "暂无每日健康指标。"
        case (.english, .noMetrics): "No daily metrics available."
        case (.chinese, .todayVsBaseline): "今日 vs 14 天基线"
        case (.english, .todayVsBaseline): "Today vs 14-day baseline"
        case (.chinese, .workouts): "训练记录"
        case (.english, .workouts): "Workouts"
        case (.chinese, .baseline): "基线"
        case (.english, .baseline): "Baseline"
        case (.chinese, .deltaUnavailable): "暂无差异"
        case (.english, .deltaUnavailable): "Delta unavailable"
        case (.chinese, .contextNotReady): "Context 尚未生成。"
        case (.english, .contextNotReady): "Context is not ready."
        case (.chinese, .promptNotReady): "Prompt 尚未生成。"
        case (.english, .promptNotReady): "Prompt is not ready."
        case (.chinese, .debugPicker): "调试"
        case (.english, .debugPicker): "Debug"
        case (.chinese, .insightsTab): "洞察"
        case (.english, .insightsTab): "Insights"
        case (.chinese, .yesterdaySection): "昨日验证"
        case (.english, .yesterdaySection): "Yesterday"
        case (.chinese, .debugSection): "调试"
        case (.english, .debugSection): "Debug"
        case (.chinese, .emptyTitle): "暂无健康数据"
        case (.english, .emptyTitle): "No Health Data"
        case (.chinese, .emptyDescription): "请检查 Apple Health 权限或连接 Apple Watch"
        case (.english, .emptyDescription): "Check Apple Health permissions or connect your Apple Watch"
        case (.chinese, .emptyPlanTitle): "暂无计划"
        case (.english, .emptyPlanTitle): "No Plan Yet"
        case (.chinese, .emptyPlanDescription): "加载健康数据或启用演示模式以生成周计划"
        case (.english, .emptyPlanDescription): "Load health data or enable demo mode to generate a weekly plan"
        // Settings
        case (.chinese, .settingsDone): "完成"
        case (.english, .settingsDone): "Done"
        case (.chinese, .accountSection): "账户与同步"
        case (.english, .accountSection): "Account & Sync"
        case (.chinese, .accountLabel): "账户"
        case (.english, .accountLabel): "Account"
        case (.chinese, .syncStatusLabel): "同步状态"
        case (.english, .syncStatusLabel): "Sync Status"
        case (.chinese, .privacySection): "隐私与同意"
        case (.english, .privacySection): "Privacy & Consent"
        case (.chinese, .aiConsentLabel): "AI 生活方式建议同意"
        case (.english, .aiConsentLabel): "AI lifestyle advice consent"
        case (.chinese, .cloudConsentLabel): "云端同步同意"
        case (.english, .cloudConsentLabel): "Cloud sync consent"
        case (.chinese, .betaAnalyticsConsentLabel): "Beta 分析同意"
        case (.english, .betaAnalyticsConsentLabel): "Beta analytics consent"
        case (.chinese, .privacyControlsLabel): "隐私控制"
        case (.english, .privacyControlsLabel): "Privacy Controls"
        case (.chinese, .healthPermissionsLabel): "健康权限"
        case (.english, .healthPermissionsLabel): "Health Permissions"
        case (.chinese, .betaSection): "Beta 工具"
        case (.english, .betaSection): "Beta Tools"
        case (.chinese, .betaFeedbackLabel): "Beta 反馈"
        case (.english, .betaFeedbackLabel): "Beta Feedback"
        case (.chinese, .betaAnalyticsLabel): "Beta 分析"
        case (.english, .betaAnalyticsLabel): "Beta Analytics"
        case (.chinese, .demoModeLabel): "演示模式"
        case (.english, .demoModeLabel): "Demo Mode"
        case (.chinese, .evaluationLabel): "评测"
        case (.english, .evaluationLabel): "Evaluation"
        case (.chinese, .agentContextLabel): "Agent 上下文"
        case (.english, .agentContextLabel): "Agent Context"
        case (.chinese, .exportLabel): "导出本地数据 JSON"
        case (.english, .exportLabel): "Export Local Data JSON"
        case (.chinese, .exportReadyYes): "导出就绪: 包含原始样本 = 是"
        case (.english, .exportReadyYes): "Export ready: raw samples included = yes"
        case (.chinese, .exportReadyNo): "导出就绪: 包含原始样本 = 否"
        case (.english, .exportReadyNo): "Export ready: raw samples included = no"
        case (.chinese, .resetLabel): "重置本地数据"
        case (.english, .resetLabel): "Reset Local Data"
        case (.chinese, .resetDialogTitle): "重置 OHeas 本地数据？"
        case (.english, .resetDialogTitle): "Reset local OHeas data?"
        case (.chinese, .resetDialogMessage): "这将清除本地 agent 状态、演示数据、隐私设置和 onboarding 状态。不会修改 Apple Health。"
        case (.english, .resetDialogMessage): "This clears local agent state, demo data, privacy settings, and onboarding state. It does not modify Apple Health."
        case (.chinese, .resetConfirmButton): "重置本地数据"
        case (.english, .resetConfirmButton): "Reset Local Data"
        case (.chinese, .cancelButton): "取消"
        case (.english, .cancelButton): "Cancel"
        case (.chinese, .appSection): "关于"
        case (.english, .appSection): "App"
        case (.chinese, .versionLabel): "版本"
        case (.english, .versionLabel): "Version"
        case (.chinese, .buildLabel): "构建号"
        case (.english, .buildLabel): "Build"
        case (.chinese, .languageSetting): "界面语言"
        case (.english, .languageSetting): "Language"
        // Chat
        case (.chinese, .chatCoachName): "健康教练"
        case (.english, .chatCoachName): "Coach"
        // Effectiveness
        case (.chinese, .effectivenessTitle): "效果分析"
        case (.english, .effectivenessTitle): "Effectiveness"
        case (.chinese, .noEffectivenessReport): "暂无效果分析报告"
        case (.english, .noEffectivenessReport): "No effectiveness report"
        case (.chinese, .mostPromising): "最有效干预"
        case (.english, .mostPromising): "Most Promising"
        case (.chinese, .weakestAreas): "最薄弱区域"
        case (.english, .weakestAreas): "Weakest Areas"
        // Onboarding
        case (.chinese, .greetingMorning): "早上好"
        case (.english, .greetingMorning): "Good Morning"
        case (.chinese, .greetingAfternoon): "下午好"
        case (.english, .greetingAfternoon): "Good Afternoon"
        case (.chinese, .greetingEvening): "晚上好"
        case (.english, .greetingEvening): "Good Evening"
        case (.chinese, .welcomeTitle): "欢迎"
        case (.english, .welcomeTitle): "Welcome"
        case (.chinese, .appSubtitle): "BodyLoop for OHeas"
        case (.english, .appSubtitle): "BodyLoop for OHeas"
        case (.chinese, .appDisclaimer): "基于 Apple Watch 数据的个人生活方式健康助手。不能替代医疗诊断和专业医疗护理。"
        case (.english, .appDisclaimer): "A lifestyle health agent for Apple Watch summaries. It does not diagnose disease and should not replace qualified medical care."
        case (.chinese, .startButton): "开始使用 OHeas"
        case (.english, .startButton): "Start OHeas"
        // Common
        case (.chinese, .refresh): "刷新"
        case (.english, .refresh): "Refresh"
        case (.chinese, .signOut): "退出登录"
        case (.english, .signOut): "Sign Out"
        case (.chinese, .mode): "模式"
        case (.english, .mode): "Mode"
        case (.chinese, .email): "邮箱"
        case (.english, .email): "Email"
        case (.chinese, .granted): "已授权"
        case (.english, .granted): "Granted"
        case (.chinese, .denied): "已拒绝"
        case (.english, .denied): "Denied"
        case (.chinese, .notAsked): "未询问"
        case (.english, .notAsked): "Not Asked"
        case (.chinese, .unknown): "未知"
        case (.english, .unknown): "Unknown"
        // Navigation titles
        case (.chinese, .betaAnalyticsNavTitle): "Beta 分析"
        case (.english, .betaAnalyticsNavTitle): "Beta Analytics"
        case (.chinese, .betaFeedbackNavTitle): "Beta 反馈"
        case (.english, .betaFeedbackNavTitle): "Beta Feedback"
        case (.chinese, .demoNavTitle): "演示"
        case (.english, .demoNavTitle): "Demo"
        case (.chinese, .evaluationNavTitle): "评测"
        case (.english, .evaluationNavTitle): "Evaluation"
        case (.chinese, .healthPermissionsNavTitle): "健康权限"
        case (.english, .healthPermissionsNavTitle): "Health Permissions"
        case (.chinese, .privacyNavTitle): "隐私"
        case (.english, .privacyNavTitle): "Privacy"
        case (.chinese, .syncNavTitle): "同步"
        case (.english, .syncNavTitle): "Sync"
        // Section headers
        case (.chinese, .localBetaAnalytics): "本地 Beta 分析"
        case (.english, .localBetaAnalytics): "Local Beta Analytics"
        case (.chinese, .quickFeedback): "快速反馈"
        case (.english, .quickFeedback): "Quick Feedback"
        case (.chinese, .demoScenarioBuilder): "演示场景构建器"
        case (.english, .demoScenarioBuilder): "Demo Scenario Builder"
        case (.chinese, .currentDemo): "当前演示"
        case (.english, .currentDemo): "Current Demo"
        case (.chinese, .evaluationResults): "评测结果"
        case (.english, .evaluationResults): "Evaluation Results"
        case (.chinese, .promptRegression): "提示词回归"
        case (.english, .promptRegression): "Prompt Regression"
        case (.chinese, .whyHealthKitTitle): "为什么需要健康权限"
        case (.english, .whyHealthKitTitle): "Why HealthKit Permissions Matter"
        case (.chinese, .permissionStatusTitle): "当前权限状态"
        case (.english, .permissionStatusTitle): "Current Permission Status"
        case (.chinese, .howToFix): "如何修复"
        case (.english, .howToFix): "How to Fix"
        case (.chinese, .llmDataControls): "LLM 数据控制"
        case (.english, .llmDataControls): "LLM Data Controls"
        case (.chinese, .llmPayloadPreview): "LLM 载荷预览"
        case (.english, .llmPayloadPreview): "LLM Payload Preview"
        case (.chinese, .policyLabel): "政策"
        case (.english, .policyLabel): "Policy"
        case (.chinese, .syncStatusSection): "同步状态"
        case (.english, .syncStatusSection): "Sync Status"
        case (.chinese, .recoverySection): "恢复"
        case (.english, .recoverySection): "Recovery"
        case (.chinese, .activitySection): "活动"
        case (.english, .activitySection): "Activity"
        case (.chinese, .experimentSection): "实验"
        case (.english, .experimentSection): "Experiment"
        case (.chinese, .nextWeekSection): "下周"
        case (.english, .nextWeekSection): "Next Week"
        // Metric tiles
        case (.chinese, .metricAdherence): "建议完成率"
        case (.english, .metricAdherence): "Recommendation adherence"
        case (.chinese, .metricPlanCompletion): "计划完成率"
        case (.english, .metricPlanCompletion): "Plan completion"
        case (.chinese, .metricExperimentCompletion): "实验完成率"
        case (.english, .metricExperimentCompletion): "Experiment completion"
        case (.chinese, .metricLikelyHelped): "可能有效"
        case (.english, .metricLikelyHelped): "Likely helped"
        case (.chinese, .metricDataCoverage): "数据覆盖率"
        case (.english, .metricDataCoverage): "Data coverage"
        case (.chinese, .metricConfidence): "置信度"
        case (.english, .metricConfidence): "Confidence"
        // Status labels
        case (.chinese, .passLabel): "通过"
        case (.english, .passLabel): "Pass"
        case (.chinese, .failLabel): "失败"
        case (.english, .failLabel): "Fail"
        case (.chinese, .regressionLabel): "回归"
        case (.english, .regressionLabel): "Regression"
        case (.chinese, .changedLabel): "已变更"
        case (.english, .changedLabel): "Changed"
        case (.chinese, .stableLabel): "稳定"
        case (.english, .stableLabel): "Stable"
        // Descriptions
        case (.chinese, .analyticsDescription): "分析属性仅限于非敏感产品摘要，绝不包含原始健康样本。"
        case (.english, .analyticsDescription): "Analytics properties are limited to non-sensitive product summaries, never raw health samples."
        case (.chinese, .feedbackResubmitNote): "你可以再次提交以更新回复。"
        case (.english, .feedbackResubmitNote): "You can submit again if you'd like to update your responses."
        case (.chinese, .feedbackDescription): "这些问题帮助我们了解 OHeas 是否在有用性、清晰度和尊重你的注意力之间找到了合适的平衡。"
        case (.english, .feedbackDescription): "These questions help us understand if OHeas is hitting the right balance between helpfulness, clarity, and respect for your attention."
        case (.chinese, .feedbackStorageNote): "Beta 反馈存储在本地。如果启用了分析同意，会记录一条非敏感事件。绝不上传原始健康数据。"
        case (.english, .feedbackStorageNote): "Beta feedback is stored locally. If analytics consent is enabled, a non-sensitive event is recorded. No raw health data is ever uploaded."
        case (.chinese, .feedbackThankYou): "你的反馈帮助塑造 OHeas。谢谢！"
        case (.english, .feedbackThankYou): "Your feedback helps shape OHeas. Thank you."
        case (.chinese, .demoDescription): "演示模式将明确生成的本地数据写入 OHeas 存储。不会修改 Apple Health。"
        case (.english, .demoDescription): "Demo mode writes clearly generated local data to OHeas stores. It does not modify Apple Health."
        case (.chinese, .noEffectivenessDescription): "请先加载数据或选择一个演示场景。"
        case (.english, .noEffectivenessDescription): "Load data or a demo scenario first."
        case (.chinese, .permissionWhyDescription): "OHeas 从 Apple Health 读取聚合的睡眠、恢复和活动数据。没有权限，agent 无法建立你的个人基线、检测恢复信号或生成个性化建议。"
        case (.english, .permissionWhyDescription): "OHeas reads aggregate sleep, recovery, and activity data from Apple Health. Without permission, the agent cannot build your personal baseline, detect recovery signals, or generate personalized recommendations."
        case (.chinese, .permissionFixDescription): "在 设置 → 健康 → 数据访问与设备 → OHeas 中，启用所有读取类别。"
        case (.english, .permissionFixDescription): "In Settings → Health → Data Access & Devices → OHeas, enable all read categories."
        case (.chinese, .privacyLLMDescription): "默认行为仅发送聚合摘要。原始 HealthKit 样本保留在本地，除非显式启用。"
        case (.english, .privacyLLMDescription): "Default behavior sends only aggregate summaries. Raw HealthKit samples stay local unless explicitly enabled."
        case (.chinese, .privacyPolicyDescription): "OHeas 是一款生活方式教练演示应用。它避免医疗诊断，不强制使用 LLM，除非用户主动开启，否则不会将 HealthKit 原始样本放入提示词中。"
        case (.english, .privacyPolicyDescription): "OHeas is a lifestyle coaching demo. It avoids medical diagnosis, does not require LLM use, and keeps HealthKit raw samples out of prompts unless the user turns that on."
        case (.chinese, .syncStatusDescription): "云同步需要 cloud_sync 同意和后端配置。LocalOnly 将所有数据保留在设备上。"
        case (.english, .syncStatusDescription): "Cloud sync requires cloud_sync consent and backend configuration. LocalOnly keeps all data on device."
        case (.chinese, .generatingRecommendation): "正在生成建议..."
        case (.english, .generatingRecommendation): "Generating recommendation..."
        case (.chinese, .fallbackLabel): "降级方案"
        case (.english, .fallbackLabel): "Fallback"
        case (.chinese, .onboardingRawSamplesNote): "原始 HealthKit 样本默认关闭，不会上传。"
        case (.english, .onboardingRawSamplesNote): "Raw HealthKit samples are off by default and are not uploaded."
        case (.chinese, .onboardingAINote): "AI 建议仅限于生活方式。未经同意，OHeas 使用本地规则。"
        case (.english, .onboardingAINote): "AI advice is lifestyle-only. Without consent, OHeas uses local rules."
        // HealthKit permission descriptions
        case (.chinese, .hkSleepDescription): "用于恢复基线和睡眠不足检测。"
        case (.english, .hkSleepDescription): "Needed for recovery baseline and sleep deficit detection."
        case (.chinese, .hkHRVDescription): "核心恢复信号。没有它，恢复状态不确定。"
        case (.english, .hkHRVDescription): "Core recovery signal. Without it, recovery state is uncertain."
        case (.chinese, .hkRHRDescription): "与 HRV 一起用于解读恢复和负荷。"
        case (.english, .hkRHRDescription): "Used alongside HRV to interpret recovery and strain."
        case (.chinese, .hkStepsDescription): "每日活动基线和低活动检测。"
        case (.english, .hkStepsDescription): "Daily activity baseline and low-activity detection."
        case (.chinese, .hkEnergyDescription): "活动能量消耗基线，用于活动解读。"
        case (.english, .hkEnergyDescription): "Caloric expenditure baseline for activity interpretation."
        case (.chinese, .hkExerciseDescription): "每日运动时长。"
        case (.english, .hkExerciseDescription): "Time spent exercising per day."
        case (.chinese, .hkWorkoutsDescription): "训练历史，用于活动模式挖掘。"
        case (.english, .hkWorkoutsDescription): "Workout history for activity pattern mining."
        // Chat
        case (.chinese, .coachSubtitle): "基于你的健康数据的个人 AI 教练"
        case (.english, .coachSubtitle): "Your personal AI coach powered by health data"
        // Common
        case (.chinese, .saveLabel): "保存"
        case (.english, .saveLabel): "Save"
        case (.chinese, .submitLabel): "提交"
        case (.english, .submitLabel): "Submit"
        case (.chinese, .loadingLabel): "加载中..."
        case (.english, .loadingLabel): "Loading..."
        case (.chinese, .recommendationLabel): "建议"
        case (.english, .recommendationLabel): "Recommendation"
        // Account
        case (.chinese, .userLabel): "用户"
        case (.english, .userLabel): "User"
        case (.chinese, .localAnonymousLabel): "本地匿名"
        case (.english, .localAnonymousLabel): "Local anonymous"
        case (.chinese, .passwordLabel): "密码"
        case (.english, .passwordLabel): "Password"
        case (.chinese, .signInLabel): "登录"
        case (.english, .signInLabel): "Sign In"
        case (.chinese, .signUpLabel): "注册"
        case (.english, .signUpLabel): "Sign Up"
        case (.chinese, .localOnlyModeLabel): "仅本地"
        case (.english, .localOnlyModeLabel): "LocalOnly"
        case (.chinese, .cloudSyncModeLabel): "云同步"
        case (.english, .cloudSyncModeLabel): "Cloud Sync"
        case (.chinese, .signedOutModeLabel): "已登出"
        case (.english, .signedOutModeLabel): "Signed out"
        case (.chinese, .errorModeLabel): "错误"
        case (.english, .errorModeLabel): "Error"
        // Score
        case (.chinese, .scoreFormat): "评分"
        case (.english, .scoreFormat): "Score"
        // Privacy toggles
        case (.chinese, .useLLMToggle): "使用 LLM"
        case (.english, .useLLMToggle): "Use LLM"
        case (.chinese, .shareAggregatedMetricsToggle): "共享聚合指标"
        case (.english, .shareAggregatedMetricsToggle): "Share aggregated metrics"
        case (.chinese, .shareMemorySummaryToggle): "共享记忆摘要"
        case (.english, .shareMemorySummaryToggle): "Share memory summary"
        case (.chinese, .shareExperimentSummaryToggle): "共享实验摘要"
        case (.english, .shareExperimentSummaryToggle): "Share experiment summary"
        case (.chinese, .sharePlanSummaryToggle): "共享计划摘要"
        case (.english, .sharePlanSummaryToggle): "Share plan summary"
        case (.chinese, .shareFeedbackSummaryToggle): "共享反馈摘要"
        case (.english, .shareFeedbackSummaryToggle): "Share feedback summary"
        case (.chinese, .allowRawHealthSamplesToggle): "允许原始健康样本"
        case (.english, .allowRawHealthSamplesToggle): "Allow raw Health samples"
        case (.chinese, .savePrivacySettings): "保存隐私设置"
        case (.english, .savePrivacySettings): "Save Privacy Settings"
        case (.chinese, .resetDefaults): "恢复默认"
        case (.english, .resetDefaults): "Reset Defaults"
        // Demo
        case (.chinese, .scenario): "场景"
        case (.english, .scenario): "Scenario"
        case (.chinese, .loadDemoScenario): "加载演示场景"
        case (.english, .loadDemoScenario): "Load Demo Scenario"
        case (.chinese, .resetDemoData): "重置演示数据"
        case (.english, .resetDemoData): "Reset Demo Data"
        case (.chinese, .modeLabel): "模式"
        case (.english, .modeLabel): "Mode"
        case (.chinese, .demoValue): "演示"
        case (.english, .demoValue): "Demo"
        case (.chinese, .liveMockValue): "真实或模拟"
        case (.english, .liveMockValue): "Live or mock"
        case (.chinese, .metricDays): "指标天数"
        case (.english, .metricDays): "Metric days"
        case (.chinese, .experimentsLabel): "实验"
        case (.english, .experimentsLabel): "Experiments"
        case (.chinese, .planDays): "计划天数"
        case (.english, .planDays): "Plan days"
        // Sync
        case (.chinese, .pendingLabel): "待同步"
        case (.english, .pendingLabel): "Pending"
        case (.chinese, .lastSyncedLabel): "上次同步"
        case (.english, .lastSyncedLabel): "Last synced"
        case (.chinese, .neverLabel): "从未"
        case (.english, .neverLabel): "Never"
        case (.chinese, .syncNow): "立即同步"
        case (.english, .syncNow): "Sync Now"
        case (.chinese, .pauseSync): "暂停同步"
        case (.english, .pauseSync): "Pause Sync"
        case (.chinese, .resumeSync): "恢复同步"
        case (.english, .resumeSync): "Resume Sync"
        // Analytics
        case (.chinese, .appOpens): "App 打开次数"
        case (.english, .appOpens): "App opens"
        case (.chinese, .recommendationsLabel): "建议数"
        case (.english, .recommendationsLabel): "Recommendations"
        case (.chinese, .feedbackRate): "反馈率"
        case (.english, .feedbackRate): "Feedback rate"
        case (.chinese, .experimentCheckins): "实验签到"
        case (.english, .experimentCheckins): "Experiment check-ins"
        case (.chinese, .safetyFlags): "安全标记"
        case (.english, .safetyFlags): "Safety flags"
        case (.chinese, .fallbacksLabel): "降级次数"
        case (.english, .fallbacksLabel): "Fallbacks"
        case (.chinese, .syncFailures): "同步失败"
        case (.english, .syncFailures): "Sync failures"
        // Permission names
        case (.chinese, .sleepName): "睡眠"
        case (.english, .sleepName): "Sleep"
        case (.chinese, .hrvName): "心率变异性（HRV）"
        case (.english, .hrvName): "Heart Rate Variability (HRV)"
        case (.chinese, .restingHeartRateName): "静息心率"
        case (.english, .restingHeartRateName): "Resting Heart Rate"
        case (.chinese, .stepsName): "步数"
        case (.english, .stepsName): "Steps"
        case (.chinese, .activeEnergyName): "活动能量"
        case (.english, .activeEnergyName): "Active Energy"
        case (.chinese, .exerciseMinutesName): "运动分钟"
        case (.english, .exerciseMinutesName): "Exercise Minutes"
        case (.chinese, .workoutsName): "训练记录"
        case (.english, .workoutsName): "Workouts"
        case (.chinese, .permissionMissingMessage): "项权限未授权。恢复基线至少需要睡眠、HRV 和静息心率数据。"
        case (.english, .permissionMissingMessage): "permission types are not granted. Recovery baseline requires at least sleep, HRV, and resting heart rate data."
        case (.chinese, .openHealthSettings): "打开健康设置"
        case (.english, .openHealthSettings): "Open Health Settings"
        case (.chinese, .checkingPermissions): "正在检查权限..."
        case (.english, .checkingPermissions): "Checking permissions..."
        // Placeholders
        case (.chinese, .titlePlaceholder): "标题"
        case (.english, .titlePlaceholder): "Title"
        case (.chinese, .descriptionPlaceholder): "描述"
        case (.english, .descriptionPlaceholder): "Description"
        // Adjust
        case (.chinese, .adjustLabel): "调整"
        case (.english, .adjustLabel): "Adjust"
        // Beta Readiness
        case (.chinese, .realDevice): "真实设备"
        case (.english, .realDevice): "Real Device"
        case (.chinese, .mockDevice): "模拟"
        case (.english, .mockDevice): "Mock"
        // Onboarding cards
        case (.chinese, .goalSetup): "目标设定"
        case (.english, .goalSetup): "Goal setup"
        case (.chinese, .goalLabel): "目标"
        case (.english, .goalLabel): "Goal"
        case (.chinese, .weeklyFrequency): "每周频率"
        case (.english, .weeklyFrequency): "Weekly frequency"
        case (.chinese, .healthKitPermission): "健康权限"
        case (.english, .healthKitPermission): "HealthKit permission"
        case (.chinese, .continueLimitedMode): "以受限模式继续"
        case (.english, .continueLimitedMode): "Continue with limited mode"
        case (.chinese, .privacyLabel): "隐私"
        case (.english, .privacyLabel): "Privacy"
        case (.chinese, .baselineLabel): "基线"
        case (.english, .baselineLabel): "Baseline"
        case (.chinese, .firstRecommendationLabel): "首次建议"
        case (.english, .firstRecommendationLabel): "First recommendation"
        case (.chinese, .firstRecommendationFallback): "设置完成后将生成第一条本地建议。"
        case (.english, .firstRecommendationFallback): "A first local recommendation will be generated after setup."
        case (.chinese, .enableCloudSyncToggle): "启用云端同步"
        case (.english, .enableCloudSyncToggle): "Enable cloud sync"
        case (.chinese, .shareBetaAnalyticsToggle): "共享 Beta 分析"
        case (.english, .shareBetaAnalyticsToggle): "Share beta analytics"
        // Beta feedback
        case (.chinese, .betaFeedbackThanks): "感谢你的反馈"
        case (.english, .betaFeedbackThanks): "Thanks for your feedback"
        case (.chinese, .betaFeedbackHelpfulQuestion): "今天的建议对你有帮助吗？"
        case (.english, .betaFeedbackHelpfulQuestion): "Was today's recommendation helpful?"
        case (.chinese, .betaFeedbackUnderstandableQuestion): "建议是否容易理解？"
        case (.english, .betaFeedbackUnderstandableQuestion): "Was the advice easy to understand?"
        case (.chinese, .betaFeedbackIntrusiveQuestion): "今天 App 是否打扰到你了？"
        case (.english, .betaFeedbackIntrusiveQuestion): "Did the app feel overly intrusive today?"
        case (.chinese, .betaFeedbackPrivacyQuestion): "你有隐私方面的顾虑吗？"
        case (.english, .betaFeedbackPrivacyQuestion): "Do you have any privacy concerns?"
        case (.chinese, .betaFeedbackFreeTextPlaceholder): "还有什么想分享的吗？（选填）"
        case (.english, .betaFeedbackFreeTextPlaceholder): "Anything else you'd like to share? (optional)"
        case (.chinese, .betaFeedbackSubmit): "提交 Beta 反馈"
        case (.english, .betaFeedbackSubmit): "Submit Beta Feedback"
        case (.chinese, .betaFeedbackSubmittedTitle): "已提交"
        case (.english, .betaFeedbackSubmittedTitle): "Submitted"
        case (.chinese, .betaFeedbackOK): "好的"
        case (.english, .betaFeedbackOK): "OK"
        case (.chinese, .feedbackVeryHelpful): "非常有帮助"
        case (.english, .feedbackVeryHelpful): "Very helpful"
        case (.chinese, .feedbackSomewhatHelpful): "有些帮助"
        case (.english, .feedbackSomewhatHelpful): "Somewhat helpful"
        case (.chinese, .feedbackNotHelpful): "没有帮助"
        case (.english, .feedbackNotHelpful): "Not helpful"
        case (.chinese, .feedbackDidNotApply): "没有按建议做"
        case (.english, .feedbackDidNotApply): "Didn't follow advice"
        case (.chinese, .feedbackEasy): "容易理解"
        case (.english, .feedbackEasy): "Easy to understand"
        case (.chinese, .feedbackOkay): "一般"
        case (.english, .feedbackOkay): "Okay"
        case (.chinese, .feedbackConfusing): "令人困惑"
        case (.english, .feedbackConfusing): "Confusing"
        case (.chinese, .feedbackNotAtAll): "完全没有"
        case (.english, .feedbackNotAtAll): "Not at all"
        case (.chinese, .feedbackALittle): "有一点"
        case (.english, .feedbackALittle): "A little"
        case (.chinese, .feedbackTooMuch): "太过了"
        case (.english, .feedbackTooMuch): "Too much"
        case (.chinese, .feedbackNoConcerns): "没有顾虑"
        case (.english, .feedbackNoConcerns): "No concerns"
        case (.chinese, .feedbackMildConcern): "轻微顾虑"
        case (.english, .feedbackMildConcern): "Mild concern"
        case (.chinese, .feedbackSignificantConcern): "明显顾虑"
        case (.english, .feedbackSignificantConcern): "Significant concern"
        // Units
        case (.chinese, .minUnit): "分钟"
        case (.english, .minUnit): "min"
        case (.chinese, .safetyAdjustedLabel): "已根据安全边界调整表达"
        case (.english, .safetyAdjustedLabel): "Adjusted for safety"
        }
    }

    func confidence(_ level: ConfidenceLevel) -> String {
        switch (self, level) {
        case (.chinese, .high): "高"
        case (.chinese, .medium): "中"
        case (.chinese, .low): "低"
        case (.english, _): level.rawValue
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
        case (.chinese, .mock): "Mock 演示"
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
}

extension AppLanguage {
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
