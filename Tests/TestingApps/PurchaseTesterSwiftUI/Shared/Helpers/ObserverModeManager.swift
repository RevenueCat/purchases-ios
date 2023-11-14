//
//  ObserverModeManager.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 12/19/22.
//

import RevenueCat

import SwiftUI

/// A type that simplfiies performing purchases directly with StoreKit to test observer mode.
final class ObserverModeManager: ObservableObject {

    let observerModeEnabled: Bool

    private let productFetcherSK1: ProductFetcherSK1
    private let productFetcherSK2: ProductFetcherSK2
    private let purchasesOrchestrator: PurchasesOrchestrator

    init(observerModeEnabled: Bool) {
        self.observerModeEnabled = observerModeEnabled
        self.productFetcherSK1 = .init()
        self.productFetcherSK2 = .init()
        self.purchasesOrchestrator = .init()
    }

    func purchaseAsSK1Product(_ product: StoreProduct) async throws {
        guard let sk1Product = try await self.productFetcherSK1.products(with: [product.productIdentifier]).first else {
            print("Failed to find product")
            return
        }

        _ = await self.purchasesOrchestrator.purchase(sk1Product: sk1Product)
    }

    #if !os(visionOS)
    func purchaseAsSK2Product(_ product: StoreProduct) async throws {
        guard let sk2Product = try await self.productFetcherSK2.products(with: [product.productIdentifier]).first else {
            print("Failed to find product")
            return
        }

        try await self.purchasesOrchestrator.purchase(sk2Product: sk2Product)
    }
    #endif

}
