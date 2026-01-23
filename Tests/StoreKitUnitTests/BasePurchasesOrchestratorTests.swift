//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BasePurchasesOrchestratorTests.swift
//
//  Created by Andrés Boedo on 1/9/21.

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class BasePurchasesOrchestratorTests: StoreKitConfigTestCase {

    var productsManager: MockProductsManager!
    var purchasedProductsFetcher: MockPurchasedProductsFetcher!
    var storeKit1Wrapper: MockStoreKit1Wrapper!
    var systemInfo: MockSystemInfo!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    var attribution: Attribution!
    var attributionFetcher: MockAttributionFetcher!
    var operationDispatcher: MockOperationDispatcher!
    var receiptFetcher: MockReceiptFetcher!
    var receiptParser: MockReceiptParser!
    var customerInfoManager: MockCustomerInfoManager!
    var paymentQueueWrapper: EitherPaymentQueueWrapper!
    var mockSimulatedStorePurchaseHandler: MockSimulatedStorePurchaseHandler!
    var backend: MockBackend!
    var offerings: MockOfferingsAPI!
    var currentUserProvider: MockCurrentUserProvider!
    var transactionsManager: MockTransactionsManager!
    var notificationCenter: MockNotificationCenter!
    var deviceCache: MockDeviceCache!
    var mockManageSubsHelper: MockManageSubscriptionsHelper!
    var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!
    var mockOfferingsManager: MockOfferingsManager!
    var mockStoreMessagesHelper: MockStoreMessagesHelper!
    var mockWinBackOfferEligibilityCalculator: MockWinBackOfferEligibilityCalculator!
    var mockTransactionFetcher: MockStoreKit2TransactionFetcher!
    private var eventsManager: EventsManagerType!
    var webPurchaseRedemptionHelper: MockWebPurchaseRedemptionHelper!
    var mockDiagnosticsTracker: DiagnosticsTrackerType!
    var mockLocalTransactionMetadataStore: MockLocalTransactionMetadataStore!

    static let eventTimestamp1: Date = .init(timeIntervalSince1970: 1694029328)
    static let eventTimestamp2: Date = .init(timeIntervalSince1970: 1694022321)
    var mockDateProvider = MockDateProvider(stubbedNow: eventTimestamp1,
                                            subsequentNows: eventTimestamp2)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var mockEventsManager: MockEventsManager {
        get throws {
            return try XCTUnwrap(self.eventsManager as? MockEventsManager)
        }
    }

    var orchestrator: PurchasesOrchestrator!

    static let mockUserID = "appUserID"

    class var storeKitVersion: StoreKitVersion { return .default }

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setUpSystemInfo()

        self.productsManager = MockProductsManager(diagnosticsTracker: nil,
                                                   systemInfo: self.systemInfo,
                                                   requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.purchasedProductsFetcher = .init()
        self.operationDispatcher = MockOperationDispatcher()
        self.receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: self.systemInfo)
        self.mockTransactionFetcher = MockStoreKit2TransactionFetcher()
        self.receiptParser = MockReceiptParser()
        self.deviceCache = MockDeviceCache(systemInfo: self.systemInfo)
        self.backend = MockBackend()
        self.offerings = try XCTUnwrap(self.backend.offerings as? MockOfferingsAPI)
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            self.eventsManager = MockEventsManager()
            self.mockDiagnosticsTracker = MockDiagnosticsTracker()
        } else {
            self.eventsManager = nil
            self.mockDiagnosticsTracker = nil
        }

        self.mockOfferingsManager = MockOfferingsManager(deviceCache: self.deviceCache,
                                                         operationDispatcher: self.operationDispatcher,
                                                         systemInfo: self.systemInfo,
                                                         backend: self.backend,
                                                         offeringsFactory: OfferingsFactory(),
                                                         productsManager: self.productsManager,
                                                         diagnosticsTracker: self.mockDiagnosticsTracker)
        self.setUpStoreKit1Wrapper()
        self.mockSimulatedStorePurchaseHandler = MockSimulatedStorePurchaseHandler()
        self.mockLocalTransactionMetadataStore = MockLocalTransactionMetadataStore()

        self.customerInfoManager = MockCustomerInfoManager(
            offlineEntitlementsManager: MockOfflineEntitlementsManager(),
            operationDispatcher: OperationDispatcher(),
            deviceCache: self.deviceCache,
            backend: self.backend,
            transactionFetcher: MockStoreKit2TransactionFetcher(),
            transactionPoster: self.transactionPoster,
            systemInfo: self.systemInfo
        )
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: Self.mockUserID)
        self.transactionsManager = MockTransactionsManager(receiptParser: MockReceiptParser())
        self.attributionFetcher = MockAttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                         systemInfo: self.systemInfo)
        self.subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.backend,
            deviceCache: self.deviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: self.attributionFetcher,
            attributionDataMigrator: MockAttributionDataMigrator())
        self.mockManageSubsHelper = MockManageSubscriptionsHelper(systemInfo: self.systemInfo,
                                                                  customerInfoManager: self.customerInfoManager,
                                                                  currentUserProvider: self.currentUserProvider)
        self.mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: self.systemInfo,
                                                                         customerInfoManager: self.customerInfoManager,
                                                                         currentUserProvider: self.currentUserProvider)
        self.mockStoreMessagesHelper = .init()
        self.mockWinBackOfferEligibilityCalculator = MockWinBackOfferEligibilityCalculator()
        self.mockTransactionFetcher = MockStoreKit2TransactionFetcher()
        self.notificationCenter = MockNotificationCenter()
        let identityManager = MockIdentityManager(mockAppUserID: "test-user-id",
                                                  mockDeviceCache: self.deviceCache)
        self.webPurchaseRedemptionHelper = MockWebPurchaseRedemptionHelper()
        self.setUpStoreKit1Wrapper()
        self.setUpAttribution()
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

    }

    func setUpStoreKit2Listener() {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self.orchestrator._storeKit2TransactionListener = MockStoreKit2TransactionListener()
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var mockStoreKit2TransactionListener: MockStoreKit2TransactionListener? {
        return self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
    }

    func setUpSystemInfo(
        finishTransactions: Bool = true
    ) {
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "1.2.3")

        self.systemInfo = .init(platformInfo: platformInfo,
                                finishTransactions: finishTransactions,
                                storeKitVersion: Self.storeKitVersion)
        self.systemInfo.stubbedIsSandbox = true
    }

    func setUpStoreKit1Wrapper() {
        self.storeKit1Wrapper = MockStoreKit1Wrapper(observerMode: self.systemInfo.observerMode)
        self.storeKit1Wrapper.mockAddPaymentTransactionState = .purchased
        self.storeKit1Wrapper.mockCallUpdatedTransactionInstantly = true

        self.paymentQueueWrapper = .left(self.storeKit1Wrapper)
    }

    func setUpAttribution() {
        let attributionPoster = AttributionPoster(deviceCache: self.deviceCache,
                                                  currentUserProvider: self.currentUserProvider,
                                                  backend: self.backend,
                                                  attributionFetcher: self.attributionFetcher,
                                                  subscriberAttributesManager: self.subscriberAttributesManager,
                                                  systemInfo: self.systemInfo)

        self.attribution = Attribution(subscriberAttributesManager: self.subscriberAttributesManager,
                                       currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.mockUserID),
                                       attributionPoster: attributionPoster,
                                       systemInfo: self.systemInfo)
    }

    func setUpOrchestrator() {
        self.orchestrator = PurchasesOrchestrator(
            productsManager: self.productsManager,
            paymentQueueWrapper: self.paymentQueueWrapper,
            simulatedStorePurchaseHandler: self.mockSimulatedStorePurchaseHandler,
            systemInfo: self.systemInfo,
            subscriberAttributes: self.attribution,
            operationDispatcher: self.operationDispatcher,
            receiptFetcher: self.receiptFetcher,
            receiptParser: self.receiptParser,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.customerInfoManager,
            backend: self.backend,
            transactionPoster: self.transactionPoster,
            currentUserProvider: self.currentUserProvider,
            transactionsManager: self.transactionsManager,
            deviceCache: self.deviceCache,
            offeringsManager: self.mockOfferingsManager,
            manageSubscriptionsHelper: self.mockManageSubsHelper,
            beginRefundRequestHelper: self.mockBeginRefundRequestHelper,
            storeMessagesHelper: self.mockStoreMessagesHelper,
            diagnosticsTracker: self.mockDiagnosticsTracker,
            winBackOfferEligibilityCalculator: self.mockWinBackOfferEligibilityCalculator,
            eventsManager: self.eventsManager,
            webPurchaseRedemptionHelper: self.webPurchaseRedemptionHelper)
        self.storeKit1Wrapper.delegate = self.orchestrator
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func setUpOrchestrator(
        storeKit2TransactionListener: StoreKit2TransactionListenerType,
        storeKit2StorefrontListener: StoreKit2StorefrontListener,
        storeKit2ObserverModePurchaseDetector: StoreKit2ObserverModePurchaseDetectorType,
        diagnosticsSynchronizer: DiagnosticsSynchronizerType? = nil,
        diagnosticsTracker: DiagnosticsTrackerType? = nil
    ) {
        self.orchestrator = PurchasesOrchestrator(
            productsManager: self.productsManager,
            paymentQueueWrapper: self.paymentQueueWrapper,
            simulatedStorePurchaseHandler: self.mockSimulatedStorePurchaseHandler,
            systemInfo: self.systemInfo,
            subscriberAttributes: self.attribution,
            operationDispatcher: self.operationDispatcher,
            receiptFetcher: self.receiptFetcher,
            receiptParser: self.receiptParser,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.customerInfoManager,
            backend: self.backend,
            transactionPoster: self.transactionPoster,
            currentUserProvider: self.currentUserProvider,
            transactionsManager: self.transactionsManager,
            deviceCache: self.deviceCache,
            offeringsManager: self.mockOfferingsManager,
            manageSubscriptionsHelper: self.mockManageSubsHelper,
            beginRefundRequestHelper: self.mockBeginRefundRequestHelper,
            storeKit2TransactionListener: storeKit2TransactionListener,
            storeKit2StorefrontListener: storeKit2StorefrontListener,
            storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchaseDetector,
            storeMessagesHelper: self.mockStoreMessagesHelper,
            diagnosticsSynchronizer: diagnosticsSynchronizer,
            diagnosticsTracker: diagnosticsTracker,
            winBackOfferEligibilityCalculator: self.mockWinBackOfferEligibilityCalculator,
            eventsManager: self.eventsManager,
            webPurchaseRedemptionHelper: self.webPurchaseRedemptionHelper,
            dateProvider: self.mockDateProvider
        )
        self.storeKit1Wrapper.delegate = self.orchestrator
    }

    var transactionPoster: TransactionPoster {
        return .init(
            productsManager: self.productsManager,
            receiptFetcher: self.receiptFetcher,
            transactionFetcher: self.mockTransactionFetcher,
            backend: self.backend,
            paymentQueueWrapper: self.paymentQueueWrapper,
            systemInfo: self.systemInfo,
            operationDispatcher: self.operationDispatcher,
            localTransactionMetadataStore: self.mockLocalTransactionMetadataStore
        )
    }
}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
extension BasePurchasesOrchestratorTests {

    func fetchSk1Product(_ productID: String = StoreKitConfigTestCase.productID) async throws -> SK1Product {
        return MockSK1Product(
            mockProductIdentifier: productID,
            mockSubscriptionGroupIdentifier: "group1"
        )
    }

    func fetchSk1StoreProduct() async throws -> SK1StoreProduct {
        return try await SK1StoreProduct(sk1Product: fetchSk1Product())
    }

    var mockCustomerInfo: CustomerInfo { .emptyInfo }

    static let testProduct = TestStoreProduct(
        localizedTitle: "Product",
        price: 3.99,
        currencyCode: "USD",
        localizedPriceString: "$3.99",
        productIdentifier: "product",
        productType: .autoRenewableSubscription,
        localizedDescription: "Description",
        locale: Locale(identifier: "en_US")
    ).toStoreProduct()

    static let paywallEventCreationData: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    /// A paywall event creation data with a date far in the future (year 2050)
    /// Used to test that transactions purchased BEFORE the paywall event are not attributed
    static let paywallEventCreationDataInFuture: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 2524608000) // January 1, 2050
    )

    static let paywallEvent: PaywallEvent.Data = .init(
        paywallIdentifier: "test_paywall_id",
        offeringIdentifier: "offering",
        paywallRevision: 5,
        sessionID: .init(),
        displayMode: .fullScreen,
        localeIdentifier: "en_US",
        darkMode: true
    )

    static let testPackageId = "test_package"
    static let testProductId = StoreKitConfigTestCase.productID
    static let testDifferentProductId = "different_product_id"
    static let testErrorCode = 12
    static let testErrorMessage = "Test error message"

    static var paywallEventWithPurchaseInfo: PaywallEvent.Data {
        return paywallEvent.withPurchaseInfo(
            packageId: testPackageId,
            productId: testProductId,
            errorCode: nil,
            errorMessage: nil
        )
    }

    static var paywallEventForPurchaseError: PaywallEvent.Data {
        return paywallEvent.withPurchaseInfo(
            packageId: testPackageId,
            productId: testProductId,
            errorCode: testErrorCode,
            errorMessage: testErrorMessage
        )
    }

    static var paywallEventWithDifferentProductId: PaywallEvent.Data {
        return paywallEvent.withPurchaseInfo(
            packageId: testPackageId,
            productId: testDifferentProductId,
            errorCode: nil,
            errorMessage: nil
        )
    }

}
