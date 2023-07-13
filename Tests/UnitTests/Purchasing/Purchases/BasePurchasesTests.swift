//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BasePurchasesTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@MainActor
class BasePurchasesTests: TestCase {

    private static let userDefaultsSuiteName = "TestDefaults"

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.storeKit1Wrapper = MockStoreKit1Wrapper()
        self.notificationCenter = MockNotificationCenter()
        self.purchasesDelegate = MockPurchasesDelegate()

        self.mockPaymentQueueWrapper = MockPaymentQueueWrapper()

        self.userDefaults = UserDefaults(suiteName: Self.userDefaultsSuiteName)
        self.systemInfo = MockSystemInfo(finishTransactions: true, storeKit2Setting: self.storeKit2Setting)
        self.deviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.systemInfo,
                                           userDefaults: self.userDefaults)
        self.requestFetcher = MockRequestFetcher()
        self.mockProductsManager = MockProductsManager(systemInfo: self.systemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.mockReceiptParser = MockReceiptParser()
        self.identityManager = MockIdentityManager(mockAppUserID: Self.appUserID)
        self.mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: self.mockProductsManager,
                                                                             receiptParser: self.mockReceiptParser)
        let platformInfo = Purchases.PlatformInfo(flavor: "iOS", version: "4.4.0")
        let systemInfoAttribution = MockSystemInfo(platformInfo: platformInfo, finishTransactions: true)
        self.receiptFetcher = MockReceiptFetcher(requestFetcher: self.requestFetcher, systemInfo: systemInfoAttribution)
        self.attributionFetcher = MockAttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                         systemInfo: systemInfoAttribution)
        self.mockProductEntitlementMappingFetcher = MockProductEntitlementMappingFetcher()
        self.mockPurchasedProductsFetcher = MockPurchasedProductsFetcher()
        self.mockTransactionFetcher = MockStoreKit2TransactionFetcher()

        let apiKey = "mockAPIKey"
        let httpClient = MockHTTPClient(apiKey: apiKey, systemInfo: self.systemInfo, eTagManager: MockETagManager())
        let config = BackendConfiguration(httpClient: httpClient,
                                          operationDispatcher: self.mockOperationDispatcher,
                                          operationQueue: MockBackend.QueueProvider.createBackendQueue(),
                                          systemInfo: self.systemInfo,
                                          offlineCustomerInfoCreator: MockOfflineCustomerInfoCreator(),
                                          dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate))
        self.backend = MockBackend(backendConfig: config, attributionFetcher: self.attributionFetcher)
        self.subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.backend,
            deviceCache: self.deviceCache,
            operationDispatcher: self.mockOperationDispatcher,
            attributionFetcher: self.attributionFetcher,
            attributionDataMigrator: AttributionDataMigrator()
        )
        self.attributionPoster = AttributionPoster(deviceCache: self.deviceCache,
                                                   currentUserProvider: self.identityManager,
                                                   backend: self.backend,
                                                   attributionFetcher: self.attributionFetcher,
                                                   subscriberAttributesManager: self.subscriberAttributesManager)
        self.attribution = Attribution(subscriberAttributesManager: self.subscriberAttributesManager,
                                       currentUserProvider: self.identityManager,
                                       attributionPoster: self.attributionPoster,
                                       systemInfo: self.systemInfo)
        self.mockOfflineEntitlementsManager = MockOfflineEntitlementsManager()
        self.customerInfoManager = CustomerInfoManager(offlineEntitlementsManager: self.mockOfflineEntitlementsManager,
                                                       operationDispatcher: self.mockOperationDispatcher,
                                                       deviceCache: self.deviceCache,
                                                       backend: self.backend,
                                                       transactionFetcher: self.mockTransactionFetcher,
                                                       transactionPoster: self.transactionPoster,
                                                       systemInfo: self.systemInfo)
        self.mockOfferingsManager = MockOfferingsManager(deviceCache: self.deviceCache,
                                                         operationDispatcher: self.mockOperationDispatcher,
                                                         systemInfo: self.systemInfo,
                                                         backend: self.backend,
                                                         offeringsFactory: self.offeringsFactory,
                                                         productsManager: self.mockProductsManager)
        self.mockManageSubsHelper = MockManageSubscriptionsHelper(systemInfo: self.systemInfo,
                                                                  customerInfoManager: self.customerInfoManager,
                                                                  currentUserProvider: self.identityManager)
        self.mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: self.systemInfo,
                                                                         customerInfoManager: self.customerInfoManager,
                                                                         currentUserProvider: self.identityManager)
        self.mockTransactionsManager = MockTransactionsManager(receiptParser: self.mockReceiptParser)

        // Some tests rely on the level being at least `.debug`
        // Because unit tests can run in parallel, if a test needs to modify
        // this level it should be moved to `StoreKitUnitTests`, which runs serially.
        Purchases.logLevel = .verbose

        self.addTeardownBlock {
            weak var purchases = self.purchases
            weak var orchestrator = self.purchasesOrchestrator
            weak var deviceCache = self.deviceCache

            Purchases.clearSingleton()
            self.clearReferences()

            // Note: this captures the boolean to avoid race conditions when Nimble tries
            // to print the instances while they're being deallocated.
            expect { purchases == nil }
                .toEventually(beTrue(), description: "Purchases has leaked")
            expect { orchestrator == nil }
                .toEventually(beTrue(), description: "PurchasesOrchestrator has leaked")
            expect { deviceCache == nil }
                .toEventually(beTrue(), description: "DeviceCache has leaked")
        }
    }

    override func tearDown() {
        self.userDefaults.removePersistentDomain(forName: Self.userDefaultsSuiteName)

        super.tearDown()
    }

    var receiptFetcher: MockReceiptFetcher!
    var requestFetcher: MockRequestFetcher!
    var mockProductsManager: MockProductsManager!
    var backend: MockBackend!
    var storeKit1Wrapper: MockStoreKit1Wrapper!
    var mockPaymentQueueWrapper: MockPaymentQueueWrapper!
    var notificationCenter: MockNotificationCenter!
    var userDefaults: UserDefaults! = nil
    let offeringsFactory = MockOfferingsFactory()
    var deviceCache: MockDeviceCache!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    var attribution: Attribution!
    var identityManager: MockIdentityManager!
    var systemInfo: MockSystemInfo!
    var mockOperationDispatcher: MockOperationDispatcher!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockReceiptParser: MockReceiptParser!
    var mockTransactionsManager: MockTransactionsManager!
    var attributionFetcher: MockAttributionFetcher!
    var attributionPoster: AttributionPoster!
    var customerInfoManager: CustomerInfoManager!
    var mockOfferingsManager: MockOfferingsManager!
    var mockOfflineEntitlementsManager: MockOfflineEntitlementsManager!
    var mockProductEntitlementMappingFetcher: MockProductEntitlementMappingFetcher!
    var mockPurchasedProductsFetcher: MockPurchasedProductsFetcher!
    var mockTransactionFetcher: MockStoreKit2TransactionFetcher!
    var purchasesOrchestrator: PurchasesOrchestrator!
    var trialOrIntroPriceEligibilityChecker: MockTrialOrIntroPriceEligibilityChecker!
    var cachingTrialOrIntroPriceEligibilityChecker: MockCachingTrialOrIntroPriceEligibilityChecker!
    var mockManageSubsHelper: MockManageSubscriptionsHelper!
    var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!

    // swiftlint:disable:next weak_delegate
    var purchasesDelegate: MockPurchasesDelegate!

    var purchases: Purchases!

    private var paymentQueueWrapper: EitherPaymentQueueWrapper {
        // Note: this logic must match `Purchases`.
        return self.systemInfo.storeKit2Setting.shouldOnlyUseStoreKit2
            ? .right(self.mockPaymentQueueWrapper)
            : .left(self.storeKit1Wrapper)
    }

    private var transactionPoster: TransactionPoster {
        return .init(
            productsManager: self.mockProductsManager,
            receiptFetcher: self.receiptFetcher,
            backend: self.backend,
            paymentQueueWrapper: self.paymentQueueWrapper,
            systemInfo: self.systemInfo,
            operationDispatcher: self.mockOperationDispatcher
        )
    }

    func setupPurchases(automaticCollection: Bool = false, withDelegate: Bool = true) {
        Purchases.deprecated.automaticAppleSearchAdsAttributionCollection = automaticCollection
        self.identityManager.mockIsAnonymous = false

        self.initializePurchasesInstance(
            appUserId: self.identityManager.currentAppUserID,
            withDelegate: withDelegate
        )
    }

    func setupAnonPurchases() {
        Purchases.deprecated.automaticAppleSearchAdsAttributionCollection = false
        self.identityManager.mockIsAnonymous = true
        self.initializePurchasesInstance(appUserId: nil)
    }

    func setUpPurchasesObserverModeOn() {
        self.systemInfo = MockSystemInfo(platformInfo: nil,
                                         finishTransactions: false,
                                         storeKit2Setting: self.storeKit2Setting)
        self.initializePurchasesInstance(appUserId: nil)
    }

    func initializePurchasesInstance(appUserId: String?, withDelegate: Bool = true) {

        self.purchasesOrchestrator = PurchasesOrchestrator(
            productsManager: self.mockProductsManager,
            paymentQueueWrapper: self.paymentQueueWrapper,
            systemInfo: self.systemInfo,
            subscriberAttributes: self.attribution,
            operationDispatcher: self.mockOperationDispatcher,
            receiptFetcher: self.receiptFetcher,
            receiptParser: self.mockReceiptParser,
            customerInfoManager: self.customerInfoManager,
            backend: self.backend,
            transactionPoster: self.transactionPoster,
            currentUserProvider: self.identityManager,
            transactionsManager: self.mockTransactionsManager,
            deviceCache: self.deviceCache,
            offeringsManager: self.mockOfferingsManager,
            manageSubscriptionsHelper: self.mockManageSubsHelper,
            beginRefundRequestHelper: self.mockBeginRefundRequestHelper
        )
        self.trialOrIntroPriceEligibilityChecker = MockTrialOrIntroPriceEligibilityChecker(
            systemInfo: self.systemInfo,
            receiptFetcher: self.receiptFetcher,
            introEligibilityCalculator: self.mockIntroEligibilityCalculator,
            backend: self.backend,
            currentUserProvider: self.identityManager,
            operationDispatcher: self.mockOperationDispatcher,
            productsManager: self.mockProductsManager
        )
        self.cachingTrialOrIntroPriceEligibilityChecker = .init(checker: self.trialOrIntroPriceEligibilityChecker)

        self.purchases = Purchases(appUserID: appUserId,
                                   requestFetcher: self.requestFetcher,
                                   receiptFetcher: self.receiptFetcher,
                                   attributionFetcher: self.attributionFetcher,
                                   attributionPoster: self.attributionPoster,
                                   backend: self.backend,
                                   paymentQueueWrapper: paymentQueueWrapper,
                                   userDefaults: self.userDefaults,
                                   notificationCenter: self.notificationCenter,
                                   systemInfo: self.systemInfo,
                                   offeringsFactory: self.offeringsFactory,
                                   deviceCache: self.deviceCache,
                                   identityManager: self.identityManager,
                                   subscriberAttributes: self.attribution,
                                   operationDispatcher: self.mockOperationDispatcher,
                                   customerInfoManager: self.customerInfoManager,
                                   productsManager: self.mockProductsManager,
                                   offeringsManager: self.mockOfferingsManager,
                                   offlineEntitlementsManager: self.mockOfflineEntitlementsManager,
                                   purchasesOrchestrator: self.purchasesOrchestrator,
                                   purchasedProductsFetcher: self.mockPurchasedProductsFetcher,
                                   trialOrIntroPriceEligibilityChecker: self.cachingTrialOrIntroPriceEligibilityChecker)

        self.purchasesOrchestrator.delegate = self.purchases

        if withDelegate {
            self.purchases.delegate = self.purchasesDelegate
        }

        Purchases.setDefaultInstance(self.purchases)
    }

    func makeAPurchase() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))

        guard let purchases = self.purchases else { fatalError("purchases is not initialized") }
        purchases.purchase(product: product) { _, _, _, _ in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKit1Wrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)
    }

    var storeKit2Setting: StoreKit2Setting {
        // Even though the new default is StoreKit 2, most of the tests from this parent class
        // were written for SK1. Therefore we want to default to it being disabled.
        return .enabledOnlyForOptimizations
    }

}

extension BasePurchasesTests {

    static let appUserID = "app_user_id"

    static let emptyCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": BasePurchasesTests.appUserID,
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": NSNull()
        ] as [String: Any]
    ]

}

extension BasePurchasesTests {

    final class MockOfferingsAPI: OfferingsAPI {

        var postedProductIdentifiers: [String]?

        override func getIntroEligibility(appUserID: String,
                                          receiptData: Data,
                                          productIdentifiers: [String],
                                          completion: @escaping OfferingsAPI.IntroEligibilityResponseHandler) {
            self.postedProductIdentifiers = productIdentifiers

            var eligibilities = [String: IntroEligibility]()
            for productID in productIdentifiers {
                eligibilities[productID] = IntroEligibility(eligibilityStatus: .eligible)
            }

            completion(eligibilities, nil)
        }

        var failOfferings = false
        var badOfferingsResponse = false
        var gotOfferings = 0

        override func getOfferings(appUserID: String,
                                   withRandomDelay randomDelay: Bool,
                                   completion: @escaping OfferingsAPI.OfferingsResponseHandler) {
            self.gotOfferings += 1
            if self.failOfferings {
                completion(.failure(.unexpectedBackendResponse(.getOfferUnexpectedResponse)))
                return
            }
            if self.badOfferingsResponse {
                completion(.failure(.networkError(.decoding(CodableError.invalidJSONObject(value: [:]), Data()))))
                return
            }

            completion(.success(.mockResponse))
        }

        var postOfferForSigningCalled = false
        var postOfferForSigningPaymentDiscountResponse: Result<[String: Any], BackendError> = .success([:])

        override func post(offerIdForSigning offerIdentifier: String,
                           productIdentifier: String,
                           subscriptionGroup: String?,
                           receiptData: Data,
                           appUserID: String,
                           completion: @escaping OfferingsAPI.OfferSigningResponseHandler) {
            self.postOfferForSigningCalled = true

            completion(
                self.postOfferForSigningPaymentDiscountResponse.map {
                    (
                        // swiftlint:disable:next force_cast line_length
                        $0["signature"] as! String, $0["keyIdentifier"] as! String, $0["nonce"] as! UUID, $0["timestamp"] as! Int
                    )
                }
            )
        }

    }

    final class MockBackend: Backend {

        static let referenceDate = Date(timeIntervalSinceReferenceDate: 700000000) // 2023-03-08 20:26:40

        var userID: String?
        var originalApplicationVersion: String?
        var originalPurchaseDate: Date?
        var getCustomerInfoCallCount = 0
        var overrideCustomerInfoResult: Result<CustomerInfo, BackendError> = .success(
            // swiftlint:disable:next force_try
            try! CustomerInfo(data: BasePurchasesTests.emptyCustomerInfoData)
        )

        override func getCustomerInfo(appUserID: String,
                                      withRandomDelay randomDelay: Bool,
                                      allowComputingOffline: Bool,
                                      completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
            self.getCustomerInfoCallCount += 1
            self.userID = appUserID

            let result = self.overrideCustomerInfoResult
            DispatchQueue.main.async {
                completion(result)
            }
        }

        var postReceiptDataCalled = false
        var postedReceiptData: Data?
        var postedIsRestore: Bool?
        var postedProductID: String?
        var postedPrice: Decimal?
        var postedPaymentMode: StoreProductDiscount.PaymentMode?
        var postedIntroPrice: Decimal?
        var postedCurrencyCode: String?
        var postedSubscriptionGroup: String?
        var postedDiscounts: [StoreProductDiscount]?
        var postedOfferingIdentifier: String?
        var postedObserverMode: Bool?
        var postedInitiationSource: ProductRequestData.InitiationSource?
        var postReceiptResult: Result<CustomerInfo, BackendError>?

        override func post(receiptData: Data,
                           productData: ProductRequestData?,
                           transactionData: PurchasedTransactionData,
                           observerMode: Bool,
                           completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
            self.postReceiptDataCalled = true
            self.postedReceiptData = receiptData
            self.postedIsRestore = transactionData.source.isRestore

            if let productData = productData {
                self.postedProductID = productData.productIdentifier
                self.postedPrice = productData.price

                self.postedPaymentMode = productData.paymentMode
                self.postedIntroPrice = productData.introPrice
                self.postedSubscriptionGroup = productData.subscriptionGroup

                self.postedCurrencyCode = productData.currencyCode
                self.postedDiscounts = productData.discounts
            }

            self.postedOfferingIdentifier = transactionData.presentedOfferingID
            self.postedObserverMode = observerMode
            self.postedInitiationSource = transactionData.source.initiationSource

            completion(self.postReceiptResult ?? .failure(.missingAppUserID()))
        }

        var invokedPostAttributionData = false
        var invokedPostAttributionDataCount = 0
        var invokedPostAttributionDataParameters: (
            data: [String: Any]?,
            network: AttributionNetwork,
            appUserID: String?
        )?
        var invokedPostAttributionDataParametersList = [(data: [String: Any]?,
                                                         network: AttributionNetwork,
                                                         appUserID: String?)]()
        var stubbedPostAttributionDataCompletionResult: (BackendError?, Void)?

        override func post(attributionData: [String: Any],
                           network: AttributionNetwork,
                           appUserID: String,
                           completion: ((BackendError?) -> Void)? = nil) {
            self.invokedPostAttributionData = true
            self.invokedPostAttributionDataCount += 1
            self.invokedPostAttributionDataParameters = (attributionData, network, appUserID)
            self.invokedPostAttributionDataParametersList.append((attributionData, network, appUserID))
            if let result = stubbedPostAttributionDataCompletionResult {
                completion?(result.0)
            }
        }
    }
}

private extension BasePurchasesTests {

    func clearReferences() {
        self.mockOperationDispatcher = nil
        self.mockPaymentQueueWrapper = nil
        self.requestFetcher = nil
        self.receiptFetcher = nil
        self.mockProductsManager = nil
        self.mockIntroEligibilityCalculator = nil
        self.mockTransactionsManager = nil
        self.backend = nil
        self.attributionFetcher = nil
        self.purchasesDelegate.makeDeferredPurchase = nil
        self.purchasesDelegate = nil
        self.storeKit1Wrapper.delegate = nil
        self.storeKit1Wrapper = nil
        self.systemInfo = nil
        self.notificationCenter = nil
        self.subscriberAttributesManager = nil
        self.trialOrIntroPriceEligibilityChecker = nil
        self.attributionPoster = nil
        self.attribution = nil
        self.customerInfoManager = nil
        self.identityManager = nil
        self.mockOfferingsManager = nil
        self.mockOfflineEntitlementsManager = nil
        self.mockPurchasedProductsFetcher = nil
        self.mockTransactionFetcher = nil
        self.mockManageSubsHelper = nil
        self.mockBeginRefundRequestHelper = nil
        self.purchasesOrchestrator = nil
        self.deviceCache = nil
        self.purchases = nil
    }

}
