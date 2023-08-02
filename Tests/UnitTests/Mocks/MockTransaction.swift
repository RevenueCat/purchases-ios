//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import StoreKit

class MockTransaction: SKPaymentTransaction {

    var mockPayment: SKPayment?
    override var payment: SKPayment {
        mockPayment ?? super.payment
    }

    var mockState = SKPaymentTransactionState.purchasing
    override var transactionState: SKPaymentTransactionState {
        mockState
    }

    var mockError: Error?
    override var error: Error? {
        mockError
    }

    var mockTransactionDate: Date? = Date()
    override var transactionDate: Date? {
        // This matches the behavior of `SKPaymentTransaction`.
        guard self.transactionState == .purchased || self.transactionState == .restored else {
            return nil
        }

        return self.mockTransactionDate
    }

    var mockTransactionIdentifier: String? = UUID().uuidString
    override var transactionIdentifier: String? {
        mockTransactionIdentifier
    }
}
