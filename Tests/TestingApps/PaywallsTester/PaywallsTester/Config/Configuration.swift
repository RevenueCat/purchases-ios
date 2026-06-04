//
//  Configuration.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

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
            with: .init(withAPIKey: Constants.apiKey)
                .with(entitlementVerificationMode: .informational)
                .with(diagnosticsEnabled: true)
                .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
        )
    }

}
