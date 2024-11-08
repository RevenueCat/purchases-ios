//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorSK2Tests.swift
//
//  Created by Mark Villacampa on 16/2/24.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchasesOrchestratorSK2Tests: BasePurchasesOrchestratorTests, PurchasesOrchestratorTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUp() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        try await super.setUp()
    }

    // MARK: - StoreFront Changes

    func testClearCachedProductsAndOfferingsAfterStorefrontChanges() async throws {
        self.orchestrator.storefrontDidUpdate(with: MockStorefront(countryCode: "ESP"))

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    // MARK: - Purchasing

    func testPurchasePostsReceipt() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let transaction = try await createTransaction(finished: true)
        let product = try await self.fetchSk2Product()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk2Product: product),
                              offeringIdentifier: "offering")
        mockStoreKit2TransactionListener?.mockTransaction = .init(transaction.sk2Transaction)
        mockStoreKit2TransactionListener?.mockJWSToken = transaction.jwsRepresentation!

        _ = try await orchestrator.purchase(sk2Product: product,
                                            package: package,
                                            promotionalOffer: nil,
                                            winBackOffer: nil)

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .jws(transaction.jwsRepresentation!)
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingContext?.offeringIdentifier
        ) == "offering"
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    func testPurchaseReturnsCorrectValues() async throws {
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        let mockTransaction = try await self.simulateAnyPurchase()
        mockStoreKit2TransactionListener?.mockTransaction = .init(mockTransaction.underlyingTransaction)

        let product = try await self.fetchSk2Product()
        let (transaction, customerInfo, userCancelled) = try await orchestrator.purchase(sk2Product: product,
                                                                                         package: nil,
                                                                                         promotionalOffer: nil,
                                                                                         winBackOffer: nil)

        expect(transaction?.sk2Transaction) == mockTransaction.underlyingTransaction
        expect(userCancelled) == false

        let expectedCustomerInfo: CustomerInfo = .emptyInfo
        expect(customerInfo) == expectedCustomerInfo

        expect(self.mockStoreKit2TransactionListener?.invokedHandle) == true
        expect(self.mockStoreKit2TransactionListener?.invokedHandleCount) == 1
    }

    func testPurchaseDoesNotPostReceiptIfPurchaseFailed() async throws {
        // As of Xcode 15.2 this makes purchases fail with `StoreKitError.unknown`
        testSession.failTransactionsEnabled = true
        let product = try await fetchSk2Product()

        do {
            _ = try await orchestrator.purchase(sk2Product: product,
                                                package: nil,
                                                promotionalOffer: nil,
                                                winBackOffer: nil)
            XCTFail("Expected error")
        } catch {
            expect(self.backend.invokedPostReceiptData) == false
            expect(self.mockStoreKit2TransactionListener?.invokedHandle) == false
        }
    }

    func testPurchaseWithPromotionalOfferPostsReceiptIfSuccessful() async throws {
        throw XCTSkip("Purchasing with a promo offer in SK2 using a StoreKit Config file returns an unknown error")
    }

    func testPurchaseWithInvalidPromotionalOfferSignatureFails() async throws {
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
            _ = try await orchestrator.purchase(
                sk2Product: product,
                package: nil,
                promotionalOffer: offer,
                winBackOffer: nil
            )
            XCTFail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.invalidPromotionalOfferError))
            expect(error.localizedDescription)
                .to(contain("The signature generated by RevenueCat could not be decoded: \(offer.signature)"))
        }
    }

    func testPurchaseCancelled() async throws {
        self.customerInfoManager.stubbedCustomerInfoResult = .success(self.mockCustomerInfo)
        self.mockStoreKit2TransactionListener?.mockResult = .init(.userCancelled)

        let product = try await self.fetchSk2Product()

        let (transaction, customerInfo, cancelled) = try await self.orchestrator.purchase(sk2Product: product,
                                                                                          package: nil,
                                                                                          promotionalOffer: nil,
                                                                                          winBackOffer: nil)

        expect(transaction).to(beNil())
        expect(customerInfo) == self.mockCustomerInfo
        expect(cancelled) == false
        expect(self.backend.invokedPostReceiptData) == false
    }

    #if swift(>=5.9)
    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
    func testPurchaseSK2CancelledWithSimulatedError() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()

        try await self.testSession.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)

        self.customerInfoManager.stubbedCustomerInfoResult = .success(self.mockCustomerInfo)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.mockStoreKit2TransactionListener?.mockCancelled = true

        let product = try await self.fetchSk2Product()

        let (transaction, info, cancelled) = try await self.orchestrator.purchase(sk2Product: product,
                                                                                  package: nil,
                                                                                  promotionalOffer: nil,
                                                                                  winBackOffer: nil)

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

    // MARK: - Purchasing, StoreKit 2 only

    func testPurchaseSK2IncludesAppUserIdIfUUID() async throws {
        let uuid = UUID()
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: uuid.uuidString)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        customerInfoManager.stubbedCustomerInfoResult = .success(.emptyInfo)
        backend.stubbedPostReceiptResult = .success(.emptyInfo)

        let product = try await fetchSk2Product()
        let result = try await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil
        )
        expect(result.transaction?.sk2Transaction?.appAccountToken).to(equal(uuid))
    }

    func testPurchaseSK2DoesNotIncludeAppUserIdIfNotUUID() async throws {
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: "not_a_uuid")
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await fetchSk2Product()
        let result = try await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil
        )
        expect(result.transaction?.sk2Transaction?.appAccountToken).to(beNil())
    }

    func testPurchaseSK2PostsSK2ReceiptInXcodeEnvironment() async throws {
        let mockListener = try XCTUnwrap(orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener)
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        let transaction = try await self.simulateAnyPurchase()
        mockListener.mockTransaction = .init(transaction.verifiedTransaction)
        mockListener.mockEnvironment = .xcode

        let receipt = StoreKit2Receipt(
            environment: .xcode,
            subscriptionStatusBySubscriptionGroupId: [
                "123_subscription_group_id": [
                    .init(state: .subscribed,
                          renewalInfoJWSToken: "123_renewal_info_jws_token",
                          transactionJWSToken: "123_transaction_jws_token")
                ]
            ],
            transactions: ["123_transaction_jws_token"],
            bundleId: "123_bundle_id",
            originalApplicationVersion: "123_original_application_version",
            originalPurchaseDate: Date(timeIntervalSince1970: 123))
        mockTransactionFetcher.stubbedReceipt = receipt

        let product = try await fetchSk2Product()
        self.productsManager.stubbedSk2StoreProductsResult = .success([product])
        let result = try await orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil
        )

        expect(result.transaction) == transaction.verifiedStoreTransaction
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .sk2receipt(receipt)
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingContext?.offeringIdentifier
        ).to(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    // MARK: - PurchaseParams

    #if ENABLE_PURCHASE_PARAMS
    func testPurchaseWithPurchaseParamsPostsReceipt() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let transaction = try await createTransaction(finished: true)
        let product = try await self.fetchSk2Product()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk2Product: product),
                              offeringIdentifier: "offering")
        mockStoreKit2TransactionListener?.mockTransaction = .init(transaction.sk2Transaction)
        mockStoreKit2TransactionListener?.mockJWSToken = transaction.jwsRepresentation!

        let metadata = ["key": "value"]
        let params = PurchaseParams.Builder(package: package)
            .with(metadata: metadata)
            .build()

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(params: params) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .jws(transaction.jwsRepresentation!)
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.metadata).to(equal(metadata))
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingContext?.offeringIdentifier
        ) == "offering"
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    func testPurchaseWithPurchaseParamsReturnsCorrectValues() async throws {
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        let mockTransaction = try await self.simulateAnyPurchase()
        mockStoreKit2TransactionListener?.mockTransaction = .init(mockTransaction.underlyingTransaction)

        let product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: product)
        let discount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                currencyCode: product.priceFormatStyle.currencyCode,
                                                price: 11.1,
                                                localizedPriceString: "$11.10",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 1, unit: .month),
                                                numberOfPeriods: 2,
                                                type: .promotional)
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)
        let promoOffer = PromotionalOffer(discount: discount, signedData: offer)
        let params = PurchaseParams.Builder(product: storeProduct)
                .with(promotionalOffer: promoOffer)
                .build()

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(params: params) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(transaction?.sk2Transaction) == mockTransaction.underlyingTransaction
        expect(userCancelled) == false

        let expectedCustomerInfo: CustomerInfo = .emptyInfo
        expect(customerInfo) == expectedCustomerInfo

        expect(self.mockStoreKit2TransactionListener?.invokedHandle) == true
        expect(self.mockStoreKit2TransactionListener?.invokedHandleCount) == 1
    }
    #endif

    // MARK: - Paywalls

    func testPurchaseWithPresentedPaywall() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        _ = try await self.orchestrator.purchase(sk2Product: product,
                                                 package: nil,
                                                 promotionalOffer: nil,
                                                 winBackOffer: nil)

        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.creationData
        ) == Self.paywallEventCreationData
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.data
        ) == Self.paywallEvent
    }

    func testPurchaseFailureRemembersPresentedPaywall() async throws {
        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        self.backend.stubbedPostReceiptResult = .failure(.unexpectedBackendResponse(.customerInfoNil))
        _ = try? await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil
        )

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        _ = try await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil
        )

        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.creationData
        ) == Self.paywallEventCreationData
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.data
        ) == Self.paywallEvent
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSyncsPaywallEvents() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let transaction = try await createTransaction(finished: true)
        let product = try await self.fetchSk2Product()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk2Product: product),
                              offeringIdentifier: "offering")
        mockStoreKit2TransactionListener?.mockTransaction = .init(transaction.sk2Transaction)
        mockStoreKit2TransactionListener?.mockJWSToken = transaction.jwsRepresentation!

        _ = try await orchestrator.purchase(sk2Product: product,
                                            package: package,
                                            promotionalOffer: nil)

        let manager = try self.mockPaywallEventsManager

        try await asyncWait { await manager.invokedFlushEvents == true }

        expect(self.operationDispatcher.invokedDispatchAsyncOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    // MARK: - AdServices and Attributes

    func testPurchaseDoesNotPostAdServicesTokenIfNotEnabled() async throws {
        try AvailabilityChecks.skipIfTVOrWatchOSOrMacOS()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.attributionFetcher.adServicesTokenToReturn = "token"
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()
        _ = try await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil
        )

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken).to(beNil())
    }

    #if !os(tvOS) && !os(watchOS)
    func testPurchasePostsAdServicesTokenAndSubscriberAttributes() async throws {
        try AvailabilityChecks.skipIfTVOrWatchOSOrMacOS()

        // Test for custom entitlement computation mode.
        // Without that mode, the token is posted upon calling `enableAdServicesAttributionTokenCollection`
        self.systemInfo = .init(
            finishTransactions: true,
            customEntitlementsComputation: true,
            storeKitVersion: .storeKit2
        )
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
        _ = try await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil
        )

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken) == token
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.unsyncedAttributes) == attributes
    }
    #endif

    // MARK: - Promotional Offers

    func testGetPromotionalOfferWorksIfThereIsATransaction() async throws {
        let transaction = try await createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = transaction
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))

        let product = try await fetchSk2Product()
        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceFormatStyle.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        let result = try await orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                             product: StoreProduct(sk2Product: product))

        expect(result.signedData.identifier) == storeProductDiscount.offerIdentifier

        expect(self.offerings.invokedPostOfferCount) == 1
        expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
        expect(self.offerings.invokedPostOfferParameters?.data?.serialized()) == transaction.jwsRepresentation
    }

    func testGetPromotionalOfferFailsWithIneligibleIfNoTransactionIsFound() async throws {
        // Non-renewable transactions do not count towards eligibility
        let transaction = try await createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction

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
            _ = try await self.orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                             product: StoreProduct(sk2Product: product))
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.ineligibleError))
        }

        expect(self.offerings.invokedPostOffer) == false
    }

    func testGetPromotionalOfferFailsWithIneligibleIfBackendReturnsIneligible() async throws {
        let transaction = try await createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = transaction
        self.offerings.stubbedPostOfferCompletionResult = .failure(
            .networkError(
                .errorResponse(
                    .init(code: .userIneligibleForPromoOffer,
                          originalCode: BackendErrorCode.userIneligibleForPromoOffer.rawValue),
                    .success
                )
            )
        )

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
        } catch let purchasesError as PurchasesError {
            expect(purchasesError.error).to(matchError(ErrorCode.ineligibleError))
            expect(self.offerings.invokedPostOfferCount) == 1
            expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
            expect(self.offerings.invokedPostOfferParameters?.data?.serialized()) == transaction.jwsRepresentation
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    // MARK: - TransactionListenerDelegate

    func testSK2TransactionListenerDelegate() async throws {
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

    func testSK2TransactionListenerDoesNotFinishTransactionIfPostingReceiptFails() async throws {
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

    func testSK2TransactionListenerOnlyFinishesTransactionsAfterPostingReceipt() async throws {
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

    func testSK2TransactionListenerDelegateWithObserverMode() async throws {
        self.setUpSystemInfo(finishTransactions: false)
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

    func testSK2ListensForSK2Transactions() throws {
        let transactionListener = MockStoreKit2TransactionListener()
        let storeKit2ObserverModePurchasesDetector = MockStoreKit2ObserverModePurchaseDetector()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil),
                               storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchasesDetector)

        expect(transactionListener.invokedDelegateSetter).toEventually(beTrue())
        expect(transactionListener.invokedListenForTransactions) == true
        expect(transactionListener.invokedListenForTransactionsCount) == 1
    }

    // MARK: - Sync Purchases

    func verifySyncPurchases(transaction: StoreTransaction) async throws {
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction
        let product = try await self.fetchSk2StoreProduct()
        self.productsManager.stubbedSk2StoreProductsResult = .success([product])
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .jws(transaction.jwsRepresentation!)
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.unsyncedAttributes).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingContext).to(beNil())
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesPostsReceipt() async throws {
        let transaction = try await createTransaction(finished: true)
        try await verifySyncPurchases(transaction: transaction)
    }

    func testSyncPurchasesPostsReceiptWithNonConsumableTransaction() async throws {
        let transaction = try await createTransaction(productID: Self.nonConsumableProductId, finished: true)
        try await verifySyncPurchases(transaction: transaction)
    }

    func testSyncPurchasesPostsReceiptWithConsumableTransaction() async throws {
        let transaction = try await createTransaction(productID: Self.consumableProductId, finished: true)
        try await verifySyncPurchases(transaction: transaction)
    }

    func testSyncPurchasesPostsReceiptWithNonRenewableTransaction() async throws {
        let transaction = try await createTransaction(productID: Self.nonRenewableProductId, finished: true)
        try await verifySyncPurchases(transaction: transaction)
    }

    func testSyncPurchasesSK2PostsReceiptInXcodeEnvironment() async throws {
        let transaction = try await createTransaction(finished: true, environment: .xcode)
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction
        let receipt = StoreKit2Receipt(
            environment: .xcode,
            subscriptionStatusBySubscriptionGroupId: [
                "123_subscription_group_id": [
                    .init(state: .subscribed,
                          renewalInfoJWSToken: "123_renewal_info_jws_token",
                          transactionJWSToken: "123_transaction_jws_token")
                ]
            ],
            transactions: ["123_transaction_jws_token"],
            bundleId: "123_bundle_id",
            originalApplicationVersion: "123_original_application_version",
            originalPurchaseDate: Date(timeIntervalSince1970: 123))
        self.mockTransactionFetcher.stubbedReceipt = receipt
        let product = try await self.fetchSk2StoreProduct()
        self.productsManager.stubbedSk2StoreProductsResult = .success([product])
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .sk2receipt(receipt)
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesDoesntPostReceiptAndReturnsCustomerInfoIfNoTransactionsAndOriginalPurchaseDatePresent()
    async throws {
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = nil
        self.customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: true,
                                                                     initiationSource: .restore)

        expect(self.backend.invokedPostReceiptData).to(beFalse())

        expect(self.customerInfoManager.invokedCachedCustomerInfo).to(beTrue())
        expect(self.customerInfoManager.invokedCachedCustomerInfoCount) == 1
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesPostsReceiptIfNoTransactionsAndEmptyOriginalPurchaseDate() async throws {
        let appTransactionJWS = "some_jws"

        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = nil
        self.mockTransactionFetcher.stubbedAppTransactionJWS = appTransactionJWS
        self.customerInfoManager.stubbedCachedCustomerInfoResult = CustomerInfo.missingOriginalPurchaseDate
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: true,
                                                                     initiationSource: .restore)

        expect(self.customerInfoManager.invokedCachedCustomerInfo).to(beTrue())
        expect(self.customerInfoManager.invokedCachedCustomerInfoCount) == 1

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.appTransaction) == appTransactionJWS
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .empty // No fetch_token
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.appUserID
        ) == Self.mockUserID

        expect(self.customerInfoManager.invokedCustomerInfo).to(beFalse())
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesPostsReceiptIfNoTransactionsAndEmptyOriginalApplicationVersionSK2() async throws {
        let appTransactionJWS = "some_jws"

        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = nil
        self.mockTransactionFetcher.stubbedAppTransactionJWS = appTransactionJWS
        self.customerInfoManager.stubbedCachedCustomerInfoResult = CustomerInfo.missingOriginalApplicationVersion
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: true,
                                                                     initiationSource: .restore)

        expect(self.customerInfoManager.invokedCachedCustomerInfo).to(beTrue())
        expect(self.customerInfoManager.invokedCachedCustomerInfoCount) == 1

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.appTransaction) == appTransactionJWS
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .empty // No fetch_token
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.appUserID
        ) == Self.mockUserID

        expect(self.customerInfoManager.invokedCustomerInfo).to(beFalse())
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesPostsReceiptIfNoTransactionsAndNoCachedCustomerInfo() async throws {
        let appTransactionJWS = "some_jws"

        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = nil
        self.mockTransactionFetcher.stubbedAppTransactionJWS = appTransactionJWS
        self.customerInfoManager.stubbedCachedCustomerInfoResult = nil
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: true,
                                                                     initiationSource: .restore)

        expect(self.customerInfoManager.invokedCachedCustomerInfo).to(beTrue())
        expect(self.customerInfoManager.invokedCachedCustomerInfoCount) == 1

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.appTransaction) == appTransactionJWS
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .empty // No fetch_token
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.appUserID
        ) == Self.mockUserID

        expect(self.customerInfoManager.invokedCustomerInfo).to(beFalse())
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesCallsSuccessDelegateMethod() async throws {
        let transaction = try await createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction

        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let receivedCustomerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                             isRestore: false,
                                                                             initiationSource: .purchase)

        expect(receivedCustomerInfo) === mockCustomerInfo
    }

    func testSyncPurchasesPassesErrorOnFailure() async throws {
        let transaction = try await self.createTransaction(finished: true)
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction

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

    // MARK: - Purchase tracks

    func testPurchaseSK2TracksCorrectly() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()
        let storeKit2ObserverModePurchaseDetector = MockStoreKit2ObserverModePurchaseDetector()
        let diagnosticsSynchronizer = MockDiagnosticsSynchronizer()
        let diagnosticsTracker = MockDiagnosticsTracker()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil),
                               storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchaseDetector,
                               diagnosticsSynchronizer: diagnosticsSynchronizer,
                               diagnosticsTracker: diagnosticsTracker)

        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        let mockTransaction = try await self.simulateAnyPurchase()
        mockStoreKit2TransactionListener?.mockTransaction = .init(mockTransaction.underlyingTransaction)

        let product = try await self.fetchSk2Product()
        let (transaction, _, _) = try await orchestrator.purchase(sk2Product: product,
                                                                  package: nil,
                                                                  promotionalOffer: nil,
                                                                  winBackOffer: nil)

        expect(transaction).toNot(beNil())
        try await asyncWait(
            description: "Diagnostics tracker should have been called",
            timeout: .seconds(4),
            pollInterval: .milliseconds(100)
        ) { [diagnosticsTracker = diagnosticsTracker] in
            diagnosticsTracker.trackedPurchaseRequestParams.value.count == 1
        }

        let params = try XCTUnwrap(diagnosticsTracker.trackedPurchaseRequestParams.value.first)
        expect(params.wasSuccessful).to(beTrue())
        expect(params.storeKitVersion) == .storeKit2
        expect(params.errorMessage).to(beNil())
        expect(params.errorCode).to(beNil())
        expect(params.storeKitErrorDescription).to(beNil())
    }

    func testPurchaseWithInvalidPromotionalOfferSignatureTracksError() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()
        let storeKit2ObserverModePurchaseDetector = MockStoreKit2ObserverModePurchaseDetector()
        let diagnosticsSynchronizer = MockDiagnosticsSynchronizer()
        let diagnosticsTracker = MockDiagnosticsTracker()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil),
                               storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchaseDetector,
                               diagnosticsSynchronizer: diagnosticsSynchronizer,
                               diagnosticsTracker: diagnosticsTracker)

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
            _ = try await orchestrator.purchase(
                sk2Product: product,
                package: nil,
                promotionalOffer: offer,
                winBackOffer: nil
            )
            XCTFail("Expected error")
        } catch {
            try await asyncWait(
                description: "Diagnostics tracker should have been called",
                timeout: .seconds(4),
                pollInterval: .milliseconds(100)
            ) { [diagnosticsTracker = diagnosticsTracker] in
                diagnosticsTracker.trackedPurchaseRequestParams.value.count == 1
            }

            let params = try XCTUnwrap(diagnosticsTracker.trackedPurchaseRequestParams.value.first)
            expect(params.wasSuccessful).to(beFalse())
            expect(params.storeKitVersion) == .storeKit2
            expect(params.errorMessage)
                .to(contain("The signature generated by RevenueCat could not be decoded: \(offer.signature)"))
            expect(params.errorCode) == ErrorCode.invalidPromotionalOfferError.rawValue
            expect(params.storeKitErrorDescription).to(beNil())
        }
    }

    #if swift(>=5.9)
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testPurchaseWithSimulatedErrorTracksError() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()
        try await self.testSession.setSimulatedError(.generic(.unknown), forAPI: .purchase)

        let transactionListener = MockStoreKit2TransactionListener()
        let storeKit2ObserverModePurchaseDetector = MockStoreKit2ObserverModePurchaseDetector()
        let diagnosticsSynchronizer = MockDiagnosticsSynchronizer()
        let diagnosticsTracker = MockDiagnosticsTracker()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil),
                               storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchaseDetector,
                               diagnosticsSynchronizer: diagnosticsSynchronizer,
                               diagnosticsTracker: diagnosticsTracker)

        let product = try await self.fetchSk2Product()

        do {
            let (transaction, _, _) = try await orchestrator.purchase(sk2Product: product,
                                                                      package: nil,
                                                                      promotionalOffer: nil,
                                                                      winBackOffer: nil)
            XCTFail("Expected error")
        } catch {
            try await asyncWait(
                description: "Diagnostics tracker should have been called",
                timeout: .seconds(4),
                pollInterval: .milliseconds(100)
            ) { [diagnosticsTracker = diagnosticsTracker] in
                diagnosticsTracker.trackedPurchaseRequestParams.value.count == 1
            }

            let params = try XCTUnwrap(diagnosticsTracker.trackedPurchaseRequestParams.value.first)
            expect(params.wasSuccessful).to(beFalse())
            expect(params.storeKitVersion) == .storeKit2
            expect(params.errorMessage) == "Unable to Complete Request"
            expect(params.errorCode) == ErrorCode.storeProblemError.rawValue
            expect(params.storeKitErrorDescription) == StoreKitError.unknown.trackingDescription
        }
    }
    #endif

    #if os(iOS) || targetEnvironment(macCatalyst) || os(macOS)
    @available(iOS 16.4, macOS 14.4, *)
    func testSetSK2PurchaseIntentListenerDoesNothingInSK1Mode() {
        let transactionListener = MockStoreKit2TransactionListener()
        let storeKit2ObserverModePurchaseDetector = MockStoreKit2ObserverModePurchaseDetector()
        let diagnosticsSynchronizer = MockDiagnosticsSynchronizer()
        let diagnosticsTracker = MockDiagnosticsTracker()

        self.systemInfo = MockSystemInfo(
            finishTransactions: true,
            storeKitVersion: .storeKit1
        )
        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil),
                               storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchaseDetector,
                               diagnosticsSynchronizer: diagnosticsSynchronizer,
                               diagnosticsTracker: diagnosticsTracker)

        let purchaseIntentListener = MockStoreKit2PurchaseIntentListener()

        self.orchestrator.setSK2PurchaseIntentListener(purchaseIntentListener)
        expect(purchaseIntentListener.listenForPurchaseIntentsCalled).to(beFalse())
        expect(purchaseIntentListener.lastProvidedDelegate).to(beNil())
        expect(purchaseIntentListener.setDelegateCalled).to(beFalse())
    }

    @available(iOS 16.4, macOS 14.4, *)
    func testSetSK2PurchaseIntentListenerStartsListeningAndSetsDelegateInSK2Mode() {
        let transactionListener = MockStoreKit2TransactionListener()
        let storeKit2ObserverModePurchaseDetector = MockStoreKit2ObserverModePurchaseDetector()
        let diagnosticsSynchronizer = MockDiagnosticsSynchronizer()
        let diagnosticsTracker = MockDiagnosticsTracker()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil),
                               storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchaseDetector,
                               diagnosticsSynchronizer: diagnosticsSynchronizer,
                               diagnosticsTracker: diagnosticsTracker)

        let purchaseIntentListener = MockStoreKit2PurchaseIntentListener()

        self.orchestrator.setSK2PurchaseIntentListener(purchaseIntentListener)
        expect(purchaseIntentListener.listenForPurchaseIntentsCalled).toEventually(beTrue())
        expect(purchaseIntentListener.lastProvidedDelegate).toEventuallyNot(beNil())
        expect(purchaseIntentListener.setDelegateCalled).toEventually(beTrue())
    }
    #endif

    #if compiler(>=6.0)
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func testEligibleWinBackOffersDoesntThrowsWhenInSK2Mode() async throws {
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        self.setUpOrchestrator()
        let product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: product)

        _ = try await self.orchestrator.eligibleWinBackOffers(forProduct: storeProduct)
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func testEligibleWinBackOffersReturnsValueFromWinBackEligibilityCalculator() async throws {
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        self.setUpOrchestrator()
        let product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: product)

        let eligibileWinBackOffers = try await self.orchestrator.eligibleWinBackOffers(forProduct: storeProduct)

        expect(eligibileWinBackOffers).to(equal([]))
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersCalled).to(beTrue())
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersCallCount).to(equal(1))
        expect(self.mockWinBackOfferEligibilityCalculator.eligibleWinBackOffersProduct).to(equal(storeProduct))
    }
    #endif
}
