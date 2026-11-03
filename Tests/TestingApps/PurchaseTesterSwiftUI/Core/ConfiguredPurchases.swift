//
//  ConfiguredPurchases.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/25/22.
//

import Foundation

#if DEBUG
@testable import RevenueCat
#else
import RevenueCat
#endif

public final class ConfiguredPurchases {

    public let purchases: Purchases
    public let proxyURL: URL?
    private let delegate: Delegate

    public init(purchases: Purchases, proxyURL: URL?) {
        self.purchases = purchases
        self.proxyURL = proxyURL
        self.delegate = Delegate()

        self.purchases.delegate = self.delegate
    }

    public convenience init(
        apiKey: String,
        proxyURL: String?,
        useStoreKit2: Bool,
        observerMode: Bool,
        entitlementVerificationMode: Configuration.EntitlementVerificationMode
    ) {
        Purchases.logLevel = .verbose
        Purchases.logHandler = Self.logger.logHandler

        if let proxyURL {
            Purchases.proxyURL = URL(string: proxyURL)!
        } else {
            Purchases.proxyURL = nil
        }

        let purchasesAreCompletedBy: PurchasesAreCompletedBy = observerMode ? .myApp : .revenueCat
        let storeKitVersion: StoreKitVersion = useStoreKit2 ? .storeKit2 : .storeKit1
        var builder = Configuration.Builder(withAPIKey: apiKey)
            .with(diagnosticsEnabled: true)
            .with(purchasesAreCompletedBy: purchasesAreCompletedBy, storeKitVersion: storeKitVersion)
            .with(entitlementVerificationMode: entitlementVerificationMode)
        #if DEBUG
        builder = builder.with(dangerousSettings: Self.simulatingAPIFailuresDangerousSettings)
        #endif
        let purchases = Purchases.configure(with: builder)

        self.init(purchases: purchases, proxyURL: Purchases.proxyURL)
    }

    // MARK: -

    public static let logger: Logger = .init()

    #if DEBUG
    /// The `UserDefaults` key of the `SimulatedHostFailures.Mode` the SDK simulates.
    public static let simulatedFailuresModeKey = "com.revenuecat.sampleapp.simulated_failures_mode"

    /// Reads the stored mode on every request, so picking another one applies without reconfiguring.
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

private final class Delegate: NSObject, PurchasesDelegate {

    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase makeDeferredPurchase: @escaping StartPurchaseBlock) {
        makeDeferredPurchase { (transaction, customerInfo, error, success) in
            print("Yay")
        }
    }

}
