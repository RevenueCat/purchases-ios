//
//  PurchaseHandler.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import StoreKit
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class PurchaseHandler: ObservableObject {

    typealias PurchaseBlock = @Sendable (Package) async throws -> PurchaseResultData
    typealias RestoreBlock = @Sendable () async throws -> CustomerInfo

    private let purchaseBlock: PurchaseBlock
    private let restoreBlock: RestoreBlock

    @Published
    var purchased: Bool = false

    convenience init(purchases: Purchases = .shared) {
        self.init { package in
            return try await purchases.purchase(package: package)
        } restorePurchases: {
            return try await purchases.restorePurchases()
        }
    }

    init(
        purchase: @escaping PurchaseBlock,
        restorePurchases: @escaping RestoreBlock
    ) {
        self.purchaseBlock = purchase
        self.restoreBlock = restorePurchases
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension PurchaseHandler {

    func purchase(package: Package) async throws -> PurchaseResultData {
        let result = try await self.purchaseBlock(package)

        if !result.userCancelled {
            withAnimation(Constants.defaultAnimation) {
                self.purchased = true
            }
        }

        return result
    }

    func restorePurchases() async throws -> CustomerInfo {
        return try await self.restoreBlock()
    }

    /// Creates a copy of this `PurchaseHandler` wrapping the purchase and restore blocks.
    func map(
        purchase: @escaping (@escaping PurchaseBlock) -> PurchaseBlock,
        restore: @escaping (@escaping RestoreBlock) -> RestoreBlock
    ) -> Self {
        return .init(purchase: purchase(self.purchaseBlock),
                     restorePurchases: restore(self.restoreBlock))
    }

}
