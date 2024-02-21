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

    // MARK: - StoreFront Changes

    func testClearCachedProductsAndOfferingsAfterStorefrontChanges() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.orchestrator.storefrontDidUpdate(with: MockStorefront(countryCode: "ESP"))

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    // MARK: - Purchasing

    func testPurchasePostsReceipt() async throws {
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

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .jws(transaction.jwsRepresentation!)
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingID) == "offering"
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    func testPurchaseReturnsCorrectValues() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        let mockTransaction = try await self.simulateAnyPurchase()
        mockStoreKit2TransactionListener?.mockTransaction = .init(mockTransaction.underlyingTransaction)

        let product = try await self.fetchSk2Product()
        let (transaction, customerInfo, userCancelled) = try await orchestrator.purchase(sk2Product: product,
                                                                                         package: nil,
                                                                                         promotionalOffer: nil)

        expect(transaction?.sk2Transaction) == mockTransaction.underlyingTransaction
        expect(userCancelled) == false

        let expectedCustomerInfo: CustomerInfo = .emptyInfo
        expect(customerInfo) == expectedCustomerInfo

        expect(self.mockStoreKit2TransactionListener?.invokedHandle) == true
        expect(self.mockStoreKit2TransactionListener?.invokedHandleCount) == 1
    }

    func testPurchaseDoesNotPostReceiptIfPurchaseFailed() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        // As of Xcode 15.2 this makes purchases fail with `StoreKitError.unknown`
        testSession.failTransactionsEnabled = true
        let product = try await fetchSk2Product()

        do {
            _ = try await orchestrator.purchase(sk2Product: product,
                                                package: nil,
                                                promotionalOffer: nil)
            XCTFail("Expected error")
        } catch {
            expect(self.backend.invokedPostReceiptData) == false
            expect(self.mockStoreKit2TransactionListener?.invokedHandle) == false
        }
    }

    func testPurchaseWithPromotionalOfferPostsReceiptIfSuccessful() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        throw XCTSkip("Purchasing with a promo offer in SK2 using a StoreKit Config file returns an unknown error")
    }

    func testPurchaseWithInvalidPromotionalOfferSignatureFails() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

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

    func testPurchaseCancelled() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.customerInfoManager.stubbedCustomerInfoResult = .success(self.mockCustomerInfo)
        self.mockStoreKit2TransactionListener?.mockResult = .init(.userCancelled)

        let product = try await self.fetchSk2Product()

        let (transaction, customerInfo, cancelled) = try await self.orchestrator.purchase(sk2Product: product,
                                                                                          package: nil,
                                                                                          promotionalOffer: nil)

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

    // MARK: - Purchasing, StoreKit 2 only

    func testPurchaseSK2IncludesAppUserIdIfUUID() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let uuid = UUID()
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: uuid.uuidString)
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        customerInfoManager.stubbedCustomerInfoResult = .success(.emptyInfo)
        backend.stubbedPostReceiptResult = .success(.emptyInfo)

        let product = try await fetchSk2Product()
        let result = try await self.orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)
        expect(result.transaction?.sk2Transaction?.appAccountToken).to(equal(uuid))
    }

    func testPurchaseSK2DoesNotIncludeAppUserIdIfNotUUID() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: "not_a_uuid")
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await fetchSk2Product()
        let result = try await self.orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)
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
        let result = try await orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

        expect(result.transaction) == transaction.verifiedStoreTransaction
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .sk2receipt(receipt)
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingID).to(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    // MARK: - Paywalls

    func testPurchaseWithPresentedPaywall() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

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
                                                 promotionalOffer: nil)

        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.creationData
        ) == Self.paywallEventCreationData
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.data
        ) == Self.paywallEvent
    }

    func testPurchaseFailureRemembersPresentedPaywall() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        self.backend.stubbedPostReceiptResult = .failure(.unexpectedBackendResponse(.customerInfoNil))
        _ = try? await self.orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        _ = try await self.orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.creationData
        ) == Self.paywallEventCreationData
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.data
        ) == Self.paywallEvent
    }

    // MARK: - AdServices and Attributes

    func testPurchaseDoesNotPostAdServicesTokenIfNotEnabled() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try AvailabilityChecks.skipIfTVOrWatchOSOrMacOS()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.attributionFetcher.adServicesTokenToReturn = "token"
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        mockListener.mockTransaction = .init(try await self.simulateAnyPurchase())

        let product = try await self.fetchSk2Product()
        _ = try await self.orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken).to(beNil())
    }

    #if !os(tvOS) && !os(watchOS)
    func testPurchasePostsAdServicesTokenAndSubscriberAttributes() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
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
        _ = try await self.orchestrator.purchase(sk2Product: product, package: nil, promotionalOffer: nil)

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

    func testSK2TransactionListenerDoesNotFinishTransactionIfPostingReceiptFails() async throws {
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

    func testSK2TransactionListenerOnlyFinishesTransactionsAfterPostingReceipt() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

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
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

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
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

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

    func testSyncPurchasesDoesntPostReceiptAndReturnsCustomerInfoIfNoTransaction() async throws {
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = nil
        self.customerInfoManager.stubbedCustomerInfoResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)
        expect(self.backend.invokedPostReceiptData).to(beFalse())
        expect(self.customerInfoManager.invokedCustomerInfo).to(beTrue())
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
}
