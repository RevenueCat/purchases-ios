//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat
import StoreKit

public class MockPurchasesDelegate: NSObject, PurchasesDelegate {

    var customerInfo: CustomerInfo?
    var customerInfoReceivedCount = 0

    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        customerInfoReceivedCount += 1
        self.customerInfo = customerInfo
    }

    var promoProduct: StoreProduct?
    var makeDeferredPurchase: StartPurchaseBlock?

    public func purchases(_ purchases: Purchases,
                          readyForPromotedProduct product: StoreProduct,
                          purchase startPurchase: @escaping StartPurchaseBlock) {
        promoProduct = product
        self.makeDeferredPurchase = startPurchase
    }

}

// `PurchasesDelegate` requires types to be `Sendable`.
// This type isn't, but it's only meant for testing.
extension MockPurchasesDelegate: @unchecked Sendable {}
