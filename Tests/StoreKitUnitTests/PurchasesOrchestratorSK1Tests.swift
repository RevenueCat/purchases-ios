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
class PurchasesOrchestratorSK1Tests: PurchasesOrchestratorTestCase {

    // MARK: - StoreFront Changes

    func testClearCachedProductsAndOfferingsAfterStorefrontChangesWithSK1() async throws {
        self.orchestrator.storeKit1WrapperDidChangeStorefront(storeKit1Wrapper)

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    // MARK: - Purchasing

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

    func testPurchaseSK1PackageRetriesReceiptFetchIfEnabled() async throws {
        self.systemInfo = .init(
            platformInfo: nil,
            finishTransactions: false,
            storeKitVersion: .storeKit1,
            dangerousSettings: .init(autoSyncPurchases: true,
                                     internalSettings: DangerousSettings.Internal(enableReceiptFetchRetry: true))
        )
        self.setUpStoreKit1Wrapper()
        self.setUpOrchestrator()
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

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

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .retryUntilProductIsFound(
            productIdentifier: storeProduct.productIdentifier,
            maximumRetries: TransactionPoster.receiptRetryCount,
            sleepDuration: TransactionPoster.receiptRetrySleepDuration
        )

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
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

    // MARK: - Paywalls

    func testPurchaseSK1PackageWithPresentedPaywall() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
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

        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

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
        try AvailabilityChecks.skipIfTVOrWatchOSOrMacOS()
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

    // MARK: - Promotional Offers

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

}
