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


    private init() {

        Purchases.logLevel = .verbose
        Purchases.proxyURL = ConfigItem.proxyURL.flatMap { URL(string: $0) }

        self.configure()
    }

    private func configure() {
        Purchases.configure(
            with: .init(withAPIKey: ConfigItem.apiKey)
                .with(entitlementVerificationMode: .informational)
                .with(diagnosticsEnabled: true)
                .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
        )
    }

}
