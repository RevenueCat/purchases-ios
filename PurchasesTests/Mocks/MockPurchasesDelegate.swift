//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit
@testable import RevenueCat

public class MockPurchasesDelegate: NSObject, PurchasesDelegate {

    var purchaserInfo: PurchaserInfo?
    var purchaserInfoReceivedCount = 0

    public func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: PurchaserInfo) {
        purchaserInfoReceivedCount += 1
        self.purchaserInfo = purchaserInfo
    }

    var promoProduct: LegacySKProduct?
    var makeDeferredPurchase: DeferredPromotionalPurchaseBlock?


    public func purchases(_ purchases: Purchases,
                          shouldPurchasePromoProduct product: LegacySKProduct,
                          defermentBlock makeDeferredPurchase: @escaping (@escaping PurchaseCompletedBlock) -> Void) {
        promoProduct = product
        self.makeDeferredPurchase = makeDeferredPurchase
    }

}
