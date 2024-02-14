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

        let purchases = Purchases.configure(
            with: .builder(withAPIKey: apiKey)
                .with(observerMode: observerMode, storeKitVersion: useStoreKit2 ? .storeKit2 : .storeKit1)
                .with(entitlementVerificationMode: entitlementVerificationMode)
                .build()
        )

        self.init(purchases: purchases, proxyURL: Purchases.proxyURL)
    }

    // MARK: -

    public static let logger: Logger = .init()

}

private final class Delegate: NSObject, PurchasesDelegate {

    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase makeDeferredPurchase: @escaping StartPurchaseBlock) {
        makeDeferredPurchase { (transaction, customerInfo, error, success) in
            print("Yay")
        }
    }

}
