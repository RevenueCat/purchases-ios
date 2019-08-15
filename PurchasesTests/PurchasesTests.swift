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

@available(iOS 12.2, *)
class MockProductDiscount: SKProductDiscount {
    
    var mockIdentifier: String
    
    init(mockIdentifier: String) {
        self.mockIdentifier = mockIdentifier
        super.init()
    }
    
    override var price: NSDecimalNumber {
        return 2.99 as NSDecimalNumber
    }
    
    override var priceLocale: Locale {
        return Locale.current
    }
    
    override var identifier: String {
        return self.mockIdentifier
    }
    
    override var subscriptionPeriod: SKProductSubscriptionPeriod {
        return SKProductSubscriptionPeriod()
    }
    
    override var numberOfPeriods: Int {
        return 2
    }
    
    override var paymentMode: SKProductDiscount.PaymentMode {
        return SKProductDiscount.PaymentMode.freeTrial;
    }

}

class PurchasesTests: XCTestCase {

    override func tearDown() {
        purchases?.delegate = nil
        purchases = nil
        Purchases.setDefaultInstance(nil)
    }
    
    class MockReceiptFetcher: RCReceiptFetcher {
        var receiptDataCalled = false
        var shouldReturnReceipt = true
        var receiptDataTimesCalled = 0

        override func receiptData() -> Data? {
            receiptDataCalled = true
            receiptDataTimesCalled += 1
            if (shouldReturnReceipt) {
                return Data(1...3)
            } else {
                return nil
            }
        }

    }

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
                p.mockDiscountIdentifier = "discount_id"
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
        var overridePurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        
        override func getSubscriberData(withAppUserID appUserID: String, completion: @escaping RCBackendPurchaserInfoResponseHandler) {
            getSubscriberCallCount += 1
            userID = appUserID
            
            if (!timeout) {
                let info = self.overridePurchaserInfo!
                DispatchQueue.main.async {
                    completion(info, nil)
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
        var postedDiscounts: Array<RCPromotionalOffer>?
        
        var postReceiptPurchaserInfo: PurchaserInfo?
        var postReceiptError: Error?
        var aliasError: Error?
        var aliasCalled = false
        
        override func postReceiptData(_ data: Data, appUserID: String, isRestore: Bool, productIdentifier: String?, price: NSDecimalNumber?, paymentMode: RCPaymentMode, introductoryPrice: NSDecimalNumber?, currencyCode: String?, subscriptionGroup: String?, discounts: Array<RCPromotionalOffer>?, completion: @escaping RCBackendPurchaserInfoResponseHandler) {
            postReceiptDataCalled = true
            postedIsRestore = isRestore

            postedProductID  = productIdentifier
            postedPrice = price

            postedPaymentMode = paymentMode
            postedIntroPrice = introductoryPrice
            postedSubscriptionGroup = subscriptionGroup

            postedCurrencyCode = currencyCode
            postedDiscounts = discounts

            completion(postReceiptPurchaserInfo, postReceiptError)
        }

        var postedProductIdentifiers: [String]?
        override func getIntroEligibility(forAppUserID appUserID: String, receiptData: Data?, productIdentifiers: [String], completion: @escaping RCIntroEligibilityResponseHandler) {
            postedProductIdentifiers = productIdentifiers

            var eligibilities = [String: RCIntroEligibility]()
            for productID in productIdentifiers {
                eligibilities[productID] = RCIntroEligibility(eligibilityStatus: RCIntroEligibilityStatus.eligible)
            }

            completion(eligibilities)
        }

        var failEntitlements = false
        var gotEntitlements = 0
        override func getEntitlementsForAppUserID(_ appUserID: String, completion: @escaping RCEntitlementResponseHandler) {
            gotEntitlements += 1
            if (failEntitlements) {
                completion(nil, PurchasesErrorUtils.unexpectedBackendResponseError())
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

        var postedAttributionData: [RCAttributionData]?
        override func postAttributionData(_ data: [AnyHashable : Any], from network: RCAttributionNetwork, forAppUserID appUserID: String, completion: ((Error?) -> Void)? = nil) {
            if (postedAttributionData == nil) {
                postedAttributionData = []
            }
            postedAttributionData?.append(RCAttributionData(data: data, from: network, forNetworkUserId: appUserID)!)
            completion!(nil)
        }

        var postOfferForSigningCalled = false
        var postOfferForSigningPaymentDiscountResponse: [String: Any] = [:]
        var postOfferForSigningError: Error?
        override func postOffer(forSigning offerIdentifier: String, withProductIdentifier productIdentifier: String, subscriptionGroup: String, receiptData: Data, appUserID applicationUsername: String, completion: @escaping RCOfferSigningResponseHandler) {
            postOfferForSigningCalled = true
            completion(postOfferForSigningPaymentDiscountResponse["signature"] as? String, postOfferForSigningPaymentDiscountResponse["keyIdentifier"] as? String, postOfferForSigningPaymentDiscountResponse["nonce"] as? UUID,  postOfferForSigningPaymentDiscountResponse["timestamp"] as? NSNumber, postOfferForSigningError)
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
    
    class MockAttributionFetcher: RCAttributionFetcher {
        var receiptDataCalled = false
        var shouldReturnReceipt = true
        var receiptDataTimesCalled = 0
        
        override func advertisingIdentifier() -> String? {
            return "rc_idfa"
        }
        
        override func identifierForVendor() -> String? {
            return "rc_idfv"
        }
        
        override func adClientAttributionDetails(completionBlock completionHandler: @escaping ([String : NSObject]?, Error?) -> Void) {
            completionHandler(["Version3.1": ["iad-campaign-id": 15292426, "iad-attribution": true] as NSObject], nil)
        }
    
    }

    class Delegate: NSObject, PurchasesDelegate {
        var purchaserInfo: PurchaserInfo?
        var purchaserInfoReceivedCount = 0
        func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: PurchaserInfo) {
            purchaserInfoReceivedCount += 1
            self.purchaserInfo = purchaserInfo
        }
        
        var promoProduct: SKProduct?
        var makeDeferredPurchase: RCDeferredPromotionalPurchaseBlock?
        func purchases(_ purchases: Purchases, shouldPurchasePromoProduct product: SKProduct, defermentBlock makeDeferredPurchase: @escaping RCDeferredPromotionalPurchaseBlock) {
            promoProduct = product
            self.makeDeferredPurchase = makeDeferredPurchase
        }
    }

    let receiptFetcher = MockReceiptFetcher()
    let requestFetcher = MockRequestFetcher()
    let backend = MockBackend()
    let storeKitWrapper = MockStoreKitWrapper()
    let notificationCenter = MockNotificationCenter();
    let userDefaults = MockUserDefaults();
    let attributionFetcher = MockAttributionFetcher();

    let purchasesDelegate = Delegate()
    
    let appUserID = "app_user"

    var purchases: Purchases?
    
    func setupPurchases(automaticCollection: Bool = false) {
        Purchases.automaticAppleSearchAdsAttributionCollection = automaticCollection
        purchases = Purchases(appUserID: appUserID,
                                requestFetcher: requestFetcher,
                                receiptFetcher: receiptFetcher,
                                attributionFetcher: attributionFetcher,
                                backend:backend,
                                storeKitWrapper: storeKitWrapper,
                                notificationCenter:notificationCenter,
                                userDefaults:userDefaults,
                                observerMode: false)
        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }

    func setupAnonPurchases() {
        Purchases.automaticAppleSearchAdsAttributionCollection = false

        purchases = Purchases(appUserID: nil,
                requestFetcher: requestFetcher,
                receiptFetcher: receiptFetcher,
                attributionFetcher: attributionFetcher,
                backend: backend,
                storeKitWrapper: storeKitWrapper,
                notificationCenter: notificationCenter,
                userDefaults: userDefaults,
                observerMode: false)

        purchases!.delegate = purchasesDelegate
    }

    func setupPurchasesObserverModeOn() {
        purchases = Purchases(appUserID: nil,
                requestFetcher: requestFetcher,
                receiptFetcher: receiptFetcher,
                attributionFetcher: attributionFetcher,
                backend: backend,
                storeKitWrapper: storeKitWrapper,
                notificationCenter: notificationCenter,
                userDefaults: userDefaults,
                observerMode: true)

        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }
    
    func testIsAbleToBeInitialized() {
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
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
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
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
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
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(3))
    }
    
    func testDelegateIsNotCalledIfBlockPassed() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }
        
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedIsRestore).to(beFalse())
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
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        expect(self.storeKitWrapper.payment).toNot(beNil())
        expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
    }

    func testTransitioningToPurchasing() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beFalse())
    }

    func testTransitioningToPurchasedSendsToBackend() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedIsRestore).to(beFalse())
    }

    func testReceiptsSendsAsRestoreWhenAnon() {
        setupAnonPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedIsRestore).to(beTrue())
    }

    func testFinishesTransactionsIfSentToBackendCorrectly() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testDoesntFinishTransactionsIfFinishingDisabled() {
        setupPurchases()
        self.purchases?.finishTransactions = false
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }
    

    func testSendsProductInfoIfProductIsCached() {
        setupPurchases()
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.products(productIdentifiers) { (newProducts) in
            let product = newProducts[0];
            self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
                
            }
            
            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!
            
            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            self.backend.postReceiptPurchaserInfo = PurchaserInfo()
            
            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            expect(self.backend.postReceiptDataCalled).to(beTrue())
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

            if #available(iOS 12.2, *) {
                expect(self.backend.postedDiscounts?.count).to(equal(1))
                expect(self.backend.postedDiscounts?[0].offerIdentifier).to(equal("discount_id"))
                expect(self.backend.postedDiscounts?[0].price).to(equal(2.99))
                expect(self.backend.postedDiscounts?[0].paymentMode).to(equal(RCPaymentMode.freeTrial))
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
        
        expect(self.requestFetcher.requestedProducts! as NSSet).to(contain([product.productIdentifier]))
        
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
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        self.backend.postReceiptError = PurchasesErrorUtils.backendError(withBackendCode: RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: false)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testAfterSendingFinishesFromBackendErrorIfAppropriate() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = PurchasesErrorUtils.backendError(withBackendCode: RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: true)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testNotifiesIfTransactionFailsFromBackend() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = PurchasesErrorUtils.backendError(withBackendCode: PurchasesErrorCode.invalidCredentialsError.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: false)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testNotifiesIfTransactionFailsFromStoreKit() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedError: Error?
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            receivedError = error
        }

        let transaction = MockTransaction()
        transaction.mockError = NSError.init(domain: SKErrorDomain, code: 2, userInfo: nil)
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = BackendError.unknown

        transaction.mockState = SKPaymentTransactionState.failed
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beFalse())
        expect(self.storeKitWrapper.finishCalled).to(beTrue())
        expect(receivedError).toEventuallyNot(beNil())
    }

    func testCallsDelegateAfterBackendResponse() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        
        var purchaserInfo: PurchaserInfo?
        var receivedError: Error?
        var receivedUserCancelled: Bool?
        
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            purchaserInfo = info
            receivedError = error
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptPurchaserInfo = PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(purchaserInfo).toEventually(be(self.backend.postReceiptPurchaserInfo))
        expect(receivedError).toEventually(beNil())
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).to(equal(2))
        expect(receivedUserCancelled).toEventually(beFalse())
    }
    
    func testCompletionBlockOnlyCalledOnce() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        
        var callCount = 0
        
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
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
        
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
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
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in }
        
        var receivedInfo: PurchaserInfo?
        var receivedError: NSError?
        var receivedUserCancelled: Bool?
        
        // Second one issues an error
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            receivedInfo = info
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }
        
        expect(receivedInfo).toEventually(beNil())
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(PurchasesErrorDomain))
        expect(receivedError?.code).toEventually(equal(PurchasesErrorCode.operationAlreadyInProgressError.rawValue))
        expect(self.storeKitWrapper.addPaymentCallCount).to(equal(1))
        expect(receivedUserCancelled).toEventually(beFalse())
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

        expect(self.backend.postReceiptDataCalled).to(beTrue())
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
        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testRestoringPurchasesAlwaysRefreshesAndPostsTheReceipt() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = true
        purchases!.restoreTransactions()

        expect(self.receiptFetcher.receiptDataTimesCalled).to(equal(1))
        expect(self.requestFetcher.refreshReceiptCalled).to(beFalse())
    }

    func testRestoringPurchasesSetsIsRestore() {
        setupPurchases()
        purchases!.restoreTransactions(nil)
        expect(self.backend.postedIsRestore!).to(beTrue())
    }

    func testRestoringPurchasesSetsIsRestoreForAnon() {
        setupAnonPurchases()
        purchases!.restoreTransactions(nil)

        expect(self.backend.postedIsRestore!).to(beTrue())
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
        
        let error = PurchasesErrorUtils.backendError(withBackendCode: RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable:true)
        
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
    
    func testShouldAddPromoPaymentDelegateMethodReturnsFalse() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init()
        
        let result = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper, shouldAddStore: payment, for: product)
        
        expect(result).to(beFalse())
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
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedProductID).to(equal(product.productIdentifier))
        expect(self.backend.postedPrice).to(equal(product.price))
    }
    
    func testDeferBlockMakesPayment() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)
        
        storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper, shouldAddStore: payment, for: product)
        
        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        
        expect(self.storeKitWrapper.payment).to(beNil())
        
        self.purchasesDelegate.makeDeferredPurchase! { (_, _, _, _) in
            
        }
        
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

        expect(self.receiptFetcher.receiptDataCalled).to(beTrue())
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
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())

        expect(self.userDefaults.cachedUserInfoCount).toEventually(equal(2))
    }

    func testCachedPurchaserInfoHasSchemaVersion() {
        let info = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let jsonObject = info!.jsonObject()
        
        let object = try! JSONSerialization.data(withJSONObject: jsonObject , options:[]);
        self.userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo." + appUserID] = object
        self.backend.timeout = true
        
        setupPurchases()
        
        var receivedInfo: PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }
        
        expect(receivedInfo).toNot(beNil())
        expect(receivedInfo?.schemaVersion).toNot(beNil())
    }
    
    func testCachedPurchaserInfoHandlesNullSchema() {
        let info = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        
        var jsonObject = info!.jsonObject()
        
        jsonObject["schema_version"] = NSNull()
        
        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options:[]);
        self.userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo." + appUserID] = object
        self.backend.timeout = true
        
        setupPurchases()
        
        var receivedInfo: PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }
        
        expect(receivedInfo).to(beNil())
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
    
    func testDoesntSendsCachedPurchaserInfoToGetterIfSchemaVersionDiffers() {
        let info = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        var jsonObject = info!.jsonObject()
        jsonObject["schema_version"] = "bad_version"
        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options:[]);
        
        self.userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo." + appUserID] = object
        self.backend.timeout = true
        
        setupPurchases()
        
        var receivedInfo: PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }
        
        expect(receivedInfo).to(beNil())
    }
    
    func testDoesntSendsCachedPurchaserInfoToGetterIfNoSchemaVersionInCached() {
        let info = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        var jsonObject = info!.jsonObject()
        jsonObject.removeValue(forKey: "schema_version")
        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options:[]);
        
        self.userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo." + appUserID] = object
        self.backend.timeout = true
        
        setupPurchases()
        
        var receivedInfo: PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }
        
        expect(receivedInfo).to(beNil())
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
            self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
                
            }
            
            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!
            
            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            self.backend.postReceiptPurchaserInfo = PurchaserInfo()
            
            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            expect(self.backend.postReceiptDataCalled).to(beTrue())
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

    func testAddAttributionAlwaysAddsAdIdsEmptyDict() {
        setupPurchases()

        Purchases.addAttributionData([:], from: RCAttributionNetwork.adjust)

        expect(self.backend.postedAttributionData?[0].data.count).toEventually(equal(2))
        expect(self.backend.postedAttributionData?[0].data["rc_idfa"] as? String).toEventually(equal("rc_idfa"))
        expect(self.backend.postedAttributionData?[0].data["rc_idfv"] as? String).toEventually(equal("rc_idfv"))
    }

    func testPassesTheArrayForAllNetworks() {
        setupPurchases()
        let data = ["yo" : "dog", "what" : 45, "is" : ["up"]] as [AnyHashable : Any]

        Purchases.addAttributionData(data, from: RCAttributionNetwork.appleSearchAds)

        for key in data.keys {
            expect(self.backend.postedAttributionData?[0].data.keys.contains(key)).toEventually(beTrue())
        }
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfa")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfv")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].network).toEventually(equal(RCAttributionNetwork.appleSearchAds))
        expect(self.backend.postedAttributionData?[0].networkUserId).toEventually(equal(self.purchases?.appUserID))
    }

    func testSharedInstanceIsSetWhenConfiguring() {
        let purchases = Purchases.configure(withAPIKey: "")
        expect(Purchases.shared).toEventually(equal(purchases))
    }
    
    func testSharedInstanceIsSetWhenConfiguringWithAppUserID() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID:"")
        expect(Purchases.shared).toEventually(equal(purchases))
    }
    
    func testSharedInstanceIsSetWhenConfiguringWithObserverMode() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true)
        expect(Purchases.shared).toEventually(equal(purchases))
        expect(Purchases.shared.finishTransactions).toEventually(beFalse())
    }
    
    
    func testSharedInstanceIsSetWhenConfiguringWithAppUserIDAndUserDefaults() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "", observerMode: false, userDefaults: nil)
        expect(Purchases.shared).toEventually(equal(purchases))
        expect(Purchases.shared.finishTransactions).toEventually(beTrue())
    }
    
    func testCreateAliasWithCompletionCallsBackend() {
        setupPurchases()

        var completionCalled = false
        self.backend.aliasError = nil
        self.purchases?.createAlias("cesarpedro") { (info, error) in
            completionCalled = error == nil
        }
        
        expect(completionCalled).toEventually(beTrue())
        
        self.backend.aliasError = PurchasesErrorUtils.backendError(withBackendCode: RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable:true)
        
        self.purchases?.createAlias("cesardro") { (info, error) in
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
        
        self.backend.overridePurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])
        
        let newAppUserID = "cesarPedro"
        
        self.purchases?.identify(newAppUserID)
        expect(self.userDefaults.cachedUserInfo[self.userDefaults.appUserIDKey]).to(beNil())
        expect(self.purchases?.appUserID).to(equal(newAppUserID))
        expect(self.purchases?.allowSharingAppStoreAccount).to(beFalse())
        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(2))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }

    func testCreateAliasIdentifies() {
        setupPurchases()
        self.backend.aliasError = nil
        
        let newAppUserID = "cesarPedro"
        
        var receivedInfo: PurchaserInfo?
        self.purchases?.createAlias(newAppUserID) { (info, error) in
            receivedInfo = info
        }
        expect(receivedInfo).toEventuallyNot(beNil())
        expect(self.userDefaults.cachedUserInfo[self.userDefaults.appUserIDKey]).to(beNil())
        expect(self.purchases?.appUserID).to(equal(newAppUserID))
        expect(self.purchases?.allowSharingAppStoreAccount).to(beFalse())
    }
    
    func testInitCallsIdentifies() {
        setupPurchases()
        expect(self.userDefaults.cachedUserInfo[self.userDefaults.appUserIDKey]).to(beNil())
        expect(self.purchases?.appUserID).to(equal(self.appUserID))
        expect(self.purchases?.allowSharingAppStoreAccount).to(beFalse())
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1))
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
        
        self.backend.overridePurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])
        
        self.purchases?.identify("new")
        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(2))
        let purchaserInfo = userDefaults.cachedUserInfo["com.revenuecat.userdefaults.purchaserInfo.new"]
        expect(purchaserInfo).toNot(beNil())
        
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testResetForcesCache() {
        setupPurchases()
        
        self.backend.overridePurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])
        
        self.purchases?.reset()
        expect(self.userDefaults.cachedUserInfo.count).toEventually(equal(2))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testCreateAliasChangesAppUserId() {
        setupPurchases()
        
        self.backend.aliasCalled = false
        self.backend.aliasError = nil
        self.backend.overridePurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])
        self.purchases?.createAlias("cesarpedro")
        
        expect(self.backend.userID).to(be("cesarpedro"))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }
    
    func testCreateAliasWithCompletionChangesAppUserId() {
        setupPurchases()
        
        self.backend.aliasCalled = false
        self.backend.aliasError = nil
        self.backend.overridePurchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])
        
        self.purchases?.createAlias("cesarpedro")
        
        expect(self.backend.userID).to(be("cesarpedro"))
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
    }

    func testCreateAliasForTheSameUserID() {
        setupPurchases()

        self.backend.aliasCalled = false
        self.backend.aliasError = nil

        var completionCalled = false
        self.purchases?.createAlias(appUserID) { (info, error) in
            completionCalled = true
        }

        expect(self.backend.aliasCalled).to(be(false))
        expect(self.backend.aliasError).to(beNil())
        expect(completionCalled).toEventually(be(true))
    }

    func testIdentifyForTheSameUserID() {
        setupPurchases()

        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1));
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1));

        self.purchases?.identify(appUserID)

        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1));
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1));
    }

    func testWhenNoReceiptDataReceiptIsRefreshed() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false
        self.purchases?.restoreTransactions()
        expect(self.requestFetcher.refreshReceiptCalled).to(beTrue())
    }

    func testRestoresDontPostMissingReceipts() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false
        var receivedError: NSError?
        self.purchases?.restoreTransactions() { (info, error) in
            receivedError = error as NSError?
        }

        expect(receivedError?.code).toEventually(be(PurchasesErrorCode.missingReceiptFileError.rawValue))
    }

    func testUserCancelledFalseIfPurchaseSuccessful() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?

        // Second one issues an error
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beFalse())
    }

    func testUserCancelledTrueIfPurchaseCancelled() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.failed
        transaction.mockError = NSError.init(domain: SKErrorDomain, code: SKError.Code.paymentCancelled.rawValue)
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beTrue())
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(be(PurchasesErrorDomain))
        expect(receivedError?.code).toEventually(be(PurchasesErrorCode.purchaseCancelledError.rawValue))
        expect(receivedUnderlyingError?.domain).toEventually(be(SKErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(SKError.Code.paymentCancelled.rawValue))
    }

    func testDoNotSendEmptyReceiptWhenMakingPurchase() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false

        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?
        var receivedError: NSError?

        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beFalse())
        expect(receivedError?.code).toEventually(be(PurchasesErrorCode.missingReceiptFileError.rawValue))
        expect(self.backend.postReceiptDataCalled).toEventually(beFalse())
    }
    
    func testDeferBlockCallsCompletionBlockAfterPurchaseCompletes() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)
        
        storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper, shouldAddStore: payment, for: product)
        
        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())
        
        expect(self.storeKitWrapper.payment).to(beNil())

        var completionCalled = false
        self.purchasesDelegate.makeDeferredPurchase! { (tx, info, error, userCancelled) in
            completionCalled = true
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.storeKitWrapper.payment).to(be(payment))
        expect(completionCalled).toEventually(beTrue())
    }
    
    func testAddsDiscountToWrapper() {
        if #available(iOS 12.2, *) {
            setupPurchases()
            let product = MockProduct(mockProductIdentifier: "com.product.id1")
            let discount = SKPaymentDiscount.init(identifier: "discount", keyIdentifier: "TIKAMASALA1", nonce: UUID(), signature: "Base64 encoded signature", timestamp: 123413232131)
            
            self.purchases?.makePurchase(product, discount: discount) { (tx, info, error, userCancelled) in
                
            }
            
            expect(self.storeKitWrapper.payment).toNot(beNil())
            expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
            expect(self.storeKitWrapper.payment?.paymentDiscount).to(equal(discount))
        }
    }

    func testPaymentDiscountForProductDiscountCreatesDiscount() {
        if #available(iOS 12.2, *) {
            setupPurchases()
            let product = MockProduct(mockProductIdentifier: "com.product.id1")
            
            let discountIdentifier = "id"
            let signature = "firma"
            let keyIdentifier = "key_id"
            let nonce = UUID()
            let timestamp = 1234
            let productDiscount = MockProductDiscount(mockIdentifier: discountIdentifier)
            self.backend.postOfferForSigningPaymentDiscountResponse["signature"] = signature
            self.backend.postOfferForSigningPaymentDiscountResponse["keyIdentifier"] = keyIdentifier
            self.backend.postOfferForSigningPaymentDiscountResponse["nonce"] = nonce
            self.backend.postOfferForSigningPaymentDiscountResponse["timestamp"] = timestamp
            
            var completionCalled = false
            var receivedPaymentDiscount: SKPaymentDiscount?
            self.purchases?.paymentDiscount(for: productDiscount, product: product, completion: { (paymentDiscount, error) in
                receivedPaymentDiscount = paymentDiscount
                completionCalled = true
            })
            
            expect(self.receiptFetcher.receiptDataTimesCalled).toEventually(equal(1))
            expect(self.backend.postOfferForSigningCalled).toEventually(beTrue())
            expect(completionCalled).toEventually(beTrue())
            expect(receivedPaymentDiscount?.identifier).toEventually(equal(discountIdentifier))
            expect(receivedPaymentDiscount?.signature).toEventually(equal(signature))
            expect(receivedPaymentDiscount?.keyIdentifier).toEventually(equal(keyIdentifier))
            expect(receivedPaymentDiscount?.nonce).toEventually(equal(nonce))
            expect(receivedPaymentDiscount?.timestamp).toEventually(be(timestamp))

        }
    }

	func testAttributionDataIsPostponedIfThereIsNoInstance() {
        let data = ["yo" : "dog", "what" : 45, "is" : ["up"]] as [AnyHashable : Any]
        
        Purchases.addAttributionData(data, from: RCAttributionNetwork.appsFlyer)
        
        setupPurchases()

        expect(self.backend.postedAttributionData).toEventuallyNot(beNil())

        for key in data.keys {
            expect(self.backend.postedAttributionData?[0].data.keys.contains(key)).toEventually(beTrue())
        }
        
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfa")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfv")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].network).toEventually(equal(RCAttributionNetwork.appsFlyer))
        expect(self.backend.postedAttributionData?[0].networkUserId).toEventually(equal(self.purchases?.appUserID))
    }
    
    func testAttributionDataSendsNetworkAppUserId() {
        let data = ["yo" : "dog", "what" : 45, "is" : ["up"]] as [AnyHashable : Any]
        
        Purchases.addAttributionData(data, from: RCAttributionNetwork.appleSearchAds, forNetworkUserId: "newuser")

        setupPurchases()
        
        for key in data.keys {
            expect(self.backend.postedAttributionData?[0].data.keys.contains(key)).toEventually(beTrue())
        }
        
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfa")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfv")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_attribution_network_id")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data["rc_attribution_network_id"] as? String).toEventually(equal("newuser"))
        expect(self.backend.postedAttributionData?[0].network).toEventually(equal(RCAttributionNetwork.appleSearchAds))
        expect(self.backend.postedAttributionData?[0].networkUserId).toEventually(equal(self.appUserID))
    }
    
    func testAttributionDataDontSendNetworkAppUserIdIfNotProvided() {
        let data = ["yo" : "dog", "what" : 45, "is" : ["up"]] as [AnyHashable : Any]
        
        Purchases.addAttributionData(data, from: RCAttributionNetwork.appleSearchAds)
        
        setupPurchases()
        
        for key in data.keys {
            expect(self.backend.postedAttributionData?[0].data.keys.contains(key)).toEventually(beTrue())
        }
        
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfa")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfv")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_attribution_network_id")).toEventually(beFalse())
        expect(self.backend.postedAttributionData?[0].network).toEventually(equal(RCAttributionNetwork.appleSearchAds))
        expect(self.backend.postedAttributionData?[0].networkUserId).toEventually(equal(self.appUserID))
    }
    
    func testAdClientAttributionDataIsAutomaticallyCollected() {
        setupPurchases(automaticCollection: true)
        expect(self.backend.postedAttributionData).toEventuallyNot(beNil())
        expect(self.backend.postedAttributionData?[0].network).toEventually(equal(RCAttributionNetwork.appleSearchAds))
        expect((self.backend.postedAttributionData?[0].data["Version3.1"] as! NSDictionary)["iad-campaign-id"]).toEventuallyNot(beNil())
    }

    func testAdClientAttributionDataIsNotAutomaticallyCollectedIfDisabled() {
        setupPurchases(automaticCollection: false)
        expect(self.backend.postedAttributionData).toEventually(beNil())
    }
    
    func testAttributionDataPostponesMultiple() {
        let data = ["yo" : "dog", "what" : 45, "is" : ["up"]] as [AnyHashable : Any]
        
        Purchases.addAttributionData(data, from: RCAttributionNetwork.appleSearchAds, forNetworkUserId: "newuser")

        setupPurchases(automaticCollection: true)
        expect(self.backend.postedAttributionData).toEventuallyNot(beNil())
        expect(self.backend.postedAttributionData?.count).toEventually(equal(2))
    }
    
    func testObserverModeSetToFalseSetFinishTransactions() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }
        
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        self.backend.postReceiptPurchaserInfo = PurchaserInfo()
        
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }
    
    func testDoesntFinishTransactionsIfObserverModeIsSet() {
        setupPurchasesObserverModeOn()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }
        
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        self.backend.postReceiptPurchaserInfo = PurchaserInfo()
        
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }
    
    func testRestoredPurchasesArePosted() {
        setupPurchasesObserverModeOn()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.makePurchase(product) { (tx, info, error, userCancelled) in
            
        }
        
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        transaction.mockState = SKPaymentTransactionState.restored
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }
    
    private func identifiedSuccessfully(appUserID: String) {
        expect(self.userDefaults.cachedUserInfo[self.userDefaults.appUserIDKey]).to(beNil())
        expect(self.purchases?.appUserID).to(equal(appUserID))
        expect(self.purchases?.allowSharingAppStoreAccount).to(beFalse())        
    }

}
