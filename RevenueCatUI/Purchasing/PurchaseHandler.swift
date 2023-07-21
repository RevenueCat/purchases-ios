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

    private let purchaseBlock: PurchaseBlock

    @Published
    var purchased: Bool = false

    convenience init(purchases: Purchases = .shared) {
        self.init { package in
            return try await purchases.purchase(package: package)
        }
    }

    init(purchase: @escaping PurchaseBlock) {
        self.purchaseBlock = purchase
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

    /// Creates a copy of this `PurchaseHandler` wrapping the purchase block
    func map(_ block: @escaping (@escaping PurchaseBlock) -> PurchaseBlock) -> Self {
        return .init(purchase: block(self.purchaseBlock))
    }

}
