//
//  StoreKit1WrapperTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

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
        let index = observers.firstIndex { $0 === observer }
        observers.remove(at: index!)
    }

    var finishedTransactions: [SKPaymentTransaction] = []
    override func finishTransaction(_ transaction: SKPaymentTransaction) {
        finishedTransactions.append(transaction)
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func simulatePaymentQueueShouldShowPriceConsent() -> [Bool] {
        return self.observers
            .compactMap { $0 as? SKPaymentQueueDelegate }
            .compactMap { $0.paymentQueueShouldShowPriceConsent?(self) }
    }
#endif

}

class StoreKit1WrapperTests: TestCase, StoreKit1WrapperDelegate {
    let paymentQueue = MockPaymentQueue()

    var wrapper: StoreKit1Wrapper?

    override func setUp() {
        super.setUp()
        wrapper = StoreKit1Wrapper.init(paymentQueue: paymentQueue)
        wrapper?.delegate = self
    }

    var updatedTransactions: [SKPaymentTransaction] = []

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper, updatedTransaction transaction: SKPaymentTransaction) {
        updatedTransactions.append(transaction)
    }

    var removedTransactions: [SKPaymentTransaction] = []

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper, removedTransaction transaction: SKPaymentTransaction) {
        removedTransactions.append(transaction)
    }

    var promoPayment: SKPayment?
    var promoProduct: SK1Product?
    var shouldAddPromo = false
    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper,
                          shouldAddStorePayment payment: SKPayment,
                          for product: SK1Product) -> Bool {
        promoPayment = payment
        promoProduct = product
        return shouldAddPromo
    }

    var storefrontChangesCount: Int = 0
    func storeKit1WrapperDidChangeStorefront(_ storeKit1Wrapper: StoreKit1Wrapper) {
        storefrontChangesCount += 1
    }

    var storeKit1WrapperShouldShowPriceConsent = true

    var productIdentifiersWithRevokedEntitlements: [String]?

    func storeKit1Wrapper(
        _ storeKit1Wrapper: StoreKit1Wrapper,
        didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]
    ) {
        productIdentifiersWithRevokedEntitlements = productIdentifiers
    }

    func testObservesThePaymentQueue() {
        expect(self.paymentQueue.observers.count).to(equal(1))
    }

    func testAddsPaymentsToTheQueue() {
        let payment = SKPayment.init(product: SK1Product())

        wrapper?.add(payment)

        expect(self.paymentQueue.addedPayments).to(contain(payment))
    }

    func testCallsDelegateWhenTransactionsAreUpdated() {
        let payment = SKPayment.init(product: SK1Product())
        wrapper?.add(payment)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        wrapper?.paymentQueue(paymentQueue, updatedTransactions: [transaction])

        expect(self.updatedTransactions).to(contain(transaction))
    }

    func testCallsDelegateWhenPromoPurchaseIsAvailable() {
        let product = SK1Product()
        let payment = SKPayment.init(product: product)

        _ = wrapper?.paymentQueue(paymentQueue, shouldAddStorePayment: payment, for: product)
        expect(self.promoPayment).to(be(payment))
        expect(self.promoProduct).to(be(product))
    }

    func testPromoDelegateMethodPassesBackReturnValueFromOwnDelegate() {
        let product = SK1Product()
        let payment = SKPayment.init(product: product)

        shouldAddPromo = Bool.random()

        let result = wrapper?.paymentQueue(paymentQueue, shouldAddStorePayment: payment, for: product)

        expect(result).to(equal(self.shouldAddPromo))
    }

    func testCallsDelegateOncePerTransaction() {
        let payment1 = SKPayment.init(product: SK1Product())
        wrapper?.add(payment1)

        let payment2 = SKPayment.init(product: SK1Product())
        wrapper?.add(payment2)

        let transaction1 = MockTransaction()
        transaction1.mockPayment = payment1
        let transaction2 = MockTransaction()
        transaction2.mockPayment = payment2

        wrapper?.paymentQueue(paymentQueue, updatedTransactions: [transaction1,
                                                                  transaction2])

        expect(self.updatedTransactions).to(contain([transaction1, transaction2]))
    }

    func testFinishesTransactions() {
        let payment = SKPayment.init(product: SK1Product())
        wrapper?.add(payment)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        wrapper?.paymentQueue(paymentQueue, updatedTransactions: [transaction])

        wrapper?.finishTransaction(transaction)

        expect(self.paymentQueue.finishedTransactions).to(contain(transaction))
    }

    func testCallsRemovedTransactionDelegateMethod() {
        let transaction1 = MockTransaction()
        transaction1.mockPayment = SKPayment.init(product: SK1Product())
        let transaction2 = MockTransaction()
        transaction2.mockPayment = SKPayment.init(product: SK1Product())

        wrapper?.paymentQueue(paymentQueue, removedTransactions: [transaction1, transaction2])

        expect(self.removedTransactions).to(contain([transaction1, transaction2]))
    }

    func testCallsStorefrontDidUpdateDelegateMethod() {
        wrapper?.paymentQueueDidChangeStorefront(self.paymentQueue)

        expect(self.storefrontChangesCount) == 1
    }

    func testDoesntAddObserverWithoutDelegate() {
        wrapper?.delegate = nil

        expect(self.paymentQueue.observers.count).to(equal(0))

        wrapper?.delegate = self

        expect(self.paymentQueue.observers.count).to(equal(1))

    }

    func testDidRevokeEntitlementsForProductIdentifiersCallsDelegateWithRightArguments() throws {
        guard #available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 7.0, *) else { throw XCTSkip() }

        expect(self.productIdentifiersWithRevokedEntitlements).to(beNil())
        let revokedProductIdentifiers = [
            "mySuperProduct",
            "theOtherProduct"
        ]

        wrapper?.paymentQueue(paymentQueue, didRevokeEntitlementsForProductIdentifiers: revokedProductIdentifiers)
        expect(self.productIdentifiersWithRevokedEntitlements) == revokedProductIdentifiers
    }

    func testPaymentWithProductReturnsCorrectPayment() {
        guard let wrapper = wrapper else { fatalError("wrapper is not initialized!") }

        let productId = "mySuperProduct"
        let mockProduct = MockSK1Product(mockProductIdentifier: productId)
        let payment = wrapper.payment(with: mockProduct)
        expect(payment.productIdentifier) == productId
    }

    @available(macOS 10.14, *)
    func testPaymentWithProductSetsSimulatesAskToBuyInSandbox() {
        guard let wrapper = wrapper else { fatalError("wrapper is not initialized!") }

        let mockProduct = MockSK1Product(mockProductIdentifier: "mySuperProduct")

        StoreKit1Wrapper.simulatesAskToBuyInSandbox = false
        let payment1 = wrapper.payment(with: mockProduct)
        expect(payment1.simulatesAskToBuyInSandbox) == false

        StoreKit1Wrapper.simulatesAskToBuyInSandbox = true
        let payment2 = wrapper.payment(with: mockProduct)
        expect(payment2.simulatesAskToBuyInSandbox) == true
    }

    func testPaymentWithProductAndDiscountReturnsCorrectPaymentWithDiscount() throws {
        guard #available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *) else {
            throw XCTSkip()
        }
        guard let wrapper = wrapper else { fatalError("wrapper is not initialized!") }

        let productId = "mySuperProduct"
        let discountId = "mySuperDiscount"

        let mockProduct = MockSK1Product(mockProductIdentifier: productId)
        let mockDiscount = MockPaymentDiscount(mockIdentifier: discountId)
        let payment = wrapper.payment(with: mockProduct, discount: mockDiscount)
        expect(payment.productIdentifier) == productId
        expect(payment.paymentDiscount) == mockDiscount
    }

    func testPaymentWithProductAndDiscountSetsSimulatesAskToBuyInSandbox() throws {
        guard #available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *) else {
            throw XCTSkip()
        }
        guard let wrapper = wrapper else { fatalError("wrapper is not initialized!") }

        let mockProduct = MockSK1Product(mockProductIdentifier: "mySuperProduct")
        let mockDiscount = MockPaymentDiscount(mockIdentifier: "mySuperDiscount")

        StoreKit1Wrapper.simulatesAskToBuyInSandbox = false
        let payment1 = wrapper.payment(with: mockProduct, discount: mockDiscount)
        expect(payment1.simulatesAskToBuyInSandbox) == false

        StoreKit1Wrapper.simulatesAskToBuyInSandbox = true
        let payment2 = wrapper.payment(with: mockProduct)
        expect(payment2.simulatesAskToBuyInSandbox) == true
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    func testShouldShowPriceConsentWiredUp() throws {
        guard #available(iOS 13.4, macCatalyst 13.4, *) else {
            throw XCTSkip()
        }
        expect(self.storeKit1WrapperShouldShowPriceConsent) == true

        self.storeKit1WrapperShouldShowPriceConsent = false

        let consentStatuses = self.paymentQueue.simulatePaymentQueueShouldShowPriceConsent()
        expect(consentStatuses) == [false]
    }
#endif

}
