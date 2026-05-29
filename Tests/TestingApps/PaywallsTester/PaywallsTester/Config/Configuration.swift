//
//  Configuration.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

import Combine
import Foundation
import RevenueCat

enum Configuration {

    static let entitlement = "pro"

    #if os(watchOS)
    // Sheets on watchOS add a close button automatically
    static let defaultDisplayCloseButton = false
    #else
    static let defaultDisplayCloseButton = true
    #endif

    static func configure() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Constants.proxyURL.flatMap { URL(string: $0) }

        Purchases.configure(
            with: .init(withAPIKey: DebugSettingsStore.effectiveAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(diagnosticsEnabled: true)
                .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
        )
    }

}

/// Runtime debug settings for PaywallsTester, persisted in `UserDefaults` so they survive a
/// kill/relaunch. Lets anyone running the app point it at their own RevenueCat project without
/// rebuilding or editing `local.xcconfig`.
final class DebugSettingsStore: ObservableObject {

    enum Keys {
        static let apiKeyOverride = "debug.apiKeyOverride"
    }

    static let shared = DebugSettingsStore()

    /// The API key to configure `Purchases` with: a non-empty override, otherwise the build-time
    /// default from `Constants.apiKey`. Reads `UserDefaults` directly so it is safe to call at
    /// launch from `Configuration.configure()` without touching the observable instance.
    static var effectiveAPIKey: String {
        let override = UserDefaults.standard.string(forKey: Keys.apiKeyOverride)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return override.isEmpty ? Constants.apiKey : override
    }

    private let defaults: UserDefaults

    /// Empty string means "no override" (falls back to `Constants.apiKey`).
    @Published var apiKeyOverride: String {
        didSet {
            let trimmed = apiKeyOverride.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                defaults.removeObject(forKey: Keys.apiKeyOverride)
            } else {
                defaults.set(trimmed, forKey: Keys.apiKeyOverride)
            }
        }
    }

    /// Bumped on every reconfigure so views can rebuild against the freshly configured instance.
    @Published private(set) var configurationGeneration: Int = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.apiKeyOverride = defaults.string(forKey: Keys.apiKeyOverride) ?? ""
    }

    /// Persists the current values and re-configures `Purchases` with the new key so the change
    /// takes effect without relaunching. A cold relaunch reaches the same state because the
    /// persisted override is read again in `Configuration.configure()`.
    func apply() {
        Configuration.configure()
        configurationGeneration += 1
    }

    /// Clears the API key override (reverting to the build default) and re-configures.
    func resetToDefault() {
        apiKeyOverride = ""
        apply()
    }

}
