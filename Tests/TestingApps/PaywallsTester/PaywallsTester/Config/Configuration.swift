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
        let configurationBuilder = Self.configurationBuilder()
        #if canImport(ObjectiveC) && (os(iOS) || targetEnvironment(macCatalyst))
        // Keep the protocol in the SDK session and let it no-op until a local JSON draft exists.
        LocalPaywallOfferingsInterceptor.install()
        #endif

        Purchases.configure(
            with: configurationBuilder
                .with(entitlementVerificationMode: .informational)
                .with(diagnosticsEnabled: true)
                .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
        )
    }

}

private extension Configuration {

    static func configurationBuilder() -> RevenueCat.Configuration.Builder {
        if LocalPaywallOfferingsOverrideStore.isActive, Purchases.isConfigured {
            LocalPaywallOfferingsOverrideStore.rememberNormalAppUserIDIfNeeded(Purchases.shared.appUserID)
        }

        return RevenueCat.Configuration.Builder(
            withAPIKey: Constants.apiKey,
            appUserID: LocalPaywallOfferingsOverrideStore.configurationAppUserID
        )
    }

}
