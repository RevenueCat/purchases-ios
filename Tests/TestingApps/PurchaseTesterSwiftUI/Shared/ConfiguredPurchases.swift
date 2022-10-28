//
//  ConfiguredPurchases.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/25/22.
//

import RevenueCat

final class ConfiguredPurchases {

    let purchases: Purchases
    private let delegate: Delegate

    init(purchases: Purchases) {
        self.purchases = purchases
        self.delegate = Delegate()

        self.purchases.delegate = self.delegate
    }

    convenience init(
        apiKey: String,
        proxyURL: String?,
        useStoreKit2: Bool
    ) {
        Purchases.logLevel = .debug
        Purchases.logHandler = Self.logger.logHandler

        if let proxyURL {
            Purchases.proxyURL = URL(string: proxyURL)!
        }

        let purchases = Purchases.configure(
            with: .builder(withAPIKey: apiKey)
                .with(usesStoreKit2IfAvailable: useStoreKit2)
                .build()
        )

        self.init(purchases: purchases)
    }

    // MARK: -

    static let logger: Logger = .init()

}

private final class Delegate: NSObject, PurchasesDelegate {

    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase makeDeferredPurchase: @escaping StartPurchaseBlock) {
        makeDeferredPurchase { (transaction, customerInfo, error, success) in
            print("Yay")
        }
    }

}
