//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Created by RevenueCat.
//

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesTests: XCTestCase {

    let emptyCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "app_user_id",
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
    ]]

    override func setUp() {
        userDefaults = UserDefaults(suiteName: "TestDefaults")
        deviceCache = MockDeviceCache(userDefaults: userDefaults)
        requestFetcher = MockRequestFetcher()
        systemInfo = try! MockSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
        mockProductsManager = MockProductsManager()
        mockOperationDispatcher = MockOperationDispatcher()
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator()
        mockReceiptParser = MockReceiptParser()
        receiptFetcher = MockReceiptFetcher(requestFetcher: requestFetcher)
        let systemInfoAttribution = try! MockSystemInfo(platformFlavor: "iOS",
                                                   platformFlavorVersion: "3.2.1",
                                                   finishTransactions: true)
        attributionFetcher = MockAttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                    systemInfo: systemInfoAttribution)
        subscriberAttributesManager =
            MockSubscriberAttributesManager(backend: self.backend,
                                            deviceCache: self.deviceCache,
                                            attributionFetcher: self.attributionFetcher,
                                            attributionDataMigrator: AttributionDataMigrator())
        attributionPoster = AttributionPoster(deviceCache: deviceCache,
                                              identityManager: identityManager,
                                              backend: backend,
                                              attributionFetcher: attributionFetcher,
                                              subscriberAttributesManager: subscriberAttributesManager)
        customerInfoManager = CustomerInfoManager(operationDispatcher: mockOperationDispatcher,
                                                    deviceCache: deviceCache,
                                                    backend: backend,
                                                    systemInfo: systemInfo)
        mockOfferingsManager = MockOfferingsManager(deviceCache: deviceCache,
                                                    operationDispatcher: mockOperationDispatcher,
                                                    systemInfo: systemInfo,
                                                    backend: backend,
                                                    offeringsFactory: offeringsFactory,
                                                    productsManager: mockProductsManager)
    }

    override func tearDown() {
        Purchases.clearSingleton()
        deviceCache = nil
        purchases = nil
        UserDefaults().removePersistentDomain(forName: "TestDefaults")
    }

    class MockBackend: Backend {
        var userID: String?
        var originalApplicationVersion: String?
        var originalPurchaseDate: Date?
        var timeout = false
        var getSubscriberCallCount = 0
        var overrideCustomerInfoError: Error? = nil
        var overrideCustomerInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        override func getSubscriberData(appUserID: String, completion: @escaping BackendCustomerInfoResponseHandler) {
            getSubscriberCallCount += 1
            userID = appUserID

            if (!timeout) {
                let info = self.overrideCustomerInfo
                DispatchQueue.main.async {
                    completion(info, self.overrideCustomerInfoError)
                }
            }
        }

        var postReceiptDataCalled = false
        var postedReceiptData: Data?
        var postedIsRestore: Bool?
        var postedProductID: String?
        var postedPrice: NSDecimalNumber?
        var postedPaymentMode: ProductInfo.PaymentMode?
        var postedIntroPrice: NSDecimalNumber?
        var postedCurrencyCode: String?
        var postedSubscriptionGroup: String?
        var postedDiscounts: Array<PromotionalOffer>?
        var postedOfferingIdentifier: String?
        var postedObserverMode: Bool?

        var postReceiptCustomerInfo: CustomerInfo?
        var postReceiptError: Error?
        var aliasError: Error?
        var aliasCalled = false

        override func post(receiptData: Data,
                           appUserID: String,
                           isRestore: Bool,
                           productInfo: ProductInfo?,
                           presentedOfferingIdentifier: String?,
                           observerMode: Bool,
                           subscriberAttributes: [String: SubscriberAttribute]?,
                           completion: @escaping BackendCustomerInfoResponseHandler) {
            postReceiptDataCalled = true
            postedReceiptData = receiptData
            postedIsRestore = isRestore

            if let productInfo = productInfo {
                postedProductID = productInfo.productIdentifier
                postedPrice = productInfo.price

                postedPaymentMode = productInfo.paymentMode
                postedIntroPrice = productInfo.introPrice
                postedSubscriptionGroup = productInfo.subscriptionGroup

                postedCurrencyCode = productInfo.currencyCode
                postedDiscounts = productInfo.discounts
            }

            postedOfferingIdentifier = presentedOfferingIdentifier
            postedObserverMode = observerMode
            completion(postReceiptCustomerInfo, postReceiptError)
        }

        var postedProductIdentifiers: [String]?

        override func getIntroEligibility(appUserID: String,
                                          receiptData: Data,
                                          productIdentifiers: [String],
                                          completion: @escaping IntroEligibilityResponseHandler) {
            postedProductIdentifiers = productIdentifiers

            var eligibilities = [String: IntroEligibility]()
            for productID in productIdentifiers {
                eligibilities[productID] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.eligible)
            }

            completion(eligibilities, nil)
        }

        var failOfferings = false
        var badOfferingsResponse = false
        var gotOfferings = 0


        override func getOfferings(appUserID: String, completion: @escaping OfferingsResponseHandler) {
            gotOfferings += 1
            if (failOfferings) {
                completion(nil, ErrorUtils.unexpectedBackendResponse(withSubError: .getOfferUnexpectedResponse))
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

        override func createAlias(appUserID: String, newAppUserID: String, completion: ((Error?) -> Void)?) {
            aliasCalled = true
            if (aliasError != nil) {
                completion!(aliasError)
            } else {
                userID = newAppUserID
                completion!(nil)
            }
        }

        var invokedPostAttributionData = false
        var invokedPostAttributionDataCount = 0
        var invokedPostAttributionDataParameters: (data: [String: Any]?, network: AttributionNetwork, appUserID: String?)?
        var invokedPostAttributionDataParametersList = [(data: [String: Any]?,
            network: AttributionNetwork,
            appUserID: String?)]()
        var stubbedPostAttributionDataCompletionResult: (Error?, Void)?

        override func post(attributionData: [String : Any],
                           network: AttributionNetwork,
                           appUserID: String,
                           completion: ((Error?) -> Void)? = nil) {
            invokedPostAttributionData = true
            invokedPostAttributionDataCount += 1
            invokedPostAttributionDataParameters = (attributionData, network, appUserID)
            invokedPostAttributionDataParametersList.append((attributionData, network, appUserID))
            if let result = stubbedPostAttributionDataCompletionResult {
                completion?(result.0)
            }
        }

        var postOfferForSigningCalled = false
        var postOfferForSigningPaymentDiscountResponse: [String: Any] = [:]
        var postOfferForSigningError: Error?

        override func post(offerIdForSigning offerIdentifier: String,
                           productIdentifier: String,
                           subscriptionGroup: String?,
                           receiptData: Data,
                           appUserID: String,
                           completion: @escaping OfferSigningResponseHandler) {
            postOfferForSigningCalled = true
            completion(postOfferForSigningPaymentDiscountResponse["signature"] as? String, postOfferForSigningPaymentDiscountResponse["keyIdentifier"] as? String, postOfferForSigningPaymentDiscountResponse["nonce"] as? UUID, postOfferForSigningPaymentDiscountResponse["timestamp"] as? NSNumber, postOfferForSigningError)
        }
    }


    var receiptFetcher: MockReceiptFetcher!
    var requestFetcher: MockRequestFetcher!
    var mockProductsManager: MockProductsManager!
    let backend = MockBackend(httpClient: MockHTTPClient(systemInfo: try! MockSystemInfo(platformFlavor: nil,
                                                                                         platformFlavorVersion: nil,
                                                                                         finishTransactions: false),
                                                         eTagManager: MockETagManager()),
                              apiKey: "mockAPIKey")
    let storeKitWrapper = MockStoreKitWrapper()
    let notificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let offeringsFactory = MockOfferingsFactory()
    var deviceCache: MockDeviceCache!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    let identityManager = MockIdentityManager(mockAppUserID: "app_user");
    var systemInfo: MockSystemInfo!
    var mockOperationDispatcher: MockOperationDispatcher!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockReceiptParser: MockReceiptParser!
    var attributionFetcher: MockAttributionFetcher!
    var attributionPoster: AttributionPoster!
    var customerInfoManager: CustomerInfoManager!
    var mockOfferingsManager: MockOfferingsManager!
    var purchasesOrchestrator: PurchasesOrchestrator!

    let purchasesDelegate = MockPurchasesDelegate()

    var purchases: Purchases!

    func setupPurchases(automaticCollection: Bool = false) {
        Purchases.automaticAppleSearchAdsAttributionCollection = automaticCollection
        self.identityManager.mockIsAnonymous = false

        initializePurchasesInstance(appUserId: identityManager.currentAppUserID)
    }

    func setupAnonPurchases() {
        Purchases.automaticAppleSearchAdsAttributionCollection = false
        self.identityManager.mockIsAnonymous = true
        initializePurchasesInstance(appUserId: nil)
    }

    func setupPurchasesObserverModeOn() {
        systemInfo = try! MockSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: false)
        initializePurchasesInstance(appUserId: nil)
    }

    private func initializePurchasesInstance(appUserId: String?) {
        purchasesOrchestrator = PurchasesOrchestrator(productsManager: mockProductsManager,
                                                      storeKitWrapper: storeKitWrapper,
                                                      systemInfo: systemInfo,
                                                      subscriberAttributesManager: subscriberAttributesManager,
                                                      operationDispatcher: mockOperationDispatcher,
                                                      receiptFetcher: receiptFetcher,
                                                      customerInfoManager: customerInfoManager,
                                                      backend: backend,
                                                      identityManager: identityManager,
                                                      receiptParser: mockReceiptParser,
                                                      deviceCache: deviceCache)

        purchases = Purchases(appUserID: appUserId,
                              requestFetcher: requestFetcher,
                              receiptFetcher: receiptFetcher,
                              attributionFetcher: attributionFetcher,
                              attributionPoster: attributionPoster,
                              backend: backend,
                              storeKitWrapper: storeKitWrapper,
                              notificationCenter: notificationCenter,
                              systemInfo: systemInfo,
                              offeringsFactory: offeringsFactory,
                              deviceCache: deviceCache,
                              identityManager: identityManager,
                              subscriberAttributesManager: subscriberAttributesManager,
                              operationDispatcher: mockOperationDispatcher,
                              introEligibilityCalculator: mockIntroEligibilityCalculator,
                              receiptParser: mockReceiptParser,
                              customerInfoManager: customerInfoManager,
                              productsManager: mockProductsManager,
                              offeringsManager: mockOfferingsManager,
                              purchasesOrchestrator: purchasesOrchestrator)

        purchasesOrchestrator.maybeDelegate = purchases
        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }

    func testIsAbleToBeInitialized() {
        setupPurchases()
        expect(self.purchases).toNot(beNil())
    }

    func testUsingSharedInstanceWithoutInitializingThrowsAssertion() {
        let expectedMessage = "Purchases has not been configured. Please call Purchases.configure()"
        expectFatalError(expectedMessage: expectedMessage) { _ = Purchases.shared }
    }

    func testUsingSharedInstanceAfterInitializingDoesntThrowAssertion() {
        setupPurchases()
        expectNoFatalError { _ = Purchases.shared }
    }

    func testIsConfiguredReturnsCorrectvalue() {
        expect(Purchases.isConfigured) == false
        setupPurchases()
        expect(Purchases.isConfigured) == true
    }

    func testFirstInitializationCallDelegate() {
        setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundDelegateForAnonIfNothingCached() {
        systemInfo.stubbedIsApplicationBackgrounded = false
        setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationFromBackgroundDoesntCallDelegateForAnonIfNothingCached() {
        systemInfo.stubbedIsApplicationBackgrounded = true
        setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(0))
    }

    func testFirstInitializationFromBackgroundCallsDelegateForAnonIfInfoCached() {
        systemInfo.stubbedIsApplicationBackgrounded = true
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationFromBackgroundDoesntUpdateCustomerInfoCache() {
        systemInfo.stubbedIsApplicationBackgrounded = true
        setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(0))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoCacheIfNotInUserDefaults() {
        systemInfo.stubbedIsApplicationBackgrounded = false
        setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoCacheIfUserDefaultsCacheStale() {
        let staleCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -20, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: staleCacheDateForForeground,
                                               appUserID: identityManager.currentAppUserID)
        systemInfo.stubbedIsApplicationBackgrounded = false

        setupPurchases()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoEvenIfCacheValid() {
        let staleCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: staleCacheDateForForeground,
                                               appUserID: identityManager.currentAppUserID)

        systemInfo.stubbedIsApplicationBackgrounded = false

        setupPurchases()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testDelegateIsCalledForRandomPurchaseSuccess() {
        setupPurchases()

        let customerInfo = CustomerInfo(data: emptyCustomerInfoData)
        self.backend.postReceiptCustomerInfo = customerInfo

        let product = MockSKProduct(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)

        let customerInfoBeforePurchase = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [:]
            ]])
        let customerInfoAfterPurchase = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [product.mockProductIdentifier: []]
            ]])
        self.backend.overrideCustomerInfo = customerInfoBeforePurchase
        self.backend.postReceiptCustomerInfo = customerInfoAfterPurchase

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testDelegateIsOnlyCalledOnceIfCustomerInfoTheSame() {
        setupPurchases()

        let customerInfo1 = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
        ])

        let customerInfo2 = customerInfo1

        let product = MockSKProduct(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = customerInfo1
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = customerInfo2
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testDelegateIsCalledTwiceIfCustomerInfoTheDifferent() {
        setupPurchases()

        let customerInfo1 = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
            ])

        let customerInfo2 = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2.0"
            ]
        ])

        let product = MockSKProduct(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = customerInfo1
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = customerInfo2
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(3))
    }

    func testDelegateIsNotCalledIfBlockPassed() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedIsRestore).to(beFalse())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testIsAbleToFetchProducts() {
        setupPurchases()
        var products: [SKProduct]?
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.getProducts(productIdentifiers) { (newProducts) in
            products = newProducts
        }

        expect(products).toEventuallyNot(beNil())
        expect(products).toEventually(haveCount(productIdentifiers.count))
    }

    func testSetsSelfAsStoreKitWrapperDelegate() {
        setupPurchases()
        expect(self.storeKitWrapper.delegate).to(be(purchasesOrchestrator))
    }

    func testAddsPaymentToWrapper() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        expect(self.storeKitWrapper.payment).toNot(beNil())
        expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
    }

    func testPurchaseProductCachesProduct() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        expect(self.mockProductsManager.invokedCacheProduct) == true
        expect(self.mockProductsManager.invokedCacheProductParameter) == product
    }

    func testDoesntFetchProductInfoIfEmptyList() {
        setupPurchases()
        var completionCalled = false
        mockProductsManager.resetMock()
        self.purchases.getProducts([]) { _ in
            completionCalled = true
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockProductsManager.invokedProducts) == false
    }

    func testTransitioningToPurchasing() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beFalse())
    }

    func testTransitioningToPurchasedSendsToBackend() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

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
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

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
        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

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
        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = true
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

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
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: emptyCustomerInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testDoesntFinishTransactionsIfFinishingDisabled() {
        setupPurchases()
        self.purchases?.finishTransactions = false
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testSendsProductInfoIfProductIsCached() {
        setupPurchases()
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.getProducts(productIdentifiers) { (newProducts) in
            let product = newProducts[0];
            self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)

            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            expect(self.backend.postReceiptDataCalled).to(beTrue())
            expect(self.backend.postedReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(product.price))

            if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                expect(self.backend.postedPaymentMode).to(equal(ProductInfo.PaymentMode.payAsYouGo))
                expect(self.backend.postedIntroPrice).to(equal(product.introductoryPrice?.price))
            } else {
                expect(self.backend.postedPaymentMode).to(equal(ProductInfo.PaymentMode.none))
                expect(self.backend.postedIntroPrice).to(beNil())
            }

            if #available(iOS 12.0, tvOS 12.0, macOS 10.14, *) {
                expect(self.backend.postedSubscriptionGroup).to(equal(product.subscriptionGroupIdentifier))
            }

            if #available(iOS 12.2, *) {
                expect(self.backend.postedDiscounts?.count).to(equal(1))
                let postedDiscount: PromotionalOffer = self.backend.postedDiscounts![0]
                expect(postedDiscount.offerIdentifier).to(equal("discount_id"))
                expect(postedDiscount.price).to(equal(1.99))
                expect(postedDiscount.paymentMode.rawValue).to(equal(ProductInfo.PaymentMode.payAsYouGo.rawValue))
            }

            expect(self.backend.postedCurrencyCode).to(equal(product.priceLocale.currencyCode))

            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testFetchesProductInfoIfNotCached() {
        systemInfo.stubbedIsApplicationBackgrounded = true
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")

        let transaction = MockTransaction()
        storeKitWrapper.payment = SKPayment(product: product);
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: emptyCustomerInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedProductsParameters).toEventually(contain([product.productIdentifier]))

        expect(self.backend.postedProductID).toNot(beNil())
        expect(self.backend.postedPrice).toNot(beNil())
        expect(self.backend.postedCurrencyCode).toNot(beNil())
        if #available(iOS 12.2, macOS 10.14.4, *) {
            expect(self.backend.postedIntroPrice).toNot(beNil())
        }
    }

    enum BackendError: Error {
        case unknown
    }

    func testAfterSendingDoesntFinishTransactionIfBackendError() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        self.backend.postReceiptError = ErrorUtils.backendError(withBackendCode: .invalidAPIKey,
                                                                backendMessage: "Invalid credentials",
                                                                finishable: false)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testAfterSendingFinishesFromBackendErrorIfAppropriate() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptError = ErrorUtils.backendError(withBackendCode: .invalidAPIKey,
                                                                backendMessage: "Invalid credentials",
                                                                finishable: true)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testNotifiesIfTransactionFailsFromBackend() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        let backendErrorCode = BackendErrorCode(maybeCode: ErrorCode.invalidCredentialsError.rawValue)
        self.backend.postReceiptError = ErrorUtils.backendError(withBackendCode: backendErrorCode,
                                                                backendMessage: "Invalid credentials",
                                                                finishable: false)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
    }

    func testNotifiesIfTransactionFailsFromStoreKit() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        var receivedError: Error?
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
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
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")

        var customerInfo: CustomerInfo?
        var receivedError: Error?
        var receivedUserCancelled: Bool?

        let customerInfoBeforePurchase = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [:]
            ]])
        let customerInfoAfterPurchase = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [product.mockProductIdentifier: []]
            ]])
        self.backend.overrideCustomerInfo = customerInfoBeforePurchase
        self.backend.postReceiptCustomerInfo = customerInfoAfterPurchase

        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
            customerInfo = info
            receivedError = error
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(customerInfo).toEventually(be(self.backend.postReceiptCustomerInfo))
        expect(receivedError).toEventually(beNil())
        expect(self.purchasesDelegate.customerInfoReceivedCount).to(equal(2))
        expect(receivedUserCancelled).toEventually(beFalse())
    }

    func testCompletionBlockOnlyCalledOnce() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")

        var callCount = 0

        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
            callCount += 1
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: emptyCustomerInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(callCount).toEventually(equal(1))
    }

    func testCompletionBlockNotCalledForDifferentProducts() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        let otherProduct = MockSKProduct(mockProductIdentifier: "com.product.id2")

        var callCount = 0

        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
            callCount += 1
        }

        let transaction = MockTransaction()
        transaction.mockPayment = SKPayment.init(product: otherProduct)

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(callCount).toEventually(equal(0))
    }

    func testCallingPurchaseWhileSameProductPendingIssuesError() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")

        // First one "works"
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
        }

        var receivedInfo: CustomerInfo?
        var receivedError: NSError?
        var receivedUserCancelled: Bool?

        // Second one issues an error
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
            receivedInfo = info
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        expect(receivedInfo).toEventually(beNil())
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.operationAlreadyInProgressForProductError.rawValue))
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
        expect(self.notificationCenter.observers.count).to(equal(2));
        if self.notificationCenter.observers.count > 0 {
            let (_, _, name, _) = self.notificationCenter.observers[0];
            expect(name).to(equal(SystemInfo.applicationDidBecomeActiveNotification))
        }
    }

    func testTriggersCallToBackend() {
        setupPurchases()
        notificationCenter.fireNotifications();
        expect(self.backend.userID).toEventuallyNot(beNil());
    }

    func testAutomaticallyFetchesCustomerInfoOnDidBecomeActiveIfCacheStale() {
        setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))

        self.deviceCache.stubbedIsCustomerInfoCacheStale = true
        notificationCenter.fireNotifications();

        expect(self.backend.getSubscriberCallCount).toEventually(equal(2))
    }

    func testDoesntAutomaticallyFetchCustomerInfoOnDidBecomeActiveIfCacheValid() {
        setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
        self.deviceCache.stubbedIsCustomerInfoCacheStale = false

        notificationCenter.fireNotifications();

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testAutomaticallyCallsDelegateOnDidBecomeActiveAndUpdate() {
        setupPurchases()
        notificationCenter.fireNotifications();
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testDoesntRemoveObservationWhenDelegateNil() {
        setupPurchases()
        purchases!.delegate = nil

        expect(self.notificationCenter.observers.count).to(equal(2));
    }

    func testRestoringPurchasesPostsTheReceipt() {
        setupPurchases()
        purchases!.restoreTransactions()
        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testRestoringPurchasesDoesntPostIfReceiptEmptyAndCustomerInfoLoaded() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        mockReceiptParser.stubbedReceiptHasTransactionsResult = false

        setupPurchases()
        purchases!.restoreTransactions()

        expect(self.backend.postReceiptDataCalled) == false
    }

    func testRestoringPurchasesPostsIfReceiptEmptyAndCustomerInfoNotLoaded() {
        mockReceiptParser.stubbedReceiptHasTransactionsResult = false

        setupPurchases()
        purchases!.restoreTransactions()

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testRestoringPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoLoaded() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        mockReceiptParser.stubbedReceiptHasTransactionsResult = true

        setupPurchases()
        purchases!.restoreTransactions()

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testRestoringPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoNotLoaded() {
        mockReceiptParser.stubbedReceiptHasTransactionsResult = true

        setupPurchases()
        purchases!.restoreTransactions()

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testRestoringPurchasesAlwaysRefreshesAndPostsTheReceipt() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = true
        purchases!.restoreTransactions()

        expect(self.receiptFetcher.receiptDataTimesCalled).to(equal(1))
    }

    func testRestoringPurchasesSetsIsRestore() {
        setupPurchases()
        purchases!.restoreTransactions()
        expect(self.backend.postedIsRestore!).to(beTrue())
    }

    func testRestoringPurchasesSetsIsRestoreForAnon() {
        setupAnonPurchases()
        purchases!.restoreTransactions()

        expect(self.backend.postedIsRestore!).to(beTrue())
    }

    func testRestoringPurchasesCallsSuccessDelegateMethod() {
        setupPurchases()

        let customerInfo = CustomerInfo(data: self.emptyCustomerInfoData)
        self.backend.postReceiptCustomerInfo = customerInfo

        var receivedCustomerInfo: CustomerInfo?

        purchases!.restoreTransactions { (info, error) in
            receivedCustomerInfo = info
        }

        expect(receivedCustomerInfo).toEventually(be(customerInfo))
    }

    func testRestorePurchasesPassesErrorOnFailure() {
        setupPurchases()


        let error = ErrorUtils.backendError(withBackendCode: .invalidAPIKey,
                                            backendMessage: "Invalid credentials",
                                            finishable: true)

        self.backend.postReceiptError = error
        self.purchasesDelegate.customerInfo = nil

        var receivedError: Error?

        purchases!.restoreTransactions { (_, newError) in
            receivedError = newError
        }

        expect(receivedError).toEventuallyNot(beNil())
    }

    func testSyncPurchasesPostsTheReceipt() {
        setupPurchases()
        purchases!.syncPurchases(completion: nil)
        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testSyncPurchasesDoesntPostIfReceiptEmptyAndCustomerInfoLoaded() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        mockReceiptParser.stubbedReceiptHasTransactionsResult = false

        setupPurchases()
        purchases!.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == false
    }

    func testSyncPurchasesPostsIfReceiptEmptyAndCustomerInfoNotLoaded() {
        mockReceiptParser.stubbedReceiptHasTransactionsResult = false

        setupPurchases()
        purchases!.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoLoaded() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        mockReceiptParser.stubbedReceiptHasTransactionsResult = true

        setupPurchases()
        purchases!.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoNotLoaded() {
        mockReceiptParser.stubbedReceiptHasTransactionsResult = true

        setupPurchases()
        purchases!.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesDoesntRefreshTheReceiptIfNotEmpty() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = true
        purchases!.syncPurchases(completion: nil)

        expect(self.receiptFetcher.receiptDataTimesCalled) == 1
        expect(self.requestFetcher.refreshReceiptCalled) == false
    }

    func testSyncPurchasesDoesntRefreshTheReceiptIfEmpty() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false
        purchases!.syncPurchases(completion: nil)

        expect(self.receiptFetcher.receiptDataTimesCalled) == 1
        expect(self.requestFetcher.refreshReceiptCalled) == false
    }

    func testSyncPurchasesPassesIsRestoreAsAllowSharingAppStoreAccount() {
        setupPurchases()

        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        purchases!.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == false

        deprecated.allowSharingAppStoreAccount = true
        purchases!.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == true
    }

    func testSyncPurchasesSetsIsRestoreForAnon() {
        setupAnonPurchases()

        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        purchases!.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == false

        deprecated.allowSharingAppStoreAccount = true
        purchases!.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == true
    }

    func testSyncPurchasesCallsSuccessDelegateMethod() {
        setupPurchases()

        let customerInfo = CustomerInfo(data: self.emptyCustomerInfoData)
        self.backend.postReceiptCustomerInfo = customerInfo

        var receivedCustomerInfo: CustomerInfo?

        purchases!.syncPurchases { (info, error) in
            receivedCustomerInfo = info
        }

        expect(receivedCustomerInfo).toEventually(be(customerInfo))
    }

    func testSyncPurchasesPassesErrorOnFailure() {
        setupPurchases()

        let error = ErrorUtils.backendError(withBackendCode: .invalidAPIKey,
                                            backendMessage: "Invalid credentials",
                                            finishable: true)

        self.backend.postReceiptError = error
        self.purchasesDelegate.customerInfo = nil

        var receivedError: Error?

        purchases!.syncPurchases { (_, newError) in
            receivedError = newError
        }

        expect(receivedError).toEventuallyNot(beNil())
    }

    func testCallsShouldAddPromoPaymentDelegateMethod() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init()

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product)

        expect(self.purchasesDelegate.promoProduct).to(be(product))
    }

    func testShouldAddPromoPaymentDelegateMethodReturnsFalse() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init()

        let result = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                               shouldAddStorePayment: payment,
                                                               for: product)

        expect(result).to(beFalse())
    }

    func testPromoPaymentDelegateMethodMakesRightCalls() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product)

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

    func testPromoPaymentDelegateMethodCachesProduct() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedCacheProduct) == true
        expect(self.mockProductsManager.invokedCacheProductParameter) == product
    }

    func testDeferBlockMakesPayment() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        guard let storeKitWrapperDelegate = storeKitWrapper.delegate else {
            fail("storeKitWrapperDelegate nil")
            return
        }

        _ = storeKitWrapperDelegate.storeKitWrapper(storeKitWrapper,
                                                    shouldAddStorePayment: payment,
                                                    for: product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())

        expect(self.storeKitWrapper.payment).to(beNil())

        guard let makeDeferredPurchase = purchasesDelegate.makeDeferredPurchase else {
            fail("makeDeferredPurchase should have been nonNil")
            return
        }

        makeDeferredPurchase { (_, _, _, _) in
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

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]
        ])

        var receivedCustomerInfo: CustomerInfo?

        purchases?.restoreTransactions { (info, error) in
            receivedCustomerInfo = info
        }

        expect(receivedCustomerInfo?.originalApplicationVersion).toEventually(equal("1.0"))
        expect(receivedCustomerInfo?.originalPurchaseDate).toEventually(equal(Date(timeIntervalSinceReferenceDate: 562288673)))
        expect(self.backend.userID).toEventuallyNot(beNil())
        expect(self.backend.postReceiptDataCalled).toEventuallyNot(beFalse())
    }

    func testCachesCustomerInfo() {
        setupPurchases()

        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(1))
        expect(self.deviceCache.cachedCustomerInfo[self.purchases!.appUserID]).toEventuallyNot(beNil())

        let customerInfo = self.deviceCache.cachedCustomerInfo[self.purchases!.appUserID]

        do {
            if (customerInfo != nil) {
                try JSONSerialization.jsonObject(with: customerInfo!, options: [])
            }
        } catch {
            fail()
        }
    }

    func testCachesCustomerInfoOnPurchase() {
        setupPurchases()

        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(1))

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())

        expect(self.deviceCache.cacheCustomerInfoCount).toEventually(equal(2))
    }

    func testCachedCustomerInfoHasSchemaVersion() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()

        var receivedInfo: CustomerInfo?

        purchases!.getCustomerInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).toNot(beNil())
        expect(receivedInfo?.schemaVersion).toNot(beNil())
    }

    func testCachedCustomerInfoHandlesNullSchema() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        var jsonObject = info!.jsonObject()

        jsonObject["schema_version"] = NSNull()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()

        var receivedInfo: CustomerInfo?

        purchases!.getCustomerInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).to(beNil())
    }

    func testSendsCachedCustomerInfoToGetter() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let object = try! JSONSerialization.data(withJSONObject: info!.jsonObject(), options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()

        var receivedInfo: CustomerInfo?

        purchases!.getCustomerInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).toNot(beNil())
    }

    func testCustomerInfoCompletionBlockCalledExactlyOnceWhenInfoCached() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        let object = try! JSONSerialization.data(withJSONObject: info!.jsonObject(), options: []);
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object
        self.deviceCache.stubbedIsCustomerInfoCacheStale = true
        self.backend.timeout = false

        setupPurchases()

        var callCount = 0

        purchases!.getCustomerInfo { (_, _) in
            callCount += 1
        }

        expect(callCount).toEventually(equal(1))
    }

    func testDoesntSendsCachedCustomerInfoToGetterIfSchemaVersionDiffers() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        var jsonObject = info!.jsonObject()
        jsonObject["schema_version"] = "bad_version"
        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);

        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()

        var receivedInfo: CustomerInfo?

        purchases!.getCustomerInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).to(beNil())
    }

    func testDoesntSendsCachedCustomerInfoToGetterIfNoSchemaVersionInCached() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);
        var jsonObject = info!.jsonObject()
        jsonObject.removeValue(forKey: "schema_version")
        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: []);

        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object
        self.backend.timeout = true

        setupPurchases()

        var receivedInfo: CustomerInfo?

        purchases!.getCustomerInfo { (info, error) in
            receivedInfo = info
        }

        expect(receivedInfo).to(beNil())
    }

    func testDoesntSendCacheIfNoCacheAndCallsBackendAgain() {
        self.backend.timeout = true

        setupPurchases()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))

        purchases!.getCustomerInfo { (info, error) in
        }

        expect(self.backend.getSubscriberCallCount).to(equal(2))
    }

    func testFirstInitializationGetsOfferingsIfAppActive() {
        systemInfo.stubbedIsApplicationBackgrounded = false
        setupPurchases()
        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))
    }

    func testFirstInitializationDoesntFetchOfferingsIfAppBackgrounded() {
        systemInfo.stubbedIsApplicationBackgrounded = true
        setupPurchases()
        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(0))
    }

    func testProductInfoIsCachedForOfferings() {
        setupPurchases()
        mockOfferingsManager.stubbedOfferingsCompletionResult = (offeringsFactory.createOfferings(withProducts: [:], data: [:]), nil)
        self.purchases?.getOfferings { (newOfferings, _) in
            let product = newOfferings!["base"]!.monthly!.product;
            self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)

            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            expect(self.backend.postReceiptDataCalled).to(beTrue())
            expect(self.backend.postedReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(product.price))
            expect(self.backend.postedCurrencyCode).to(equal(product.priceLocale.currencyCode))

            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testAddAttributionAlwaysAddsAdIdsEmptyDict() {
        setupPurchases()

        Purchases.deprecated.addAttributionData([:], fromNetwork: AttributionNetwork.adjust)

        let attributionData = self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParameters?.attributionData
        expect(attributionData?.count) == 2
        expect(attributionData?["rc_idfa"] as? String) == "rc_idfa"
        expect(attributionData?["rc_idfv"] as? String) == "rc_idfv"
    }

    func testPassesTheArrayForAllNetworks() {
        setupPurchases()
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: AttributionNetwork.appleSearchAds)

        for key in data.keys {
            expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains(key)).toEventually(beTrue())
        }
        expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains("rc_idfa")) == true
        expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains("rc_idfv")) == true
        expect(self.backend.invokedPostAttributionDataParametersList[0].network) == AttributionNetwork.appleSearchAds
        expect(self.backend.invokedPostAttributionDataParametersList[0].appUserID) == self.purchases?.appUserID
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
        var info: CustomerInfo?
        purchases.deprecated.createAlias("cesarpedro") { (newInfo, error) in
            completionCalled = (error == nil)
            info = newInfo
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.identityManager.aliasCalled).toEventually(beTrue())
        expect(info).toEventuallyNot(beNil())

        self.identityManager.aliasError = ErrorUtils.backendError(withBackendCode: .invalidAPIKey,
                                                                  backendMessage: "Invalid credentials",
                                                                  finishable: true)

        purchases.deprecated.createAlias("cesardro") { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beFalse())
        expect(self.identityManager.aliasCalled).toEventually(beTrue())
    }

    func testCreateAliasUpdatesCaches() {
        setupPurchases()
        self.backend.overrideCustomerInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])

        let newAppUserID = "cesarPedro"

        var completionCalled = false
        self.identityManager.aliasError = nil
        purchases.deprecated.createAlias(newAppUserID) { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beTrue())
        verifyUpdatedCaches(newAppUserID: newAppUserID)
    }

    func testIdentify() {
        setupPurchases()

        var completionCalled = false
        var info: CustomerInfo?
        self.purchases.deprecated.identify("cesarpedro") { (newInfo, error) in
            completionCalled = true
            info = newInfo
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.identityManager.identifyCalled).toEventually(beTrue())
        expect(info).toEventuallyNot(beNil())

        self.identityManager.identifyError = ErrorUtils.backendError(withBackendCode: .invalidAPIKey,
                                                                     backendMessage: "Invalid credentials",
                                                                     finishable: true)

        self.purchases.deprecated.identify("cesardro") { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beFalse())
        expect(self.identityManager.identifyCalled).toEventually(beTrue())
    }

    func testIdentifyUpdatesCaches() {
        setupPurchases()

        self.backend.overrideCustomerInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "other_purchases": [:],
                "original_application_version": "2"
            ]])

        let newAppUserID = "cesarPedro"

        var completionCalled = false
        purchases.deprecated.identify(newAppUserID) { (info, error) in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        verifyUpdatedCaches(newAppUserID: newAppUserID)
    }

    func testReset() {
        setupPurchases()

        var completionCalled = false
        var info: CustomerInfo?
        purchases.deprecated.reset { newInfo, error in
            completionCalled = true
            info = newInfo
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.identityManager.resetCalled).toEventually(beTrue())
        expect(info).toEventuallyNot(beNil())
    }

    func testResetUpdatesCaches() {
        setupPurchases()
        self.backend.overrideCustomerInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2"
            ]])

        var completionCalled = false
        purchases.deprecated.reset() { (info, error) in
            completionCalled = (error == nil)
        }

        expect(completionCalled).toEventually(beTrue())
        verifyUpdatedCaches(newAppUserID: identityManager.currentAppUserID)
    }

    func testCreateAliasForTheSameUserID() {
        setupPurchases()

        self.identityManager.aliasCalled = false
        self.identityManager.aliasError = nil

        var completionCalled = false
        var info: CustomerInfo?
        purchases.deprecated.createAlias(identityManager.currentAppUserID) { (newInfo, error) in
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
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1));
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1));

        var completionCalled = false
        var info: CustomerInfo?
        purchases.deprecated.identify(identityManager.currentAppUserID) { (newInfo, error) in
            completionCalled = true
            info = newInfo
        }

        expect(self.identityManager.identifyCalled).to(be(false))
        expect(completionCalled).toEventually(be(true))
        expect(info).toEventuallyNot(beNil())
    }

    func testWhenNoReceiptDataReceiptIsRefreshed() {
        setupPurchases()
        receiptFetcher.shouldReturnReceipt = true
        receiptFetcher.shouldReturnZeroBytesReceipt = true

        makeAPurchase()
        
        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .onlyIfEmpty
    }

    private func makeAPurchase() {
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")

        guard let purchases = purchases else { fatalError("purchases is not initialized") }
        purchases.purchase(product: product) { _,_,_,_ in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased

        storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
    }

    func testRestoresDontPostMissingReceipts() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false
        var receivedError: NSError?
        self.purchases?.restoreTransactions() { (info, error) in
            receivedError = error as NSError?
        }

        expect(receivedError?.code).toEventually(be(ErrorCode.missingReceiptFileError.rawValue))
    }

    func testRestoreTransactionsCallsCompletionOnMainThreadWhenMissingReceipts() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false
        var receivedError: NSError?
        self.purchases?.restoreTransactions() { (info, error) in
            receivedError = error as NSError?
        }

        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == 1
        expect(receivedError?.code).toEventually(be(ErrorCode.missingReceiptFileError.rawValue))
    }

    func testUserCancelledFalseIfPurchaseSuccessful() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?

        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
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
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
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
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.purchaseCancelledError.rawValue))
        expect(receivedUnderlyingError?.domain).toEventually(be(SKErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(SKError.Code.paymentCancelled.rawValue))
    }

    func testDoNotSendEmptyReceiptWhenMakingPurchase() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false

        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        var receivedUserCancelled: Bool?
        var receivedError: NSError?

        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beFalse())
        expect(receivedError?.code).toEventually(be(ErrorCode.missingReceiptFileError.rawValue))
        expect(self.backend.postReceiptDataCalled).toEventually(beFalse())
    }

    func testDeferBlockCallsCompletionBlockAfterPurchaseCompletes() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())

        expect(self.storeKitWrapper.payment).to(beNil())

        var completionCalled = false

        guard let makeDeferredPurchase = purchasesDelegate.makeDeferredPurchase else {
            fail("makeDeferredPurchase nil")
            return
        }
        
        makeDeferredPurchase { (tx, info, error, userCancelled) in
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
        if #available(iOS 12.2, tvOS 12.2, macOS 10.14.4, *) {
            setupPurchases()
            let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
            let discount = SKPaymentDiscount.init(identifier: "discount", keyIdentifier: "TIKAMASALA1", nonce: UUID(), signature: "Base64 encoded signature", timestamp: NSNumber(value: Int64(123413232131)))

            self.purchases?.purchase(product: product, discount: discount) { (tx, info, error, userCancelled) in

            }

            expect(self.storeKitWrapper.payment).toNot(beNil())
            expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
            expect(self.storeKitWrapper.payment?.paymentDiscount).to(equal(discount))
        }
    }

    func testPaymentDiscountForProductDiscountCreatesDiscount() {
        if #available(iOS 12.2, tvOS 12.2, macOS 10.14.4, *) {
            setupPurchases()
            let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
            product.mockSubscriptionGroupIdentifier = "productGroup"

            let discountIdentifier = "id"
            let signature = "firma"
            let keyIdentifier = "key_id"
            let nonce = UUID()
            let timestamp = 1234
            let productDiscount = MockProductDiscount(identifier: discountIdentifier)
            self.backend.postOfferForSigningPaymentDiscountResponse["signature"] = signature
            self.backend.postOfferForSigningPaymentDiscountResponse["keyIdentifier"] = keyIdentifier
            self.backend.postOfferForSigningPaymentDiscountResponse["nonce"] = nonce
            self.backend.postOfferForSigningPaymentDiscountResponse["timestamp"] = timestamp

            var completionCalled = false
            var receivedPaymentDiscount: SKPaymentDiscount?
            self.purchases?.paymentDiscount(forProductDiscount: productDiscount,
                                            product: product,
                                            completion: { (paymentDiscount, error) in
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

    func testPaymentDiscountForProductDiscountWithNoIDReturnsError() {
        if #available(iOS 12.2, tvOS 12.2, macOS 10.14.4, *) {
            setupPurchases()
            let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
            let signature = "firma"
            let keyIdentifier = "key_id"
            let nonce = UUID()
            let timestamp = 1234
            let productDiscount = MockProductDiscount(identifier: nil)
            self.backend.postOfferForSigningPaymentDiscountResponse["signature"] = signature
            self.backend.postOfferForSigningPaymentDiscountResponse["keyIdentifier"] = keyIdentifier
            self.backend.postOfferForSigningPaymentDiscountResponse["nonce"] = nonce
            self.backend.postOfferForSigningPaymentDiscountResponse["timestamp"] = timestamp

            var maybeError: Error?
            self.purchases?.paymentDiscount(forProductDiscount: productDiscount,
                                            product: product,
                                            completion: { (paymentDiscount, error) in
                maybeError = error
            })

            expect(maybeError?.localizedDescription)
                .toEventually(equal(ErrorUtils.productDiscountMissingIdentifierError().localizedDescription))
        }
    }

    func testPaymentDiscountForProductDiscountCallsCompletionWithErrorIfReceiptNil() {
        if #available(iOS 12.2, tvOS 12.2, macOS 10.14.4, *) {
            setupPurchases()
            let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
            product.mockSubscriptionGroupIdentifier = "productGroup"

            let discountIdentifier = "id"
            let productDiscount = MockProductDiscount(identifier: discountIdentifier)

            self.receiptFetcher.shouldReturnReceipt = false
            var completionCalled = false
            var receivedPaymentDiscount: SKPaymentDiscount?
            var receivedError: Error? = nil
            self.purchases?.paymentDiscount(forProductDiscount: productDiscount,
                                            product: product,
                                            completion: { (paymentDiscount, error) in
                receivedPaymentDiscount = paymentDiscount
                completionCalled = true
                receivedError = error
            })

            expect(self.receiptFetcher.receiptDataCalled).toEventually(beTrue())
            expect(receivedPaymentDiscount).to(beNil())
            expect(completionCalled).toEventually(beTrue())
            expect(self.backend.postOfferForSigningCalled) == false
            expect((receivedError! as NSError).code) == ErrorCode.missingReceiptFileError.rawValue
        }
    }

    func testPaymentDiscountForProductDiscountCallsCompletionWithErrorIfReceiptEmpty() {
        if #available(iOS 12.2, tvOS 12.2, macOS 10.14.4, *) {
            setupPurchases()
            let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
            product.mockSubscriptionGroupIdentifier = "productGroup"

            let discountIdentifier = "id"
            let productDiscount = MockProductDiscount(identifier: discountIdentifier)

            self.receiptFetcher.shouldReturnReceipt = true
            self.receiptFetcher.shouldReturnZeroBytesReceipt = true
            var completionCalled = false
            var receivedPaymentDiscount: SKPaymentDiscount?
            var receivedError: Error? = nil
            self.purchases?.paymentDiscount(forProductDiscount: productDiscount,
                                            product: product,
                                            completion: { (paymentDiscount, error) in
                receivedPaymentDiscount = paymentDiscount
                completionCalled = true
                receivedError = error
            })

            expect(self.receiptFetcher.receiptDataCalled).toEventually(beTrue())
            expect(receivedPaymentDiscount).to(beNil())
            expect(completionCalled).toEventually(beTrue())
            expect(self.backend.postOfferForSigningCalled) == false
            expect((receivedError! as NSError).code) == ErrorCode.missingReceiptFileError.rawValue
        }
    }

    func testAttributionDataIsPostponedIfThereIsNoInstance() {
        let data = ["yo" : "dog", "what" : 45, "is" : ["up"]] as [String : Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: AttributionNetwork.appsFlyer)

        setupPurchases()

        let invokedParameters = self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParameters
        expect(invokedParameters?.attributionData).toNot(beNil())

        for key in data.keys {
            expect(invokedParameters?.attributionData.keys.contains(key)).toEventually(beTrue())
        }

        expect(invokedParameters?.attributionData.keys.contains("rc_idfa")) == true
        expect(invokedParameters?.attributionData.keys.contains("rc_idfv")) == true
        expect(invokedParameters?.network) == AttributionNetwork.appsFlyer
        expect(invokedParameters?.appUserID) == self.purchases?.appUserID
    }

    func testAttributionDataSendsNetworkAppUserId() {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, from: AttributionNetwork.appleSearchAds, forNetworkUserId: "newuser")

        setupPurchases()

        expect(self.backend.invokedPostAttributionData).toEventually(beTrue())
        for key in data.keys {
            expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains(key)).to(beTrue())
        }

        expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains("rc_idfa")) == true
        expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains("rc_idfv")) == true
        expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains("rc_attribution_network_id")) == true
        expect(self.backend.invokedPostAttributionDataParameters?.data?["rc_attribution_network_id"] as? String) == "newuser"
        expect(self.backend.invokedPostAttributionDataParameters?.network) == AttributionNetwork.appleSearchAds
        expect(self.backend.invokedPostAttributionDataParameters?.appUserID) == identityManager.currentAppUserID
    }

    func testAttributionDataDontSendNetworkAppUserIdIfNotProvided() {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: AttributionNetwork.appleSearchAds)

        setupPurchases()

        for key in data.keys {
            expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains(key)) == true
        }

        expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains("rc_idfa")) == true
        expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains("rc_idfv")) == true
        expect(self.backend.invokedPostAttributionDataParameters?.data?.keys.contains("rc_attribution_network_id")) == false
        expect(self.backend.invokedPostAttributionDataParameters?.network) == AttributionNetwork.appleSearchAds
        expect(self.backend.invokedPostAttributionDataParameters?.appUserID) == identityManager.currentAppUserID
    }

    func testAdClientAttributionDataIsAutomaticallyCollected() {
        setupPurchases(automaticCollection: true)
        expect(self.backend.invokedPostAttributionDataParameters).toNot(beNil())
        expect(self.backend.invokedPostAttributionDataParameters?.network) == AttributionNetwork.appleSearchAds
        expect((self.backend.invokedPostAttributionDataParameters?.data?["Version3.1"] as! NSDictionary)["iad-campaign-id"]).toNot(beNil())
    }

    func testAdClientAttributionDataIsNotAutomaticallyCollectedIfDisabled() {
        setupPurchases(automaticCollection: false)
        expect(self.backend.invokedPostAttributionDataParameters).to(beNil())
    }

    func testAttributionDataPostponesMultiple() {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, from: AttributionNetwork.adjust, forNetworkUserId: "newuser")

        setupPurchases(automaticCollection: true)
        expect(self.backend.invokedPostAttributionDataParametersList.count) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParametersList.count) == 1
    }

    func testObserverModeSetToFalseSetFinishTransactions() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testDoesntFinishTransactionsIfObserverModeIsSet() {
        setupPurchasesObserverModeOn()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testRestoredPurchasesArePosted() {
        setupPurchasesObserverModeOn()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

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
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
            receivedError = error
        }

        expect(receivedError).toNot(beNil())
    }

    func testNoCrashIfPaymentIsMissing() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
        }

        let transaction = SKPaymentTransaction()

        transaction.setValue(SKPaymentTransactionState.purchasing.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.setValue(SKPaymentTransactionState.purchased.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
    }
    
    func testNoCrashIfPaymentDoesNotHaveProductIdenfier() {
        setupPurchases()

        let transaction = MockTransaction()
        transaction.mockPayment = SKPayment()

        transaction.setValue(SKPaymentTransactionState.purchasing.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        
        transaction.setValue(SKPaymentTransactionState.purchased.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
    }

    func testPostsOfferingIfPurchasingPackage() {
        setupPurchases()
        mockOfferingsManager.stubbedOfferingsCompletionResult = (offeringsFactory.createOfferings(withProducts: [:], data: [:]), nil)
        self.purchases!.getOfferings { (newOfferings, _) in
            let package = newOfferings!["base"]!.monthly!
            self.purchases!.purchase(package: package) { (tx, info, error, userCancelled) in

            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)

            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            expect(self.backend.postReceiptDataCalled).to(beTrue())
            expect(self.backend.postedReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(package.product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(package.product.price))
            expect(self.backend.postedOfferingIdentifier).to(equal("base"))
            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testRetrievingDiscountMissingSubscriptionGroupIdentifierErrors() {
        if #available(iOS 12.2, tvOS 12.2, macOS 10.14.4, *) {
            setupPurchases()
            var receivedError: NSError? = nil
            var receivedPaymentDiscount: SKPaymentDiscount? = nil
            let product = MockSKProduct(mockProductIdentifier: "Tacos_with_free_guac")
            let discount = MockDiscount()

            purchases.paymentDiscount(forProductDiscount: discount, product: product) { discount, error in
                receivedError = error as NSError?
                receivedPaymentDiscount = discount
            }
            expect(receivedPaymentDiscount).to(beNil())
            expect(receivedError?.code)
                .to(equal(ErrorCode.productDiscountMissingSubscriptionGroupIdentifierError.rawValue))
        }
    }

    func testPurchasingPackageDoesntThrowPurchaseAlreadyInProgressIfCallbackMakesANewPurchase() {
        setupPurchases()
        var receivedError: NSError? = nil
        var secondCompletionCalled = false
        mockOfferingsManager.stubbedOfferingsCompletionResult = (offeringsFactory.createOfferings(withProducts: [:], data: [:]), nil)
        self.purchases!.getOfferings { (newOfferings, _) in
            let package = newOfferings!["base"]!.monthly!
            self.purchases!.purchase(package: package) { _,_,_,_  in
                self.purchases!.purchase(package: package) { (tx, info, error, userCancelled) in
                    receivedError = error as NSError?
                    secondCompletionCalled = true
                }
            }

            self.performTransaction()
            self.performTransaction()
        }
        expect(secondCompletionCalled).toEventually(beTrue(), timeout: .seconds(10))
        expect(receivedError).to(beNil())
    }

    func performTransaction() {
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        self.backend.postReceiptCustomerInfo = CustomerInfo(data: self.emptyCustomerInfoData)
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
    }

    func testFetchCustomerInfoWhenCacheStale() {
        setupPurchases()
        self.deviceCache.stubbedIsCustomerInfoCacheStale = true

        self.purchases?.getCustomerInfo() { (info, error) in

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
        self.mockProductsManager.stubbedProductsCompletionResult = Set<SKProduct>()
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "product")

        let customerInfoBeforePurchase = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [:]
            ]])
        let customerInfoAfterPurchase = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [product.mockProductIdentifier: []]
            ]])
        self.backend.overrideCustomerInfo = customerInfoBeforePurchase
        self.backend.postReceiptCustomerInfo = customerInfoAfterPurchase

        let payment = SKPayment(product: product)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testReceiptsSendsObserverModeWhenObserverMode() {
        setupPurchasesObserverModeOn()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

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
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in

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

    func testInvalidateCustomerInfoCacheRemovesCachedCustomerInfo() {
        setupPurchases()
        guard let nonOptionalPurchases = purchases else { fatalError("failed when setting up purchases for testing") }
        let appUserID = identityManager.currentAppUserID
        self.deviceCache.cache(customerInfo: Data(), appUserID: appUserID)
        expect(self.deviceCache.cachedCustomerInfoData(appUserID: appUserID)).toNot(beNil())
        expect(self.deviceCache.invokedClearCustomerInfoCacheCount) == 0

        nonOptionalPurchases.invalidateCustomerInfoCache()
        expect(self.deviceCache.cachedCustomerInfoData(appUserID: appUserID)).to(beNil())
        expect(self.deviceCache.invokedClearCustomerInfoCacheCount) == 1
    }

    func testGetCustomerInfoAfterInvalidatingDoesntReturnCachedVersion() {
        setupPurchases()
        guard let nonOptionalPurchases = purchases else { fatalError("failed when setting up purchases for testing") }

        let appUserID = identityManager.currentAppUserID
        let oldAppUserInfo = Data()
        self.deviceCache.cache(customerInfo: oldAppUserInfo, appUserID: appUserID)
        let overrideCustomerInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        self.backend.overrideCustomerInfo = overrideCustomerInfo

        var receivedCustomerInfo: CustomerInfo? = nil
        var completionCallCount = 0
        var receivedError: Error? = nil
        nonOptionalPurchases.getCustomerInfo { (customerInfo, error) in
            completionCallCount += 1
            receivedError = error
            receivedCustomerInfo = customerInfo
        }

        nonOptionalPurchases.invalidateCustomerInfoCache()

        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).to(beNil())
        expect(receivedCustomerInfo) == overrideCustomerInfo
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 1
    }

    func testGetCustomerInfoAfterInvalidatingCallsCompletionWithErrorIfBackendError() {
        let backendError = ErrorUtils.backendError(withBackendCode: .invalidAPIKey,
                                                   backendMessage: "Invalid credentials",
                                                   finishable: true)
        self.backend.overrideCustomerInfoError = backendError
        self.backend.overrideCustomerInfo = nil

        setupPurchases()
        guard let nonOptionalPurchases = purchases else { fatalError("failed when setting up purchases for testing") }
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 0

        let appUserID = identityManager.currentAppUserID
        let oldAppUserInfo = Data()
        self.deviceCache.cache(customerInfo: oldAppUserInfo, appUserID: appUserID)


        var receivedCustomerInfo: CustomerInfo? = nil
        var completionCallCount = 0
        var receivedError: Error? = nil
        nonOptionalPurchases.getCustomerInfo { (customerInfo, error) in
            completionCallCount += 1
            receivedError = error
            receivedCustomerInfo = customerInfo
        }

        nonOptionalPurchases.invalidateCustomerInfoCache()

        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())
        expect(receivedCustomerInfo).to(beNil())
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 0
    }

    func testInvalidateCustomerInfoCacheDoesntClearOfferingsCache() {
        setupPurchases()
        guard let nonOptionalPurchases = purchases else { fatalError("failed when setting up purchases for testing") }

        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0

        nonOptionalPurchases.invalidateCustomerInfoCache()
        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0
    }

    func testProxyURL() {
        expect(SystemInfo.proxyURL).to(beNil())
        let defaultHostURL = URL(string: "https://api.revenuecat.com")
        expect(SystemInfo.serverHostURL) == defaultHostURL

        let testURL = URL(string: "https://test_url")
        Purchases.proxyURL = testURL

        expect(SystemInfo.serverHostURL) == testURL

        Purchases.proxyURL = nil

        expect(SystemInfo.serverHostURL) == defaultHostURL
    }

    func testNotifiesIfTransactionIsDeferredFromStoreKit() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        var receivedError: NSError?
        self.purchases?.purchase(product: product) { (tx, info, error, userCancelled) in
            receivedError = error as NSError?
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.deferred
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beFalse())
        expect(self.storeKitWrapper.finishCalled).to(beFalse())
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.paymentPendingError.rawValue))
    }


    func testSyncsPurchasesIfEntitlementsRevokedForProductIDs() {
        if #available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            setupPurchases()
            guard let _ = purchases else { fatalError() }
            expect(self.backend.postReceiptDataCalled).to(beFalse())
            (purchasesOrchestrator as StoreKitWrapperDelegate)
                .storeKitWrapper(storeKitWrapper, didRevokeEntitlementsForProductIdentifiers: ["a", "b"])
            expect(self.backend.postReceiptDataCalled).to(beTrue())
        }
    }

    @available(*, deprecated) // Ignore deprecation warnings
    func testSetDebugLogsEnabledSetsTheCorrectValue() {
        Logger.logLevel = .warn

        Purchases.debugLogsEnabled = true
        expect(Logger.logLevel) == .debug

        Purchases.debugLogsEnabled = false
        expect(Logger.logLevel) == .info
    }


    private func verifyUpdatedCaches(newAppUserID: String) {
        let expectedCallCount = 2
        expect(self.backend.getSubscriberCallCount).toEventually(equal(expectedCallCount))
        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(expectedCallCount))
        expect(self.deviceCache.cachedCustomerInfo[newAppUserID]).toEventuallyNot(beNil())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(expectedCallCount))
        expect(self.deviceCache.setCustomerInfoCacheTimestampToNowCount).toEventually(equal(expectedCallCount))
        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(expectedCallCount))
    }

}
