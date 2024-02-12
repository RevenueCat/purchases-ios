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

    @Published var currentMode: Mode {
        didSet {
            self.configure()
        }
    }

    static let entitlement = "pro"

    #if os(watchOS)
    // Sheets on watchOS add a close button automatically
    static let defaultDisplayCloseButton = false
    #else
    static let defaultDisplayCloseButton = true
    #endif

    enum Mode: Equatable {
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
        if Self.apiKey.isEmpty {
            self.currentMode = Self.apiKeyFromCIForTesting.isEmpty ? .listOnly : .testing
        } else {
            self.currentMode = .custom
        }

        Purchases.logLevel = .verbose
        Purchases.proxyURL = Self.proxyURL.isEmpty
        ? nil
        : URL(string: Self.proxyURL)!

        self.configure()
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

    private func configure() {
        guard let currentAPIKey = self.currentAPIKey,
              !currentAPIKey.isEmpty else {
            return
        }

        Purchases.configure(
            with: .init(withAPIKey: currentAPIKey)
                .with(entitlementVerificationMode: .informational)
                .with(storeKitVersion: .storeKit2)
        )
    }

}
