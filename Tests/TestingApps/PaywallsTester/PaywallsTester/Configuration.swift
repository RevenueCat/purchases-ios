//
//  Configuration.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import RevenueCat

class Configuration: ObservableObject {
    static let shared = Configuration()

    // This is modified by CI:
    private static let apiKeyFromCIForTesting = ""
    private static let apiKeyFromCIForDemos = ""

    @Published private(set) var currentMode: Mode

    let entitlement = "pro"

    #warning("Configure API key if you want to test paywalls from your dashboard")
    // Note: you can leave this empty to use the production server, or point to your own instance.
    private let proxyURL = ""
    private let apiKey = ""

    enum Mode {
        case custom, testing, demos
    }

    private init() {
        currentMode = apiKey.isEmpty ? .custom : .testing
    }


    var currentAPIKey: String {
        switch currentMode {
        case .custom:
            self.apiKey
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
        Purchases.proxyURL = self.proxyURL.isEmpty
        ? nil
        : URL(string: self.proxyURL)!

        Purchases.configure(
            with: .init(withAPIKey: currentAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

}
