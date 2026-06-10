//
//  HealthPermissionRecoveryView.swift
//  OHeas
//
//  HealthPermissionRecoveryView.swift — OHeas UI component.
//  HealthPermissionRecoveryView.swift — OHeas UI 组件。
//


import HealthKit
import SwiftUI

struct HealthPermissionRecoveryView: View {
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    @State private var sleepStatus: HKAuthorizationStatus = .notDetermined
    @State private var hrvStatus: HKAuthorizationStatus = .notDetermined
    @State private var restingHRStatus: HKAuthorizationStatus = .notDetermined
    @State private var stepsStatus: HKAuthorizationStatus = .notDetermined
    @State private var energyStatus: HKAuthorizationStatus = .notDetermined
    @State private var exerciseStatus: HKAuthorizationStatus = .notDetermined
    @State private var workoutStatus: HKAuthorizationStatus = .notDetermined
    @State private var isChecking = true
    @Environment(\.scenePhase) private var scenePhase

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(language.text(.permissionWhyDescription))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(language.text(.whyHealthKitTitle))
                }

                Section {
                    statusRow(
                        icon: "moon.zzz",
                        name: language.text(.sleepName),
                        description: language.text(.hkSleepDescription),
                        status: sleepStatus
                    )
                    statusRow(
                        icon: "heart",
                        name: language.text(.hrvName),
                        description: language.text(.hkHRVDescription),
                        status: hrvStatus
                    )
                    statusRow(
                        icon: "heart.text.square",
                        name: language.text(.restingHeartRateName),
                        description: language.text(.hkRHRDescription),
                        status: restingHRStatus
                    )
                    statusRow(
                        icon: "shoeprints.fill",
                        name: language.text(.stepsName),
                        description: language.text(.hkStepsDescription),
                        status: stepsStatus
                    )
                    statusRow(
                        icon: "flame",
                        name: language.text(.activeEnergyName),
                        description: language.text(.hkEnergyDescription),
                        status: energyStatus
                    )
                    statusRow(
                        icon: "figure.walk",
                        name: language.text(.exerciseMinutesName),
                        description: language.text(.hkExerciseDescription),
                        status: exerciseStatus
                    )
                    statusRow(
                        icon: "figure.run",
                        name: language.text(.workoutsName),
                        description: language.text(.hkWorkoutsDescription),
                        status: workoutStatus
                    )
                } header: {
                    Text(language.text(.permissionStatusTitle))
                } footer: {
                    if missingCount > 0 {
                        Text("\(missingCount) \(language.text(.permissionMissingMessage))")
                    }
                }

                Section {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link(destination: url) {
                            Label(language.text(.openHealthSettings), systemImage: "gear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text(language.text(.permissionFixDescription))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(language.text(.howToFix))
                }
            }
            .navigationTitle(language.text(.healthPermissionsNavTitle))
            .overlay {
                if isChecking {
                    ProgressView(language.text(.checkingPermissions))
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onAppear { checkAllPermissions() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkAllPermissions()
            }
        }
    }

    private func statusRow(icon: String, name: String, description: String, status: HKAuthorizationStatus) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(status == .sharingAuthorized ? .green : .secondary)

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
    private func statusBadge(_ status: HKAuthorizationStatus) -> some View {
        switch status {
        case .sharingAuthorized:
            Text(language.text(.granted))
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
        case .sharingDenied:
            Text(language.text(.denied))
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
        case .notDetermined:
            Text(language.text(.notAsked))
                .font(.caption.weight(.medium))
                .foregroundStyle(.orange)
        @unknown default:
            Text(language.text(.unknown))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var missingCount: Int {
        [sleepStatus, hrvStatus, restingHRStatus, stepsStatus, energyStatus, exerciseStatus, workoutStatus]
            .filter { $0 != .sharingAuthorized }
            .count
    }

    private func checkAllPermissions() {
        isChecking = true
        let store = HKHealthStore()

        sleepStatus = store.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        hrvStatus = store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!)
        restingHRStatus = store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .restingHeartRate)!)
        stepsStatus = store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .stepCount)!)
        energyStatus = store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!)
        exerciseStatus = store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!)
        workoutStatus = store.authorizationStatus(for: HKObjectType.workoutType())

        isChecking = false
    }
}

#Preview {
    HealthPermissionRecoveryView()
}
