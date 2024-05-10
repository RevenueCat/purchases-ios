//
//  Configuration.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import RevenueCat

final class Configuration: ObservableObject {
    static let shared = Configuration()


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

    private init() {

        Purchases.logLevel = .verbose
        Purchases.proxyURL = Self.proxyURL.isEmpty
        ? nil
        : URL(string: Self.proxyURL)!

        self.configure()
    }

    private func configure() {
        Purchases.configure(
            with: .init(withAPIKey: Self.apiKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

}
