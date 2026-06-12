//
//  HealthPermissionRecoveryView.swift
//  OHeas
//
//  Shows per-metric HealthKit data coverage instead of authorization
//  status.  Apple HealthKit does not expose read-permission status
//  per type – `authorizationStatus(for:)` only reports sharing (write)
//  authorization.  Since OHeas requests read-only access, that API
//  always returns `.sharingDenied`.
//
//  This view reports what we can actually observe: whether HealthKit
//  data is flowing for each metric, which is what the user really
//  cares about.
//

import HealthKit
import OHeasCore
import SwiftUI

struct HealthPermissionRecoveryView: View {
    /// Whether the app is currently reading from Apple Health.
    let dataSource: HealthDataSource

    /// Per‑metric data coverage from the most recent load.
    let perMetricStatus: [HealthMetric: MetricStatus]

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    // MARK: - Metric list (same 7 types the app reads)

    private struct MetricInfo {
        let metric: HealthMetric
        let icon: String
        let nameKey: TextKey
        let descriptionKey: TextKey
    }

    private let metrics: [MetricInfo] = [
        .init(metric: .sleepHours,       icon: "moon.zzz",           nameKey: .sleepName,           descriptionKey: .hkSleepDescription),
        .init(metric: .hrv,              icon: "heart",              nameKey: .hrvName,             descriptionKey: .hkHRVDescription),
        .init(metric: .restingHeartRate, icon: "heart.text.square",  nameKey: .restingHeartRateName, descriptionKey: .hkRHRDescription),
        .init(metric: .steps,            icon: "shoeprints.fill",    nameKey: .stepsName,           descriptionKey: .hkStepsDescription),
        .init(metric: .activeEnergyKcal, icon: "flame",              nameKey: .activeEnergyName,    descriptionKey: .hkEnergyDescription),
        .init(metric: .exerciseMinutes,  icon: "figure.walk",        nameKey: .exerciseMinutesName, descriptionKey: .hkExerciseDescription),
        .init(metric: .workouts,         icon: "figure.run",         nameKey: .workoutsName,        descriptionKey: .hkWorkoutsDescription),
    ]

    var body: some View {
        NavigationStack {
            List {
                // Overall status banner
                Section {
                    overallStatusBanner
                }

                // Per‑metric data coverage
                Section {
                    ForEach(metrics, id: \.metric) { info in
                        let status = perMetricStatus[info.metric] ?? .missing
                        statusRow(
                            icon: info.icon,
                            name: language.text(info.nameKey),
                            description: language.text(info.descriptionKey),
                            status: status
                        )
                    }
                } header: {
                    Text(language.text(.permissionStatusTitle))
                } footer: {
                    Text(language.text(.permissionFixDescription))
                }

                // System settings link
                Section {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link(destination: url) {
                            Label(language.text(.openHealthSettings), systemImage: "gear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } header: {
                    Text(language.text(.howToFix))
                }
            }
            .navigationTitle(language.text(.healthPermissionsNavTitle))
        }
    }

    // MARK: - Overall Status

    private var overallStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch.radiowaves")
                .font(.title)
                .foregroundStyle(bannerColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(bannerTitle)
                    .font(.headline)
                Text(bannerSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var bannerColor: Color {
        switch dataSource {
        case .appleHealth: return .green
        case .mock:        return .orange
        }
    }

    private var bannerTitle: String {
        switch dataSource {
        case .appleHealth:
            return language.text(.healthKitConnected)
        case .mock:
            return language.text(.healthKitNotConnected)
        }
    }

    private var bannerSubtitle: String {
        switch dataSource {
        case .appleHealth:
            let available = perMetricStatus.values.filter { $0 == .valid || $0 == .partial }.count
            return "\(available)/\(metrics.count) \(language.text(.metricsHaveData))"
        case .mock:
            return language.text(.permissionWhyDescription)
        }
    }

    // MARK: - Status row

    private func statusRow(icon: String, name: String, description: String, status: MetricStatus) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(statusColor(status))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    statusBadge(status)
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusBadge(_ status: MetricStatus) -> some View {
        switch status {
        case .valid:
            Text(language.text(.dataAvailable))
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
        case .partial:
            Text(language.text(.dataPartial))
                .font(.caption.weight(.medium))
                .foregroundStyle(.blue)
        case .missing:
            Text(language.text(.noData))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private func statusColor(_ status: MetricStatus) -> Color {
        switch status {
        case .valid:   return .green
        case .partial: return .blue
        case .missing: return .secondary
        }
    }
}

#Preview {
    HealthPermissionRecoveryView(
        dataSource: .mock,
        perMetricStatus: [
            .sleepHours: .valid,
            .hrv: .partial,
            .restingHeartRate: .valid,
            .steps: .valid,
            .activeEnergyKcal: .missing,
            .exerciseMinutes: .valid,
            .workouts: .partial,
        ]
    )
}
