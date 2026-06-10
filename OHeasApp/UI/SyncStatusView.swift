//
//  SyncStatusView.swift
//  OHeas
//
//  SyncStatusView.swift — OHeas UI component.
//  SyncStatusView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var viewModel: OHeasViewModel

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }


    var body: some View {
        Form {
            Section {
                LabeledContent(language.text(.modeLabel), value: viewModel.syncState.mode.rawValue)
                LabeledContent(language.text(.pendingLabel), value: "\(viewModel.syncState.pendingCount)")
                LabeledContent(language.text(.lastSyncedLabel), value: viewModel.syncState.lastSyncedAt?.formatted(date: .abbreviated, time: .shortened) ?? language.text(.neverLabel))
                if let error = viewModel.syncState.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text(language.text(.syncStatusSection))
            }

            Section {
                Button {
                    Task { await viewModel.syncNow() }
                } label: {
                    Label(language.text(.syncNow), systemImage: "arrow.triangle.2.circlepath")
                }
                Button {
                    viewModel.pauseSync()
                } label: {
                    Label(language.text(.pauseSync), systemImage: "pause.circle")
                }
                Button {
                    viewModel.resumeSync()
                } label: {
                    Label(language.text(.resumeSync), systemImage: "play.circle")
                }
            } footer: {
                Text(language.text(.syncStatusDescription))
            }
        }
        .navigationTitle(language.text(.syncNavTitle))
    }
}
