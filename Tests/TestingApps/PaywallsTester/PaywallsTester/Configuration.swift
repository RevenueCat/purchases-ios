//
//  Configuration.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import RevenueCat

enum Configuration {

    #warning("Configure API key if you want to test paywalls from your dashboard")

    // Note: you can leave this empty to use the production server, or point to your own instance.
    static let proxyURL = ""
    static let apiKey = ""

    static let entitlement = "pro"

}

extension Configuration {
    enum Mode {
        case custom, testing, demos
    }

    static private(set) var currentMode: Mode = Self.apiKey.isEmpty ? .custom : .testing

    static var currentAPIKey: String {
        switch currentMode {
        case .custom:
            Self.apiKey
        case .testing:
            Self.apiKeyFromCIForTesting
        case .demos:
            Self.apiKeyFromCIForDemos
        }
    }

    static func reconfigure(for mode: Mode) {
        Self.currentMode = mode
        Purchases.configure(
            with: .init(withAPIKey: currentAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    static func configure() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Configuration.proxyURL.isEmpty
        ? nil
        : URL(string: Configuration.proxyURL)!

        Purchases.configure(
            with: .init(withAPIKey: currentAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    // This is modified by CI:
    static let apiKeyFromCIForTesting = ""
    static let apiKeyFromCIForDemos = ""

}
