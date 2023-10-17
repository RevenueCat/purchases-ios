//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorTests.swift
//
//  Created by Andrés Boedo on 1/9/21.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class PurchasesOrchestratorTests: StoreKitConfigTestCase {

    private var productsManager: MockProductsManager!
    private var purchasedProductsFetcher: MockPurchasedProductsFetcher!
    private var storeKit1Wrapper: MockStoreKit1Wrapper!
    private var systemInfo: MockSystemInfo!
    private var subscriberAttributesManager: MockSubscriberAttributesManager!
    private var attribution: Attribution!
    private var attributionFetcher: MockAttributionFetcher!
    private var operationDispatcher: MockOperationDispatcher!
    private var receiptFetcher: MockReceiptFetcher!
    private var receiptParser: MockReceiptParser!
    private var customerInfoManager: MockCustomerInfoManager!
    private var paymentQueueWrapper: EitherPaymentQueueWrapper!
    private var backend: MockBackend!
    private var offerings: MockOfferingsAPI!
    private var currentUserProvider: MockCurrentUserProvider!
    private var transactionsManager: MockTransactionsManager!
    private var deviceCache: MockDeviceCache!
    private var mockManageSubsHelper: MockManageSubscriptionsHelper!
    private var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!
    private var mockOfferingsManager: MockOfferingsManager!
    private var mockStoreMessagesHelper: MockStoreMessagesHelper!
    private var mockTransactionFetcher: MockStoreKit2TransactionFetcher!

    private var orchestrator: PurchasesOrchestrator!

    private static let mockUserID = "appUserID"

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setUpSystemInfo()

        self.productsManager = MockProductsManager(systemInfo: self.systemInfo,
                                                   requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.purchasedProductsFetcher = .init()
        self.operationDispatcher = MockOperationDispatcher()
        self.receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: self.systemInfo)
        self.receiptParser = MockReceiptParser()
        self.deviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.systemInfo)
        self.backend = MockBackend()
        self.offerings = try XCTUnwrap(self.backend.offerings as? MockOfferingsAPI)

        self.mockOfferingsManager = MockOfferingsManager(deviceCache: self.deviceCache,
                                                         operationDispatcher: self.operationDispatcher,
                                                         systemInfo: self.systemInfo,
                                                         backend: self.backend,
                                                         offeringsFactory: OfferingsFactory(),
                                                         productsManager: self.productsManager)
        self.setUpStoreKit1Wrapper()

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
        self.mockTransactionFetcher = MockStoreKit2TransactionFetcher()
        self.setUpStoreKit1Wrapper()
        self.setUpAttribution()
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()
    }

    fileprivate func setUpStoreKit2Listener() {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self.orchestrator._storeKit2TransactionListener = MockStoreKit2TransactionListener()
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var mockStoreKit2TransactionListener: MockStoreKit2TransactionListener? {
        return self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
    }

    fileprivate func setUpSystemInfo(
        finishTransactions: Bool = true,
        storeKit2Setting: StoreKit2Setting = .default,
        usesStoreKit2JWS: Bool = false
    ) {
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "1.2.3")

        self.systemInfo = .init(platformInfo: platformInfo,
                                finishTransactions: finishTransactions,
                                storeKit2Setting: storeKit2Setting,
                                usesStoreKit2JWS: usesStoreKit2JWS)
        self.systemInfo.stubbedIsSandbox = true
    }

    fileprivate func setUpStoreKit1Wrapper() {
        self.storeKit1Wrapper = MockStoreKit1Wrapper(observerMode: self.systemInfo.observerMode)
        self.storeKit1Wrapper.mockAddPaymentTransactionState = .purchased
        self.storeKit1Wrapper.mockCallUpdatedTransactionInstantly = true

        self.paymentQueueWrapper = .left(self.storeKit1Wrapper)
    }

    fileprivate func setUpAttribution() {
        let attributionPoster = AttributionPoster(deviceCache: self.deviceCache,
                                                  currentUserProvider: self.currentUserProvider,
                                                  backend: self.backend,
                                                  attributionFetcher: self.attributionFetcher,
                                                  subscriberAttributesManager: self.subscriberAttributesManager)

        self.attribution = Attribution(subscriberAttributesManager: self.subscriberAttributesManager,
                                       currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.mockUserID),
                                       attributionPoster: attributionPoster,
                                       systemInfo: self.systemInfo)
    }

    fileprivate func setUpOrchestrator() {
        self.orchestrator = PurchasesOrchestrator(productsManager: self.productsManager,
                                                  paymentQueueWrapper: self.paymentQueueWrapper,
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
                                                  storeMessagesHelper: self.mockStoreMessagesHelper)
        self.storeKit1Wrapper.delegate = self.orchestrator
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    fileprivate func setUpOrchestrator(
        storeKit2TransactionListener: StoreKit2TransactionListenerType,
        storeKit2StorefrontListener: StoreKit2StorefrontListener
    ) {
        self.orchestrator = PurchasesOrchestrator(productsManager: self.productsManager,
                                                  paymentQueueWrapper: self.paymentQueueWrapper,
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
                                                  storeMessagesHelper: self.mockStoreMessagesHelper)
        self.storeKit1Wrapper.delegate = self.orchestrator
    }

    private var transactionPoster: TransactionPoster {
        return .init(
            productsManager: self.productsManager,
            receiptFetcher: self.receiptFetcher,
            backend: self.backend,
            paymentQueueWrapper: self.paymentQueueWrapper,
            systemInfo: self.systemInfo,
            operationDispatcher: self.operationDispatcher
        )
    }

    // MARK: - tests

    func testPurchasingTestProductFails() async throws {
        let error = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: Self.testProduct, package: nil) { _, _, error, _ in
                continuation.resume(returning: error)
            }
        }
        expect(error).to(matchError(ErrorCode.productNotAvailableForPurchaseError))
    }

    func testPurchasingTestProductWithPromotionalOfferFails() async throws {
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        let error = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                product: Self.testProduct,
                package: nil,
                promotionalOffer: offer
            ) { _, _, error, _ in
                continuation.resume(returning: error)
            }
        }
        expect(error).to(matchError(ErrorCode.productNotAvailableForPurchaseError))
    }

    func testPurchaseSK1PackageSendsReceiptToBackendIfSuccessful() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let storeProduct = try await self.fetchSk1StoreProduct()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: .from(product: storeProduct),
                              offeringIdentifier: "offering")

        let payment = storeKit1Wrapper.payment(with: product)

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: package,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingID) == "offering"
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    func testPurchaseSK1PackageWithPresentedPaywall() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = self.storeKit1Wrapper.payment(with: product)

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEvent))

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: nil,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall) == Self.paywallEvent
    }

    func testFailedSK1PurchaseRemembersPresentedPaywall() async throws {
        func purchase() async throws {
            let product = try await self.fetchSk1Product()
            let payment = self.storeKit1Wrapper.payment(with: product)

            _ = await withCheckedContinuation { continuation in
                self.orchestrator.purchase(
                    sk1Product: product,
                    payment: payment,
                    package: nil,
                    wrapper: self.storeKit1Wrapper
                ) { transaction, customerInfo, error, userCancelled in
                    continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
                }
            }
        }

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEvent))
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        self.backend.stubbedPostReceiptResult = .failure(.unexpectedBackendResponse(.customerInfoNil))
        try await purchase()

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        try await purchase()

        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall) == Self.paywallEvent
    }

    func testPurchaseSK1PackageDoesNotPostAdServicesTokenIfNotEnabled() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.attributionFetcher.adServicesTokenToReturn = "token"

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let payment = self.storeKit1Wrapper.payment(with: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: package,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken).to(beNil())
    }

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func testPurchaseSK1PackageWithSubscriberAttributesAndAdServicesToken() async throws {
        try AvailabilityChecks.skipIfTVOrWatchOS()
        try AvailabilityChecks.iOS14_3APIAvailableOrSkipTest()

        // Test for custom entitlement computation mode.
        // Without that mode, the token is posted upon calling `enableAdServicesAttributionTokenCollection`
        self.systemInfo = .init(finishTransactions: true, customEntitlementsComputation: true)
        self.setUpAttribution()
        self.setUpOrchestrator()

        let token = "token"
        let attributes: SubscriberAttribute.Dictionary = [
            "attribute_1": .init(attribute: .campaign, value: "campaign"),
            "attribute_2": .init(attribute: .email, value: "email")
        ]

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.attributionFetcher.adServicesTokenToReturn = "token"
        self.subscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = attributes
        self.attribution.enableAdServicesAttributionTokenCollection()

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let payment = self.storeKit1Wrapper.payment(with: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: package,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken) == token
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.unsyncedAttributes) == attributes
    }

    func testSK1PurchaseDoesNotAlwaysRefreshReceiptInProduction() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.systemInfo.stubbedIsSandbox = false

        let product = try await self.fetchSk1Product()
        let storeProduct = try await self.fetchSk1StoreProduct()

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: .from(product: storeProduct),
                              offeringIdentifier: "offering")

        let payment = self.storeKit1Wrapper.payment(with: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: package,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .onlyIfEmpty
    }

    func testGetSK1PromotionalOffer() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))
        self.receiptParser.stubbedReceiptHasTransactionsResult = true

        let product = try await fetchSk1Product()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceLocale.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        let result = try await Async.call { completion in
            orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                          product: StoreProduct(sk1Product: product),
                                          completion: completion)
        }

        expect(result.signedData.identifier) == storeProductDiscount.offerIdentifier

        expect(self.offerings.invokedPostOfferCount) == 1
        expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
        expect(self.offerings.invokedPostOfferParameters?.data?.serialized()) ==
            self.receiptFetcher.mockReceiptData.asFetchToken
    }

    func testGetSK1PromotionalOfferFailsWithIneligibleIfNoReceiptIsFound() async throws {
        self.receiptFetcher.shouldReturnReceipt = false

        let product = try await self.fetchSk1Product()
        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceLocale.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        do {
            _ = try await Async.call { completion in
                self.orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                   product: StoreProduct(sk1Product: product),
                                                   completion: completion)
            }
        } catch {
            expect(error).to(matchError(ErrorCode.ineligibleError))
        }

        expect(self.offerings.invokedPostOffer) == false
    }

    func testGetSK1PromotionalOfferFailsWithIneligibleIfReceiptHasNoTransactions() async throws {
        self.receiptParser.stubbedReceiptHasTransactionsResult = false

        let product = try await self.fetchSk1Product()
        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceLocale.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        do {
            _ = try await Async.call { completion in
                self.orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                   product: StoreProduct(sk1Product: product),
                                                   completion: completion)
            }
        } catch {
            expect(error).to(matchError(ErrorCode.ineligibleError))
        }

        expect(self.offerings.invokedPostOffer) == false
    }

    func testGetSK1PromotionalOfferWorksWhenReceiptHasTransactions() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))
        self.receiptParser.stubbedReceiptHasTransactionsResult = true

        let product = try await self.fetchSk1Product()
        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceLocale.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        let result = try await Async.call { completion in
            orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                          product: StoreProduct(sk1Product: product),
                                          completion: completion)
        }

        expect(result.signedData.identifier) == storeProductDiscount.offerIdentifier

        expect(self.offerings.invokedPostOfferCount) == 1
        expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
    }

    func testGetSK1PromotionalOfferFailsWithIneligibleDiscount() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        self.offerings.stubbedPostOfferCompletionResult = .failure(
            .networkError(
                .errorResponse(
                    .init(code: .userIneligibleForPromoOffer,
                          originalCode: BackendErrorCode.userIneligibleForPromoOffer.rawValue),
                    .success
                )
            )
        )

        let product = try await self.fetchSk1Product()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceLocale.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        do {
            _ = try await Async.call { completion in
                self.orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                   product: StoreProduct(sk1Product: product),
                                                   completion: completion)
            }

            fail("Expected error")
        } catch let purchasesError as PurchasesError {
            expect(purchasesError.error).to(matchError(ErrorCode.ineligibleError))
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testPurchaseSK1PackageWithDiscountSendsReceiptToBackendIfSuccessful() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  promotionalOffer: offer,
                                  package: package,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingID) == "offering"
    }

    func testPurchaseSK1PackageWithNoProductIdentifierDoesNotPostReceipt() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let payment = self.storeKit1Wrapper.payment(with: product)
        payment.productIdentifier = ""

        let (transaction, customerInfo, error, cancelled) =
        try await withCheckedThrowingContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: package,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        // Internally PurchasesOrchestrator uses product identifiers for callback keys
        // When the transaction comes back, its payment is the only source for product identifier.
        // There is no point starting the purchase if we can't retrieve the product identifier from it.
        expect(transaction).to(beNil())
        expect(customerInfo).to(beNil())
        expect(error).to(matchError(ErrorCode.storeProblemError))
        expect(cancelled) == false

        expect(self.backend.invokedPostReceiptDataCount) == 0
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testGetSK2PromotionalOfferWorksIfThereIsATransaction() async throws {
        self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices, usesStoreKit2JWS: true)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        let transaction = try await createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = transaction

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))
        self.receiptParser.stubbedReceiptHasTransactionsResult = true

        let product = try await fetchSk2Product()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceFormatStyle.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        let result = try await Async.call { completion in
            orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                          product: StoreProduct(sk2Product: product),
                                          completion: completion)
        }

        expect(result.signedData.identifier) == storeProductDiscount.offerIdentifier

        expect(self.offerings.invokedPostOfferCount) == 1
        expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
        expect(self.offerings.invokedPostOfferParameters?.data?.serialized()) == transaction.jwsRepresentation
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testGetSK2PromotionalOfferFailsWithIneligibleIfNoTransactionIsFound() async throws {
        self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices, usesStoreKit2JWS: true)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = nil

        let product = try await self.fetchSk2Product()
        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceFormatStyle.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        do {
            _ = try await Async.call { completion in
                self.orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                   product: StoreProduct(sk2Product: product),
                                                   completion: completion)
            }
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.ineligibleError))
        }

        expect(self.offerings.invokedPostOffer) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsCorrectValues() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockTransaction = try await self.simulateAnyPurchase()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        mockStoreKit2TransactionListener?.mockTransaction = .init(mockTransaction.underlyingTransaction)

        let product = try await self.fetchSk2Product()

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk2Product: product),
                              offeringIdentifier: "offering")

        let (transaction, customerInfo, userCancelled) = try await orchestrator.purchase(sk2Product: product,
                                                                                         package: package,
                                                                                         promotionalOffer: nil)

        expect(transaction?.sk2Transaction) == mockTransaction.underlyingTransaction
        expect(userCancelled) == false

        let expectedCustomerInfo: CustomerInfo = .emptyInfo
        expect(customerInfo) == expectedCustomerInfo
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageHandlesPurchaseResult() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let storeProduct = StoreProduct.from(product: try await fetchSk2StoreProduct())
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(product: storeProduct,
                                  package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        let mockListener = try XCTUnwrap(orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener)
        expect(mockListener.invokedHandle) == true
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSendsReceiptToBackendIfSuccessful() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockListener = try XCTUnwrap(orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener)

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await fetchSk2Product()

        _ = try await orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingID).to(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageWithPresentedPaywall() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEvent))

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        _ = try await self.orchestrator.purchase(sk2Product: product,
                                                 package: nil,
                                                 promotionalOffer: nil)

        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall) == Self.paywallEvent
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testFailedSK2PurchaseRemembersPresentedPaywall() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEvent))

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        self.backend.stubbedPostReceiptResult = .failure(.unexpectedBackendResponse(.customerInfoNil))
        _ = try? await self.orchestrator.purchase(sk2Product: product,
                                                  package: nil,
                                                  promotionalOffer: nil)

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        _ = try await self.orchestrator.purchase(sk2Product: product,
                                                 package: nil,
                                                 promotionalOffer: nil)

        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall) == Self.paywallEvent
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSK2PurchaseDoesNotAlwaysRefreshReceiptInProduction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.systemInfo.stubbedIsSandbox = false

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        _ = try await orchestrator.purchase(sk2Product: self.fetchSk2Product(),
                                            package: nil,
                                            promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .onlyIfEmpty
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSendsOfferingIdentifierIfSuccessful() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockListener = try XCTUnwrap(orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener)

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await fetchSk2Product()

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk2Product: product),
                              offeringIdentifier: "offering")

        _ = try await orchestrator.purchase(sk2Product: product, package: package, promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingID) == "offering"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    func testPurchaseSK2PackageDoesNotPostAdServicesTokenIfNotEnabled() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try AvailabilityChecks.skipIfTVOrWatchOS()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.attributionFetcher.adServicesTokenToReturn = "token"
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk2Product: product),
                              offeringIdentifier: "offering")

        _ = try await self.orchestrator.purchase(sk2Product: product, package: package, promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken).to(beNil())
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func testPurchaseSK2PackagePostsAdServicesTokenAndAttributes() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try AvailabilityChecks.skipIfTVOrWatchOS()

        // Test for custom entitlement computation mode.
        // Without that mode, the token is posted upon calling `enableAdServicesAttributionTokenCollection`
        self.systemInfo = .init(finishTransactions: true, customEntitlementsComputation: true)
        self.setUpAttribution()
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        let token = "token"
        let attributes: SubscriberAttribute.Dictionary = [
            "attribute_1": .init(attribute: .campaign, value: "campaign"),
            "attribute_2": .init(attribute: .email, value: "email")
        ]

        self.attributionFetcher.adServicesTokenToReturn = "token"
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.attributionFetcher.adServicesTokenToReturn = "token"
        self.subscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = attributes
        self.attribution.enableAdServicesAttributionTokenCollection()

        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk2Product: product),
                              offeringIdentifier: "offering")

        _ = try await self.orchestrator.purchase(sk2Product: product, package: package, promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken) == token
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.unsyncedAttributes) == attributes
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageRetriesReceiptFetchIfEnabled() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.systemInfo = .init(
            platformInfo: nil,
            finishTransactions: false,
            storeKit2Setting: .enabledForCompatibleDevices,
            dangerousSettings: .init(autoSyncPurchases: true,
                                     internalSettings: DangerousSettings.Internal(enableReceiptFetchRetry: true))
        )

        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        _ = try await orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .retryUntilProductIsFound(
            productIdentifier: product.id,
            maximumRetries: TransactionPoster.receiptRetryCount,
            sleepDuration: TransactionPoster.receiptRetrySleepDuration
        )

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSkipsIfPurchaseFailed() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        testSession.failTransactionsEnabled = true
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await fetchSk2Product()
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        do {
            _ = try await orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: offer)
            XCTFail("Expected error")
        } catch {
            expect(self.backend.invokedPostReceiptData) == false
            let mockListener = try XCTUnwrap(
                orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
            )
            expect(mockListener.invokedHandle) == false
        }
    }

    #if swift(>=5.9)
    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
    func testPurchaseSK2ProductCancelled() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()

        try await self.testSession.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)

        self.customerInfoManager.stubbedCustomerInfoResult = .success(self.mockCustomerInfo)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.mockStoreKit2TransactionListener?.mockCancelled = true

        let product = try await self.fetchSk2Product()

        let (transaction, info, cancelled) = try await self.orchestrator.purchase(sk2Product: product,
                                                                                  package: nil,
                                                                                  promotionalOffer: nil)

        expect(self.mockStoreKit2TransactionListener?.invokedHandle) == true
        let purchaseResult = try XCTUnwrap(
            self.mockStoreKit2TransactionListener?.invokedHandleParameters?.purchaseResult.value)

        switch purchaseResult {
        case .userCancelled:
            // Expected
            break
        default:
            fail("Unexpected result: \(purchaseResult)")
        }

        expect(transaction).to(beNil())
        expect(info) === self.mockCustomerInfo
        expect(cancelled) == true
        expect(self.backend.invokedPostReceiptData) == false
    }
    #endif

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageWithInvalidPromotionalOfferSignatureThrowsError() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk2Product()
        let offer = PromotionalOffer.SignedData(
            identifier: "identifier \(Int.random(in: 0..<1000))",
            keyIdentifier: "key identifier \(Int.random(in: 0..<1000))",
            nonce: .init(),
            // This should be base64
            signature: "signature \(Int.random(in: 0..<1000))",
            timestamp: Int.random(in: 0..<1000)
        )

        do {
            _ = try await orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: offer)
            XCTFail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.invalidPromotionalOfferError))
            expect(error.localizedDescription)
                .to(contain("The signature generated by RevenueCat could not be decoded: \(offer.signature)"))
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsCustomerInfoForFailedTransaction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.customerInfoManager.stubbedCustomerInfoResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        let (transaction, customerInfo, cancelled) = try await self.orchestrator.purchase(sk2Product: product,
                                                                                          package: nil,
                                                                                          promotionalOffer: nil)

        expect(transaction).to(beNil())
        expect(customerInfo) == self.mockCustomerInfo
        expect(cancelled) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsMissingReceiptErrorIfSendReceiptFailed() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let product = try await fetchSk2Product()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.receiptFetcher.shouldReturnReceipt = false
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        do {
            _ = try await self.orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

            XCTFail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.missingReceiptFileError))
            expect(mockListener.invokedHandle) == true
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testStoreKit2TransactionListenerDelegate() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setUpStoreKit2Listener()

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let transaction = MockStoreTransaction()

        try await self.orchestrator.storeKit2TransactionListener(
            self.mockStoreKit2TransactionListener!,
            updatedTransaction: transaction
        )

        expect(transaction.finishInvoked) == true
        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.isRestore) == false
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .queue
        expect(self.customerInfoManager.invokedCacheCustomerInfo) == true
        expect(self.customerInfoManager.invokedCacheCustomerInfoParameters?.appUserID) == Self.mockUserID
        expect(self.customerInfoManager.invokedCacheCustomerInfoParameters?.info) === self.mockCustomerInfo
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testStoreKit2TransactionListenerDoesNotFinishTransactionIfPostingReceiptFails() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setUpStoreKit2Listener()

        let expectedError: BackendError = .missingReceiptFile(nil)

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .failure(expectedError)

        let transaction = MockStoreTransaction()

        do {
            try await self.orchestrator.storeKit2TransactionListener(
                self.mockStoreKit2TransactionListener!,
                updatedTransaction: transaction
            )
            fail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError))
        }

        expect(transaction.finishInvoked) == false
        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.isRestore) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testStoreKit2TransactionListenerOnlyFinishesTransactionsAfterPostingReceipt() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setUpStoreKit2Listener()

        enum Operation {
            case receiptPost
            case finishTransaction
        }

        var operations: [Operation] = []

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.backend.onPostReceipt = { operations.append(.receiptPost) }

        let transaction = MockStoreTransaction()
        transaction.onFinishInvoked = { operations.append(.finishTransaction) }

        try await self.orchestrator.storeKit2TransactionListener(
            self.mockStoreKit2TransactionListener!,
            updatedTransaction: transaction
        )

        expect(operations) == [
            .receiptPost,
            .finishTransaction
        ]
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testStoreKit2TransactionListenerDelegateWithObserverMode() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setUpSystemInfo(finishTransactions: false, storeKit2Setting: .enabledForCompatibleDevices)

        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        let transaction = MockStoreTransaction()

        try await self.orchestrator.storeKit2TransactionListener(
            self.mockStoreKit2TransactionListener!,
            updatedTransaction: transaction
        )

        expect(transaction.finishInvoked) == false
        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.isRestore) == false
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .queue
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PromotionalOffer() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))
        self.receiptParser.stubbedReceiptHasTransactionsResult = true

        let storeProduct = try await self.fetchSk2StoreProduct()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: storeProduct.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 3,
                                                            type: .promotional)

        _ = try await orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                    product: storeProduct)

        expect(self.offerings.invokedPostOfferCount) == 1
        expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
        expect(self.offerings.invokedPostOfferParameters?.data).toNot(beNil())
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testClearCachedProductsAndOfferingsAfterStorefrontChangesWithSK2() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.orchestrator.storefrontDidUpdate(with: MockStorefront(countryCode: "ESP"))

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    func testClearCachedProductsAndOfferingsAfterStorefrontChangesWithSK1() async throws {
        self.orchestrator.storeKit1WrapperDidChangeStorefront(storeKit1Wrapper)

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testDoesNotListenForSK2TransactionsWithSK2Disabled() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        self.setUpSystemInfo(storeKit2Setting: .disabled)

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

        expect(transactionListener.invokedDelegateSetter).toEventually(beTrue())
        expect(transactionListener.invokedListenForTransactions) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testDoesNotListenForSK2TransactionsWithSK2EnabledOnlyForOptimizations() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        self.setUpSystemInfo(storeKit2Setting: .enabledOnlyForOptimizations)

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

        expect(transactionListener.invokedDelegateSetter).toEventually(beTrue())
        expect(transactionListener.invokedListenForTransactions) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testListensForSK2TransactionsWithSK2Enabled() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices)

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

        expect(transactionListener.invokedDelegateSetter).toEventually(beTrue())
        expect(transactionListener.invokedListenForTransactions) == true
        expect(transactionListener.invokedListenForTransactionsCount) == 1
    }

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func testShowManageSubscriptionsCallsCompletionWithErrorIfThereIsAFailure() {
        let message = "Failed to get managementURL from CustomerInfo. Details: customerInfo is nil."
        mockManageSubsHelper.mockError = ErrorUtils.customerInfoError(withMessage: message)

        let receivedError: Error? = waitUntilValue { completed in
            self.orchestrator.showManageSubscription { error in
                completed(error)
            }
        }

        expect(receivedError).to(matchError(ErrorCode.customerInfoError))
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForProductCompletesWithoutErrorAndPassesThroughStatusIfSuccessful() async throws {
        let expectedStatus = RefundRequestStatus.userCancelled
        mockBeginRefundRequestHelper.mockRefundRequestStatus = expectedStatus

        let refundStatus = try await orchestrator.beginRefundRequest(forProduct: "1234")
        expect(refundStatus) == expectedStatus
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForProductCompletesWithErrorIfThereIsAFailure() async {
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        mockBeginRefundRequestHelper.mockError = expectedError

        do {
            _ = try await orchestrator.beginRefundRequest(forProduct: "1235")
            XCTFail("beginRefundRequestForProduct should have thrown an error")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForEntitlementCompletesWithoutErrorAndPassesThroughStatusIfSuccessful() async throws {
        let expectedStatus = RefundRequestStatus.userCancelled
        mockBeginRefundRequestHelper.mockRefundRequestStatus = expectedStatus

        let receivedStatus = try await orchestrator.beginRefundRequest(forEntitlement: "1234")
        expect(receivedStatus) == expectedStatus
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForEntitlementCompletesWithErrorIfThereIsAFailure() async {
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        mockBeginRefundRequestHelper.mockError = expectedError

        do {
            _ = try await orchestrator.beginRefundRequest(forEntitlement: "1234")
            XCTFail("beginRefundRequestForEntitlement should have thrown error")
        } catch {
            expect(error).toNot(beNil())
            expect(error).to(matchError(expectedError))
        }

    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForActiveEntitlementCompletesWithoutErrorAndPassesThroughStatusIfSuccessful() async throws {
        let expectedStatus = RefundRequestStatus.userCancelled
        mockBeginRefundRequestHelper.mockRefundRequestStatus = expectedStatus

        let receivedStatus = try await orchestrator.beginRefundRequestForActiveEntitlement()
        expect(receivedStatus) == expectedStatus
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForActiveEntitlementCompletesWithErrorIfThereIsAFailure() async {
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        mockBeginRefundRequestHelper.mockError = expectedError

        do {
            _ = try await orchestrator.beginRefundRequestForActiveEntitlement()
            XCTFail("beginRefundRequestForActiveEntitlement should have thrown error")
        } catch {
            expect(error).toNot(beNil())
            expect(error).to(matchError(expectedError))
            expect(error.localizedDescription).to(equal(expectedError.localizedDescription))
        }
    }

    #endif

    func testRestorePurchasesDoesNotLogWarningIfAllowSharingAppStoreAccountIsNotDefined() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        self.logger.verifyMessageWasNotLogged(
            Strings
                .purchase
                .restorepurchases_called_with_allow_sharing_appstore_account_false
        )
    }

    func testRestorePurchasesDoesNotLogWarningIfAllowSharingAppStoreAccountIsTrue() async throws {
        self.orchestrator.allowSharingAppStoreAccount = true

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        self.logger.verifyMessageWasNotLogged(
            Strings
                .purchase
                .restorepurchases_called_with_allow_sharing_appstore_account_false
        )
    }

    func testRestorePurchasesLogsWarningIfAllowSharingAppStoreAccountIsFalse() async throws {
        self.orchestrator.allowSharingAppStoreAccount = false

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        self.logger.verifyMessageWasLogged(
            Strings
                .purchase
                .restorepurchases_called_with_allow_sharing_appstore_account_false,
            level: .warn
        )
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSyncPurchasesPostsTheReceipt() async throws {
        self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices, usesStoreKit2JWS: true)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        let transaction = try await createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = transaction
        let product = try await self.fetchSk2StoreProduct()
        self.productsManager.stubbedSk2StoreProductsResult = .success([product])
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesDoesntPostAndReturnsCustomerInfoIfNoTransaction() async throws {
        self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices, usesStoreKit2JWS: true)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = nil
        self.customerInfoManager.stubbedCustomerInfoResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)
        expect(self.backend.invokedPostReceiptData).to(beFalse())
        expect(self.customerInfoManager.invokedCustomerInfo).to(beTrue())
        expect(customerInfo) == mockCustomerInfo
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSyncPurchasesCallsSuccessDelegateMethod() async throws {
        self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices, usesStoreKit2JWS: true)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        let transaction = try await createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = transaction

        let customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "foo",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": NSNull()
            ] as [String: Any]
        ])
        self.backend.stubbedPostReceiptResult = .success(customerInfo)

        let receivedCustomerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                             isRestore: false,
                                                                             initiationSource: .purchase)

        expect(receivedCustomerInfo) === customerInfo
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSyncPurchasesPassesErrorOnFailure() async throws {
        self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices, usesStoreKit2JWS: true)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        let transaction = try await self.createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = transaction

        let expectedError: BackendError = .missingAppUserID()

        self.backend.stubbedPostReceiptResult = .failure(expectedError)

        do {
            _ = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                          isRestore: false,
                                                          initiationSource: .purchase)
            fail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError.asPurchasesError))
        }
    }
}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
private extension PurchasesOrchestratorTests {

    @MainActor
    func fetchSk1Product() async throws -> SK1Product {
        return MockSK1Product(
            mockProductIdentifier: Self.productID,
            mockSubscriptionGroupIdentifier: "group1"
        )
    }

    @MainActor
    func fetchSk1StoreProduct() async throws -> SK1StoreProduct {
        return try await SK1StoreProduct(sk1Product: fetchSk1Product())
    }

    var mockCustomerInfo: CustomerInfo { .emptyInfo }

    static let testProduct = TestStoreProduct(
        localizedTitle: "Product",
        price: 3.99,
        localizedPriceString: "$3.99",
        productIdentifier: "product",
        productType: .autoRenewableSubscription,
        localizedDescription: "Description"
    ).toStoreProduct()

    static let paywallEvent: PaywallEvent.Data = .init(
        offeringIdentifier: "offering",
        paywallRevision: 5,
        sessionID: .init(),
        displayMode: .fullScreen,
        localeIdentifier: "en_US",
        darkMode: true,
        date: .init(timeIntervalSince1970: 1694029328)
    )

}
