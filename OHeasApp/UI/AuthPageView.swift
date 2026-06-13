//
//  AuthPageView.swift
//  OHeas
//
//  Standalone full‑screen auth page shown after onboarding.
//  Offers Sign Up, Sign In, and Apple Sign In.
//  独立的全屏登录/注册页面，在引导流程之后展示。
//

import AuthenticationServices
import OHeasCore
import SwiftUI

struct AuthPageView: View {
    @ObservedObject var viewModel: OHeasViewModel
    /// Called when the user dismisses this page (skip or signed in).
    let onDismiss: () -> Void

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    @State private var isSignUpMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some View {
        VStack(spacing: 0) {
            // Brand header
            brandHeader

            // Form
            ScrollView {
                VStack(spacing: 24) {
                    // Sign Up / Sign In segmented picker
                    Picker(language.text(.mode), selection: $isSignUpMode) {
                        Text(language.text(.signUpTabLabel)).tag(true)
                        Text(language.text(.signInTabLabel)).tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)

                    // Email form card
                    VStack(spacing: 14) {
                        if isSignUpMode {
                            TextField(language.text(.nicknamePlaceholder), text: $nickname)
                                .textContentType(.nickname)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        TextField(language.text(.emailPlaceholder), text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        SecureField(language.text(.passwordPlaceholder), text: $password)
                            .textContentType(isSignUpMode ? .newPassword : .password)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Submit button
                        Button {
                            submit()
                        } label: {
                            HStack {
                                Spacer()
                                if case .loading = viewModel.authState {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUpMode
                                         ? language.text(.createAccountButton)
                                         : language.text(.signInLabel))
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(email.isEmpty || password.count < 6
                                          ? Color(.systemGray4)
                                          : (isSignUpMode ? Color.indigo : Color.accentColor))
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(email.isEmpty || password.count < 6)

                        if let err = viewModel.authError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                    .padding(.horizontal, 16)

                    // Divider
                    HStack(spacing: 12) {
                        VStack { Divider() }
                        Text(language.text(.orLabel))
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        VStack { Divider() }
                    }
                    .padding(.horizontal, 32)

                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            syncFields()
                            await viewModel.handleAppleSignIn(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)

                    // Footer note
                    Text(language.text(.deviceAutoLoginNote))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 16)
            }

            // Skip button — pinned at bottom
            VStack(spacing: 0) {
                Divider()
                Button {
                    viewModel.completeAuthPage()
                    onDismiss()
                } label: {
                    Text(language.text(.authPageSkip))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            email = viewModel.accountEmail
            password = viewModel.accountPassword
            nickname = viewModel.accountNickname
            // Try device auth in background so user has anonymous access if they skip.
            Task { await viewModel.performDeviceAuth() }
        }
        .onChange(of: viewModel.authState) {
            if viewModel.authState == .signedIn {
                // Mark auth page as done so it won't show again next launch.
                // Navigation is state-driven — shouldShowAuthPage in AppRootView
                // will switch to RootTabView automatically.
                viewModel.completeAuthPage()
            }
        }
    }

    // MARK: - Brand header

    private var brandHeader: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 32)

            OHeasLogo(size: 56, showBackground: true)

            Text(language.text(.authPageTitle))
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(language.text(.authPageSubtitle))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Helpers

    private func submit() {
        syncFields()
        Task {
            if isSignUpMode {
                await viewModel.registerWithEmail()
            } else {
                await viewModel.loginWithEmail()
            }
        }
    }

    private func syncFields() {
        viewModel.accountEmail = email
        viewModel.accountPassword = password
        viewModel.accountNickname = nickname
    }
}
