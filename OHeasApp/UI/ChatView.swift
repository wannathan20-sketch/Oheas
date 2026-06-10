//
//  ChatView.swift
//  OHeas
//

import OHeasCore
import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage
    @StateObject private var chatVM = ChatViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @AppStorage("oheas.aiEnabled") private var aiEnabled = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Offline banner
                if chatVM.connectionStatus == .localOnly && !chatVM.messages.isEmpty {
                    offlineBanner
                }

                // Error banner
                if case .error(let msg) = chatVM.streamState {
                    errorBanner(msg)
                }

                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if chatVM.messages.isEmpty && chatVM.streamState == .idle {
                                emptyState
                            }

                            ForEach(chatVM.messages) { message in
                                MessageBubble(message: message, language: language)
                            }

                            if chatVM.streamState != .idle {
                                StreamingBubble(
                                    text: chatVM.streamingText,
                                    streamState: chatVM.streamState,
                                    language: language
                                )
                                .id("streaming")
                            }

                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    .onChange(of: chatVM.messages.count) { _, _ in scrollToBottom(proxy: proxy) }
                    .onChange(of: chatVM.streamingText) { _, _ in scrollToBottom(proxy: proxy) }
                    .onChange(of: chatVM.streamState) { _, _ in scrollToBottom(proxy: proxy) }
                }
                .background(Color(.systemGroupedBackground))

                inputBar
            }
            .navigationTitle(chatVM.currentSession?.displayTitle ?? language.text(.chatTab))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        chatVM.showSessionList = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.indigo)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        chatVM.newChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.indigo)
                    }
                }
                ToolbarItem(placement: .status) {
                    connectionBadge
                }
            }
            .sheet(isPresented: $chatVM.showSessionList) {
                sessionListSheet
            }
            .onAppear {
                chatVM.loadSessions()
                chatVM.checkConnection()
                chatVM.generateStarters(context: viewModel.agentContext, preferredLanguage: language.rawValue)
            }
            .onChange(of: aiEnabled) { _, _ in
                chatVM.checkConnection()
                chatVM.generateStarters(context: viewModel.agentContext, preferredLanguage: language.rawValue)
            }
        }
    }

    // MARK: - Session List Sheet

    private var sessionListSheet: some View {
        NavigationStack {
            List {
                Section {
                    // New chat button
                    Button {
                        chatVM.newChat()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.indigo)
                            Text(language == .chinese ? "新对话" : "New Chat")
                                .font(.body.weight(.medium))
                        }
                    }
                }

                Section {
                    if chatVM.sessions.isEmpty {
                        HStack {
                            Spacer()
                            Text(language == .chinese ? "暂无历史对话" : "No recent chats")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        ForEach(chatVM.sessions) { session in
                            Button {
                                chatVM.switchToSession(session)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.displayTitle)
                                        .font(.body.weight(chatVM.currentSession?.id == session.id ? .semibold : .regular))
                                        .foregroundStyle(chatVM.currentSession?.id == session.id ? Color.indigo : .primary)
                                        .lineLimit(1)

                                    HStack {
                                        Text(session.preview)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(formatSessionDate(session.updatedAt))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    chatVM.deleteSession(session)
                                } label: {
                                    Label(language == .chinese ? "删除" : "Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text(language == .chinese ? "最近" : "Recent")
                }
            }
            .navigationTitle(language == .chinese ? "对话历史" : "Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == .chinese ? "完成" : "Done") {
                        chatVM.showSessionList = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func formatSessionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return date.formatted(.dateTime.hour().minute())
        } else if calendar.isDateInYesterday(date) {
            return language == .chinese ? "昨天" : "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.abbreviated))
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    // MARK: - Offline Banner

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash").font(.caption)
            Text(language == .chinese
                 ? "AI 未连接 — 当前使用本地回复。请检查 API Key 配置或开启 AI 开关。"
                 : "AI not connected — using local replies. Check API Key or enable AI in Settings.")
                .font(.caption2)
            Spacer()
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").font(.caption)
            Text(message).font(.caption2)
            Spacer()
            Button {
                chatVM.streamState = .idle
                chatVM.retryLastMessage(context: viewModel.agentContext, aiEnabled: aiEnabled, preferredLanguage: language.rawValue)
            } label: {
                Text(language == .chinese ? "重试" : "Retry").font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(.red)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }

    private var connectionBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(chatVM.connectionStatus == .connected ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
            Text(chatVM.connectionStatus == .connected
                 ? (language == .chinese ? "AI 已连接" : "AI Connected")
                 : (language == .chinese ? "本地模式" : "Local Mode"))
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            if chatVM.connectionStatus == .localOnly {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 40)).foregroundStyle(.orange.opacity(0.6))
                Text(language == .chinese ? "AI 教练未连接" : "AI Coach Offline")
                    .font(.title3.weight(.semibold))
                Text(language == .chinese
                     ? "请确认：\n1. 设置中 AI 开关已开启\n2. API Key 已配置（运行 ./configure.sh）\n\n当前使用本地规则回复，基础健康问题仍可回答。"
                     : "Please check:\n1. AI is enabled in Settings\n2. API Key is configured (run ./configure.sh)\n\nLocal rule-based replies are available for basic health questions.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            } else {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 48)).foregroundStyle(.indigo.opacity(0.5))
                Text(language.text(.chatEmptyTitle)).font(.title3.weight(.semibold))
                Text(language.text(.chatEmptyDescription))
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)

                if !chatVM.conversationStarters.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(chatVM.conversationStarters) { starter in
                            Button {
                                sendStarter(starter.text)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: starter.icon).font(.caption)
                                    Text(starter.text).font(.subheadline)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .id("empty")
    }

    private func sendStarter(_ text: String) {
        chatVM.sendMessage(text, context: viewModel.agentContext, aiEnabled: aiEnabled, preferredLanguage: language.rawValue)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                TextField(language.text(.chatPlaceholder), text: $inputText, axis: .vertical)
                    .lineLimit(1...5).textFieldStyle(.plain)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }

                if chatVM.streamState == .connecting || chatVM.streamState == .streaming {
                    Button { chatVM.cancelStreaming() } label: {
                        Image(systemName: "stop.circle.fill").font(.title3).foregroundStyle(.red)
                    }
                    .padding(.trailing, 4)
                }

                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title2).symbolRenderingMode(.hierarchical)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || chatVM.streamState == .connecting
                          || chatVM.streamState == .streaming)
                .padding(.trailing, 12).padding(.bottom, 5)
            }
            .padding(.vertical, 4)
            .background(.regularMaterial)
            .shadow(color: .black.opacity(0.06), radius: 4, y: -2)
        }
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        chatVM.sendMessage(text, context: viewModel.agentContext, aiEnabled: aiEnabled, preferredLanguage: language.rawValue)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let language: AppLanguage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
                Text(message.content)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.indigo.gradient).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text(.chatCoachName))
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.leading, 4)
                    Text(message.content)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Streaming Bubble

private struct StreamingBubble: View {
    let text: String
    let streamState: StreamState
    let language: AppLanguage

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text(.chatCoachName))
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.leading, 4)

                switch streamState {
                case .connecting:
                    HStack(spacing: 4) {
                        Text(language == .chinese ? "正在思考" : "Thinking")
                            .font(.subheadline).foregroundStyle(.secondary)
                        PulsingDots()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                case .streaming:
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(text.isEmpty ? "..." : text)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        if !text.isEmpty {
                            Rectangle().fill(Color.accentColor).frame(width: 2, height: 16).opacity(0.8)
                        }
                    }

                case .error, .idle:
                    EmptyView()
                }
            }
            Spacer(minLength: 60)
        }
    }
}

// MARK: - Pulsing Dots

private struct PulsingDots: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(width: 5, height: 5)
                    .scaleEffect(animating ? 1.2 : 0.7)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.2), value: animating)
            }
        }
        .onAppear { animating = true }
    }
}

#Preview {
    ChatView(viewModel: OHeasViewModel(), language: .chinese)
}
