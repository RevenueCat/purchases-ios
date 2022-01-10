//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat
import StoreKit

class MockStoreKitWrapper: StoreKitWrapper {
    var payment: SKPayment?
    var addPaymentCallCount = 0

    override func add(_ newPayment: SKPayment) {
        payment = newPayment
        addPaymentCallCount += 1
    }

    var finishCalled = false

    override func finishTransaction(_ transaction: SKPaymentTransaction) {
        finishCalled = true
    }

    weak var mockDelegate: StoreKitWrapperDelegate?
    override var delegate: StoreKitWrapperDelegate? {
        get {
            return mockDelegate
        }
        set {
            mockDelegate = newValue
        }
    }
}
