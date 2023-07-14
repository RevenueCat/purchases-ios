//
//  PurchaseHandler.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import StoreKit

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class PurchaseHandler: ObservableObject {

    typealias PurchaseBlock = @Sendable (Package) async throws -> PurchaseResultData

    let purchaseBlock: PurchaseBlock

    convenience init(purchases: Purchases = .shared) {
        self.init { package in
            return try await purchases.purchase(package: package)
        }
    }

    init(purchase: @escaping PurchaseBlock) {
        self.purchaseBlock = purchase
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension PurchaseHandler {

    func purchase(package: Package) async throws -> PurchaseResultData {
        return try await self.purchaseBlock(package)
    }

}
