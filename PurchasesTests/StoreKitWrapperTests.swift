//
//  StoreKitWrapperTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 Purchases. All rights reserved.
//

import Foundation
import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class MockPaymentQueue: SKPaymentQueue {
    var addedPayments: [SKPayment] = []
    override func add(_ payment: SKPayment) {
        addedPayments.append(payment)
    }

    var observers: [SKPaymentTransactionObserver] = []
    override func add(_ observer: SKPaymentTransactionObserver) {
        observers.append(observer)
    }

    override func remove(_ observer: SKPaymentTransactionObserver) {
        let i = observers.index { $0 === observer }
        observers.remove(at: i!)
    }

    var finishedTransactions: [SKPaymentTransaction] = []
    override func finishTransaction(_ transaction: SKPaymentTransaction) {
        finishedTransactions.append(transaction)
    }
}

class StoreKitWrapperTests: XCTestCase, RCStoreKitWrapperDelegate {

    let paymentQueue = MockPaymentQueue()

    var wrapper: RCStoreKitWrapper?

    override func setUp() {
        super.setUp()
        wrapper = RCStoreKitWrapper.init(paymentQueue: paymentQueue)
        wrapper?.delegate = self
    }

    var updatedTransactions: [SKPaymentTransaction] = []

    func storeKitWrapper(_ storeKitWrapper: RCStoreKitWrapper, updatedTransaction transaction: SKPaymentTransaction) {
        updatedTransactions.append(transaction)
    }

    var removedTransactions: [SKPaymentTransaction] = []

    func storeKitWrapper(_ storeKitWrapper: RCStoreKitWrapper, removedTransaction transaction: SKPaymentTransaction) {
        removedTransactions.append(transaction)
    }

    func testObservesThePaymentQueue() {
        expect(self.paymentQueue.observers.count).to(equal(1))
    }

    func testAddsPaymentsToTheQueue() {
        let payment = SKPayment.init(product: SKProduct.init())

        wrapper?.add(payment)

        expect(self.paymentQueue.addedPayments).to(contain(payment))
    }

    func testCallsDelegateWhenTransactionsAreUpdated() {
        let payment = SKPayment.init(product: SKProduct.init())
        wrapper?.add(payment)

        let transaction = MockTransaction()

        wrapper?.paymentQueue(paymentQueue, updatedTransactions: [transaction])

        expect(self.updatedTransactions).to(contain(transaction))
    }

    func testCallsDelegateOncePerTransaction() {
        let payment1 = SKPayment.init(product: SKProduct.init())
        wrapper?.add(payment1)

        let payment2 = SKPayment.init(product: SKProduct.init())
        wrapper?.add(payment2)

        let transaction1 = MockTransaction()
        let transaction2 = MockTransaction()

        wrapper?.paymentQueue(paymentQueue, updatedTransactions: [transaction1,
                                                                  transaction2])

        expect(self.updatedTransactions).to(contain([transaction1, transaction2]))
    }

    func testFinishesTransactions() {
        let payment = SKPayment.init(product: SKProduct.init())
        wrapper?.add(payment)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        wrapper?.paymentQueue(paymentQueue, updatedTransactions: [transaction])

        wrapper?.finish(transaction)

        expect(self.paymentQueue.finishedTransactions).to(contain(transaction))
    }

    func testCallsRemovedTransactionDelegateMethod() {
        let transaction1 = MockTransaction()
        let transaction2 = MockTransaction()

        wrapper?.paymentQueue(paymentQueue, removedTransactions: [transaction1, transaction2])

        expect(self.removedTransactions).to(contain([transaction1, transaction2]))
    }

    func testPurchasingFalseIfAllTransactionsNotPurchasing() {
        let transaction1 = MockTransaction()
        let transaction2 = MockTransaction()

        transaction1.mockState = SKPaymentTransactionState.purchased
        transaction2.mockState = SKPaymentTransactionState.failed

        wrapper?.paymentQueue(paymentQueue, updatedTransactions:[transaction1, transaction2])

        expect(self.wrapper?.purchasing).to(beFalse())
    }

    func testPurchasingTrueIfOneIsPurchasing() {
        let transaction1 = MockTransaction()
        let transaction2 = MockTransaction()

        transaction1.mockState = SKPaymentTransactionState.purchasing
        transaction2.mockState = SKPaymentTransactionState.purchased

        wrapper?.paymentQueue(paymentQueue, updatedTransactions:[transaction1, transaction2])

        expect(self.wrapper?.purchasing).to(beTrue())
    }

    func testPurchasingIsKVOCompliant() {
        class KVOListener: NSObject {
            var lastValue = false;
            override func observeValue(forKeyPath keyPath: String?,
                                       of object: Any?,
                                       change: [NSKeyValueChangeKey : Any]?,
                                       context: UnsafeMutableRawPointer?) {
                lastValue = (object as! RCStoreKitWrapper).purchasing
            }
        }

        let listener = KVOListener()

        wrapper!.addObserver(listener, forKeyPath: "purchasing",
                             options: [.old, .new, .initial],
                             context: nil)

        expect(listener.lastValue).to(beFalse())

        let transaction1 = MockTransaction()
        let transaction2 = MockTransaction()

        transaction1.mockState = SKPaymentTransactionState.purchasing
        transaction2.mockState = SKPaymentTransactionState.purchased

        wrapper?.paymentQueue(paymentQueue, updatedTransactions:[transaction1, transaction2])

        expect(listener.lastValue).to(beTrue())

        wrapper!.removeObserver(listener, forKeyPath: "purchasing")
    }

    func testDoesntAddObserverWithoutDelegate() {
        wrapper?.delegate = nil

        expect(self.paymentQueue.observers.count).to(equal(0))

        wrapper?.delegate = self

        expect(self.paymentQueue.observers.count).to(equal(1))

    }
}
