//
//  SimpleApp.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@main
struct SimpleApp: App {

    init() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Configuration.proxyURL.isEmpty
            ? nil
            : URL(string: Configuration.proxyURL)!

        Purchases.configure(
            with: .init(withAPIKey: Configuration.effectiveApiKey)
                .with(entitlementVerificationMode: .informational)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    var body: some Scene {
        WindowGroup {
            AppContentView(
                customerInfoStream: Self.apiKeyIsConfigured
                ? Purchases.shared.customerInfoStream
                : nil
            )
        }
    }

    private static let apiKeyIsConfigured = !Configuration.effectiveApiKey.isEmpty

}
