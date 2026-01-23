//
//  ObserverModeManager.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 12/19/22.
//

import RevenueCat
import StoreKit
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

    func purchaseAsSK1Product(_ product: StoreProduct) async -> PurchaseResult {
        do {
            guard let sk1Product = try await self.productFetcherSK1.products(with: [product.productIdentifier]).first else {
                print("Failed to find product")
                return .failure(Self.productNotFoundError)
            }

            let resultData = await self.purchasesOrchestrator.purchase(sk1Product: sk1Product)
            if resultData.transactionState == .failed,
                let skError = resultData.error as? SKError,
               (skError.code == .paymentCancelled || skError.code == .overlayCancelled) {
                return .userCancelled
            } else if let error = resultData.error {
                return .failure(error)
            } else {
                return .success
            }
        } catch {
            return .failure(error)
        }
    }

    #if !os(visionOS)
    func purchaseAsSK2Product(_ product: StoreProduct) async -> PurchaseResult {
        do {
            guard let sk2Product = try await self.productFetcherSK2.products(with: [product.productIdentifier]).first else {
                print("Failed to find product")
                return .failure(Self.productNotFoundError)
            }

            let purchaseMade = try await self.purchasesOrchestrator.purchase(sk2Product: sk2Product)
            if purchaseMade {
                return .success
            } else {
                return .userCancelled
            }
        } catch {
            return .failure(error)
        }
    }
    #endif

    private static let productNotFoundError = NSError(domain: "PurchaseTester",
                                                      code: 1, userInfo: [
                                                        NSLocalizedDescriptionKey: "Failed to find product"
                                                      ])

}
