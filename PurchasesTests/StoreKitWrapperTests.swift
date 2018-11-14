//
//  StoreKitWrapperTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2018 Purchases. All rights reserved.
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
    
    var promoPayment: SKPayment?
    var promoProduct: SKProduct?
    var shouldAddPromo = false
    func storeKitWrapper(_ storeKitWrapper: RCStoreKitWrapper, shouldAddStore payment: SKPayment, for product: SKProduct) -> Bool {
        promoPayment = payment
        promoProduct = product
        return shouldAddPromo
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
    
    func testCallsDelegateWhenPromoPurchaseIsAvailable() {
        let product = SKProduct.init();
        let payment = SKPayment.init(product: product)
        
        wrapper?.paymentQueue(paymentQueue, shouldAddStorePayment: payment, for: product)
        
        expect(self.promoPayment).to(be(payment));
        expect(self.promoProduct).to(be(product))
    }
    
    func testPromoDelegateMethodPassesBackReturnValueFromOwnDelegate() {
        let product = SKProduct.init();
        let payment = SKPayment.init(product: product)
        
        shouldAddPromo = (arc4random() % 2 == 0) as Bool
        
        let result = wrapper?.paymentQueue(paymentQueue, shouldAddStorePayment: payment, for: product)
        
        expect(result).to(equal(self.shouldAddPromo))
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

    func testDoesntAddObserverWithoutDelegate() {
        wrapper?.delegate = nil

        expect(self.paymentQueue.observers.count).to(equal(0))

        wrapper?.delegate = self

        expect(self.paymentQueue.observers.count).to(equal(1))

    }
}
