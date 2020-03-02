//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockStoreKitWrapper: RCStoreKitWrapper {
    var payment: SKPayment?
    var addPaymentCallCount = 0

    override func add(_ newPayment: SKPayment) {
        payment = newPayment
        addPaymentCallCount += 1
    }

    var finishCalled = false

    override func finish(_ transaction: SKPaymentTransaction) {
        finishCalled = true
    }

    var mockDelegate: RCStoreKitWrapperDelegate?
    override var delegate: RCStoreKitWrapperDelegate? {
        get {
            return mockDelegate
        }
        set {
            mockDelegate = newValue
        }
    }
}
