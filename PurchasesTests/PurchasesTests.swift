//
//  PurchasesTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/28/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
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
    
    var mockError: Error?
    override var error: Error? {
        get {
            return mockError
        }
    }
}

class PurchasesTests: XCTestCase {

    class MockRequestFetcher: RCStoreKitRequestFetcher {
        var refreshReceiptCalled = false
        var failProducts = false
        var requestedProducts: Set<String?>?
        override func fetchProducts(_ identifiers: Set<String>, completion: @escaping RCFetchProductsCompletionHandler) {
            if (failProducts) {
                completion([SKProduct]())
                return
            }
            requestedProducts = identifiers
            let products = identifiers.map { (identifier) -> MockProduct in
                let p = MockProduct(mockProductIdentifier: identifier)
                p.mockSubscriptionGroupIdentifier = "1234567"
                return p
            }
            completion(products)
        }

        override func fetchReceiptData(_ completion: @escaping RCFetchReceiptCompletionHandler) {
            refreshReceiptCalled = true
            completion()
        }
    }

    class MockBackend: RCBackend {
        var userID: String?
        var originalApplicationVersion: String?
        var timeout = false
        var getSubscriberCallCount = 0
        override func getSubscriberData(withAppUserID appUserID: String, completion: @escaping RCBackendResponseHandler) {
            getSubscriberCallCount += 1
            userID = appUserID
            var info: PurchaserInfo?
            if let version = originalApplicationVersion {
                info = PurchaserInfo(data: [
                    "subscriber": [
                        "subscriptions": [:],
                        "other_purchases": [:],
                        "original_application_version": version
                    ]
                ])
            } else {
                info = PurchaserInfo(data: [
                    "subscriber": [
                        "subscriptions": [:],
                        "other_purchases": [:]
                    ]])
            }

            if (!timeout) {
                DispatchQueue.main.async {
                    completion(info!, nil)
                }
            }
        }

        var postReceiptDataCalled = false
        var postedIsRestore: Bool?
        var postedProductID: String?
        var postedPrice: NSDecimalNumber?
        var postedPaymentMode: RCPaymentMode?
        var postedIntroPrice: NSDecimalNumber?
        var postedCurrencyCode: String?
        var postedSubscriptionGroup: String?
        
        var postReceiptPurchaserInfo: PurchaserInfo?
        var postReceiptError: Error?
        var aliasError: Error?
        var aliasCalled = false

        override func postReceiptData(_ data: Data, appUserID: String, isRestore: Bool, productIdentifier: String?, price: NSDecimalNumber?, paymentMode: RCPaymentMode, introductoryPrice: NSDecimalNumber?, currencyCode: String?, subscriptionGroup: String?, completion: @escaping RCBackendResponseHandler) {
            postReceiptDataCalled = true
            postedIsRestore = isRestore

            postedProductID  = productIdentifier
            postedPrice = price

            postedPaymentMode = paymentMode
            postedIntroPrice = introductoryPrice
            postedSubscriptionGroup = subscriptionGroup

            postedCurrencyCode = currencyCode

            completion(postReceiptPurchaserInfo, postReceiptError)
        }

        var postedProductIdentifiers: [String]?
        override func getIntroEligibility(forAppUserID appUserID: String, receiptData: Data?, productIdentifiers: [String], completion: @escaping RCIntroEligibilityResponseHandler) {
            postedProductIdentifiers = productIdentifiers

            var eligibilities = [String: RCIntroEligibility]()
            for productID in productIdentifiers {
                eligibilities[productID] = RCIntroEligibility(eligibilityStatus: RCIntroEligibityStatus.eligible)
            }

            completion(eligibilities)
        }

        var failEntitlements = false
        var gotEntitlements = 0
        override func getEntitlementsForAppUserID(_ appUserID: String, completion: @escaping RCEntitlementResponseHandler) {
            gotEntitlements += 1
            if (failEntitlements) {
                completion(nil, NSError.init(domain: RCBackendErrorDomain, code: 0, userInfo:nil))
                return
            }

            let offering = Offering()
            offering.activeProductIdentifier = "monthly_freetrial"
            let entitlement = Entitlement(offerings: ["monthly" : offering])
            completion(["pro" : entitlement!], nil)
        }
        
        override func createAlias(forAppUserID appUserID: String, withNewAppUserID newAppUserID: String, completion: ((Error?) -> Void)? = nil) {
            aliasCalled = true
            if (aliasError != nil) {
                completion!(aliasError)
            } else {
                userID = newAppUserID
                completion!(nil)
            }
        }

        var postedAttributionData: [AnyHashable : Any]?
        var postedAttributionFromNetwork: RCAttributionNetwork?
        var postedAttributionAppUserId: String?
        override func postAttributionData(_ data: [AnyHashable : Any], from network: RCAttributionNetwork, forAppUserID appUserID: String) {
            postedAttributionData = data
            postedAttributionAppUserId = appUserID
            postedAttributionFromNetwork = network
        }

    }

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

    class MockNotificationCenter: NotificationCenter {

        var observers = [(AnyObject, Selector, NSNotification.Name?, Any?)]();

        override func addObserver(_ observer: Any, selector
            aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
            observers.append((observer as AnyObject, aSelector, aName, anObject))
        }

        override func removeObserver(_ anObserver: Any, name aName: NSNotification.Name?, object anObject: Any?) {
            observers = observers.filter {$0.0 !== anObserver as AnyObject || $0.2 != aName}
        }

        func fireNotifications() {
            for (observer, selector, _, _) in observers {
                _ = observer.perform(selector, with:nil);
            }
        }
    }

    class MockUserDefaults: UserDefaults {
        let appUserIDKey = "com.revenuecat.userdefaults.appUserID"
        let purchaserInfoCachePrefix = "com.revenuecat.userdefaults.purchaserInfo"

        var appUserID: String?
        var cachedUserInfoCount = 0
        var cachedUserInfo = [String : Data]()

        override func string(forKey defaultName: String) -> String? {
            return appUserID;
        }

        override func data(forKey defaultName: String) -> Data? {
            return cachedUserInfo[defaultName];
        }

        override func set(_ value: Any?, forKey defaultName: String) {
            if (defaultName == appUserIDKey) {
                appUserID = value as! String?
            } else if (defaultName.starts(with: purchaserInfoCachePrefix)) {
                cachedUserInfoCount += 1
                cachedUserInfo[defaultName] = value as! Data?
            }
        }
        
        override func removeObject(forKey defaultName: String) {
            appUserID = nil
        }
    }

    class Delegate: NSObject, PurchasesDelegate {
        var purchaserInfo: PurchaserInfo?
        var purchaserInfoReceivedCount = 0
        func purchases(_ purchases: Purchases, didReceive purchaserInfo: PurchaserInfo) {
            purchaserInfoReceivedCount += 1
            self.purchaserInfo = purchaserInfo
        }
        
        var promoProduct: SKProduct?
        var shouldAddPromo = false
        var makeDeferredPurchase: RCDeferredPromotionalPurchaseBlock?
        func purchases(_ purchases: Purchases, shouldPurchasePromoProduct product: SKProduct, defermentBlock makeDeferredPurchase: @escaping RCDeferredPromotionalPurchaseBlock) -> Bool {
            promoProduct = product
            self.makeDeferredPurchase = makeDeferredPurchase
            return shouldAddPromo
        }
    }

    let requestFetcher = MockRequestFetcher()
    let backend = MockBackend()
    let storeKitWrapper = MockStoreKitWrapper()
    let notificationCenter = MockNotificationCenter();
    let userDefaults = MockUserDefaults();

    let purchasesDelegate = Delegate()
    
    let appUserID = "app_user"

    var purchases: Purchases?

    func setupPurchases() {
        purchases = Purchases(appUserID: appUserID,
                                requestFetcher: requestFetcher,
                                backend:backend,
                                storeKitWrapper: storeKitWrapper,
                                notificationCenter:notificationCenter,
                                userDefaults:userDefaults)

        purchases!.delegate = purchasesDelegate
    }

    func setupAnonPurchases() {
        purchases = Purchases(appUserID: nil,
                                requestFetcher: requestFetcher,
                                backend:backend,
                                storeKitWrapper: storeKitWrapper,
                                notificationCenter:notificationCenter,
                                userDefaults:userDefaults)

        purchases!.delegate = purchasesDelegate
    }
    
    func testIsAbleToBeIntialized() {
        setupPurchases()
        expect(self.purchases).toNot(beNil())
    }
    
    func testFirstInitializationCallDelegate() {
        setupPurchases()
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1))
    }
    
    func testFirstInitializationCallDelegateForAnon() {
        setupAnonPurchases()
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1))
    }
    
    func testDelegateIsCalledForRandomPurchaseSuccess() {
        setupPurchases()
        
        let purchaserInfo = PurchaserInfo()
        self.backend.postReceiptPurchaserInfo = purchaserInfo
        
        let product = MockProduct(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)
        
        let transaction = MockTransaction()
        
        transaction.mockPayment = payment
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testDelegateIsOnlyCalledOnceIfPurchaserInfoTheSame() {
        setupPurchases()
        
        let purchaserInfo1 = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
        ])
        
        let purchaserInfo2 = purchaserInfo1
        
        let product = MockProduct(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)
        
        let transaction = MockTransaction()
        
        transaction.mockPayment = payment
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        self.backend.postReceiptPurchaserInfo = purchaserInfo1
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        self.backend.postReceiptPurchaserInfo = purchaserInfo2
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testDelegateIsCalledTwiceIfPurchaserInfoTheDifferent() {
        setupPurchases()
        
        let purchaserInfo1 = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
            ])
        
        let purchaserInfo2 = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2.0"
            ]
            ])
        
        let product = MockProduct(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)
        
        let transaction = MockTransaction()
        
        transaction.mockPayment = payment
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        self.backend.postReceiptPurchaserInfo = purchaserInfo1
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        self.backend.postReceiptPurchaserInfo = purchaserInfo2
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(3))
    }
    
    func testDelegateIsNotCalledIfBlockPassed() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }
        
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.backend.postedIsRestore).to(equal(false))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1))
    }

    func testIsAbleToFetchProducts() {
        setupPurchases()
        var products: [SKProduct]?
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.products(productIdentifiers) { (newProducts) in
            products = newProducts
        }

        expect(products).toEventuallyNot(beNil())
        expect(products).toEventually(haveCount(productIdentifiers.count))
    }

    func testSetsSelfAsStoreKitWrapperDelegate() {
        setupPurchases()
        expect(self.storeKitWrapper.delegate).to(be(purchases))
    }

    func testAddsPaymentToWrapper() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        expect(self.storeKitWrapper.payment).toNot(beNil())
        expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
    }

    func testTransitioningToPurchasing() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(false))
    }

    func testTransitioningToPurchasedSendsToBackend() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.backend.postedIsRestore).to(equal(false))
    }

    func testReceiptsSendsAsRestoreWhenAnon() {
        setupAnonPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.backend.postedIsRestore).to(equal(true))
    }

    func testFinishesTransactionsIfSentToBackendCorrectly() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testDoesntFinishTransactionsIfFinishingDisbaled() {
        setupPurchases()
        self.purchases?.finishTransactions = false
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }
    

    func testSendsProductInfoIfProductIsCached() {
        setupPurchases()
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.products(productIdentifiers) { (newProducts) in
            let product = newProducts[0];
            self.purchases?.makePurchase(product) { (tx, info, error) in
                
            }
            
            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!
            
            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            self.backend.postReceiptPurchaserInfo = PurchaserInfo()
            
            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            expect(self.backend.postReceiptDataCalled).to(equal(true))
            expect(self.backend.postReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(product.price))

            if #available(iOS 11.2, *) {
                expect(self.backend.postedPaymentMode).to(equal(RCPaymentMode.payAsYouGo))
                expect(self.backend.postedIntroPrice).to(equal(product.introductoryPrice?.price))
            } else {
                expect(self.backend.postedPaymentMode).to(equal(RCPaymentMode.none))
                expect(self.backend.postedIntroPrice).to(beNil())
            }
            
            if #available(iOS 12.0, *) {
                expect(self.backend.postedSubscriptionGroup).to(equal(product.subscriptionGroupIdentifier))
            }
            
            expect(self.backend.postedCurrencyCode).to(equal(product.priceLocale.currencyCode))

            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }
    
    func testFetchesProductInfoIfNotCached() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        
        let transaction = MockTransaction()
        storeKitWrapper.payment = SKPayment(product: product);
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        self.backend.postReceiptPurchaserInfo = PurchaserInfo()
        
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.requestFetcher.requestedProducts).to(contain([product.productIdentifier]))
        
        expect(self.backend.postedProductID).toNot(beNil())
        expect(self.backend.postedPrice).toNot(beNil())
        expect(self.backend.postedIntroPrice).toNot(beNil())
        expect(self.backend.postedCurrencyCode).toNot(beNil())
    }
    
    enum BackendError: Error {
        case unknown
    }

    func testAfterSendingDoesntFinishTransactionIfBackendError() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = NSError(domain: "error_domain", code: RCUnfinishableError, userInfo: nil)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testAfterSendingFinishesFromBackendErrorIfAppropriate() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = NSError(domain: "error_domain", code: RCFinishableError, userInfo: nil)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testNotifiesIfTransactionFailsFromBackend() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = NSError(domain: "error_domain", code: RCUnfinishableError, userInfo: nil)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testNotifiesIfTransactionFailsFromStoreKit() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedError: Error?
        self.purchases?.makePurchase(product) { (tx, info, error) in
            receivedError = error
        }

        let transaction = MockTransaction()
        transaction.mockError = NSError.init(domain: SKErrorDomain, code: 2, userInfo: nil)
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = BackendError.unknown

        transaction.mockState = SKPaymentTransactionState.failed
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(false))
        expect(self.storeKitWrapper.finishCalled).to(beTrue())
        expect(receivedError).toEventuallyNot(beNil())
    }

    func testCallsDelegateAfterBackendResponse() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        
        var purchaserInfo: PurchaserInfo?
        var receivedError: Error?
        
        self.purchases?.makePurchase(product) { (tx, info, error) in
            purchaserInfo = info
            receivedError = error
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptPurchaserInfo = PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(purchaserInfo).toEventually(be(self.backend.postReceiptPurchaserInfo))
        expect(receivedError).toEventually(beNil())
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).to(equal(2))
    }
    
    func testCompletionBlockOnlyCalledOnce() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        
        var callCount = 0
        
        self.purchases?.makePurchase(product) { (tx, info, error) in
            callCount += 1
        }
        
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        self.backend.postReceiptPurchaserInfo = PurchaserInfo()
        
        transaction.mockState = SKPaymentTransactionState.purchased
        
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(callCount).toEventually(equal(1))
    }
    
    func testCompletionBlockNotCalledForDifferentProducts() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        let otherProduct = MockProduct(mockProductIdentifier: "com.product.id2")
        
        var callCount = 0
        
        self.purchases?.makePurchase(product) { (tx, info, error) in
            callCount += 1
        }
        
        let transaction = MockTransaction()
        transaction.mockPayment = SKPayment.init(product: otherProduct)
        
        self.backend.postReceiptPurchaserInfo = PurchaserInfo()
        
        transaction.mockState = SKPaymentTransactionState.purchased
        
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(callCount).toEventually(equal(0))
    }
    
    func testCallingPurchaseWhileSameProductPendingIssuesError() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        
        // First one "works"
        self.purchases?.makePurchase(product) { (tx, info, error) in }
        
        var receivedInfo: PurchaserInfo?
        var receivedError: Error?
        
        // Second one issues an error
        self.purchases?.makePurchase(product) { (tx, info, error) in
            receivedInfo = info
            receivedError = error
        }
        
        expect(receivedInfo).toEventually(beNil())
        expect(receivedError).toEventuallyNot(beNil())
        expect(self.storeKitWrapper.addPaymentCallCount).to(equal(1))
    }

    func testDoesntIgnorePurchasesThatDoNotHaveApplicationUserNames() {
        setupPurchases()
        let transaction = MockTransaction()

        let payment = SKMutablePayment()
        payment.productIdentifier = "test"

        expect(payment.applicationUsername).to(equal(""))

        transaction.mockPayment = payment
        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))
    }

    func testDoesntSetWrapperDelegateToNilIfDelegateNil() {
        setupPurchases()
        purchases!.delegate = nil

        expect(self.storeKitWrapper.delegate).toNot(beNil())

        purchases!.delegate = purchasesDelegate

        expect(self.storeKitWrapper.delegate).toNot(beNil())
    }

    func testSubscribesToUIApplicationDidBecomeActive() {
        setupPurchases()
        expect(self.notificationCenter.observers.count).to(equal(1));
        if self.notificationCenter.observers.count > 0 {
            let (_, _, name, _) = self.notificationCenter.observers[0];
            expect(name).to(equal(NSNotification.Name.UIApplicationDidBecomeActive))
        }
    }

    func testTriggersCallToBackend() {
        setupPurchases()
        notificationCenter.fireNotifications();
        expect(self.backend.userID).toEventuallyNot(beNil());
    }

    func testAutomaticallyFetchesPurchaserInfoOnDidBecomeActive() {
        setupPurchases()
        notificationCenter.fireNotifications();
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }
    
    func testAutomaticallyCallsDelegateOnDidBecomeActiveAndUpdate() {
        setupPurchases()
        notificationCenter.fireNotifications();
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1))
    }

    func testDoesntRemovesObservationWhenDelegateNild() {
        setupPurchases()
        purchases!.delegate = nil

        expect(self.notificationCenter.observers.count).to(equal(1));
    }

    func testRestoringPurchasesPostsTheReceipt() {
        setupPurchases()
        purchases!.restoreTransactions()
        expect(self.backend.postReceiptDataCalled).to(equal(true))
    }

    func testRestoringPurchasesRefreshesAndPostsTheReceipt() {
        setupPurchases()
        purchases!.restoreTransactions()

        expect(self.requestFetcher.refreshReceiptCalled).to(equal(true))
    }

    func testRestoringPurchasesSetsIsRestore() {
        setupPurchases()
        purchases!.restoreTransactions(nil)
        expect(self.backend.postedIsRestore!).to(equal(true))
    }

    func testRestoringPurchasesSetsIsRestoreForAnon() {
        setupAnonPurchases()
        purchases!.restoreTransactions(nil)

        expect(self.backend.postedIsRestore!).to(equal(true))
    }

    func testRestoringPurchasesCallsSuccessDelegateMethod() {
        setupPurchases()

        let purchaserInfo = PurchaserInfo()
        self.backend.postReceiptPurchaserInfo = purchaserInfo
        
        var receivedPurchaserInfo: PurchaserInfo?

        purchases!.restoreTransactions { (info, error) in
            receivedPurchaserInfo = info
        }

        expect(receivedPurchaserInfo).toEventually(be(purchaserInfo))
    }

    func testRestorePurchasesPassesErrorOnFailure() {
        setupPurchases()
        
        let error = NSError(domain: "error_domain", code: RCFinishableError, userInfo: nil)
        self.backend.postReceiptError = error
        self.purchasesDelegate.purchaserInfo = nil
        
        var receivedError: Error?
        
        purchases!.restoreTransactions { (_, newError) in
            receivedError = newError
        }
        
        expect(receivedError).toEventuallyNot(beNil())
    }
    
    func testCallsShouldAddPromoPaymentDelegateMethod() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init()
        
        storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper, shouldAddStore: payment, for: product)
        
        expect(self.purchasesDelegate.promoProduct).to(be(product))
    }
    
    func testShouldAddPromoPaymentDelegateMethodPassesUpResult() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init()
        
        let randomBool = (arc4random() % 2 == 0) as Bool
        purchasesDelegate.shouldAddPromo = randomBool
        
        let result = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper, shouldAddStore: payment, for: product)
        
        expect(randomBool).to(equal(result))
    }
    
    func testShouldCacheProductsFromPromoPaymentDelegateMethod() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)
        
        storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper, shouldAddStore: payment, for: product)
        
        let transaction = MockTransaction()
        transaction.mockPayment = payment
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(equal(true))
        expect(self.backend.postedProductID).to(equal(product.productIdentifier))
        expect(self.backend.postedPrice).to(equal(product.price))
    }
    
    func testDeferBlockMakesPayment() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)
        
        purchasesDelegate.shouldAddPromo = false
        storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper, shouldAddStore: payment, for: product)
        
        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        
        expect(self.storeKitWrapper.payment).to(beNil())
        
        self.purchasesDelegate.makeDeferredPurchase!()
        
        expect(self.storeKitWrapper.payment).to(be(payment))
    }


    func testAnonPurchasesGeneratesAnAppUserID() {
        setupAnonPurchases()
        expect(self.purchases?.appUserID).toNot(beEmpty())
    }

    func testAnonPurchasesSavesTheAppUserID() {
        setupAnonPurchases()
        expect(self.userDefaults.appUserID).toNot(beNil())
    }

    func testAnonPurchasesReadsSavedAppUserID() {
        let appUserID = "jerry"
        userDefaults.appUserID = appUserID
        setupAnonPurchases()

        expect(self.purchases?.appUserID).to(equal(appUserID))
    }
    
    func testGetEligibility() {
        setupPurchases()
        purchases!.checkTrialOrIntroductoryPriceEligibility([]) { (eligibilities) in}
    }

    func testGetEligibilitySendsAReceipt() {
        setupPurchases()
        purchases!.checkTrialOrIntroductoryPriceEligibility([]) { (eligibilities) in}

        expect(self.requestFetcher.refreshReceiptCalled).to(beTrue())
    }

    func testFetchVersionSendsAReceiptIfNoVersion() {
        setupPurchases()

        self.backend.postReceiptPurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
        ])
        
        var receivedPurchaserInfo: PurchaserInfo?

        purchases?.restoreTransactions { (info, error) in
            receivedPurchaserInfo = info
        }

        expect(receivedPurchaserInfo?.originalApplicationVersion).toEventually(equal("1.0"))
        expect(self.backend.userID).toEventuallyNot(beNil())
        expect(self.backend.postReceiptDataCalled).toEventuallyNot(beFalse())
    }

    func testCachesPurchaserInfo() {
        setupPurchases()

        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(1))
        expect(self.userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo." + self.purchases!.appUserID]).toEventuallyNot(beNil())
        
        let purchaserInfo = self.userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo." + self.purchases!.appUserID]
        
        do {
            if (purchaserInfo != nil) {
                try JSONSerialization.jsonObject(with: purchaserInfo!, options: [])
            }
        } catch {
            fail()
        }
    }

    func testCachesPurchaserInfoOnPurchase() {
        setupPurchases()

        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(1))

        self.backend.postReceiptPurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(equal(true))

        expect(self.userDefaults.cachedUserInfoCount).toEventually(equal(2))
    }

    func testSendsCachedPurchaserInfoToGetter() {
        let info = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let object = try! JSONSerialization.data(withJSONObject: info!.jsonObject(), options:[]);
        self.userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo." + appUserID] = object
        self.backend.timeout = true

        setupPurchases()
        
        var receivedInfo: PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }
        
        expect(receivedInfo).toNot(beNil())
    }
    
    func testDoesntSendCacheIfNoCacheAndCallsBackendAgain() {
        self.backend.timeout = true
        
        setupPurchases()
        
        expect(self.backend.getSubscriberCallCount).to(equal(1))
        
        purchases!.purchaserInfo { (info, error) in
        }
        
        expect(self.backend.getSubscriberCallCount).to(equal(2))
    }

    func testGetsProductInfoFromEntitlements() {
        setupPurchases()
        expect(self.backend.gotEntitlements).toEventually(equal(1))

        var entitlements: [String : Entitlement]?
        
        self.purchases?.entitlements { (newEntitlements, _)  in
            entitlements = newEntitlements
        }

        expect(entitlements).toEventuallyNot(beNil());

        guard let e = entitlements else { return }

        expect(e.count).toEventually(equal(1))
        let pro = e["pro"]!;
        expect(pro.offerings["monthly"]).toNot(beNil())
        expect(pro.offerings["monthly"]?.activeProduct).toNot(beNil())
    }

    func testProductInfoIsCachedForEntitlements() {
        setupPurchases()
        expect(self.backend.gotEntitlements).toEventually(equal(1))
        self.purchases?.entitlements { (newEntitlements, _) in
            let product = (newEntitlements?["pro"]?.offerings["monthly"]?.activeProduct)!;
            self.purchases?.makePurchase(product) { (tx, info, error) in
                
            }
            
            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!
            
            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            self.backend.postReceiptPurchaserInfo = PurchaserInfo()
            
            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            expect(self.backend.postReceiptDataCalled).to(equal(true))
            expect(self.backend.postReceiptData).toNot(beNil())
            
            expect(self.backend.postedProductID).to(equal(product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(product.price))
            expect(self.backend.postedCurrencyCode).to(equal(product.priceLocale.currencyCode))
            
            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testFailBackendEntitlementsReturnsNil() {
        self.backend.failEntitlements = true
        setupPurchases()

        var entitlements: [String : Entitlement]?
        self.purchases?.entitlements({ (newEntitlements, _) in
            entitlements = newEntitlements
        })

        expect(entitlements).toEventually(beNil());

    }

    func testMissingProductDetailsReturnsNil() {
        requestFetcher.failProducts = true
        setupPurchases()

        var entitlements: [String : Entitlement]?
        self.purchases?.entitlements({ (newEntitlements, _) in
            entitlements = newEntitlements
        })

        expect(entitlements).toEventuallyNot(beNil());
        expect(entitlements).toEventually(haveCount(1))
    }

    func testAddAttributionDoesntCallEmptyDict() {
        setupPurchases()

        self.purchases?.addAttributionData([:], from: RCAttributionNetwork.adjust)

        expect(self.backend.postedAttributionData).toEventually(beNil())
    }

    func testPassesTheArrayForAllNetworks() {
        setupPurchases()
        let data = ["yo" : "dog", "what" : 45, "is" : ["up"]] as [AnyHashable : Any]

        self.purchases?.addAttributionData(data, from: RCAttributionNetwork.appleSearchAds)

        expect(self.backend.postedAttributionData?.keys).toEventually(equal(data.keys))
        expect(self.backend.postedAttributionFromNetwork).toEventually(equal(RCAttributionNetwork.appleSearchAds))
        expect(self.backend.postedAttributionAppUserId).toEventually(equal(self.purchases?.appUserID))
    }

    func testSharedInstanceIsSetWhenConfiguring() {
        let purchases = Purchases.configure(withAPIKey: "")
        expect(Purchases.shared).toEventually(equal(purchases))
    }
    
    func testSharedInstanceIsSetWhenConfiguringWithAppUserID() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID:"")
        expect(Purchases.shared).toEventually(equal(purchases))
    }
    
    func testSharedInstanceIsSetWhenConfiguringWithAppUserIDAndUserDefaults() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "", userDefaults: nil)
        expect(Purchases.shared).toEventually(equal(purchases))
    }
    
    func testCreateAliasWithCompletionCallsBackend() {
        setupPurchases()

        var completionCalled = false
        self.backend.aliasError = nil
        self.purchases?.createAlias("cesarpedro") { (info, error) in
            completionCalled = error == nil
        }
        
        expect(completionCalled).toEventually(beTrue())
        
        self.backend.aliasError = NSError(domain: "error_domain", code: RCFinishableError, userInfo: nil)
        
        self.purchases?.createAlias("cesarpedro") { (info, error) in
            completionCalled = error == nil
        }
        
        expect(completionCalled).toEventually(beFalse())
    }
    
    func testCreateAliasCallsBackend() {
        setupPurchases()
        self.backend.aliasCalled = false
        self.purchases?.createAlias("cesarpedro")
        
        expect(self.backend.aliasCalled).toEventually(beTrue())
    }
    
    func testIdentify() {
        setupPurchases()
        
        let newAppUserID = "cesarPedro"
        self.purchases?.identify(newAppUserID)
        identifiedSuccesfully(appUserID: newAppUserID)
        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(2))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }

    func testCreateAliasIdentifies() {
        setupPurchases()
        self.backend.aliasError = nil
        
        let newAppUserID = "cesarPedro"
        self.purchases?.createAlias(newAppUserID) { (info, error) in
            self.identifiedSuccesfully(appUserID: newAppUserID)
        }
    }
    
    func testInitCallsIdentifies() {
        setupPurchases()
        self.identifiedSuccesfully(appUserID: appUserID)
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testResetCreatesRandomIDAndCachesIt() {
        setupPurchases()
        self.purchases?.reset()
        expect(self.userDefaults.appUserID).toNot(beNil())
    }
    
    func testResetGetsNewAppUserID() {
        setupPurchases()
        var info: PurchaserInfo?
        
        self.purchases?.reset() { (newInfo, error) in
            info = newInfo
        }
        
        expect(info).toEventuallyNot(beNil())
    }
    
    func testIdentifyForcesCache() {
        setupPurchases()
        self.purchases?.identify("new")
        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(2))
        let purchaserInfo = userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo.new"]
        expect(purchaserInfo).toNot(beNil())
        
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testResetForcesCache() {
        setupPurchases()
        self.purchases?.reset()
        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(2))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testCreateAliasChangesAppUserId() {
        setupPurchases()
        
        self.backend.aliasCalled = false
        self.backend.aliasError = nil
        self.purchases?.createAlias("cesarpedro")
        
        expect(self.backend.userID).to(be("cesarpedro"))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testCreateAliasWithCompletionChangesAppUserId() {
        setupPurchases()
        
        self.backend.aliasCalled = false
        self.backend.aliasError = nil
        self.purchases?.createAlias("cesarpedro")
        
        expect(self.backend.userID).to(be("cesarpedro"))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    private func identifiedSuccesfully(appUserID: String) {
        expect(self.userDefaults.cachedUserInfo[self.userDefaults.appUserIDKey]).to(beNil())
        expect(self.purchases?.appUserID).to(equal(appUserID))
        expect(self.purchases?.allowSharingAppStoreAccount).to(beFalse())
    }
    
}
