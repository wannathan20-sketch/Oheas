//
//  SyncViewModel.swift
//  OHeas
//
//  Manages auth, cloud sync, analytics, beta readiness, export, reset.
//  管理认证、云同步、分析、Beta 就绪、导出、重置。
//


import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import OHeasCore

@MainActor
final class SyncViewModel: ObservableObject {
    @Published var currentUser: AuthenticatedUser?
    @Published var authState: AuthState = .localOnly
    @Published var accountEmail = ""
    @Published var accountPassword = ""
    @Published var accountNickname = ""
    @Published var syncState: SyncState = SyncState()
    @Published var analyticsSummary: BetaAnalyticsSummary = BetaAnalyticsSummary(
        appOpenCount: 0, recommendationGeneratedCount: 0, feedbackRate: 0,
        experimentCheckinCount: 0, safetyFlagCount: 0, fallbackCount: 0, syncFailureCount: 0
    )
    @Published var recentErrors: [ErrorEvent] = []
    @Published var betaReadinessReport: BetaReadinessReport?
    @Published var exportManifest: LocalDataExportManifest?
    @Published var resetConfirmationState: ResetConfirmationState = .idle
    @Published var scheduledReminders: [Reminder] = []
    @Published var authError: String?

    private let authService = LocalAuthService()
    private let consentManager: ConsentManager
    private let errorReporter: ErrorReporter
    private let reminderScheduler = ReminderScheduler()
    private var syncEngine: SyncEngine!
    private var analyticsService: BetaAnalyticsService!
    private var appleAuthService: AppleAuthService?
    private var backendBaseURL: URL?

    init(consentManager: ConsentManager, errorReporter: ErrorReporter) {
        self.consentManager = consentManager
        self.errorReporter = errorReporter
    }

    func configure(syncEngine: SyncEngine, analyticsService: BetaAnalyticsService) {
        self.syncEngine = syncEngine
        self.analyticsService = analyticsService
    }

    // MARK: - Auth

    func refreshProductState() async {
        currentUser = await authService.restoreSession()
        authState = authService.authState
        syncState = syncEngine.loadState()
        analyticsSummary = analyticsService.summary()
        recentErrors = errorReporter.recent()
    }

    func signIn() async {
        do {
            currentUser = try await authService.signInWithEmail(accountEmail, password: accountPassword)
            authState = authService.authState
            try syncEngine.resumeCloudSync()
            syncState = syncEngine.loadState()
        } catch {
            authState = .error(error.localizedDescription)
            errorReporter.record(category: .sync, message: error.localizedDescription)
        }
    }

    func signUp() async {
        do {
            currentUser = try await authService.signUpWithEmail(accountEmail, password: accountPassword)
            authState = authService.authState
            try syncEngine.resumeCloudSync()
            syncState = syncEngine.loadState()
        } catch {
            authState = .error(error.localizedDescription)
            errorReporter.record(category: .sync, message: error.localizedDescription)
        }
    }

    func signOut() async {
        await authService.signOut()
        currentUser = nil
        authState = authService.authState
    }

    // MARK: - Apple Sign In

    /// Configure the backend URL for Apple Sign In.
    func configureBackend(baseURL: URL?) {
        backendBaseURL = baseURL
        if let url = baseURL {
            appleAuthService = AppleAuthService(backendBaseURL: url)
        } else {
            appleAuthService = nil
        }
    }

    /// Handle Apple Sign In result from ASAuthorizationController.
    func handleAppleSignIn(result: Result<ASAuthorization, any Error>) async {
        #if canImport(AuthenticationServices) && os(iOS)
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                authState = .error("No identity token from Apple")
                authError = "Failed to get identity token from Apple. Please try again."
                return
            }

            guard let service = appleAuthService else {
                authState = .error("Backend not configured")
                authError = authErrorMessage(
                    "Backend URL is not set. Configure OHEAS_BACKEND_URL to enable cloud features.",
                    "未配置后端地址。请在 Info.plist 或 Xcode 编译设置中设置 OHEAS_BACKEND_URL 以启用云服务。"
                )
                return
            }

            authState = .loading
            authError = nil

            do {
                let fullName = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
                let pair = try await service.exchange(
                    identityToken: identityToken,
                    fullName: fullName.isEmpty ? nil : fullName
                )

                // Persist tokens to Keychain.
                AuthTokenStore.saveTokens(pair)

                // Update state.
                currentUser = AuthenticatedUser(
                    id: pair.userId,
                    email: credential.email,
                    displayName: pair.nickname ?? (fullName.isEmpty ? nil : fullName),
                    nickname: pair.nickname,
                    isLocalOnly: false
                )
                if let nick = pair.nickname { accountNickname = nick }
                authState = .signedIn
                try syncEngine.resumeCloudSync()
                syncState = syncEngine.loadState()

                // Update BackendConfiguration for sync.
                if backendBaseURL != nil {
                    BackendAppConfiguration.updateBearerToken(pair.accessToken)
                }
            } catch {
                authState = .error(error.localizedDescription)
                authError = error.localizedDescription
                errorReporter.record(category: .sync, message: "Apple Sign In failed: \(error.localizedDescription)")
            }
        case .failure(let error):
            authState = .error(error.localizedDescription)
            authError = error.localizedDescription
        }
        #else
        authState = .error("Sign in with Apple requires iOS.")
        authError = "Sign in with Apple requires iOS."
        #endif
    }

    /// Sign out of Apple ID and clear tokens.
    func signOutOfApple() {
        AuthTokenStore.clearTokens()
        currentUser = nil
        authState = .localOnly
        authError = nil
        var state = syncEngine.loadState()
        state.mode = .localOnly
        try? syncEngine.saveState(state)
        syncState = syncEngine.loadState()
        BackendAppConfiguration.clearBearerToken()
    }

    /// Try to restore a previous session (Apple or device) from Keychain.
    func restoreAppleSession() {
        guard let pair = AuthTokenStore.loadTokens() else { return }
        currentUser = AuthenticatedUser(
            id: pair.userId,
            email: nil,
            displayName: pair.nickname,
            nickname: pair.nickname,
            isLocalOnly: false
        )
        authState = .signedIn
        if let nick = pair.nickname { accountNickname = nick }
        if backendBaseURL != nil {
            BackendAppConfiguration.updateBearerToken(pair.accessToken)
        }
    }

    /// Perform anonymous device login — no Apple ID required.
    /// Generates a stable device UUID on first launch, exchanges it for a JWT pair.
    func performDeviceAuth() async {
        guard let baseURL = backendBaseURL else { return }

        let deviceAuth = DeviceAuthService()
        do {
            let pair = try await deviceAuth.login(backendBaseURL: baseURL)

            AuthTokenStore.saveTokens(pair)
            currentUser = AuthenticatedUser(
                id: pair.userId,
                email: nil,
                displayName: pair.nickname,
                nickname: pair.nickname,
                isLocalOnly: false
            )
            authState = .signedIn
            if let nick = pair.nickname { accountNickname = nick }

            BackendAppConfiguration.updateBearerToken(pair.accessToken)
            try syncEngine.resumeCloudSync()
            syncState = syncEngine.loadState()
        } catch {
            // Device auth is best-effort — if backend is unreachable or
            // DB is not connected, the app still works in local mode.
            print("[SyncViewModel] Device auth skipped: \(error.localizedDescription)")
        }
    }

    /// Login with email + password. Used for cross-device account recovery
    /// after binding an email to an existing anonymous or Apple account.
    func loginWithEmail() async {
        guard let baseURL = backendBaseURL else {
            authError = authErrorMessage("Backend URL is not configured. Set OHEAS_BACKEND_URL in Info.plist or Xcode build settings.",
                                         "未配置后端地址。请在 Info.plist 或 Xcode 编译设置中设置 OHEAS_BACKEND_URL。")
            return
        }

        authState = .loading
        authError = nil

        do {
            let url = baseURL.appendingPathComponent("v1/auth/email")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = EmailLoginRequest(email: accountEmail, password: accountPassword)
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw AuthError.networkError("Invalid response type")
            }
            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 401 {
                    authError = authErrorMessage("Invalid email or password.",
                                                 "邮箱或密码错误。")
                    authState = .localOnly
                    return
                }
                throw AuthError.networkError("Email login failed: HTTP \(http.statusCode) \(bodyStr)")
            }

            let pair = try JSONDecoder().decode(AuthTokenPair.self, from: data)

            AuthTokenStore.saveTokens(pair)
            currentUser = AuthenticatedUser(
                id: pair.userId,
                email: accountEmail,
                displayName: pair.nickname,
                nickname: pair.nickname,
                isLocalOnly: false
            )
            authState = .signedIn
            if let nick = pair.nickname { accountNickname = nick }

            BackendAppConfiguration.updateBearerToken(pair.accessToken)
            try syncEngine.resumeCloudSync()
            syncState = syncEngine.loadState()
        } catch {
            authState = .error(error.localizedDescription)
            authError = error.localizedDescription
            errorReporter.record(category: .sync, message: "Email login failed: \(error.localizedDescription)")
        }
    }

    /// Register a new account with email + password.
    /// Used for first-time email sign-up (does not require a pre-existing account).
    func registerWithEmail() async {
        guard let baseURL = backendBaseURL else {
            authError = authErrorMessage("Backend URL is not configured. Set OHEAS_BACKEND_URL in Info.plist or Xcode build settings.",
                                         "未配置后端地址。请在 Info.plist 或 Xcode 编译设置中设置 OHEAS_BACKEND_URL。")
            return
        }

        authState = .loading
        authError = nil

        do {
            let url = baseURL.appendingPathComponent("v1/auth/register")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let nickname = accountNickname.trimmingCharacters(in: .whitespaces)
            let body = EmailRegisterRequest(
                email: accountEmail,
                password: accountPassword,
                nickname: nickname.isEmpty ? nil : nickname
            )
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw AuthError.networkError("Invalid response type")
            }
            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 409 {
                    authError = authErrorMessage("This email is already registered. Please sign in instead.",
                                                 "该邮箱已注册，请切换到登录。")
                    authState = .localOnly
                    return
                }
                throw AuthError.networkError("Email registration failed: HTTP \(http.statusCode) \(bodyStr)")
            }

            let pair = try JSONDecoder().decode(AuthTokenPair.self, from: data)

            AuthTokenStore.saveTokens(pair)
            currentUser = AuthenticatedUser(
                id: pair.userId,
                email: accountEmail,
                displayName: pair.nickname,
                nickname: pair.nickname,
                isLocalOnly: false
            )
            authState = .signedIn
            if let nick = pair.nickname { accountNickname = nick }

            BackendAppConfiguration.updateBearerToken(pair.accessToken)
            try syncEngine.resumeCloudSync()
            syncState = syncEngine.loadState()
        } catch {
            authState = .error(error.localizedDescription)
            authError = error.localizedDescription
            errorReporter.record(category: .sync, message: "Email registration failed: \(error.localizedDescription)")
        }
    }

    /// Bind an email + password to the currently authenticated user.
    /// This enables cross-device account recovery via email login.
    func bindEmail() async {
        guard let baseURL = backendBaseURL else {
            authError = authErrorMessage("Backend URL is not configured.",
                                         "未配置后端地址，请先设置服务器地址。")
            return
        }

        guard let tokens = AuthTokenStore.loadTokens() else {
            authError = authErrorMessage("Not authenticated. Please sign in first.",
                                         "未登录，请先登录。")
            return
        }

        authError = nil

        do {
            let url = baseURL.appendingPathComponent("v1/auth/bind-email")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")

            let body = EmailBindRequest(email: accountEmail, password: accountPassword)
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw AuthError.networkError("Invalid response type")
            }
            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 409 {
                    authError = authErrorMessage("This email is already in use by another account.",
                                                 "该邮箱已被其他账户使用。")
                    return
                }
                throw AuthError.networkError("Email bind failed: HTTP \(http.statusCode) \(bodyStr)")
            }

            // Update the local user state to reflect the bound email.
            currentUser = AuthenticatedUser(
                id: tokens.userId,
                email: accountEmail,
                displayName: currentUser?.displayName,
                isLocalOnly: false
            )
            authError = nil
            accountPassword = ""
        } catch {
            authError = error.localizedDescription
            errorReporter.record(category: .sync, message: "Email bind failed: \(error.localizedDescription)")
        }
    }

    /// Set or change the display nickname for the current user.
    /// Returns true on success, false if the nickname was taken.
    func setNickname() async -> Bool {
        guard let baseURL = backendBaseURL else {
            authError = authErrorMessage("Backend URL is not configured.",
                                         "未配置后端地址，请先设置服务器地址。")
            return false
        }

        guard let tokens = AuthTokenStore.loadTokens() else {
            authError = authErrorMessage("Not authenticated. Please sign in first.",
                                         "未登录，请先登录。")
            return false
        }

        let nickname = accountNickname.trimmingCharacters(in: .whitespaces)
        guard !nickname.isEmpty else { return false }

        authError = nil

        do {
            let url = baseURL.appendingPathComponent("v1/auth/set-nickname")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")

            let body = SetNicknameRequest(nickname: nickname)
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw AuthError.networkError("Invalid response type")
            }
            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 409 {
                    authError = authErrorMessage("Nickname already taken. Please choose another.",
                                                 "昵称已被占用，请换一个。")
                    return false
                }
                throw AuthError.networkError("Set nickname failed: HTTP \(http.statusCode) \(bodyStr)")
            }

            currentUser = AuthenticatedUser(
                id: tokens.userId,
                email: currentUser?.email,
                displayName: nickname,
                nickname: nickname,
                isLocalOnly: false
            )
            return true
        } catch {
            authError = error.localizedDescription
            errorReporter.record(category: .sync, message: "Set nickname failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Consent

    func recordConsent(_ type: ConsentType, accepted: Bool) {
        do {
            try consentManager.recordConsent(type: type, accepted: accepted, textSummary: consentSummary(for: type))
        } catch {
            errorReporter.record(category: .storage, message: "Failed to record consent: \(error.localizedDescription)")
        }
        if type == .cloudSync {
            if accepted {
                do { try syncEngine.resumeCloudSync() } catch {
                    errorReporter.record(category: .sync, message: "Failed to resume sync: \(error.localizedDescription)")
                }
            } else {
                var state = syncEngine.loadState()
                state.mode = .localOnly
                do { try syncEngine.saveState(state) } catch {
                    errorReporter.record(category: .sync, message: "Failed to save sync state: \(error.localizedDescription)")
                }
            }
            syncState = syncEngine.loadState()
        }
    }

    func hasConsent(_ type: ConsentType) -> Bool {
        consentManager.hasConsent(type)
    }

    // MARK: - Sync

    func syncNow() async {
        guard let userId = currentUser?.id else { return }
        syncState = await syncEngine.syncNow(userId: userId)
        if syncState.lastError != nil {
            errorReporter.record(category: .sync, message: syncState.lastError ?? "Sync failed")
        }
        analyticsSummary = analyticsService.summary()
    }

    func pauseSync() {
        do { try syncEngine.pause() } catch {
            errorReporter.record(category: .sync, message: "Failed to pause sync: \(error.localizedDescription)")
        }
        syncState = syncEngine.loadState()
    }

    func resumeSync() {
        do { try syncEngine.resumeCloudSync() } catch {
            errorReporter.record(category: .sync, message: "Failed to resume sync: \(error.localizedDescription)")
        }
        syncState = syncEngine.loadState()
    }

    // MARK: - Reminders

    func buildReminders(
        plan: WeeklyPlan?,
        activeExperiment: PersonalExperiment?,
        quality: DataQualityReport,
        enabled: Bool
    ) {
        guard let plan else {
            scheduledReminders = []
            return
        }
        scheduledReminders = reminderScheduler.reminders(for: plan, activeExperiment: activeExperiment, dataQuality: quality, enabled: enabled)
        if enabled {
            Task {
                guard await reminderScheduler.requestAuthorization() else { return }
                for reminder in scheduledReminders {
                    await reminderScheduler.schedule(reminder)
                }
            }
        }
    }

    // MARK: - Diagnostics

    func refreshBetaReadiness(
        dataSource: HealthDataSource,
        todayMetrics: DailyHealthMetrics?,
        recentMetrics: [DailyHealthMetrics],
        baseline14d: HealthBaseline?
    ) {
        betaReadinessReport = BetaReadinessReport.build(
            dataSource: dataSource,
            todayMetrics: todayMetrics,
            recentMetrics: recentMetrics,
            baseline14d: baseline14d
        )
    }

    func refreshAnalyticsSummary() {
        analyticsSummary = analyticsService.summary()
    }

    func exportLocalData(
        recommendations: [CoachRecommendation],
        feedback: [DailyFeedback],
        reports: [VerificationReport],
        goals: [UserGoal],
        plans: [WeeklyPlan],
        privacy: PrivacySettings
    ) {
        exportManifest = LocalDataExporter().export(
            recommendations: recommendations,
            feedback: feedback,
            reports: reports,
            goals: goals,
            plans: plans,
            privacy: privacy
        )
    }

    func requestResetLocalData() {
        resetConfirmationState = .needsConfirmation
    }

    func confirmResetLocalData() {
        resetConfirmationState = .confirmed
    }

    func resetConfirmationHandled() {
        resetConfirmationState = .idle
    }

    // MARK: - Analytics

    func recordAnalytics(_ type: BetaAnalyticsEventType, properties: [String: String] = [:]) {
        let userId = currentUser?.id.uuidString ?? AuthenticatedUser.localAnonymous.id.uuidString
        do {
            _ = try analyticsService.record(eventType: type, userId: userId, properties: properties)
        } catch {
            // Non-critical
        }
        analyticsSummary = analyticsService.summary()
    }

    // MARK: - Private

    /// Returns a bilingual error message based on the user's current language preference.
    private func authErrorMessage(_ en: String, _ zh: String) -> String {
        let lang = UserDefaults.standard.string(forKey: "oheas.language") ?? AppLanguage.chinese.rawValue
        return lang == AppLanguage.chinese.rawValue ? zh : en
    }

    private func consentSummary(for type: ConsentType) -> String {
        switch type {
        case .healthKitRead: return "Read aggregate HealthKit metrics for lifestyle coaching."
        case .aiLifestyleAdvice: return "Allow AI lifestyle advice with no medical diagnosis."
        case .cloudSync: return "Sync aggregate summaries and agent state to the configured backend."
        case .betaAnalytics: return "Record non-sensitive beta analytics for product quality."
        case .notifications: return "Allow local reminders for plans, feedback, and experiments."
        }
    }
}
