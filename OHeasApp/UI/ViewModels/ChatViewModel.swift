//
//  ChatViewModel.swift
//  OHeas
//
//  Manages chat sessions, SSE streaming from LLM, persistence, and local fallback.
//  管理聊天会话、LLM SSE 流式输出、持久化和本地降级。
//

import Foundation
import OHeasCore

// MARK: - Stream state

enum StreamState: Equatable {
    case idle
    case connecting
    case streaming
    case error(String)
}

// MARK: - Connection status

enum ChatConnectionStatus {
    case checking
    case connected
    case localOnly
}

// MARK: - Chat ViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    // Published state
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    @Published var streamState: StreamState = .idle
    @Published var streamingText: String = ""
    @Published var errorMessage: String?
    @Published var connectionStatus: ChatConnectionStatus = .checking
    @Published var conversationStarters: [ConversationStarter] = []
    @Published var showSessionList: Bool = false

    /// Convenience accessor for current session's messages.
    var messages: [ChatMessage] {
        get { currentSession?.messages ?? [] }
    }

    private var streamingTask: Task<Void, Never>?
    private let messageStore = ChatMessageStore(
        fileURL: OHeasStorageURLs.chatMessages,
        maxMessagesPerSession: 200,
        maxSessions: 50
    )

    // MARK: - Connection

    func checkConnection() {
        let config = OpenAIAppConfiguration.load()
        if config.makeClient() != nil {
            connectionStatus = .connected
            if let key = config.apiKey, !key.isEmpty {
                KeychainStore.save(key: "DEEPSEEK_API_KEY", value: key)
            }
        } else {
            connectionStatus = .localOnly
        }
    }

    // MARK: - Persistence & Session Management

    /// Load all sessions from disk and restore the most recent as current.
    func loadSessions() {
        do {
            sessions = try messageStore.loadSessions()
        } catch {
            print("[ChatViewModel] Failed to load sessions: \(error.localizedDescription)")
            sessions = []
        }
        if let last = sessions.first {
            currentSession = last
        }
    }

    /// Save all sessions to disk.
    private func saveSessions() {
        do {
            try messageStore.saveSessions(sessions)
        } catch {
            print("[ChatViewModel] Failed to save sessions: \(error.localizedDescription)")
        }
    }

    /// Start a brand-new conversation.
    func newChat() {
        let newSession = ChatSession()
        sessions.insert(newSession, at: 0)
        currentSession = newSession
        streamState = .idle
        streamingText = ""
        errorMessage = nil
        showSessionList = false
        saveSessions()
    }

    /// Switch to an existing session.
    func switchToSession(_ session: ChatSession) {
        // Save current session state back to the list before switching
        upsertCurrentSession()

        currentSession = session
        streamState = .idle
        streamingText = ""
        errorMessage = nil
        showSessionList = false
    }

    /// Delete a session. If it's the current one, switch to another or start fresh.
    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = sessions.first
        }
        if currentSession == nil {
            let newSession = ChatSession()
            sessions.insert(newSession, at: 0)
            currentSession = newSession
        }
        streamState = .idle
        streamingText = ""
        saveSessions()
    }

    /// Persist the current session into the sessions array.
    private func upsertCurrentSession() {
        guard var session = currentSession else { return }
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            session.updatedAt = Date()
            // Auto-title from first user message
            if session.title == "New Chat",
               let firstUser = session.messages.first(where: { $0.role == .user }) {
                session.title = String(firstUser.content.prefix(40))
            }
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
        // Move current session to top
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            let s = sessions.remove(at: idx)
            sessions.insert(s, at: 0)
        }
        currentSession = session
        saveSessions()
    }

    // MARK: - Conversation Starters

    func generateStarters(context: AgentContext?, preferredLanguage: String = "en") {
        let zh = preferredLanguage == "zh"
        var starters: [ConversationStarter] = []

        guard let ctx = context else {
            starters = [
                ConversationStarter(text: zh ? "我今天应该关注什么？" : "What should I focus on today?", icon: "target"),
                ConversationStarter(text: zh ? "如何读懂我的健康数据？" : "How do I understand my health data?", icon: "chart.bar"),
                ConversationStarter(text: zh ? "给我一个简单的健康建议" : "Give me a simple health tip", icon: "lightbulb"),
            ]
            conversationStarters = starters
            return
        }

        let signals = ctx.detectedSignals

        if let sleep = ctx.todayMetrics.sleepHours, let baseline = ctx.baseline14d.averageSleepHours {
            if sleep < baseline - 0.5 {
                starters.append(ConversationStarter(text: zh ? "我昨晚睡得不太好，怎么办？" : "I didn't sleep well last night — what can I do?", icon: "bed.double"))
            } else if sleep > baseline + 0.5 {
                starters.append(ConversationStarter(text: zh ? "昨晚睡得很好，今天适合运动吗？" : "Slept great — is today good for exercise?", icon: "bed.double"))
            }
        }

        if signals.contains(where: { $0.type == .hrvLow }) {
            starters.append(ConversationStarter(text: zh ? "HRV 偏低说明什么？" : "What does low HRV mean?", icon: "waveform.path.ecg"))
        }

        starters.append(ConversationStarter(text: zh ? "帮我看看今天的数据怎么样" : "How do my numbers look today?", icon: "heart.text.square"))

        if ctx.todayDailyPlan != nil {
            starters.append(ConversationStarter(text: zh ? "今天的计划是什么？" : "What's my plan for today?", icon: "calendar"))
        }

        starters.append(ConversationStarter(text: zh ? "我今天感觉有点累，正常吗？" : "I'm feeling tired today — is that normal?", icon: "questionmark.bubble"))

        if ctx.activeExperiment != nil {
            starters.append(ConversationStarter(text: zh ? "实验进展如何？我应该注意什么？" : "How's my experiment going?", icon: "flask"))
        }

        conversationStarters = starters
    }

    // MARK: - System Prompt

    func buildSystemPrompt(context: AgentContext?, preferredLanguage: String = "en") -> String {
        let zh = preferredLanguage == "zh"
        var prompt = ""

        if zh {
            prompt += """
            你叫 OHeas Coach，是一位温暖、专业、善于倾听的健康教练。

            ## 你的性格
            - 先倾听，再建议。用户分享感受时，先共情再回应。
            - 善于提问。理解用户的生活背景比给建议更重要。
            - 数据是你的工具，不是你的全部。自然地引用数据，不要生硬背诵数字。
            - 庆祝小进步。用户做对了什么，你要注意到。
            - 诚实面对不确定性。可以说"根据你的数据来看…但每个人的反应不同"。

            ## 对话规则
            - 回复控制在 2-5 句——像聊天，不要像讲课。
            - 引用数据时给出解读，而不是只报数字：❌ "你的睡眠是 6.2 小时，基线是 7.1 小时" → ✅ "昨晚睡了 6.2 小时，比你平时的 7.1 小时少了一些。今天感觉精力怎么样？"
            - 用"你"而不是"用户"。
            - 不知道就说不知道，不要编造。
            - 适当用问句结尾，引导用户继续对话——但不要每句都问。
            - 偶尔使用 emoji 让对话更亲切（每 2-3 条消息用 1 个即可）。

            ## 安全红线
            - 绝不诊断疾病或建议用药。
            - 绝不建议极端节食、过度训练或危险行为。
            - 如果用户描述严重症状（胸痛、昏厥等），建议他们立即就医。
            - 当不确定某项建议是否安全时，选择保守方案。

            CRITICAL: 你必须始终用简体中文回复。
            """
        } else {
            prompt += """
            You are OHeas Coach, a warm, professional, and attentive health coach.

            ## Personality
            - Listen first, advise second. When the user shares a feeling, acknowledge it before responding.
            - Ask good questions. Understanding the user's life context matters more than giving advice.
            - Data is your tool, not your identity. Reference metrics naturally — don't mechanically recite numbers.
            - Celebrate small wins. Notice when the user does something right.
            - Be honest about uncertainty. Say "Based on your data, it looks like… but everyone's different."

            ## Conversation Rules
            - Keep responses 2-5 sentences — conversational, not lecturing.
            - When citing data, interpret it: ❌ "Your sleep is 6.2h, baseline is 7.1h" → ✅ "You got 6.2 hours last night, a bit below your usual 7.1. How's your energy today?"
            - Use "you" — you're talking to a person.
            - Don't make things up. If you don't know, say so.
            - End with a question sometimes to keep the conversation going — but not every time.
            - Occasional light emoji use is fine (1 every 2-3 messages).

            ## Safety Red Lines
            - NEVER diagnose disease or recommend medication.
            - NEVER suggest extreme dieting, overtraining, or dangerous behaviors.
            - If the user describes serious symptoms (chest pain, fainting, etc.), advise them to seek medical attention immediately.
            - When unsure about safety, choose the conservative option.

            Respond in English.
            """
        }

        guard let ctx = context else {
            if zh {
                prompt += "\n\n用户尚未同步健康数据。鼓励他们连接 Apple Health 或探索 App 的功能。"
            } else {
                prompt += "\n\nThe user hasn't synced health data yet. Encourage them to connect Apple Health or explore the app."
            }
            return prompt
        }

        if zh {
            prompt += "\n\n## 当前健康上下文（自然地引用，不要逐条背诵）\n"
        } else {
            prompt += "\n\n## Current Health Context (reference naturally — don't recite)\n"
        }

        let t = ctx.todayMetrics
        let b = ctx.baseline14d

        if zh { prompt += "### 今日指标（与14天基线对比）\n" }
        else { prompt += "### Today's Metrics (vs 14-day baseline)\n" }

        if let sleep = t.sleepHours, let baseSleep = b.averageSleepHours {
            let diff = sleep - baseSleep
            if diff < -0.5 {
                prompt += zh ? "- 睡眠 \(String(format: "%.1f", sleep))h（⚠️ 低于基线 \(String(format: "%.1f", baseSleep))h，差 \(String(format: "%.1f", abs(diff)))h）\n"
                    : "- Sleep \(String(format: "%.1f", sleep))h (⚠️ below baseline \(String(format: "%.1f", baseSleep))h by \(String(format: "%.1f", abs(diff)))h)\n"
            } else if diff > 0.5 {
                prompt += zh ? "- 睡眠 \(String(format: "%.1f", sleep))h（✅ 高于基线 \(String(format: "%.1f", baseSleep))h）\n"
                    : "- Sleep \(String(format: "%.1f", sleep))h (✅ above baseline \(String(format: "%.1f", baseSleep))h)\n"
            } else {
                prompt += zh ? "- 睡眠 \(String(format: "%.1f", sleep))h（接近基线 \(String(format: "%.1f", baseSleep))h）\n"
                    : "- Sleep \(String(format: "%.1f", sleep))h (near baseline \(String(format: "%.1f", baseSleep))h)\n"
            }
        }

        if let hrv = t.hrv, let baseHRV = b.averageHRV {
            let diff = hrv - baseHRV
            if diff < -5 {
                prompt += zh ? "- HRV \(String(format: "%.0f", hrv))ms（⚠️ 低于基线 \(String(format: "%.0f", baseHRV))ms，恢复可能不足）\n"
                    : "- HRV \(String(format: "%.0f", hrv))ms (⚠️ below baseline \(String(format: "%.0f", baseHRV))ms — recovery may be low)\n"
            } else {
                prompt += zh ? "- HRV \(String(format: "%.0f", hrv))ms（接近基线 \(String(format: "%.0f", baseHRV))ms）\n"
                    : "- HRV \(String(format: "%.0f", hrv))ms (near baseline \(String(format: "%.0f", baseHRV))ms)\n"
            }
        }

        if let rhr = t.restingHeartRate, let baseRHR = b.averageRestingHeartRate {
            let diff = rhr - baseRHR
            if diff > 5 {
                prompt += zh ? "- 静息心率 \(String(format: "%.0f", rhr))bpm（⚠️ 高于基线 \(String(format: "%.0f", baseRHR))bpm，可能压力或恢复不足）\n"
                    : "- Resting HR \(String(format: "%.0f", rhr))bpm (⚠️ above baseline \(String(format: "%.0f", baseRHR))bpm — possible stress or under-recovery)\n"
            } else {
                prompt += zh ? "- 静息心率 \(String(format: "%.0f", rhr))bpm（接近基线 \(String(format: "%.0f", baseRHR))bpm）\n"
                    : "- Resting HR \(String(format: "%.0f", rhr))bpm (near baseline \(String(format: "%.0f", baseRHR))bpm)\n"
            }
        }

        if let steps = t.steps {
            prompt += zh ? "- 步数 \(String(format: "%.0f", steps))\n" : "- Steps \(String(format: "%.0f", steps))\n"
        }

        let conf = ctx.dataQuality.overallConfidence
        if zh {
            let label = conf == .high ? "高" : (conf == .medium ? "中" : "低")
            prompt += "- 数据置信度：\(label)\n"
            if conf == .low, let reason = ctx.dataQuality.missingReasons.first {
                prompt += "  （注意：数据不完整，\(reason)，给出建议时要更保守）\n"
            }
        } else {
            prompt += "- Data confidence: \(conf.rawValue)\n"
            if conf == .low, let reason = ctx.dataQuality.missingReasons.first {
                prompt += "  (Note: data is incomplete — \(reason), be more conservative with advice)\n"
            }
        }

        if !ctx.detectedSignals.isEmpty {
            prompt += zh ? "\n### 检测到的信号\n" : "\n### Detected Signals\n"
            for s in ctx.detectedSignals {
                let sev = s.severity == .high ? "⚠️" : "ℹ️"
                if zh {
                    prompt += "- \(sev) \(signalName(s.type, zh: true))\n  证据：\(s.evidence)\n"
                } else {
                    prompt += "- \(sev) \(s.type.rawValue)\n  Evidence: \(s.evidence)\n"
                }
            }
        }

        if let plan = ctx.currentWeeklyPlan, !plan.days.isEmpty {
            prompt += zh ? "\n### 本周计划\n策略：\(plan.strategySummary)\n" : "\n### Weekly Plan\nStrategy: \(plan.strategySummary)\n"
            for day in plan.days.prefix(4) {
                prompt += "- \(day.date.formatted(date: .abbreviated, time: .omitted))：\(day.title)（\(day.planType.rawValue)）\n"
            }
        }

        if let exp = ctx.activeExperiment {
            prompt += zh ? "\n### 活跃实验\n标题：\(exp.title)\n假设：\(exp.hypothesis)\n干预：\(exp.intervention)\n"
                : "\n### Active Experiment\nTitle: \(exp.title)\nHypothesis: \(exp.hypothesis)\nIntervention: \(exp.intervention)\n"
        }

        if !ctx.activeGoals.isEmpty {
            prompt += zh ? "\n### 用户目标\n" : "\n### User Goals\n"
            for g in ctx.activeGoals { prompt += "- \(g.title)\n" }
        }

        if !ctx.knownPatterns.isEmpty {
            prompt += zh ? "\n### 已学习的模式\n" : "\n### Learned Patterns\n"
            for p in ctx.knownPatterns.prefix(3) { prompt += "- \(p.title)\n" }
        }

        if zh {
            prompt += "\n---\n以上是背景信息。在对话中自然引用，不要逐条背诵。\n用户可能问任何健康相关的问题——不限于以上数据。\n"
        } else {
            prompt += "\n---\nThe above is background. Reference it naturally — don't recite it.\nThe user may ask about anything health-related — not just this data.\n"
        }
        return prompt
    }

    // MARK: - Send Message

    func sendMessage(_ text: String, context: AgentContext?, aiEnabled: Bool, preferredLanguage: String = "en") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, streamState == .idle else { return }

        // Auto-create session if needed
        if currentSession == nil {
            let newSession = ChatSession()
            sessions.insert(newSession, at: 0)
            currentSession = newSession
        }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        appendMessage(userMessage)

        streamState = .connecting
        streamingText = ""
        errorMessage = nil

        streamingTask = Task {
            await streamCoachResponse(userText: trimmed, context: context, aiEnabled: aiEnabled, preferredLanguage: preferredLanguage)
        }
    }

    func retryLastMessage(context: AgentContext?, aiEnabled: Bool, preferredLanguage: String = "en") {
        guard streamState == .idle, let lastUser = currentSession?.messages.last(where: { $0.role == .user }) else { return }
        streamState = .connecting
        streamingText = ""
        errorMessage = nil
        streamingTask = Task {
            await streamCoachResponse(userText: lastUser.content, context: context, aiEnabled: aiEnabled, preferredLanguage: preferredLanguage)
        }
    }

    private func streamCoachResponse(userText: String, context: AgentContext?, aiEnabled: Bool, preferredLanguage: String = "en") async {
        let config = OpenAIAppConfiguration.load()

        guard aiEnabled else {
            connectionStatus = .localOnly
            await finalizeStreaming(localFallbackResponse(to: userText, context: context, preferredLanguage: preferredLanguage))
            return
        }
        guard let llmClient = config.makeClient() else {
            connectionStatus = .localOnly
            await finalizeStreaming(localFallbackResponse(to: userText, context: context, preferredLanguage: preferredLanguage))
            return
        }

        connectionStatus = .connected
        let systemPrompt = buildSystemPrompt(context: context, preferredLanguage: preferredLanguage)
        var apiMessages: [[String: String]] = [["role": "system", "content": systemPrompt]]

        let msgs = currentSession?.messages ?? []
        let recentHistory = msgs.suffix(21).dropLast()
        for msg in recentHistory {
            apiMessages.append(["role": msg.role == .user ? "user" : "assistant", "content": msg.content])
        }
        apiMessages.append(["role": "user", "content": userText])

        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            guard streamState == .connecting else { return }
            streamingTask?.cancel()
            streamState = .error(preferredLanguage == "zh" ? "响应超时，请稍后重试" : "Response timed out. Please try again.")
        }

        if let streamingClient = llmClient as? ChatCompletionsClient {
            let stream = streamingClient.chat(messages: apiMessages)
            do {
                var accumulated = ""
                var firstTokenReceived = false
                for try await event in stream {
                    guard !Task.isCancelled else { break }
                    if !firstTokenReceived {
                        firstTokenReceived = true
                        timeoutTask.cancel()
                        streamState = .streaming
                    }
                    if event.isComplete {
                        await finalizeStreaming(event.accumulatedText)
                        return
                    }
                    accumulated = event.accumulatedText
                    streamingText = accumulated
                }
                await finalizeStreaming(accumulated)
            } catch {
                timeoutTask.cancel()
                if !Task.isCancelled {
                    connectionStatus = .localOnly
                    await finalizeStreaming(localFallbackResponse(to: userText, context: context, preferredLanguage: preferredLanguage))
                }
            }
        } else {
            timeoutTask.cancel()
            do {
                let systemAndUser = apiMessages.map { "\($0["role"] ?? ""): \($0["content"] ?? "")" }.joined(separator: "\n\n")
                let payload = CoachPromptPayload(systemPrompt: systemPrompt, userContextJSON: systemAndUser)
                let raw = try await llmClient.generateRecommendationJSON(payload: payload)
                await finalizeStreaming(raw)
            } catch {
                if !Task.isCancelled {
                    connectionStatus = .localOnly
                    await finalizeStreaming(localFallbackResponse(to: userText, context: context, preferredLanguage: preferredLanguage))
                }
            }
        }
    }

    private func finalizeStreaming(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            appendMessage(ChatMessage(role: .coach, content: trimmed))
        }
        streamState = .idle
        streamingText = ""
    }

    // MARK: - Message helpers

    private func appendMessage(_ message: ChatMessage) {
        guard var session = currentSession else { return }
        session.messages.append(message)
        session.updatedAt = Date()
        if session.title == "New Chat", message.role == .user {
            session.title = String(message.content.prefix(40))
        }
        currentSession = session
        upsertCurrentSession()
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        let trimmed = streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            appendMessage(ChatMessage(role: .coach, content: trimmed + "…"))
        }
        streamState = .idle
        streamingText = ""
    }

    func reset() {
        cancelStreaming()
        sessions = []
        currentSession = nil
        errorMessage = nil
        try? messageStore.deleteAll()
    }

    // MARK: - Context-Aware Fallback

    private func localFallbackResponse(to userText: String, context: AgentContext?, preferredLanguage: String = "en") -> String {
        let lowercased = userText.lowercased()
        let zh = preferredLanguage == "zh"

        if lowercased.contains("sleep") || lowercased.contains("睡眠") || lowercased.contains("睡") {
            if let sleep = context?.todayMetrics.sleepHours, let base = context?.baseline14d.averageSleepHours {
                let diff = sleep - base
                if diff < -0.5 {
                    return zh ? "你昨晚睡了 \(String(format: "%.1f", sleep)) 小时，比你平时（\(String(format: "%.1f", base))h）少了一些。今晚试着提前 30 分钟开始放松——关掉屏幕，做点轻松的事，让身体自然进入睡眠状态。💤"
                        : "You slept \(String(format: "%.1f", sleep))h last night, a bit below your usual \(String(format: "%.1f", base))h. Try winding down 30 minutes earlier tonight — put away screens, do something relaxing, and let your body ease into sleep. 💤"
                } else {
                    return zh ? "昨晚睡了 \(String(format: "%.1f", sleep)) 小时，和你平时差不多。保持这个节奏！固定的作息是高质量恢复的基础。"
                        : "You got \(String(format: "%.1f", sleep))h of sleep last night, right around your baseline. Keep that rhythm — consistent sleep timing is the foundation of good recovery."
                }
            }
            return zh ? "睡眠是恢复的基石。保持固定的入睡和起床时间，睡前减少屏幕使用，这些都是简单有效的方法。你的睡眠数据最近怎么样？"
                : "Sleep is the foundation of recovery. A consistent bedtime and wake time, plus less screen time before bed, are simple but powerful habits. How's your sleep been lately?"
        }

        if lowercased.contains("hrv") || lowercased.contains("心率变异性") || lowercased.contains("恢复") {
            if let hrv = context?.todayMetrics.hrv, let base = context?.baseline14d.averageHRV {
                if hrv < base - 5 {
                    return zh ? "你今天的 HRV 是 \(String(format: "%.0f", hrv))ms，低于你的基线（\(String(format: "%.0f", base))ms）。这可能意味着恢复不够充分。今天适合降低运动强度，试试深呼吸、冥想或者出门散个步。🌿"
                        : "Your HRV is \(String(format: "%.0f", hrv))ms today, below your baseline of \(String(format: "%.0f", base))ms. This can be a sign of incomplete recovery. Consider lighter activity today — deep breathing, meditation, or a walk outside can help. 🌿"
                } else {
                    return zh ? "你的 HRV 在 \(String(format: "%.0f", hrv))ms，和你平时差不多，说明自主神经系统状态不错。继续保持当前的节奏！"
                        : "Your HRV is around \(String(format: "%.0f", hrv))ms, close to your baseline — your nervous system seems well-regulated. Keep doing what you're doing!"
                }
            }
            return zh ? "HRV 反映你神经系统的恢复状态。偏低不一定有问题——但如果持续偏低，可能意味着压力或恢复不足。你的感觉和数据一致吗？"
                : "HRV reflects your nervous system's recovery. A single low day isn't a concern, but a sustained drop can signal stress or under-recovery. How do you feel?"
        }

        if lowercased.contains("心率") || lowercased.contains("heart rate") || lowercased.contains("静息") || lowercased.contains("resting") {
            if let rhr = context?.todayMetrics.restingHeartRate, let base = context?.baseline14d.averageRestingHeartRate {
                if rhr > base + 5 {
                    return zh ? "你的静息心率今天 \(String(format: "%.0f", rhr))bpm，比平时（\(String(format: "%.0f", base))bpm）偏高。这在压力大、睡眠不足或训练过度时可能出现。今天注意多休息。"
                        : "Your resting HR is \(String(format: "%.0f", rhr))bpm today, above your usual \(String(format: "%.0f", base))bpm. This can happen with stress, poor sleep, or overtraining. Prioritize rest today."
                } else {
                    return zh ? "静息心率在 \(String(format: "%.0f", rhr))bpm，和你平时差不多。这是个好信号，说明身体没有在额外应激状态。"
                        : "Your resting HR is \(String(format: "%.0f", rhr))bpm, close to your baseline — a good sign your body isn't under extra stress."
                }
            }
            return zh ? "静息心率是衡量整体压力水平的好指标。早晨刚醒时测量最准确。你的数据看起来有变化吗？"
                : "Resting heart rate is a great overall stress indicator — most accurate when measured right after waking up. Are you noticing any patterns?"
        }

        if lowercased.contains("exercise") || lowercased.contains("运动") || lowercased.contains("训练") || lowercased.contains("workout") {
            if let steps = context?.todayMetrics.steps {
                if steps < 5000 {
                    return zh ? "今天走了 \(String(format: "%.0f", steps)) 步，偏少。哪怕 15 分钟的散步也能改善心情、促进恢复。不一定要高强度——持续最重要。🚶"
                        : "You've got \(String(format: "%.0f", steps)) steps so far — a bit on the low side. Even a 15-minute walk can boost your mood and recovery. Consistency over intensity! 🚶"
                } else {
                    return zh ? "今天已经 \(String(format: "%.0f", steps)) 步了，不错！关键不是一天的运动量，而是长期保持活跃的习惯。"
                        : "\(String(format: "%.0f", steps)) steps today — nice! It's not about one big day, it's about staying consistently active."
                }
            }
            return zh ? "坚持比强度更重要。关注身体的恢复信号——如果 HRV 低或静息心率高，就放轻松一点。你今天想做什么类型的活动？"
                : "Consistency beats intensity. Watch your body's recovery signals — if HRV is low or resting HR is high, keep it easy. What kind of activity are you thinking about today?"
        }

        if lowercased.contains("stress") || lowercased.contains("压力") || lowercased.contains("tired") || lowercased.contains("累") || lowercased.contains("疲劳") || lowercased.contains("感觉") || lowercased.contains("feel") {
            var resp = zh ? "谢谢你跟我分享这个。感觉疲惫是很正常的，每个人的状态都会有起伏。" : "Thanks for sharing that. It's completely normal to have ups and downs — everyone does."
            if let sleep = context?.todayMetrics.sleepHours, let base = context?.baseline14d.averageSleepHours, sleep < base - 0.5 {
                resp += zh ? "\n\n我注意到你昨晚睡眠偏少，这可能和今天的疲劳感有关。今天优先休息，能做多少做多少就好。"
                    : "\n\nI do notice your sleep was on the low side last night — that could be contributing. Rest is the priority today. Whatever you get done is enough."
            }
            return resp
        }

        if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("你好") || lowercased.contains("嘿") {
            if let sleep = context?.todayMetrics.sleepHours, let base = context?.baseline14d.averageSleepHours {
                let sleepMsg = sleep < base - 0.5 ? (zh ? "昨晚睡得偏少" : "sleep was a bit low last night") : (zh ? "睡眠数据看起来不错" : "sleep looks good")
                return zh ? "你好！👋 今天 \(sleepMsg)。有什么我可以帮你的？你可以问我关于睡眠、运动、恢复或者任何健康相关的问题。"
                    : "Hey there! 👋 Today \(sleepMsg). What can I help with? Ask me about your sleep, activity, recovery, or anything health-related."
            }
            return zh ? "你好！我是你的健康教练。有什么想聊的？你可以问我今天的身体数据，也可以聊聊你的感受。"
                : "Hi! I'm your health coach. What's on your mind? You can ask about today's numbers, or just tell me how you're feeling."
        }

        return zh ? "我在这里帮你理解身体发出的信号、建立可持续的健康习惯。你可以问我：今天的数据怎么样？该怎么改善睡眠？今天适合运动吗？或者直接告诉我你现在的感受。"
            : "I'm here to help you understand your body's signals and build sustainable habits. Try asking:\n- How do my numbers look today?\n- How can I sleep better?\n- Is today good for exercise?\n- Or just tell me how you're feeling right now."
    }

    private func signalName(_ type: SignalType, zh: Bool) -> String {
        if zh {
            switch type {
            case .sleepLow: return "睡眠偏低"
            case .hrvLow: return "HRV 偏低"
            case .restingHeartHigh: return "静息心率偏高"
            case .activityLow: return "活动量偏低"
            case .activityHigh: return "活动量偏高"
            case .recoveryUncertainDueToMissingData: return "恢复判断不确定（数据缺失）"
            }
        }
        return type.rawValue
    }
}
