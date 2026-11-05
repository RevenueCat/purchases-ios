//
//  Configuration.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
#if DEBUG
@testable import RevenueCat
#else
import RevenueCat
#endif

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

        var builder = RevenueCat.Configuration.Builder(withAPIKey: Constants.apiKey)
            .with(entitlementVerificationMode: .informational)
            .with(diagnosticsEnabled: true)
            .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
        #if DEBUG
        builder = builder.with(dangerousSettings: Self.simulatingAPIFailuresDangerousSettings)
        #endif
        Purchases.configure(with: builder)
    }

    #if DEBUG
    /// The `UserDefaults` key of the `SimulatedHostFailures.Mode` the SDK simulates.
    static let simulatedFailuresModeKey = "com.revenuecat.paywallstester.simulated_failures_mode"

    /// Reads the stored mode on every request, so picking another one applies without relaunching.
    private static var simulatingAPIFailuresDangerousSettings: DangerousSettings {
        let strategy = ForceServerErrorStrategy.simulating {
            let mode = UserDefaults.standard.string(forKey: Self.simulatedFailuresModeKey)
                .flatMap(SimulatedHostFailures.Mode.init(rawValue:))
            return (mode ?? SimulatedHostFailures.Mode.none).hostFailures
        }
        return DangerousSettings(autoSyncPurchases: true,
                                 internalSettings: DangerousSettings.Internal(forceServerErrorStrategy: strategy))
    }
    #endif

}
