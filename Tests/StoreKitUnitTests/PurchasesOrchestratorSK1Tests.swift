//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorSK1Tests.swift
//
//  Created by Mark Villacampa on 16/2/24.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class PurchasesOrchestratorSK1Tests: BasePurchasesOrchestratorTests, PurchasesOrchestratorTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    // MARK: - StoreFront Changes

    func testClearCachedProductsAndOfferingsAfterStorefrontChanges() async throws {
        self.orchestrator.storeKit1WrapperDidChangeStorefront(storeKit1Wrapper)

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    // MARK: - Purchasing

    func testPurchasePostsReceipt() async throws {
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
        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .receipt(self.receiptFetcher.mockReceiptData)
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingID) == "offering"
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.source.initiationSource) == .purchase
    }

    func testPurchaseReturnsCorrectValues() async throws {
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = storeKit1Wrapper.payment(with: product)

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: nil,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(transaction?.sk1Transaction?.productIdentifier) == product.productIdentifier
        expect(userCancelled) == false
        expect(error).to(beNil())

        let expectedCustomerInfo: CustomerInfo = .emptyInfo
        expect(customerInfo) == expectedCustomerInfo
    }

    func testPurchaseDoesNotPostReceiptIfPurchaseFailed() async throws {
        storeKit1Wrapper.mockAddPaymentTransactionState = .failed
        storeKit1Wrapper.mockTransactionError = NSError(domain: SKErrorDomain,
                                                        code: SKError.Code.paymentCancelled.rawValue)

        let product = try await self.fetchSk1Product()
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  promotionalOffer: offer,
                                  package: nil,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }
        expect(self.backend.invokedPostReceiptData) == false
        expect(transaction?.sk1Transaction?.transactionState) == .failed
        expect(customerInfo).to(beNil())
        expect(error).to(matchError(ErrorCode.purchaseCancelledError))
        expect(userCancelled) == true
    }

    func testPurchaseWithPromotionalOfferPostsReceiptIfSuccessful() async throws {
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await fetchSk1Product()
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        let (transaction, customerInfo, error, userCancelled)  = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  promotionalOffer: offer,
                                  package: nil,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(transaction).toNot(beNil())
        expect(transaction?.sk1Transaction?.payment.paymentDiscount).toNot(beNil())
        expect(customerInfo) == mockCustomerInfo
        expect(error).to(beNil())
        expect(userCancelled) == false
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
    }

    func testPurchaseWithInvalidPromotionalOfferSignatureFails() async throws {
        storeKit1Wrapper.mockAddPaymentTransactionState = .failed
        storeKit1Wrapper.mockTransactionError = NSError(domain: SKErrorDomain,
                                                        code: SKError.Code.invalidSignature.rawValue)
        let product = try await self.fetchSk1Product()
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  promotionalOffer: offer,
                                  package: nil,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }
        expect(transaction).toNot(beNil())
        expect(transaction?.sk1Transaction?.payment.paymentDiscount).toNot(beNil())
        expect(customerInfo).to(beNil())
        expect(error).to(matchError(ErrorCode.invalidPromotionalOfferError))
        expect(userCancelled) == false
        expect(self.backend.invokedPostReceiptData) == false
    }

    func testPurchaseCancelled() async throws {
        storeKit1Wrapper.mockAddPaymentTransactionState = .failed
        storeKit1Wrapper.mockTransactionError = NSError(domain: SKErrorDomain,
                                                        code: SKError.Code.paymentCancelled.rawValue)
        let product = try await self.fetchSk1Product()
        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(product: StoreProduct(sk1Product: product),
                                  package: nil) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }
        expect(transaction).toNot(beNil())
        expect(customerInfo).to(beNil())
        expect(error).to(matchError(ErrorCode.purchaseCancelledError))
        expect(userCancelled) == true
        expect(self.backend.invokedPostReceiptData) == false
    }

    // MARK: - Purchasing, StoreKit 1 only

    func testPurchaseSK1DoesNotAlwaysRefreshReceiptInProduction() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.systemInfo.stubbedIsSandbox = false

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

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .onlyIfEmpty
    }

    func testPurchaseSK1RetriesReceiptFetchIfEnabled() async throws {
        self.systemInfo = .init(
            platformInfo: nil,
            finishTransactions: false,
            storeKitVersion: .storeKit1,
            dangerousSettings: .init(autoSyncPurchases: true,
                                     internalSettings: DangerousSettings.Internal(enableReceiptFetchRetry: true))
        )
        self.setUpStoreKit1Wrapper()
        self.setUpOrchestrator()
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

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

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .retryUntilProductIsFound(
            productIdentifier: product.productIdentifier,
            maximumRetries: TransactionPoster.receiptRetryCount,
            sleepDuration: TransactionPoster.receiptRetrySleepDuration
        )

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
    }

    func testPurchaseSK1WithNoProductIdentifierDoesNotPostReceipt() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = self.storeKit1Wrapper.payment(with: product)
        payment.productIdentifier = ""

        let (transaction, customerInfo, error, cancelled) =
        try await withCheckedThrowingContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: nil,
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

    func testPurchaseSK1ReturnsMissingReceiptErrorIfSendReceiptFailed() async throws {
        let product = try await self.fetchSk1Product()
        let payment = self.storeKit1Wrapper.payment(with: product)
        self.receiptFetcher.shouldReturnReceipt = false

        let (_, _, error, _) = try await withCheckedThrowingContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: nil,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }
        expect(error).to(matchError(ErrorCode.missingReceiptFileError))
    }

    // MARK: - Paywalls

    func testPurchaseWithPresentedPaywall() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = self.storeKit1Wrapper.payment(with: product)

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

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

        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.creationData
        ) == Self.paywallEventCreationData
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.data
        ) == Self.paywallEvent
    }

    func testPurchaseFailureRemembersPresentedPaywall() async throws {
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

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        self.backend.stubbedPostReceiptResult = .failure(.unexpectedBackendResponse(.customerInfoNil))
        try await purchase()

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        try await purchase()

        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.creationData
        ) == Self.paywallEventCreationData
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedPaywall?.data
        ) == Self.paywallEvent
    }

    // MARK: - AdServices and Attributes

    func testPurchaseDoesNotPostAdServicesTokenIfNotEnabled() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.attributionFetcher.adServicesTokenToReturn = "token"
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
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken).to(beNil())
    }

    #if !os(tvOS) && !os(watchOS)
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testPurchasePostsAdServicesTokenAndSubscriberAttributes() async throws {
        try AvailabilityChecks.skipIfTVOrWatchOSOrMacOS()
        try AvailabilityChecks.iOS14_3APIAvailableOrSkipTest()

        // Test for custom entitlement computation mode.
        // Without that mode, the token is posted upon calling `enableAdServicesAttributionTokenCollection`
        self.systemInfo = .init(
            finishTransactions: true,
            customEntitlementsComputation: true,
            storeKitVersion: .storeKit1
        )
        self.setUpAttribution()
        self.setUpOrchestrator()

        let token = "token"
        let attributes: SubscriberAttribute.Dictionary = [
            "attribute_1": .init(attribute: .campaign, value: "campaign"),
            "attribute_2": .init(attribute: .email, value: "email")
        ]

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.attributionFetcher.adServicesTokenToReturn = "token"
        self.subscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = attributes
        self.attribution.enableAdServicesAttributionTokenCollection()
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

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.aadAttributionToken) == token
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData.unsyncedAttributes) == attributes
    }
    #endif

    // MARK: - Promotional Offers

    func testGetPromotionalOfferWorksIfThereIsATransaction() async throws {
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

    func testGetPromotionalOfferSK1FailsWithIneligibleIfNoReceiptIsFound() async throws {
        self.receiptParser.stubbedReceiptHasTransactionsResult = true
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
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.ineligibleError))
        }

        expect(self.offerings.invokedPostOffer) == false
    }

    func testGetPromotionalOfferFailsWithIneligibleIfNoTransactionIsFound() async throws {
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
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.ineligibleError))
        }

        expect(self.offerings.invokedPostOffer) == false
    }

    func testGetPromotionalOfferFailsWithIneligibleIfBackendReturnsIneligible() async throws {
        self.receiptParser.stubbedReceiptHasTransactionsResult = true
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
            expect(self.offerings.invokedPostOfferCount) == 1
            expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    // MARK: - TransactionListenerDelegate

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSK1DoesNotListenForSK2Transactions() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

        expect(transactionListener.invokedDelegateSetter).toEventually(beTrue())
        expect(transactionListener.invokedListenForTransactions) == false
    }

    // MARK: - Sync Purchases

    func testSyncPurchasesPostsReceipt() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .receipt(self.receiptFetcher.mockReceiptData)
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesDoesntPostReceiptAndReturnsCustomerInfoIfNoTransaction() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        self.receiptParser.stubbedReceiptHasTransactionsResult = false

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)
        expect(self.backend.invokedPostReceiptData).to(beFalse())
        expect(self.customerInfoManager.invokedCustomerInfo).to(beFalse())
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesSK1PostsReceiptIfNoTransactionsAndEmptyOriginalPurchaseDate() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = try .init(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": "1.0",
                // Explicitly setting nil original_purchase_date
                "original_purchase_date": nil
            ] as [String: Any?]
        ])
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.receiptParser.stubbedReceiptHasTransactionsResult = false

        let customerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                     isRestore: false,
                                                                     initiationSource: .purchase)
        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.customerInfoManager.invokedCustomerInfo).to(beFalse())
        expect(customerInfo) == mockCustomerInfo
    }

    func testSyncPurchasesCallsSuccessDelegateMethod() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let receivedCustomerInfo = try await self.orchestrator.syncPurchases(receiptRefreshPolicy: .always,
                                                                             isRestore: false,
                                                                             initiationSource: .purchase)

        expect(receivedCustomerInfo) === mockCustomerInfo
    }

    func testSyncPurchasesPassesErrorOnFailure() async throws {
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
