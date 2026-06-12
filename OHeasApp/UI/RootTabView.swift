//
//  RootTabView.swift
//  OHeas
//
//  RootTabView.swift — OHeas UI component.
//

import SwiftUI

enum AppTab: Hashable {
    case today, plan, trends, chat, settings
}

struct RootTabView: View {
    @ObservedObject var viewModel: OHeasViewModel
    @Environment(\.appLanguage) private var language
    @State private var selectedTab: AppTab = .today
    /// Shared pending chat prompt — set by TodayView chips, read & cleared by ChatView.
    @State private var pendingChatPrompt: String?

    init(viewModel: OHeasViewModel) {
        self.viewModel = viewModel

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = .secondaryLabel
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        itemAppearance.selected.iconColor = .systemIndigo
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemIndigo]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(viewModel: viewModel, language: language, onNavigateToChat: { prompt in
                pendingChatPrompt = prompt
                selectedTab = .chat
            })
                .tabItem {
                    Label(language.text(.todayTab), systemImage: selectedTab == .today
                          ? "heart.text.square.fill" : "heart.text.square")
                }
                .tag(AppTab.today)

            PlanTabView(viewModel: viewModel, language: language)
                .tabItem {
                    Label(language.text(.planTab), systemImage: selectedTab == .plan
                          ? "calendar.badge.clock" : "calendar")
                }
                .tag(AppTab.plan)

            TrendsTabView(viewModel: viewModel, language: language)
                .tabItem {
                    Label(language.text(.trendsTab), systemImage: selectedTab == .trends
                          ? "chart.xyaxis.line" : "chart.xyaxis.line")
                }
                .tag(AppTab.trends)

            ChatView(viewModel: viewModel, language: language, pendingPrompt: $pendingChatPrompt)
                .tabItem {
                    Label(language.text(.chatTab), systemImage: selectedTab == .chat
                          ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                }
                .tag(AppTab.chat)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label(language.text(.settingsTitle), systemImage: selectedTab == .settings
                          ? "gearshape.fill" : "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(.indigo)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: selectedTab)
    }
}
