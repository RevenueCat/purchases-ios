//
//  Configuration.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
@_spi(Internal) import RevenueCat

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

        let env = ProcessInfo.processInfo.environment
        let apiKey = env["REVENUECAT_API_KEY"]
            .flatMap { $0.isEmpty ? nil : $0 } ?? Constants.apiKey

        // Hermetic UITest mode: when LOCAL_OFFERINGS_PATH is set, the test wants the SDK
        // to behave fully offline. `uiPreviewMode` tells the SDK to return mock products
        // instead of asking StoreKit for live ones — that suppresses the Apple Account
        // sign-in dialog that otherwise pops up over the paywall during the test.
        let isHermetic = (env["LOCAL_OFFERINGS_PATH"].map { !$0.isEmpty } ?? false)

        if isHermetic {
            Purchases.configure(
                with: .init(withAPIKey: apiKey)
                    .with(entitlementVerificationMode: .informational)
                    .with(diagnosticsEnabled: true)
                    .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
                    .with(dangerousSettings: DangerousSettings(uiPreviewMode: true))
            )
        } else {
            Purchases.configure(
                with: .init(withAPIKey: apiKey)
                    .with(entitlementVerificationMode: .informational)
                    .with(diagnosticsEnabled: true)
                    .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
            )
        }
    }

}
