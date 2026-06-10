//
//  RootTabView.swift
//  OHeas
//
//  RootTabView.swift — OHeas UI component.
//

import SwiftUI

struct RootTabView: View {
    @ObservedObject var viewModel: OHeasViewModel
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

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
        TabView {
            TodayView(viewModel: viewModel, language: language)
                .tabItem {
                    Label(language.text(.todayTab), systemImage: "heart.text.square.fill")
                }

            ChatView(viewModel: viewModel, language: language)
                .tabItem {
                    Label(language.text(.chatTab), systemImage: "bubble.left.and.bubble.right.fill")
                }

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label(language.text(.settingsTitle), systemImage: "gearshape.fill")
                }
        }
        .tint(.indigo)
    }
}
