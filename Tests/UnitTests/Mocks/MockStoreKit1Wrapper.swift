//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat
import StoreKit

class MockStoreKit1Wrapper: StoreKit1Wrapper {
    init(observerMode: Bool = false) {
        super.init(observerMode: observerMode)
    }

    var payment: SKPayment?
    var addPaymentCallCount = 0

    var mockAddPaymentTransactionState: SKPaymentTransactionState = .purchasing
    var mockCallUpdatedTransactionInstantly = false

    override func add(_ newPayment: SKPayment) {
        payment = newPayment
        addPaymentCallCount += 1

        if mockCallUpdatedTransactionInstantly {
            let transaction = MockTransaction()
            transaction.mockPayment = newPayment
            transaction.mockState = mockAddPaymentTransactionState
            delegate?.storeKit1Wrapper(self, updatedTransaction: transaction)
        }
    }

    var finishCalled = false
    var finishProductIdentifier: String?

    override func finishTransaction(_ transaction: SKPaymentTransaction, completion: @escaping () -> Void) {
        self.finishCalled = true
        self.finishProductIdentifier = transaction.productIdentifier

        completion()
    }

    weak var mockDelegate: StoreKit1WrapperDelegate?
    override var delegate: StoreKit1WrapperDelegate? {
        get {
            return mockDelegate
        }
        set {
            mockDelegate = newValue
        }
    }
}
