//
//  AccountView.swift
//  OHeas
//
//  Account management — Apple Sign In, Email Login, Email Binding.
//  账号管理 — Apple 登录、邮箱登录、邮箱绑定。
//

import AuthenticationServices
import OHeasCore
import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: OHeasViewModel
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    @State private var authMode: AuthFormMode = .signUp

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    private enum AuthFormMode: String, CaseIterable {
        case signUp
        case signIn

        var labelKey: TextKey {
            switch self {
            case .signUp: .signUpTabLabel
            case .signIn: .signInTabLabel
            }
        }
    }

    var body: some View {
        Form {
            // MARK: Mode
            Section {
                LabeledContent(language.text(.mode), value: modeText)
                if let userId = viewModel.currentUserId {
                    LabeledContent(language.userIDLabel, value: userId.uuidString)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                if let email = viewModel.currentUser?.email {
                    LabeledContent(language.text(.email), value: email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(language.text(.mode))
            }

            // MARK: Signed-in actions
            if viewModel.authState == .signedIn {
                signedInContent
            } else {
                notSignedInContent
            }

            // Error display
            if let authError = viewModel.authError {
                Section {
                    Text(authError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(language.text(.accountLabel))
    }

    // MARK: - Signed In Content

    @ViewBuilder
    private var signedInContent: some View {
        // Nickname
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.text(.nicknameDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    TextField(
                        viewModel.currentUser?.nickname ?? language.text(.nicknamePlaceholder),
                        text: Binding(
                            get: { viewModel.accountNickname },
                            set: { viewModel.accountNickname = $0 }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                    Button(language.text(.setNicknameButton)) {
                        Task {
                            let ok = await viewModel.setNickname()
                            if ok {
                                viewModel.accountNickname = viewModel.accountNickname.trimmingCharacters(in: .whitespaces)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(viewModel.accountNickname.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if let err = viewModel.authError, err.contains("Nickname") || err.contains("昵称") {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text(language.text(.nicknameLabel))
        }

        // Email binding
        Section {
            if viewModel.currentUser?.email != nil {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.text(.emailAlreadyBoundLabel))
                            .font(.headline)
                        Text(viewModel.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.text(.bindEmailDescription))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField(language.text(.emailPlaceholder), text: Binding(
                        get: { viewModel.accountEmail },
                        set: { viewModel.accountEmail = $0 }
                    ))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                    SecureField(language.text(.passwordPlaceholder), text: Binding(
                        get: { viewModel.accountPassword },
                        set: { viewModel.accountPassword = $0 }
                    ))
                    .textContentType(.newPassword)

                    Button {
                        Task { await viewModel.bindEmail() }
                    } label: {
                        HStack {
                            Spacer()
                            Text(language.text(.bindEmailButton))
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.accountEmail.isEmpty || viewModel.accountPassword.count < 6)
                }
            }
        } header: {
            Text(language.text(.bindEmailLabel))
        }

        // Sign out
        Section {
            Button(role: .destructive) {
                viewModel.signOutOfApple()
            } label: {
                Label(language.text(.signOut), systemImage: "rectangle.portrait.and.arrow.right")
            }
        } header: {
            Text(language.text(.accountLabel))
        }
    }

    // MARK: - Not Signed In Content

    @ViewBuilder
    private var notSignedInContent: some View {
        // Sign Up / Sign In picker
        Section {
            Picker(language.text(.mode), selection: $authMode) {
                ForEach(AuthFormMode.allCases, id: \.self) { mode in
                    Text(language.text(mode.labelKey)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }

        // Email form
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(authMode == .signUp
                     ? language.text(.registerDescription)
                     : language.text(.emailLoginDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Nickname field — only for sign up
                if authMode == .signUp {
                    TextField(language.text(.nicknamePlaceholder), text: Binding(
                        get: { viewModel.accountNickname },
                        set: { viewModel.accountNickname = $0 }
                    ))
                    .textContentType(.nickname)
                    .autocorrectionDisabled()
                }

                TextField(language.text(.emailPlaceholder), text: Binding(
                    get: { viewModel.accountEmail },
                    set: { viewModel.accountEmail = $0 }
                ))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)

                SecureField(language.text(.passwordPlaceholder), text: Binding(
                    get: { viewModel.accountPassword },
                    set: { viewModel.accountPassword = $0 }
                ))
                .textContentType(authMode == .signUp ? .newPassword : .password)

                Button {
                    Task {
                        if authMode == .signUp {
                            await viewModel.registerWithEmail()
                        } else {
                            await viewModel.loginWithEmail()
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if case .loading = viewModel.authState {
                            ProgressView()
                        } else {
                            Text(authMode == .signUp
                                 ? language.text(.createAccountButton)
                                 : language.text(.signInLabel))
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.accountEmail.isEmpty || viewModel.accountPassword.count < 6)
                .tint(authMode == .signUp ? .indigo : .accentColor)
            }
        } header: {
            Text(authMode == .signUp
                 ? language.text(.createAccountLabel)
                 : language.text(.emailLoginLabel))
        }

        // Divider
        Section {
            HStack {
                VStack { Divider() }
                Text(language.text(.orLabel))
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                VStack { Divider() }
            }
        }

        // Apple Sign In
        Section {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    await viewModel.handleAppleSignIn(result: result)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
        } header: {
            Text(language.signInWithAppleLabel)
        } footer: {
            Text(language.text(.signInFooter))
        }

        // Skip / anonymous note
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text(.deviceAutoLoginNote))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
