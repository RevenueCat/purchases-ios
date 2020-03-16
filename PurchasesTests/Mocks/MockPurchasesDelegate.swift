//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockPurchasesDelegate: NSObject, PurchasesDelegate {
    var purchaserInfo: Purchases.PurchaserInfo?
    var purchaserInfoReceivedCount = 0

    func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: Purchases.PurchaserInfo) {
        purchaserInfoReceivedCount += 1
        self.purchaserInfo = purchaserInfo
    }

    var promoProduct: SKProduct?
    var makeDeferredPurchase: RCDeferredPromotionalPurchaseBlock?

    func purchases(_ purchases: Purchases,
                   shouldPurchasePromoProduct product: SKProduct,
                   defermentBlock makeDeferredPurchase: @escaping RCDeferredPromotionalPurchaseBlock) {
        promoProduct = product
        self.makeDeferredPurchase = makeDeferredPurchase
    }
}
