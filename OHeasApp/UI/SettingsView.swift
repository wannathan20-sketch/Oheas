//
//  SettingsView.swift
//  OHeas
//
//  SettingsView.swift — OHeas UI component.
//

import OHeasCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: OHeasViewModel
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    @AppStorage("oheas.aiEnabled") private var aiEnabled = true
    @AppStorage("oheas.remindersEnabled") private var remindersEnabled = false
    @State private var showResetConfirmation = false
    @State private var showBetaTools = false

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some View {
        NavigationStack {
            Form {
                // Profile summary
                profileSection

                // Privacy & Consent
                Section {
                    Toggle(language.text(.aiEnabled), isOn: $aiEnabled)
                    Toggle(language.text(.remindersEnabled), isOn: $remindersEnabled)
                    Toggle(language.text(.aiConsentLabel), isOn: Binding(
                        get: { viewModel.hasConsent(.aiLifestyleAdvice) },
                        set: { viewModel.recordConsent(.aiLifestyleAdvice, accepted: $0) }
                    ))
                    Toggle(language.text(.cloudConsentLabel), isOn: Binding(
                        get: { viewModel.hasConsent(.cloudSync) },
                        set: { viewModel.recordConsent(.cloudSync, accepted: $0) }
                    ))
                    Toggle(language.text(.betaAnalyticsConsentLabel), isOn: Binding(
                        get: { viewModel.hasConsent(.betaAnalytics) },
                        set: { viewModel.recordConsent(.betaAnalytics, accepted: $0) }
                    ))
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
                } header: {
                    Text(language.text(.privacySection))
                } footer: {
                    Text(language.text(.aiFooter))
                }

                // Account & Sync
                Section {
                    NavigationLink {
                        AccountView(viewModel: viewModel)
                    } label: {
                        Label(language.text(.accountLabel), systemImage: "person.crop.circle")
                    }
                    NavigationLink {
                        SyncStatusView(viewModel: viewModel)
                    } label: {
                        Label(language.text(.syncStatusLabel), systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text(language.text(.accountSection))
                }

                // Effectiveness
                if viewModel.effectivenessReport != nil {
                    Section {
                        NavigationLink {
                            EffectivenessDetailView(viewModel: viewModel, language: language)
                        } label: {
                            Label(language.text(.effectivenessTitle), systemImage: "chart.bar.doc.horizontal")
                        }
                    } header: {
                        Text(language.text(.insightsTab))
                    }
                }

                // Beta Tools (collapsible) — DEBUG only
#if DEBUG
                Section {
                    DisclosureGroup(isExpanded: $showBetaTools) {
                        betaToolsContent
                            .padding(.top, 8)
                    } label: {
                        Label(language.text(.betaSection), systemImage: "wrench.and.screwdriver")
                            .font(.subheadline.weight(.medium))
                    }
                }
#endif

                // Language
                Section {
                    Picker(language.text(.languageSetting), selection: $languageRawValue) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.settingsName).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(language.text(.languageSetting))
                } footer: {
                    Text(language.text(.languageFooter))
                }

                // App info
                Section {
                    LabeledContent(language.text(.versionLabel), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Beta")
                    LabeledContent(language.text(.buildLabel), value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Local")
                } header: {
                    Text(language.text(.appSection))
                }
            }
            .navigationTitle(language.text(.settingsTitle))
            .confirmationDialog(language.text(.resetDialogTitle), isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button(language.text(.resetConfirmButton), role: .destructive) {
                    viewModel.confirmResetLocalData()
                }
                Button(language.text(.cancelButton), role: .cancel) {}
            } message: {
                Text(language.text(.resetDialogMessage))
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.indigo.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: viewModel.dataSource == .appleHealth ? "applewatch" : "testtube.2")
                        .font(.title3)
                        .foregroundStyle(viewModel.dataSource == .appleHealth ? .green : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("OHeas")
                        .font(.headline)
                    Text(language.dataSource(viewModel.dataSource))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let today = viewModel.todayMetrics, let quality = viewModel.dataQuality {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(confidenceColor(quality.overallConfidence))
                                .frame(width: 6, height: 6)
                            Text("\(language.text(.dataConfidence)): \(language.confidence(quality.overallConfidence))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }

    // MARK: - Beta Tools Content

#if DEBUG
    private var betaToolsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                BetaFeedbackView(viewModel: viewModel)
            } label: {
                Label(language.text(.betaFeedbackLabel), systemImage: "bubble.left.and.bubble.right")
            }

            NavigationLink {
                BetaAnalyticsDashboardView(viewModel: viewModel)
            } label: {
                Label(language.text(.betaAnalyticsLabel), systemImage: "chart.bar.doc.horizontal")
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

            NavigationLink {
                AgentContextView(viewModel: viewModel, language: language)
            } label: {
                Label(language.text(.agentContextLabel), systemImage: "curlybraces.square")
            }

            Button {
                viewModel.exportLocalData()
            } label: {
                Label(language.text(.exportLabel), systemImage: "square.and.arrow.up")
            }

            if let export = viewModel.exportManifest {
                Text(export.includesRawHealthSamples ? language.text(.exportReadyYes) : language.text(.exportReadyNo))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                viewModel.requestResetLocalData()
                showResetConfirmation = true
            } label: {
                Label(language.text(.resetLabel), systemImage: "trash")
            }
        }
    }
#endif
}

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
                        EffectivenessMetricTile(title: language.text(.metricAdherence), value: percent(report.recommendationAdherenceRate), icon: "checkmark.circle")
                        EffectivenessMetricTile(title: language.text(.metricPlanCompletion), value: percent(report.planCompletionRate), icon: "calendar.badge.checkmark")
                        EffectivenessMetricTile(title: language.text(.metricExperimentCompletion), value: percent(report.experimentCompletionRate), icon: "flask")
                        EffectivenessMetricTile(title: language.text(.metricLikelyHelped), value: percent(report.likelyHelpedRate), icon: "chart.line.uptrend.xyaxis")
                        EffectivenessMetricTile(title: language.text(.metricDataCoverage), value: percent(report.dataCoverageRate), icon: "applewatch")
                        EffectivenessMetricTile(title: language.text(.metricConfidence), value: percent(report.averageConfidence), icon: "gauge")
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
                    ContentUnavailableView(language.text(.noEffectivenessReport), systemImage: "chart.bar.doc.horizontal", description: Text(language.text(.emptyDescription)))
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

private struct EffectivenessMetricTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SettingsView(viewModel: OHeasViewModel())
}
