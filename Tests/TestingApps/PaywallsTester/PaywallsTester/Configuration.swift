//
//  Configuration.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import RevenueCat

final class Configuration: ObservableObject {
    static let shared = Configuration()

    // This is modified by CI:
    private static let apiKeyFromCIForTesting = ""
    private static let apiKeyFromCIForDemos = ""

    @Published private(set) var currentMode: Mode

    let entitlement = "pro"

    #warning("Configure API key if you want to test paywalls from your dashboard")
    // Note: you can leave this empty to use the production server, or point to your own instance.
    private static let proxyURL = ""
    private static let apiKey = ""

    enum Mode {
        case custom, testing, demos
    }

    private init() {
        self.currentMode = Self.apiKey.isEmpty ? .testing : .custom
    }


    var currentAPIKey: String {
        switch currentMode {
        case .custom:
            Self.apiKey
        case .testing:
            Self.apiKeyFromCIForTesting
        case .demos:
            Self.apiKeyFromCIForDemos
        }
    }

    func reconfigure(for mode: Mode) {
        self.currentMode = mode
        Purchases.configure(
            with: .init(withAPIKey: currentAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    func configure() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Self.proxyURL.isEmpty
        ? nil
        : URL(string: Self.proxyURL)!

        Purchases.configure(
            with: .init(withAPIKey: currentAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

}
