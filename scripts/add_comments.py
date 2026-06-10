#!/usr/bin/env python3
"""Add bilingual file headers and MARK comments to Swift files based on path/content analysis."""
import os, re, sys

ROOT = '/Users/wanna/watch_health'

# Map directory paths to bilingual descriptions
DIR_DESCRIPTIONS = {
    'Models/HealthModels.swift': ('Core health data models — daily metrics, baselines, signals, and agent context.',
                                   '核心健康数据模型 — 每日指标、基线、信号和 Agent 上下文。'),
    'Models/RecommendationModels.swift': ('Coach recommendation and feedback models.',
                                          '教练建议和反馈模型。'),
    'Models/MemoryModels.swift': ('User memory and pattern models for long-term learning.',
                                   '用户记忆和模式模型，用于长期学习。'),
    'Models/ExperimentModels.swift': ('Personal experiment models — hypothesis, check-in, and evaluation.',
                                      '个人实验模型 — 假设、签到和评估。'),
    'Models/GoalPlanModels.swift': ('Goal, weekly plan, and adaptive reschedule models.',
                                     '目标、周计划和自适应重调度模型。'),
    'Models/ReminderReviewModels.swift': ('Reminder and weekly review models.',
                                          '提醒和周复盘模型。'),
    'Models/SafetyPrivacyModels.swift': ('Safety guardrail, privacy, and consent models.',
                                         '安全护栏、隐私和同意模型。'),
    'Agent/AgentContextBuilder.swift': ('Builds AgentContext from health data, memory, and experiments.',
                                        '从健康数据、记忆和实验中构建 AgentContext。'),
    'Agent/CoachPromptBuilder.swift': ('Assembles the LLM system prompt and user context JSON payload.',
                                       '组装 LLM 系统提示词和用户上下文 JSON。'),
    'Agent/CoachPromptTemplates.swift': ('Versioned coach prompt templates (V1 baseline / V2 personalized).',
                                         '版本化的教练提示词模板（V1 基线 / V2 个性化）。'),
    'Analysis/BaselineEngine.swift': ('Computes health baselines over 7/14/30 day windows.',
                                      '计算 7/14/30 天窗口的健康基线。'),
    'Analysis/DailyMetricsAggregator.swift': ('Aggregates raw HealthKit samples into DailyHealthMetrics.',
                                               '将原始 HealthKit 采样聚合为 DailyHealthMetrics。'),
    'Analysis/DataCoverageLayer.swift': ('Assesses data quality, completeness, and confidence.',
                                         '评估数据质量、完整性和置信度。'),
    'Analysis/SignalDetector.swift': ('Detects health signals (HRV drop, sleep low, activity anomaly).',
                                      '检测健康信号（HRV 下降、睡眠不足、活动异常）。'),
    'Data/HealthDataProvider.swift': ('Protocol and factory for HealthKit vs mock data sources.',
                                      'HealthKit 与模拟数据源的协议和工厂。'),
    'Data/HealthKitReader.swift': ('Reads sleep, HRV, RHR, steps, energy, exercise, workouts from HealthKit.',
                                   '从 HealthKit 读取睡眠、HRV、静息心率、步数、能量、运动和训练。'),
    'Data/MockHealthDataProvider.swift': ('Generates 30 days of deterministic mock health data with edge cases.',
                                          '生成 30 天确定性模拟健康数据，包含边缘情况。'),
    'LLM/LLMClient.swift': ('LLM client abstraction — OpenAI, Chat Completions (DeepSeek), streaming, mock.',
                            'LLM 客户端抽象 — OpenAI、Chat Completions（DeepSeek）、流式、模拟。'),
    'Analytics/BetaAnalyticsService.swift': ('Beta analytics event recording with privacy filtering.',
                                             'Beta 分析事件记录，带隐私过滤。'),
    'Auth/AuthService.swift': ('Local authentication service — sign in, sign out, local only mode.',
                               '本地认证服务 — 登录、登出、仅本地模式。'),
    'Backend/BackendAPIClient.swift': ('Backend API client with local fallback.',
                                       '后端 API 客户端，带本地降级。'),
    'Consent/ConsentManager.swift': ('Manages user consent for AI, cloud sync, and analytics.',
                                     '管理用户对 AI、云同步和分析的同意。'),
    'Demo/DemoScenarioBuilder.swift': ('Builds demo scenarios (normal, overtraining, missing data, recovery).',
                                       '构建演示场景（正常、过度训练、数据缺失、恢复）。'),
    'Effectiveness/EffectivenessAnalyzer.swift': ('Analyzes long-term effectiveness of recommendations and interventions.',
                                                   '分析建议和干预的长期效果。'),
    'Evaluation/AgentEvaluationRunner.swift': ('Runs agent evaluation suite against predefined cases.',
                                               '针对预定义案例运行 Agent 评估套件。'),
    'Evaluation/EvaluationModels.swift': ('Evaluation result and regression test models.',
                                          '评估结果和回归测试模型。'),
    'Evaluation/PromptRegressionTester.swift': ('Detects prompt regression by comparing snapshots.',
                                                '通过比较快照检测提示词回归。'),
    'Experiments/ExperimentPlanner.swift': ('Proposes personalized experiments based on patterns and data.',
                                            '基于模式和数据提出个性化实验。'),
    'Experiments/ExperimentStore.swift': ('Persists and manages personal experiment lifecycle.',
                                          '持久化和管理个人实验生命周期。'),
    'Export/LocalDataExporter.swift': ('Exports aggregated local data (no raw HealthKit samples).',
                                       '导出聚合本地数据（不含原始 HealthKit 采样）。'),
    'Feedback/FeedbackStore.swift': ('Stores and retrieves daily user feedback on recommendations.',
                                     '存储和检索用户对建议的每日反馈。'),
    'Goals/GoalStore.swift': ('CRUD operations for user health and lifestyle goals.',
                              '用户健康和生活目标的 CRUD 操作。'),
    'Memory/MemoryStore.swift': ('Persists user memory patterns with 30-day half-life decay.',
                                 '持久化用户记忆模式，30 天半衰期衰减。'),
    'Memory/MemoryUpdateService.swift': ('Updates memory from feedback, verification, and mined patterns.',
                                         '从反馈、验证和挖掘的模式中更新记忆。'),
    'Observability/ErrorReporter.swift': ('Local error logging with sensitive field redaction.',
                                          '本地错误日志，敏感字段脱敏。'),
    'Onboarding/OnboardingModels.swift': ('Onboarding state machine models.',
                                          '引导流程状态机模型。'),
    'PatternMining/PatternMiner.swift': ('Mines recurring health patterns from daily metrics and feedback.',
                                         '从每日指标和反馈中挖掘重复出现的健康模式。'),
    'Planning/AdaptiveRescheduler.swift': ('Adaptively reschedules weekly plans based on recovery signals.',
                                           '基于恢复信号自适应重调度周计划。'),
    'Planning/PlanStore.swift': ('Persists weekly plans.',
                                  '持久化周计划。'),
    'Planning/WeeklyPlanPlanner.swift': ('Generates personalized weekly plans with constraints.',
                                         '生成带约束的个性化周计划。'),
    'Privacy/PrivacyManager.swift': ('Redacts sensitive context fields per privacy settings.',
                                     '根据隐私设置脱敏敏感上下文字段。'),
    'Recommendations/CoachRecommendationService.swift': ('Orchestrates LLM recommendation with safety filtering and streaming.',
                                                          '编排 LLM 建议，带安全过滤和流式输出。'),
    'Recommendations/RuleBasedRecommendationGenerator.swift': ('Deterministic fallback recommendation engine (5 coach states).',
                                                                '确定性降级建议引擎（5 种教练状态）。'),
    'Reminders/ReminderScheduler.swift': ('Schedules local notifications for plans, feedback, and reviews.',
                                          '为计划、反馈和周复盘安排本地通知。'),
    'Safety/SafetyGuardrail.swift': ('Two-level safety check: L1 regex (0ms) + L2 LLM semantic deep review.',
                                     '双级安全检查：L1 正则（零延迟）+ L2 LLM 语义深度审查。'),
    'Storage/CodableFileStore.swift': ('Generic JSON file-based Codable storage.',
                                       '基于 JSON 文件的通用 Codable 存储。'),
    'Sync/SyncEngine.swift': ('Syncs local data to backend with conflict resolution and privacy guards.',
                              '将本地数据同步到后端，带冲突解决和隐私保护。'),
    'Verification/VerificationEngine.swift': ('Verifies yesterday recommendation against today metrics.',
                                              '用今日指标验证昨日建议。'),
    'WeeklyReview/WeeklyReviewEngine.swift': ('Computes weekly adherence, effectiveness, and insights.',
                                              '计算周完成率、效果和洞察。'),
}

APP_UI_DESCRIPTIONS = {
    'OHeasApp.swift': ('App entry point — sets up WindowGroup with AppRootView.',
                       '应用入口 — 使用 AppRootView 设置 WindowGroup。'),
    'AccountView.swift': ('Account management — sign in, sign up, sign out, mode display.',
                          '账户管理 — 登录、注册、登出、模式显示。'),
    'AgentContextView.swift': ('Debug view showing full agent context across 20+ tabs.',
                               '调试视图，在 20+ 标签页中显示完整 Agent 上下文。'),
    'AppConfiguration.swift': ('Storage URL configuration and backend client setup.',
                               '存储 URL 配置和后端客户端设置。'),
    'AppLanguage.swift': ('Localization — TextKey enum with Chinese/English translations.',
                          '本地化 — TextKey 枚举及中英文翻译。'),
    'AppRootView.swift': ('Root view — routes to onboarding or main content based on state.',
                          '根视图 — 根据状态路由到引导页或主内容。'),
    'BetaAnalyticsDashboardView.swift': ('Beta analytics dashboard — events, usage patterns, trends.',
                                         'Beta 分析仪表盘 — 事件、使用模式、趋势。'),
    'BetaFeedbackView.swift': ('In-app beta feedback form — ratings and free text.',
                               '应用内 Beta 反馈表单 — 评分和自由文本。'),
    'BetaReadinessReport.swift': ('Beta readiness diagnostics — permissions, coverage, baseline.',
                                  'Beta 就绪诊断 — 权限、覆盖率、基线。'),
    'ChatView.swift': ('AI chat interface — message bubbles, streaming text, TextEditor input.',
                       'AI 对话界面 — 消息气泡、流式文本、TextEditor 输入。'),
    'DemoModeView.swift': ('Demo scenario selector — normal, overtraining, missing data, recovery.',
                           '演示场景选择器 — 正常、过度训练、数据缺失、恢复。'),
    'EffectivenessDashboardView.swift': ('Long-term effectiveness dashboard — adherence, promising interventions.',
                                         '长期效果仪表盘 — 完成率、有效干预。'),
    'EvaluationDebugView.swift': ('Agent evaluation debug view — run suite, view regression results.',
                                  'Agent 评估调试视图 — 运行套件、查看回归结果。'),
    'ExperimentsView.swift': ('Personal experiments view — active, proposed, history, check-in.',
                              '个人实验视图 — 进行中、提议、历史、签到。'),
    'GoalsView.swift': ('Goals management — add, update, deactivate health/lifestyle goals.',
                        '目标管理 — 添加、更新、停用健康/生活目标。'),
    'HealthPermissionRecoveryView.swift': ('Guides users to restore denied HealthKit permissions.',
                                           '引导用户恢复被拒绝的 HealthKit 权限。'),
    'InsightsTabView.swift': ('Insights tab — metrics, effectiveness, agent context, evaluation.',
                              '洞察标签页 — 指标、效果、Agent 上下文、评估。'),
    'MetricsView.swift': ('Daily metrics view — today vs 14-day baseline comparison.',
                          '每日指标视图 — 今日与 14 天基线对比。'),
    'OHeasAppConfiguration.swift': ('LLM provider configuration — DeepSeek, OpenAI, custom endpoint auto-detection.',
                                    'LLM 提供商配置 — DeepSeek、OpenAI、自定义端点自动检测。'),
    'OHeasViewModel.swift': ('Thin coordinator — owns sub-ViewModels, exposes delegated properties.',
                             '薄协调层 — 拥有子 ViewModel，暴露委托属性。'),
    'OnboardingView.swift': ('Onboarding flow — welcome, HealthKit permission, consent, AI opt-in.',
                             '引导流程 — 欢迎、HealthKit 权限、同意、AI 选择。'),
    'PlanTabView.swift': ('Plan tab — plans, goals, experiments, weekly review in NavigationStack.',
                          '计划标签页 — 计划、目标、实验、周复盘，使用 NavigationStack。'),
    'PlanView.swift': ('Weekly plan view — daily plan cards with status and adjustments.',
                       '周计划视图 — 每日计划卡片，含状态和调整。'),
    'PrivacyView.swift': ('Privacy settings — LLM usage, raw samples, data sharing controls.',
                          '隐私设置 — LLM 使用、原始采样、数据共享控制。'),
    'RootTabView.swift': ('Root tab bar — Today, Plan, Insights, Chat (4 tabs).',
                          '根标签栏 — 今日、计划、洞察、对话（4 个标签）。'),
    'SettingsView.swift': ('Settings sheet — account, privacy, beta, about, language.',
                           '设置 Sheet — 账户、隐私、Beta、关于、语言。'),
    'SyncStatusView.swift': ('Sync status — cloud sync state, pending queue, last sync time.',
                             '同步状态 — 云同步状态、待处理队列、上次同步时间。'),
    'TodayView.swift': ('Today view — body budget, recommendations, yesterday verification.',
                        '今日视图 — 身体预算、建议、昨日验证。'),
    'WeeklyReviewView.swift': ('Weekly review — adherence, effectiveness, insights summary.',
                               '周复盘 — 完成率、效果、洞察摘要。'),
    'Components/SkeletonView.swift': ('Skeleton loading views with shimmer animation.',
                                      '骨架加载视图，带微光动画。'),
    'Components/SparklineView.swift': ('7-day sparkline mini-chart for body budget trends.',
                                       '7 天迷你趋势图，用于身体预算趋势。'),
}

VIEWMODEL_DESCRIPTIONS = {
    'ChatViewModel.swift': ('Manages chat messages, SSE streaming from LLM, and local fallback.',
                            '管理聊天消息、LLM SSE 流式输出和本地降级。'),
    'ExperimentViewModel.swift': ('Manages experiment lifecycle — propose, start, check-in, evaluate.',
                                  '管理实验生命周期 — 提议、开始、签到、评估。'),
    'HealthDataViewModel.swift': ('Loads health data, computes baselines, detects signals.',
                                  '加载健康数据、计算基线、检测信号。'),
    'MemoryViewModel.swift': ('Loads and updates user memory and pattern mining results.',
                              '加载和更新用户记忆和模式挖掘结果。'),
    'OnboardingViewModel.swift': ('Onboarding state machine — gates, HealthKit, consent.',
                                  '引导状态机 — 门控、HealthKit、同意。'),
    'PlanViewModel.swift': ('Manages goals, weekly plans, adaptive rescheduling, weekly reviews.',
                            '管理目标、周计划、自适应重调度、周复盘。'),
    'RecommendationViewModel.swift': ('Manages LLM recommendations, safety, feedback, verification, streaming.',
                                      '管理 LLM 建议、安全、反馈、验证、流式输出。'),
    'SyncViewModel.swift': ('Manages auth, cloud sync, analytics, beta readiness, export, reset.',
                            '管理认证、云同步、分析、Beta 就绪、导出、重置。'),
}

TEST_DESCRIPTIONS = {
    'Tests/OHeasCoreTests/OHeasCoreTests.swift': ('Core library unit tests — 80 tests covering all modules.',
                                                   '核心库单元测试 — 80 个测试覆盖所有模块。'),
    'OHeasAppTests/ViewModelTests.swift': ('ViewModel layer unit tests — 25 tests for 7 sub-ViewModels.',
                                           'ViewModel 层单元测试 — 25 个测试覆盖 7 个子 ViewModel。'),
    'OHeasAppTests/DeepSeekConnectivityTests.swift': ('DeepSeek API connectivity tests — streaming and non-streaming.',
                                                      'DeepSeek API 连通性测试 — 流式和非流式。'),
}


def find_swift_files():
    """Find all Swift files that need comments."""
    files = []
    for dirpath, dirs, filenames in os.walk(ROOT):
        if any(skip in dirpath for skip in ['.build', '.derivedData', '.swiftpm', '.claude', '.xcodeproj']):
            continue
        for f in filenames:
            if f.endswith('.swift'):
                files.append(os.path.join(dirpath, f))
    return files


def get_description(filepath):
    """Get bilingual description for a file based on its path."""
    rel = os.path.relpath(filepath, ROOT)

    # Check Sources/OHeasCore/...
    core_prefix = 'Sources/OHeasCore/'
    if core_prefix in rel:
        subpath = rel.replace(core_prefix, '')
        if subpath in DIR_DESCRIPTIONS:
            return DIR_DESCRIPTIONS[subpath]
        return (f'{os.path.basename(filepath)} — OHeasCore module.',
                f'{os.path.basename(filepath)} — OHeasCore 模块。')

    # Check OHeasApp/UI/ViewModels/...
    vm_prefix = 'OHeasApp/UI/ViewModels/'
    if vm_prefix in rel:
        filename = rel.replace(vm_prefix, '')
        if filename in VIEWMODEL_DESCRIPTIONS:
            return VIEWMODEL_DESCRIPTIONS[filename]
        return (f'ViewModel for {filename.replace(".swift", "")}.',
                f'{filename.replace(".swift", "")} 的 ViewModel。')

    # Check OHeasApp/...
    app_prefix = 'OHeasApp/'
    if app_prefix in rel:
        subpath = rel.replace(app_prefix, '')
        if subpath in APP_UI_DESCRIPTIONS:
            return APP_UI_DESCRIPTIONS[subpath]
        return (f'{os.path.basename(filepath)} — OHeas UI component.',
                f'{os.path.basename(filepath)} — OHeas UI 组件。')

    # Check test files
    for key, desc in TEST_DESCRIPTIONS.items():
        if key in rel:
            return desc

    return (f'{os.path.basename(filepath)}.',
            f'{os.path.basename(filepath)}。')


def has_file_header(content):
    """Check if file already has a proper file header comment."""
    lines = content.strip().split('\n')
    for line in lines[:10]:
        if line.strip().startswith('//') and ('OHeas' in line or '模块' in line or '视图' in line or '模型' in line):
            return True
    return False


def add_file_header(filepath, content):
    """Add bilingual file header comment."""
    en_desc, zh_desc = get_description(filepath)

    header = f'''//
//  {os.path.basename(filepath)}
//  OHeas
//
//  {en_desc}
//  {zh_desc}
//

'''
    # Find where to insert — after any existing single-line header, before imports
    lines = content.split('\n')

    # If file already has a header we added, skip
    if '//  OHeas' in '\n'.join(lines[:15]):
        return content

    # Find first non-comment, non-blank line
    insert_idx = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped and not stripped.startswith('//'):
            insert_idx = i
            break

    # If the first non-comment line starts with 'import', insert header before it
    new_lines = header.split('\n') + lines[insert_idx:]
    if insert_idx > 0:
        new_lines = lines[:insert_idx] + header.split('\n') + lines[insert_idx:]
    else:
        new_lines = header.split('\n') + lines

    return '\n'.join(new_lines)


def needs_mark_sections(content):
    """Check if file could benefit from MARK sections."""
    lines = content.split('\n')
    has_mark = any('MARK:' in line for line in lines)
    return not has_mark and len(lines) > 80  # Only add MARK to larger files


def process_file(filepath):
    """Process a single Swift file: add header comments and MARK sections."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Add file header
    if not has_file_header(content):
        content = add_file_header(filepath, content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def main():
    files = find_swift_files()
    print(f"Found {len(files)} Swift files")

    updated = 0
    for f in sorted(files):
        try:
            if process_file(f):
                print(f"  Updated: {os.path.relpath(f, ROOT)}")
                updated += 1
        except Exception as e:
            print(f"  Error {f}: {e}")

    print(f"\nUpdated {updated} files.")


if __name__ == '__main__':
    main()
