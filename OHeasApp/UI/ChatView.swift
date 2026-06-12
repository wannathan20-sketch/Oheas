//
//  ChatView.swift
//  OHeas
//

import OHeasCore
import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage
    @Binding var pendingPrompt: String?
    @StateObject private var chatVM = ChatViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("oheas.aiEnabled") private var aiEnabled = true

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && chatVM.streamState != .connecting
        && chatVM.streamState != .streaming
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Offline banner
                if chatVM.connectionStatus == .localOnly && !chatVM.messages.isEmpty {
                    offlineBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Error banner
                if case .error(let msg) = chatVM.streamState {
                    errorBanner(msg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if chatVM.connectionStatus == .checking && chatVM.messages.isEmpty {
                                chatSkeleton
                            } else if chatVM.messages.isEmpty && chatVM.streamState == .idle {
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
                .animation(OhAnimation.stagger(), value: chatVM.messages.count)
                .animation(OhAnimation.stagger(), value: chatVM.connectionStatus == .localOnly)

                inputBar
            }
            .navigationTitle(chatVM.currentSession.map(displayTitle) ?? language.text(.chatTab))
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
            .onChange(of: pendingPrompt) { _, prompt in
                guard let prompt, !prompt.isEmpty else { return }
                pendingPrompt = nil
                inputText = prompt
                Task {
                    // Give SwiftUI time to update inputText before sending
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await MainActor.run { sendMessage() }
                }
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
                            Text(language.text(.newChatAction))
                                .font(.body.weight(.medium))
                        }
                    }
                }

                Section {
                    if chatVM.sessions.isEmpty {
                        HStack {
                            Spacer()
                            Text(language.text(.noRecentChats))
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
                                    Text(displayTitle(session))
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
                                    Label(language.text(.deleteAction), systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text(language.text(.recentHeader))
                }
            }
            .navigationTitle(language.text(.chatHistoryTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text(.doneAction)) {
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
            return language.formatDate(date, dateStyle: .none, timeStyle: .short)
        } else if calendar.isDateInYesterday(date) {
            return language.text(.yesterdayLabel)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.locale = language.locale
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        } else {
            return language.formatDate(date, dateStyle: .medium)
        }
    }

    private func displayTitle(_ session: ChatSession) -> String {
        if language == .chinese, session.title == "New Chat", session.messages.first(where: { $0.role == .user }) == nil {
            return "新对话"
        }
        return session.displayTitle
    }

    // MARK: - Offline Banner

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right").font(.caption)
            Text(language.text(.offlineBannerText))
                .font(.caption2)
            Spacer()
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.orange.opacity(0.08))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.orange.opacity(0.25)).frame(height: 1)
        }
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
                Text(language.text(.retryAction)).font(.caption.weight(.semibold))
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
                 ? language.text(.aiOnlineShort)
                 : language.text(.localModeShort))
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            if chatVM.connectionStatus == .localOnly {
                // Offline empty state — clear but friendly
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 44)).foregroundStyle(.orange.opacity(0.45))
                Text(language.text(.chatOfflineTitle))
                    .font(.title3.weight(.semibold))
                Text(language.text(.chatOfflineDescription))
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)

                if !chatVM.conversationStarters.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(chatVM.conversationStarters.prefix(3)), id: \.id) { starter in
                            Button { sendStarter(starter.text) } label: {
                                starterRow(starter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                // Connected empty state — context-aware
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 44)).foregroundStyle(.indigo.opacity(0.45))
                Text(language.text(.chatContextEmptyTitle))
                    .font(.title3.weight(.semibold))
                Text(language.text(.chatContextEmptyHint))
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)

                if !chatVM.conversationStarters.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(chatVM.conversationStarters.enumerated()), id: \.element.id) { index, starter in
                            Button { sendStarter(starter.text) } label: {
                                starterRow(starter)
                            }
                            .buttonStyle(.plain)
                            .softAppear(true, delay: Double(index) * 0.05, yOffset: 8, reduceMotion: reduceMotion)
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

    private func starterRow(_ starter: ConversationStarter) -> some View {
        HStack(spacing: 8) {
            Image(systemName: starter.icon)
                .font(.caption)
                .foregroundStyle(.indigo)
                .frame(width: 20)
            Text(starter.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
    }

    private func sendStarter(_ text: String) {
        chatVM.sendMessage(text, context: viewModel.agentContext, aiEnabled: aiEnabled, preferredLanguage: language.rawValue)
    }

    // MARK: - Skeleton State

    private var chatSkeleton: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            ForEach(0..<4) { i in
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: CGFloat([200, 160, 240, 180][i]), height: 14)
                    Spacer()
                }
                .padding(.vertical, 6)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .id("chatSkeleton")
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                TextField(language.text(.chatPlaceholder), text: $inputText, axis: .vertical)
                    .lineLimit(1...5).textFieldStyle(.plain)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isInputFocused ? Color.indigo.opacity(0.45) : Color.clear, lineWidth: 1)
                    }
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
                .disabled(!canSend)
                .pressableScale()
                .scaleEffect(canSend && !reduceMotion ? 1.08 : 1)
                .padding(.trailing, 12).padding(.bottom, 5)
            }
            .padding(.vertical, 4)
            .padding(.leading, 8)
            .background(.regularMaterial)
            .shadow(color: .black.opacity(OhShadow.input.opacity), radius: OhShadow.input.radius, y: OhShadow.input.y)
            .animation(OhAnimation.press(), value: isInputFocused)
            .animation(OhAnimation.press(), value: canSend)
        }
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        withAnimation(OhAnimation.tab()) {
            chatVM.sendMessage(text, context: viewModel.agentContext, aiEnabled: aiEnabled, preferredLanguage: language.rawValue)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .softAppear(true, yOffset: 8, reduceMotion: reduceMotion)
        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: message.role == .user ? .trailing : .leading)))
    }
}

// MARK: - Streaming Bubble

private struct StreamingBubble: View {
    let text: String
    let streamState: StreamState
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text(.chatCoachName))
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.leading, 4)

                switch streamState {
                case .connecting:
                    HStack(spacing: 4) {
                        Text(language.text(.thinkingLabel))
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
        .softAppear(true, yOffset: 8, reduceMotion: reduceMotion)
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
                    .animation(OhAnimation.dotPulse.delay(Double(i) * 0.2), value: animating)
            }
        }
        .onAppear { animating = true }
    }
}

#Preview {
    ChatView(viewModel: OHeasViewModel(), language: .chinese, pendingPrompt: .constant(nil))
}
