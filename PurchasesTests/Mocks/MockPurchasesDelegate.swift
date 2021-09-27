//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

public class MockPurchasesDelegate: NSObject, PurchasesDelegate {

    var purchaserInfo: CustomerInfo?
    var purchaserInfoReceivedCount = 0

    public func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: CustomerInfo) {
        purchaserInfoReceivedCount += 1
        self.purchaserInfo = purchaserInfo
    }

    var promoProduct: SKProduct?
    var makeDeferredPurchase: DeferredPromotionalPurchaseBlock?


    public func purchases(_ purchases: Purchases,
                          shouldPurchasePromoProduct product: SKProduct,
                          defermentBlock makeDeferredPurchase: @escaping (@escaping PurchaseCompletedBlock) -> Void) {
        promoProduct = product
        self.makeDeferredPurchase = makeDeferredPurchase
    }

}
