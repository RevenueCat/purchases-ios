//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockTransaction: SKPaymentTransaction {

    var mockPayment: SKPayment?
    override var payment: SKPayment {
        get {
            return mockPayment!
        }
    }

    var mockState = SKPaymentTransactionState.purchasing
    override var transactionState: SKPaymentTransactionState {
        get {
            return mockState
        }
    }

    var mockError: Error?
    override var error: Error? {
        get {
            return mockError
        }
    }
}
