//
//  AccountView.swift
//  OHeas
//
//  Apple Sign In account management.
//  Apple 登录账号管理。
//

import AuthenticationServices
import OHeasCore
import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: OHeasViewModel
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some View {
        Form {
            Section {
                LabeledContent(language.text(.mode), value: modeText)
                if let userId = viewModel.currentUserId {
                    LabeledContent("User ID", value: userId.uuidString)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(language.text(.mode))
            }

            Section {
                if viewModel.authState == .signedIn {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sign in with Apple")
                                .font(.headline)
                            Text(language.text(.cloudSyncModeLabel))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }

                    Button(role: .destructive) {
                        viewModel.signOutOfApple()
                    } label: {
                        Label(language.text(.signOut), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } else {
                    // Sign in with Apple button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await viewModel.handleAppleSignIn(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                }
            } header: {
                Text(language.text(.accountLabel))
            } footer: {
                if viewModel.authState == .signedOut || viewModel.authState == .localOnly {
                    Text(language.text(.signInFooter))
                } else if case .error(let message) = viewModel.authState {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }

            if let lastError = viewModel.authError {
                Section {
                    Text(lastError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(language.text(.accountLabel))
    }

    private var modeText: String {
        switch viewModel.authState {
        case .localOnly: language.text(.localOnlyModeLabel)
        case .signedIn: language.text(.cloudSyncModeLabel)
        case .signedOut: language.text(.signedOutModeLabel)
        case .loading: language.text(.loadingLabel)
        case .error: language.text(.errorModeLabel)
        }
    }
}
