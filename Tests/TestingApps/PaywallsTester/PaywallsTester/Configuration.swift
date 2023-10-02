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

    @Published private(set) var currentMode: Mode

    static let entitlement = "pro"

    enum Mode {
        case custom, testing, demos, listOnly
    }

    #warning("Configure API key if you want to test paywalls from your dashboard")
    // Note: you can leave this empty to use the production server, or point to your own instance.
    private static let proxyURL = ""
    private static let apiKey = ""

    // This is modified by CI:
    private static let apiKeyFromCIForTesting = ""
    private static let apiKeyFromCIForDemos = ""

    private init() {
        self.currentMode = Self.apiKey.isEmpty ? .testing : .custom
    }

    var currentAPIKey: String? {
        switch currentMode {
        case .custom:
            Self.apiKey
        case .testing:
            Self.apiKeyFromCIForTesting
        case .demos:
            Self.apiKeyFromCIForDemos
        case .listOnly:
            nil
        }
    }

    func reconfigure(for mode: Mode) {
        self.currentMode = mode
        self.configureRCSDK()
    }

    func configure() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Self.proxyURL.isEmpty
        ? nil
        : URL(string: Self.proxyURL)!
        self.configureRCSDK()
    }

    private func configureRCSDK() {
        guard let currentAPIKey = self.currentAPIKey,
              !currentAPIKey.isEmpty else {
            return
        }

        Purchases.configure(
            with: .init(withAPIKey: currentAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

}
