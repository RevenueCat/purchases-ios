//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

import Purchases

class PurchasesTests: XCTestCase {

    override func setUp() {
        self.userDefaults = UserDefaults(suiteName: "TestDefaults")
    }

    override func tearDown() {
        purchases?.delegate = nil
        purchases = nil
        Purchases.setDefaultInstance(nil)
        UserDefaults().removePersistentDomain(forName: "TestDefaults")
    }

    class MockBackend: RCBackend {
        var userID: String?
        var originalApplicationVersion: String?
        var originalPurchaseDate: Date?
        var timeout = false
        var getSubscriberCallCount = 0
        var overridePurchaserInfo = Purchases.PurchaserInfo(data: [
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
        var postedOfferingIdentifier: String?
        var postedObserverMode: Bool?

        var postReceiptPurchaserInfo: Purchases.PurchaserInfo?
        var postReceiptError: Error?
        var aliasError: Error?
        var aliasCalled = false

        override func postReceiptData(_ data: Data,
                                      appUserID: String,
                                      isRestore: Bool,
                                      productIdentifier: String?,
                                      price: NSDecimalNumber?,
                                      paymentMode: RCPaymentMode,
                                      introductoryPrice: NSDecimalNumber?,
                                      currencyCode: String?,
                                      subscriptionGroup: String?,
                                      discounts: Array<RCPromotionalOffer>?,
                                      presentedOfferingIdentifier: String?,
                                      observerMode: Bool,
                                      subscriberAttributes: [String: RCSubscriberAttribute]?,
                                      completion: @escaping RCBackendPurchaserInfoResponseHandler) {
            postReceiptDataCalled = true
            postedIsRestore = isRestore

            postedProductID = productIdentifier
            postedPrice = price

            postedPaymentMode = paymentMode
            postedIntroPrice = introductoryPrice
            postedSubscriptionGroup = subscriptionGroup

            postedCurrencyCode = currencyCode
            postedDiscounts = discounts
            postedOfferingIdentifier = presentedOfferingIdentifier
            postedObserverMode = observerMode
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

        var failOfferings = false
        var badOfferingsResponse = false
        var gotOfferings = 0

        override func getOfferingsForAppUserID(_ appUserID: String, completion: @escaping RCOfferingsResponseHandler) {
            gotOfferings += 1
            if (failOfferings) {
                completion(nil, Purchases.ErrorUtils.unexpectedBackendResponseError())
                return
            }
            if (badOfferingsResponse) {
                completion([:], nil)
                return
            }

            let offeringsData = [
                "offerings": [
                    [
                        "identifier": "base",
                        "description": "This is the base offering",
                        "packages": [
                            ["identifier": "$rc_monthly",
                             "platform_product_identifier": "monthly_freetrial"]
                        ]
                    ]
                ],
                "current_offering_id": "base"
            ] as [String: Any]

            completion(offeringsData, nil)
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

        override func postAttributionData(_ data: [AnyHashable: Any], from network: RCAttributionNetwork, forAppUserID appUserID: String, completion: ((Error?) -> Void)? = nil) {
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
            completion(postOfferForSigningPaymentDiscountResponse["signature"] as? String, postOfferForSigningPaymentDiscountResponse["keyIdentifier"] as? String, postOfferForSigningPaymentDiscountResponse["nonce"] as? UUID, postOfferForSigningPaymentDiscountResponse["timestamp"] as? NSNumber, postOfferForSigningError)
        }
    }


    let receiptFetcher = MockReceiptFetcher()
    let requestFetcher = MockRequestFetcher()
    let backend = MockBackend()
    let storeKitWrapper = MockStoreKitWrapper()
    let notificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let attributionFetcher = MockAttributionFetcher()
    let offeringsFactory = MockOfferingsFactory()
    let deviceCache = MockDeviceCache()
    let subscriberAttributesManager = MockSubscriberAttributesManager()
    let identityManager = MockUserManager(mockAppUserID: "app_user");

    let purchasesDelegate = MockPurchasesDelegate()

    var purchases: Purchases!

    func setupPurchases(automaticCollection: Bool = false) {
        Purchases.automaticAppleSearchAdsAttributionCollection = automaticCollection
        self.identityManager.mockIsAnonymous = false
        purchases = Purchases(appUserID: identityManager.currentAppUserID,
                              requestFetcher: requestFetcher,
                              receiptFetcher: receiptFetcher,
                              attributionFetcher: attributionFetcher,
                              backend: backend,
                              storeKitWrapper: storeKitWrapper,
                              notificationCenter: notificationCenter,
                              userDefaults: userDefaults,
                              observerMode: false,
                              offeringsFactory: offeringsFactory,
                              deviceCache: deviceCache,
                              identityManager: identityManager,
                              subscriberAttributesManager: subscriberAttributesManager)
        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }

    func setupAnonPurchases() {
        Purchases.automaticAppleSearchAdsAttributionCollection = false
        self.identityManager.mockIsAnonymous = true
        purchases = Purchases(appUserID: nil,
                              requestFetcher: requestFetcher,
                              receiptFetcher: receiptFetcher,
                              attributionFetcher: attributionFetcher,
                              backend: backend,
                              storeKitWrapper: storeKitWrapper,
                              notificationCenter: notificationCenter,
                              userDefaults: userDefaults,
                              observerMode: false,
                              offeringsFactory: offeringsFactory,
                              deviceCache: deviceCache,
                              identityManager: identityManager,
                              subscriberAttributesManager: subscriberAttributesManager)

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
                              observerMode: true,
                              offeringsFactory: offeringsFactory,
                              deviceCache: deviceCache,
                              identityManager: identityManager,
                              subscriberAttributesManager: subscriberAttributesManager)

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
        
        let purchaserInfo = Purchases.PurchaserInfo()
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
        
        let purchaserInfo1 = Purchases.PurchaserInfo(data: [
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
        
        let purchaserInfo1 = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
            ])
        
        let purchaserInfo2 = Purchases.PurchaserInfo(data: [
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
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

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
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        expect(self.storeKitWrapper.payment).toNot(beNil())
        expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
    }

    func testTransitioningToPurchasing() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

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
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

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
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

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

    func testReceiptsSendsAsNotRestoreWhenAnonymousAndNotAllowingSharingAppStoreAccount() {
        setupAnonPurchases()
        self.purchases.allowSharingAppStoreAccount = false
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

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

    func testReceiptsSendsAsRestoreWhenNotAnonymousAndAllowingSharingAppStoreAccount() {
        setupPurchases()
        self.purchases.allowSharingAppStoreAccount = true
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

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
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testDoesntFinishTransactionsIfFinishingDisabled() {
        setupPurchases()
        self.purchases?.finishTransactions = false
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()

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
            self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
            
            self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()
            
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
        
        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()
        
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
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        self.backend.postReceiptError = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: false)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testAfterSendingFinishesFromBackendErrorIfAppropriate() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: true)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testNotifiesIfTransactionFailsFromBackend() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.ErrorCode.invalidCredentialsError.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: false)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testNotifiesIfTransactionFailsFromStoreKit() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedError: Error?
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
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
        
        var purchaserInfo: Purchases.PurchaserInfo?
        var receivedError: Error?
        var receivedUserCancelled: Bool?

        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
            purchaserInfo = info
            receivedError = error
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()

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

        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
            callCount += 1
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        
        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()
        
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

        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
            callCount += 1
        }

        let transaction = MockTransaction()
        transaction.mockPayment = SKPayment.init(product: otherProduct)
        
        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()
        
        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(callCount).toEventually(equal(0))
    }

    func testCallingPurchaseWhileSameProductPendingIssuesError() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")

        // First one "works"
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
        }

        var receivedInfo: Purchases.PurchaserInfo?
        var receivedError: NSError?
        var receivedUserCancelled: Bool?

        // Second one issues an error
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
            receivedInfo = info
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        expect(receivedInfo).toEventually(beNil())
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(Purchases.ErrorDomain))
        expect(receivedError?.code).toEventually(equal(Purchases.ErrorCode.operationAlreadyInProgressError.rawValue))
        expect(self.storeKitWrapper.addPaymentCallCount).to(equal(1))
        expect(receivedUserCancelled).toEventually(beFalse())
    }

    func testDoesntIgnorePurchasesThatDoNotHaveApplicationUserNames() {
        setupPurchases()
        let transaction = MockTransaction()

        let payment = SKMutablePayment()
        payment.productIdentifier = "test"

        expect(payment.applicationUsername).to(beNil())

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
        expect(self.notificationCenter.observers.count).to(equal(3));
        if self.notificationCenter.observers.count > 0 {
            let (_, _, name, _) = self.notificationCenter.observers[0];
            expect(name).to(equal(UIApplication.didBecomeActiveNotification))
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

    func testDoesntRemoveObservationWhenDelegateNil() {
        setupPurchases()
        purchases!.delegate = nil

        expect(self.notificationCenter.observers.count).to(equal(3));
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

        let purchaserInfo = Purchases.PurchaserInfo()
        self.backend.postReceiptPurchaserInfo = purchaserInfo

        var receivedPurchaserInfo: Purchases.PurchaserInfo?

        purchases!.restoreTransactions { (info, error) in
            receivedPurchaserInfo = info
        }

        expect(receivedPurchaserInfo).toEventually(be(purchaserInfo))
    }

    func testRestorePurchasesPassesErrorOnFailure() {
        setupPurchases()
        
        let error = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable:true)
        
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

    func testAnonPurchasesConfiguresAppUserID() {
        setupAnonPurchases()
        expect(self.identityManager.configurationCalled).to(beTrue())
    }

    func testPurchasesSetupConfiguresAppUserID() {
        setupPurchases()
        expect(self.identityManager.configurationCalled).to(beTrue())
    }

    func testGetEligibility() {
        setupPurchases()
        purchases!.checkTrialOrIntroductoryPriceEligibility([]) { (eligibilities) in
        }
    }

    func testGetEligibilitySendsAReceipt() {
        setupPurchases()
        purchases!.checkTrialOrIntroductoryPriceEligibility([]) { (eligibilities) in
        }

        expect(self.receiptFetcher.receiptDataCalled).to(beTrue())
    }

    func testFetchVersionSendsAReceiptIfNoVersion() {
        setupPurchases()

        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]
        ])
        
        var receivedPurchaserInfo: Purchases.PurchaserInfo?

        purchases?.restoreTransactions { (info, error) in
            receivedPurchaserInfo = info
        }

        expect(receivedPurchaserInfo?.originalApplicationVersion).toEventually(equal("1.0"))
        expect(receivedPurchaserInfo?.originalPurchaseDate).toEventually(equal(Date(timeIntervalSinceReferenceDate: 562288673)))
        expect(self.backend.userID).toEventuallyNot(beNil())
        expect(self.backend.postReceiptDataCalled).toEventuallyNot(beFalse())
    }

    func testCachesPurchaserInfo() {
        setupPurchases()

        expect(self.deviceCache.cachedPurchaserInfo.count).toEventually(equal(1))
        expect(self.deviceCache.cachedPurchaserInfo[self.purchases!.appUserID]).toEventuallyNot(beNil())

        let purchaserInfo = self.deviceCache.cachedPurchaserInfo[self.purchases!.appUserID]

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

        expect(self.deviceCache.cachedPurchaserInfo.count).toEventually(equal(1))

        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())

        expect(self.deviceCache.cachePurchaserInfoCount).toEventually(equal(2))
    }

    func testCachedPurchaserInfoHasSchemaVersion() {
        let info = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedPurchaserInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()
        
        var receivedInfo: Purchases.PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).toNot(beNil())
        expect(receivedInfo?.schemaVersion).toNot(beNil())
    }

    func testCachedPurchaserInfoHandlesNullSchema() {
        let info = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        var jsonObject = info!.jsonObject()

        jsonObject["schema_version"] = NSNull()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedPurchaserInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()
        
        var receivedInfo: Purchases.PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).to(beNil())
    }

    func testSendsCachedPurchaserInfoToGetter() {
        let info = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let object = try! JSONSerialization.data(withJSONObject: info!.jsonObject(), options: []);
        self.deviceCache.cachedPurchaserInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()
        
        var receivedInfo: Purchases.PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).toNot(beNil())
    }

    func testPurchaserInfoCompletionBlockCalledExactlyOnceWhenInfoCached() {
        let info = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let object = try! JSONSerialization.data(withJSONObject: info!.jsonObject(), options: []);
        self.deviceCache.cachedPurchaserInfo[identityManager.currentAppUserID] = object
        self.deviceCache.stubbedIsPurchaserInfoCacheStale = true
        self.backend.timeout = false

        setupPurchases()

        var callCount = 0

        purchases!.purchaserInfo { (_, _) in
            callCount += 1
        }

        expect(callCount).toEventually(equal(1))
    }

    func testDoesntSendsCachedPurchaserInfoToGetterIfSchemaVersionDiffers() {
        let info = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        var jsonObject = info!.jsonObject()
        jsonObject["schema_version"] = "bad_version"
        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);

        self.deviceCache.cachedPurchaserInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()
        
        var receivedInfo: Purchases.PurchaserInfo?
        
        purchases!.purchaserInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).to(beNil())
    }

    func testDoesntSendsCachedPurchaserInfoToGetterIfNoSchemaVersionInCached() {
        let info = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        var jsonObject = info!.jsonObject()
        jsonObject.removeValue(forKey: "schema_version")
        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);

        self.deviceCache.cachedPurchaserInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()
        
        var receivedInfo: Purchases.PurchaserInfo?
        
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

    func testGetsProductInfoFromOfferings() {
        setupPurchases()
        expect(self.backend.gotOfferings).toEventually(equal(1))

        var offerings: Purchases.Offerings?
        self.purchases?.offerings { (newOfferings, _) in
            offerings = newOfferings
        }

        expect(offerings).toEventuallyNot(beNil());
        expect(offerings!["base"]).toNot(beNil())
        expect(offerings!["base"]!.monthly).toNot(beNil())
        expect(offerings!["base"]!.monthly?.product).toNot(beNil())
    }

    func testProductInfoIsCachedForOfferings() {
        setupPurchases()
        expect(self.backend.gotOfferings).toEventually(equal(1))
        self.purchases?.offerings { (newOfferings, _) in
            let product = newOfferings!["base"]!.monthly!.product;
            self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()

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

    func testFailBackendOfferingsReturnsNil() {
        self.backend.failOfferings = true
        setupPurchases()

        var offerings: Purchases.Offerings?
        self.purchases?.offerings({ (newOfferings, _) in
            offerings = newOfferings
        })

        expect(offerings).toEventually(beNil());
    }

    func testBadBackendResponseForOfferings() {
        self.backend.badOfferingsResponse = true
        self.offeringsFactory.badOfferings = true
        setupPurchases()

        var receivedError: NSError?
        self.purchases?.offerings({ (_, error) in
            receivedError = error as NSError?
        })

        expect(receivedError).toEventuallyNot(beNil());
        expect(receivedError?.domain).to(equal(Purchases.ErrorDomain))
        expect(receivedError?.code).to(be(Purchases.ErrorCode.unexpectedBackendResponseError.rawValue))
    }

    func testMissingProductDetailsReturnsNil() {
        requestFetcher.failProducts = true
        offeringsFactory.emptyOfferings = true
        setupPurchases()

        var offerings: Purchases.Offerings?
        self.purchases?.offerings({ (newOfferings, _) in
            offerings = newOfferings
        })

        expect(offerings).toEventuallyNot(beNil());
        expect(offerings!["base"]).toEventually(beNil())
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
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [AnyHashable: Any]

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
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "")
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

    func testCreateAlias() {
        setupPurchases()

        var completionCalled = false
        self.identityManager.aliasError = nil
        var info: Purchases.PurchaserInfo?
        self.purchases?.createAlias("cesarpedro") { (newInfo, error) in
            completionCalled = (error == nil)
            info = newInfo
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.identityManager.aliasCalled).toEventually(beTrue())
        expect(info).toEventuallyNot(beNil())

        self.identityManager.aliasError = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: true)

        self.purchases?.createAlias("cesardro") { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beFalse())
        expect(self.identityManager.aliasCalled).toEventually(beTrue())
    }

    func testCreateAliasUpdatesCaches() {
        setupPurchases()
        self.backend.overridePurchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])

        let newAppUserID = "cesarPedro"

        var completionCalled = false
        self.identityManager.aliasError = nil
        self.purchases?.createAlias(newAppUserID) { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beTrue())
        verifyUpdatedCaches(newAppUserID: newAppUserID)
    }

    func testIdentify() {
        setupPurchases()

        var completionCalled = false
        var info: Purchases.PurchaserInfo?
        self.purchases?.identify("cesarpedro") { (newInfo, error) in
            completionCalled = true
            info = newInfo
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.identityManager.identifyCalled).toEventually(beTrue())
        expect(info).toEventuallyNot(beNil())

        self.identityManager.identifyError = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: true)

        self.purchases?.identify("cesardro") { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beFalse())
        expect(self.identityManager.identifyCalled).toEventually(beTrue())
    }

    func testIdentifyUpdatesCaches() {
        setupPurchases()
        
        self.backend.overridePurchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])

        let newAppUserID = "cesarPedro"

        var completionCalled = false
        self.purchases?.identify(newAppUserID) { (info, error) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        verifyUpdatedCaches(newAppUserID: newAppUserID)
    }

    func testReset() {
        setupPurchases()

        var completionCalled = false
        var info: Purchases.PurchaserInfo?
        self.purchases?.reset { newInfo, error in
            completionCalled = true
            info = newInfo
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.identityManager.resetCalled).toEventually(beTrue())
        expect(info).toEventuallyNot(beNil())
    }

    func testResetUpdatesCaches() {
        setupPurchases()
        self.backend.overridePurchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])

        var completionCalled = false
        self.purchases?.reset() { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beTrue())
        verifyUpdatedCaches(newAppUserID: self.identityManager.currentAppUserID)
    }

    func testCreateAliasForTheSameUserID() {
        setupPurchases()

        self.identityManager.aliasCalled = false
        self.identityManager.aliasError = nil

        var completionCalled = false
        var info: Purchases.PurchaserInfo?
        self.purchases?.createAlias(identityManager.currentAppUserID) { (newInfo, error) in
            completionCalled = true
            info = newInfo
        }

        expect(self.identityManager.aliasCalled).to(be(false))
        expect(self.identityManager.aliasError).to(beNil())
        expect(completionCalled).toEventually(be(true))
        expect(info).toEventuallyNot(beNil())
    }

    func testIdentifyForTheSameUserID() {
        setupPurchases()
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(1));
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1));

        var completionCalled = false
        var info: Purchases.PurchaserInfo?
        self.purchases?.identify(identityManager.currentAppUserID) { (newInfo, error) in
            completionCalled = true
            info = newInfo
        }

        expect(self.identityManager.identifyCalled).to(be(false))
        expect(completionCalled).toEventually(be(true))
        expect(info).toEventuallyNot(beNil())
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

        expect(receivedError?.code).toEventually(be(Purchases.ErrorCode.missingReceiptFileError.rawValue))
    }

    func testUserCancelledFalseIfPurchaseSuccessful() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?

        // Second one issues an error
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
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

        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
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
        expect(receivedError?.domain).toEventually(be(Purchases.ErrorDomain))
        expect(receivedError?.code).toEventually(be(Purchases.ErrorCode.purchaseCancelledError.rawValue))
        expect(receivedUnderlyingError?.domain).toEventually(be(SKErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(SKError.Code.paymentCancelled.rawValue))
    }

    func testDoNotSendEmptyReceiptWhenMakingPurchase() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false

        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?
        var receivedError: NSError?

        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beFalse())
        expect(receivedError?.code).toEventually(be(Purchases.ErrorCode.missingReceiptFileError.rawValue))
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

            self.purchases?.purchaseProduct(product, discount: discount) { (tx, info, error, userCancelled) in

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
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [AnyHashable: Any]

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
        expect(self.backend.postedAttributionData?[0].networkUserId).toEventually(equal(self.identityManager.currentAppUserID))
    }

    func testAttributionDataDontSendNetworkAppUserIdIfNotProvided() {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [AnyHashable: Any]

        Purchases.addAttributionData(data, from: RCAttributionNetwork.appleSearchAds)

        setupPurchases()

        for key in data.keys {
            expect(self.backend.postedAttributionData?[0].data.keys.contains(key)).toEventually(beTrue())
        }

        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfa")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_idfv")).toEventually(beTrue())
        expect(self.backend.postedAttributionData?[0].data.keys.contains("rc_attribution_network_id")).toEventually(beFalse())
        expect(self.backend.postedAttributionData?[0].network).toEventually(equal(RCAttributionNetwork.appleSearchAds))
        expect(self.backend.postedAttributionData?[0].networkUserId).toEventually(equal(self.identityManager.currentAppUserID))
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
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [AnyHashable: Any]

        Purchases.addAttributionData(data, from: RCAttributionNetwork.adjust, forNetworkUserId: "newuser")

        setupPurchases(automaticCollection: true)
        expect(self.backend.postedAttributionData).toEventuallyNot(beNil())
        expect(self.backend.postedAttributionData?.count).toEventually(equal(2))
    }

    func testObserverModeSetToFalseSetFinishTransactions() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testDoesntFinishTransactionsIfObserverModeIsSet() {
        setupPurchasesObserverModeOn()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testRestoredPurchasesArePosted() {
        setupPurchasesObserverModeOn()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.restored
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testNilProductIdentifier() {
        setupPurchases()
        let product = SKProduct()
        var receivedError: Error?
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in
            receivedError = error
        }
        
        expect(receivedError).toNot(beNil())
    }

    func testPostsOfferingIfPurchasingPackage() {
        setupPurchases()

        self.purchases!.offerings { (newOfferings, _) in
            let package = newOfferings!["base"]!.monthly!
            self.purchases!.purchasePackage(package) { (tx, info, error, userCancelled) in

            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptPurchaserInfo = Purchases.PurchaserInfo()

            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            expect(self.backend.postReceiptDataCalled).to(beTrue())
            expect(self.backend.postReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(package.product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(package.product.price))
            expect(self.backend.postedOfferingIdentifier).to(equal("base"))
            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testFetchPurchaserInfoWhenCacheStale() {
        setupPurchases()
        self.deviceCache.stubbedIsPurchaserInfoCacheStale = true

        self.purchases?.purchaserInfo() { (info, error) in

        }

        expect(self.backend.getSubscriberCallCount).toEventually(equal(2))
    }

    func testIsAnonymous() {
        setupAnonPurchases()
        expect(self.purchases.isAnonymous).to(beTrue())
    }

    func testIsNotAnonymous() {
        setupPurchases()
        expect(self.purchases.isAnonymous).to(beFalse())
    }

    func testProductIsRemovedButPresentInTheQueuedTransaction() {
        self.requestFetcher.failProducts = true
        setupPurchases()

        let purchaserInfo = Purchases.PurchaserInfo()
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
    
    func testReceiptsSendsObserverModeWhenObserverMode() {
        setupPurchasesObserverModeOn()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedObserverMode).to(beTrue())
    }
    
    func testReceiptsSendsObserverModeOffWhenObserverModeOff() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedObserverMode).to(beFalse())
    }

    func testInvalidatePurchaserInfoCacheClearsPurchaserInfoCache() {
        setupPurchases()
        guard let nonOptionalPurchases = purchases else { fatalError("failed when setting up purchases for testing") }

        expect(self.deviceCache.clearPurchaserInfoCacheTimestampCount) == 0

        nonOptionalPurchases.invalidatePurchaserInfoCache()
        expect(self.deviceCache.clearPurchaserInfoCacheTimestampCount) == 1
    }

    func testInvalidatePurchaserInfoCacheDoesntClearOfferingsCache() {
        setupPurchases()
        guard let nonOptionalPurchases = purchases else { fatalError("failed when setting up purchases for testing") }

        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0

        nonOptionalPurchases.invalidatePurchaserInfoCache()
        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0
    }

    private func verifyUpdatedCaches(newAppUserID: String) {
        expect(self.backend.getSubscriberCallCount).toEventually(equal(2))
        expect(self.deviceCache.cachedPurchaserInfo.count).toEventually(equal(2))
        expect(self.deviceCache.cachedPurchaserInfo[newAppUserID]).toNot(beNil())
        expect(self.purchasesDelegate.purchaserInfoReceivedCount).toEventually(equal(2))
        expect(self.deviceCache.setPurchaserInfoCacheTimestampToNowCount).toEventually(equal(2))
        expect(self.deviceCache.setOfferingsCacheTimestampToNowCount).toEventually(equal(2))
        expect(self.backend.gotOfferings).toEventually(equal(2))
        expect(self.deviceCache.cachedOfferingsCount).toEventually(equal(2))
    }

}
