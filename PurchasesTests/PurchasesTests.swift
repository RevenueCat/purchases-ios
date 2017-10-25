//
//  PurchasesTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/28/17.
//  Copyright © 2017 Purchases. All rights reserved.
//

import XCTest
import Nimble

import Purchases

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
}

class PurchasesTests: XCTestCase {

    class MockProductFetcher: RCProductFetcher {
        override func fetchProducts(_ identifiers: Set<String>, completion: @escaping RCProductFetcherCompletionHandler) {
            let products = identifiers.map { (identifier) -> MockProduct in
                MockProduct(mockProductIdentifier: identifier)
            }
            completion(products)
        }
    }

    class MockBackend: RCBackend {
        var userID: String?
        override func getSubscriberData(withAppUserID appUserID: String, completion: @escaping RCBackendResponseHandler) {
            userID = appUserID
            completion(RCPurchaserInfo(), nil)
        }

        var postReceiptDataCalled = false
        var postReceiptPurchaserInfo: RCPurchaserInfo?
        var postReceiptError: Error?

        override func postReceiptData(_ data: Data, appUserID: String, completion: @escaping RCBackendResponseHandler) {
            postReceiptDataCalled = true
            completion(postReceiptPurchaserInfo, postReceiptError)
        }


        var mockIsPurchasing: Bool = false {
            willSet {
                self.willChangeValue(forKey: "purchasing")
            }
            didSet {
                self.didChangeValue(forKey: "purchasing")
            }
        }
        override var purchasing: Bool {
            get {
                return mockIsPurchasing
            }
        }
    }

    class MockStoreKitWrapper: RCStoreKitWrapper {
        var payment: SKPayment?
        override func add(_ newPayment: SKPayment) {
            payment = newPayment
        }

        var finishCalled = false
        override func finish(_ transaction: SKPaymentTransaction) {
            finishCalled = true
        }

        var mockIsPurchasing: Bool = false {
            willSet {
                self.willChangeValue(forKey: "purchasing")
            }
            didSet {
                self.didChangeValue(forKey: "purchasing")
            }
        }
        override var purchasing: Bool {
            get {
                return mockIsPurchasing
            }
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

    class PurchasesDelegate: RCPurchasesDelegate {
        var completedTransaction: SKPaymentTransaction?
        var purchaserInfo: RCPurchaserInfo?
        func purchases(_ purchases: RCPurchases, completedTransaction transaction: SKPaymentTransaction, withUpdatedInfo purchaserInfo: RCPurchaserInfo) {
            self.completedTransaction = transaction
            self.purchaserInfo = purchaserInfo
        }

        var failedTransaction: SKPaymentTransaction?
        func purchases(_ purchases: RCPurchases, failedTransaction transaction: SKPaymentTransaction, withReason failureReason: Error) {
            self.failedTransaction = transaction
        }
    }

    let productFetcher = MockProductFetcher()
    let backend = MockBackend()
    let storeKitWrapper = MockStoreKitWrapper()

    let purchasesDelegate = PurchasesDelegate()

    let sharedSecret = "thisisasecret"
    let appUserID = "app_user"

    var purchases: RCPurchases?

    override func setUp() {
        super.setUp()
        purchases = RCPurchases.init(appUserID: appUserID,
                                     productFetcher: productFetcher,
                                     backend:backend,
                                     storeKitWrapper: storeKitWrapper)

        purchases!.delegate = purchasesDelegate
    }
    
    func testIsAbleToBeIntializedWithASharedSecret() {
        expect(self.purchases).toNot(beNil())
    }

    func testIsAbleToFetchProducts() {
        var products: [SKProduct]?
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.products(withIdentifiers:Set(productIdentifiers)) { (newProducts) in
            products = newProducts
        }

        expect(products).toEventuallyNot(beNil())
        expect(products).toEventually(haveCount(productIdentifiers.count))
    }

    func testIsAbleToGetPurchaserInfo() {
        var purchaserInfo: RCPurchaserInfo?
        purchases!.purchaserInfo() { (newPurchaserInfo) in
            purchaserInfo = newPurchaserInfo
        }

        expect(purchaserInfo).toEventuallyNot(beNil())
        expect(self.backend.userID).toEventually(equal(appUserID))
    }

    func testSetsSelfAsStoreKitWrapperDelegate() {
        expect(self.storeKitWrapper.delegate).to(be(purchases))
    }

    func testAddsPaymentToWrapper() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        expect(self.storeKitWrapper.payment).toNot(beNil())
        expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
    }

    func testTransitioningToPurchasing() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(false))
    }

    func testTransitioningToPurchasedSendsToBackend() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
    }

    func testFinishesTransactionsIfSentToBackendCorrectly() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = RCPurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).to(beTrue())
    }

    enum BackendError: Error {
        case unknown
    }

    func testAfterSendingDoesntFinishTransactionIfBackendError() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = BackendError.unknown

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testNotifiesIfTransactionFailsFromBackend() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = BackendError.unknown

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
        expect(self.purchasesDelegate.failedTransaction).to(be(transaction))
    }

    func testNotifiesIfTransactionFailsFromStoreKit() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = BackendError.unknown

        transaction.mockState = SKPaymentTransactionState.failed
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(false))
        expect(self.storeKitWrapper.finishCalled).to(beTrue())
        expect(self.purchasesDelegate.failedTransaction).to(be(transaction))
    }

    func testCallsDelegateAfterBackendResponse() {
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product)

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptPurchaserInfo = RCPurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.purchasesDelegate.completedTransaction).to(be(transaction))
        expect(self.purchasesDelegate.purchaserInfo).to(be(self.backend.postReceiptPurchaserInfo))
    }

    func testIsPurchasingLogic() {
        storeKitWrapper.mockIsPurchasing = false
        backend.mockIsPurchasing = false
        expect(self.purchases?.purchasing).to(beFalse())

        storeKitWrapper.mockIsPurchasing = true
        backend.mockIsPurchasing = false
        expect(self.purchases?.purchasing).to(beTrue())

        storeKitWrapper.mockIsPurchasing = false
        backend.mockIsPurchasing = true
        expect(self.purchases?.purchasing).to(beTrue())

        storeKitWrapper.mockIsPurchasing = true
        backend.mockIsPurchasing = true
        expect(self.purchases?.purchasing).to(beTrue())
    }

    func testDoesntIgnorePurchasesThatDoNotHaveApplicationUserNames() {
        let transaction = MockTransaction()

        let payment = SKMutablePayment()

        expect(payment.applicationUsername).to(equal(""))

        transaction.mockPayment = payment
        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
    }

    func testPurchasingIsKVOCompliant() {
        class KVOListener: NSObject {
            var lastValue = false;
            override func observeValue(forKeyPath keyPath: String?,
                                       of object: Any?,
                                       change: [NSKeyValueChangeKey : Any]?,
                                       context: UnsafeMutableRawPointer?) {
                lastValue = (object as! RCPurchases).purchasing
            }
        }

        let listener = KVOListener()

        purchases!.addObserver(listener, forKeyPath: "purchasing",
                               options: [.old, .new, .initial],
                               context: nil)

        expect(listener.lastValue).to(beFalse())

        storeKitWrapper.mockIsPurchasing = true
        expect(listener.lastValue).to(beTrue())

        storeKitWrapper.mockIsPurchasing = false
        expect(listener.lastValue).to(beFalse())

        storeKitWrapper.mockIsPurchasing = true
        expect(listener.lastValue).to(beTrue())

        storeKitWrapper.mockIsPurchasing = false
        backend.mockIsPurchasing = true
        expect(listener.lastValue).to(beTrue())

        backend.mockIsPurchasing = false
        expect(listener.lastValue).to(beFalse())

        purchases!.removeObserver(listener, forKeyPath: "purchasing")
    }

    func testDoesntSetWrapperDelegateUntilDelegateIsSet() {
        purchases!.delegate = nil

        expect(self.storeKitWrapper.delegate).to(beNil())

        purchases!.delegate = purchasesDelegate

        expect(self.storeKitWrapper.delegate).toNot(beNil())
    }
}
