//
//  SettingsView.swift
//  OHeas
//
//  SettingsView.swift — OHeas UI component.
//  iOS-native drill-down structure: compact top-level rows → sub-pages.
//

import OHeasCore
import SwiftUI

// MARK: - Settings (Top Level)

struct SettingsView: View {
    @ObservedObject var viewModel: OHeasViewModel
    @State private var showResetConfirmation = false

    private var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "oheas.language") ?? "zh") ?? .chinese
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Profile + Account
                Section {
                    NavigationLink {
                        AccountView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(.indigo.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: viewModel.dataSource == .appleHealth ? "applewatch" : "testtube.2")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.dataSource == .appleHealth ? .green : .secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.currentUser?.displayName ?? viewModel.currentUser?.email ?? "OHeas")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(confidenceColor(viewModel.dataQuality?.overallConfidence ?? .low))
                                        .frame(width: 5, height: 5)
                                    Text(language.dataSource(viewModel.dataSource))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }

                // MARK: Achievements
                Section {
                    NavigationLink {
                        AchievementsView(
                            snapshot: viewModel.gamificationSnapshot,
                            language: language
                        )
                    } label: {
                        Label(language.text(.achievementsTitle), systemImage: "trophy.fill")
                    }
                }

                // MARK: Preferences
                Section {
                    NavigationLink {
                        PreferencesView(language: language)
                    } label: {
                        Label(language.text(.preferencesSection), systemImage: "gearshape")
                    }
                }

                // MARK: Privacy & Consent
                Section {
                    NavigationLink {
                        PrivacyConsentView(viewModel: viewModel, language: language)
                    } label: {
                        Label(language.text(.privacySection), systemImage: "hand.raised")
                    }
                }

                // MARK: About
                Section {
                    LabeledContent(
                        language.text(.versionLabel),
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? language.text(.betaLabel)
                    )
                    LabeledContent(
                        language.text(.buildLabel),
                        value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Local"
                    )
                    if viewModel.effectivenessReport != nil {
                        NavigationLink {
                            EffectivenessDetailView(viewModel: viewModel, language: language)
                        } label: {
                            Label(language.text(.effectivenessTitle), systemImage: "chart.bar.doc.horizontal")
                        }
                    }
                } header: {
                    Text(language.text(.appSection))
                }

                // MARK: Developer Tools (DEBUG only)
#if DEBUG
                Section {
                    NavigationLink {
                        DeveloperToolsView(viewModel: viewModel, language: language, showResetConfirmation: $showResetConfirmation)
                    } label: {
                        Label(language.text(.testingToolsSection), systemImage: "wrench.and.screwdriver")
                    }
                } footer: {
                    Text(language.text(.testingToolsFooter))
                }
#endif
            }
            .navigationTitle(language.text(.settingsTitle))
            .confirmationDialog(
                language.text(.resetDialogTitle),
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button(language.text(.resetConfirmButton), role: .destructive) {
                    viewModel.confirmResetLocalData()
                }
                Button(language.text(.cancelButton), role: .cancel) {}
            } message: {
                Text(language.text(.resetDialogMessage))
            }
        }
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }
}

// MARK: - Preferences Sub-page

private struct PreferencesView: View {
    let language: AppLanguage
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    @AppStorage("oheas.aiEnabled") private var aiEnabled = true
    @AppStorage("oheas.remindersEnabled") private var remindersEnabled = false

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    LanguageView(selectedLanguage: $languageRawValue)
                } label: {
                    LabeledContent(language.text(.languageSetting), value: currentLanguage.settingsName)
                }
            }

            Section {
                Toggle(language.text(.remindersEnabled), isOn: $remindersEnabled)
            }

            Section {
                Toggle(language.text(.aiEnabled), isOn: $aiEnabled)
            } footer: {
                Text(language.text(.aiFooter))
            }
        }
        .navigationTitle(language.text(.preferencesSection))
    }
}

// MARK: - Language Sub-page

private struct LanguageView: View {
    @Binding var selectedLanguage: String

    var body: some View {
        Form {
            Section {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        selectedLanguage = lang.rawValue
                    } label: {
                        HStack {
                            Text(lang.settingsName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedLanguage == lang.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle((AppLanguage(rawValue: selectedLanguage) ?? .chinese).text(.languageSetting))
    }
}

// MARK: - Privacy & Consent Sub-page

private struct PrivacyConsentView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    var body: some View {
        Form {
            Section {
                Toggle(language.text(.aiConsentLabel), isOn: Binding(
                    get: { viewModel.hasConsent(.aiLifestyleAdvice) },
                    set: { viewModel.recordConsent(.aiLifestyleAdvice, accepted: $0) }
                ))
            }

            Section {
                Toggle(language.text(.cloudConsentLabel), isOn: Binding(
                    get: { viewModel.hasConsent(.cloudSync) },
                    set: { viewModel.recordConsent(.cloudSync, accepted: $0) }
                ))
            }

            Section {
                Toggle(language.text(.betaAnalyticsConsentLabel), isOn: Binding(
                    get: { viewModel.hasConsent(.betaAnalytics) },
                    set: { viewModel.recordConsent(.betaAnalytics, accepted: $0) }
                ))
            }

            Section {
                NavigationLink {
                    PrivacyView(viewModel: viewModel)
                } label: {
                    Label(language.text(.privacyControlsLabel), systemImage: "lock.shield")
                }
                NavigationLink {
                    HealthPermissionRecoveryView()
                } label: {
                    Label(language.text(.healthPermissionsLabel), systemImage: "heart.text.square")
                }
            }
        }
        .navigationTitle(language.text(.privacySection))
    }
}

// MARK: - Developer Tools Sub-page (DEBUG only)

#if DEBUG
private struct DeveloperToolsView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage
    @Binding var showResetConfirmation: Bool

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    BetaFeedbackView(viewModel: viewModel)
                } label: {
                    Label(language.text(.betaFeedbackLabel), systemImage: "bubble.left.and.bubble.right")
                }
                NavigationLink {
                    BetaAnalyticsDashboardView(viewModel: viewModel)
                } label: {
                    Label(language.text(.betaAnalyticsLabel), systemImage: "chart.bar")
                }
                NavigationLink {
                    AgentContextView(viewModel: viewModel, language: language)
                } label: {
                    Label(language.text(.agentContextLabel), systemImage: "curlybraces.square")
                }
                NavigationLink {
                    DemoModeView(viewModel: viewModel)
                } label: {
                    Label(language.text(.demoModeLabel), systemImage: "theatermasks")
                }
                NavigationLink {
                    EvaluationDebugView(viewModel: viewModel)
                } label: {
                    Label(language.text(.evaluationLabel), systemImage: "checklist")
                }
            } header: {
                Text(language.text(.testingToolsSection))
            }

            Section {
                Button {
                    viewModel.exportLocalData()
                } label: {
                    Label(language.text(.exportLabel), systemImage: "square.and.arrow.up")
                }
                if let export = viewModel.exportManifest {
                    Text(export.includesRawHealthSamples
                        ? language.text(.exportReadyYes)
                        : language.text(.exportReadyNo))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(language.text(.dataManagementSection))
            }

            Section {
                Button(role: .destructive) {
                    viewModel.requestResetLocalData()
                    showResetConfirmation = true
                } label: {
                    Label(language.text(.resetLabel), systemImage: "trash")
                }
            }
        }
        .navigationTitle(language.text(.testingToolsSection))
    }
}
#endif

// MARK: - Effectiveness Detail View

private struct EffectivenessDetailView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let report = viewModel.effectivenessReport {
                    Text(report.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricTile(title: language.text(.metricAdherence), value: percent(report.recommendationAdherenceRate), icon: "checkmark.circle")
                        MetricTile(title: language.text(.metricPlanCompletion), value: percent(report.planCompletionRate), icon: "calendar.badge.checkmark")
                        MetricTile(title: language.text(.metricExperimentCompletion), value: percent(report.experimentCompletionRate), icon: "flask")
                        MetricTile(title: language.text(.metricLikelyHelped), value: percent(report.likelyHelpedRate), icon: "chart.line.uptrend.xyaxis")
                        MetricTile(title: language.text(.metricDataCoverage), value: percent(report.dataCoverageRate), icon: "applewatch")
                        MetricTile(title: language.text(.metricConfidence), value: percent(report.averageConfidence), icon: "gauge")
                    }

                    if !report.mostPromisingInterventions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(language.text(.mostPromising))
                                .font(.subheadline.weight(.semibold))
                            ForEach(report.mostPromisingInterventions, id: \.self) { item in
                                Label(item, systemImage: "sparkle.magnifyingglass")
                                    .font(.footnote)
                            }
                        }
                        .padding()
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if !report.weakestAreas.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(language.text(.weakestAreas))
                                .font(.subheadline.weight(.semibold))
                            ForEach(report.weakestAreas, id: \.self) { item in
                                Label(item, systemImage: "exclamationmark.triangle")
                                    .font(.footnote)
                            }
                        }
                        .padding()
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    ContentUnavailableView(
                        language.text(.noEffectivenessReport),
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text(language.text(.emptyDescription))
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(language.text(.effectivenessTitle))
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

#Preview {
    SettingsView(viewModel: OHeasViewModel())
}
