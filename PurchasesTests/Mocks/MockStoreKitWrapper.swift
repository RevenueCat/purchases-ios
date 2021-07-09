//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import PurchasesCoreSwift

class MockStoreKitWrapper: StoreKitWrapper {
    var payment: SKPayment?
    var addPaymentCallCount = 0

    override func addPayment(_ newPayment: SKPayment) {
        payment = newPayment
        addPaymentCallCount += 1
    }

    var finishCalled = false

    override func finishTransaction(_ transaction: SKPaymentTransaction) {
        finishCalled = true
    }

    var mockDelegate: StoreKitWrapperDelegate?
    override var delegate: StoreKitWrapperDelegate? {
        get {
            return mockDelegate
        }
        set {
            mockDelegate = newValue
        }
    }
}
