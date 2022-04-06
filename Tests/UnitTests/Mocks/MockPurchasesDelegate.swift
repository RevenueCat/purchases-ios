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
    var makeDeferredPurchase: DeferredPromotionalPurchaseBlock?

    public func purchases(_ purchases: Purchases,
                          isReadyForPromotedProduct product: StoreProduct,
                          purchase startPurchase: @escaping DeferredPromotionalPurchaseBlock) {
        promoProduct = product
        self.makeDeferredPurchase = startPurchase
    }

}
