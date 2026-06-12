//
//  LanguageEnvironment.swift
//  OHeas
//
//  LanguageEnvironment.swift — unified language access via SwiftUI Environment.
//  Instead of each view reading @AppStorage("oheas.language") independently,
//  the language is injected once in AppRootView and consumed via @Environment.
//

import SwiftUI

// MARK: - Environment Key

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .chinese
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}
