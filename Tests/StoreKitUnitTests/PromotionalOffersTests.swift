//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PromotionalOffersSK2Tests: BasePurchasesOrchestratorTests {

    override class var storeKitVersion: StoreKitVersion { return .storeKit2 }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.receiptParser.stubbedReceiptHasTransactionsResult = true
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = StoreTransaction.from(
            transaction: MockStoreTransaction(jwsRepresentation: "jws", environment: .sandbox)
        )
    }

    func testMultipleProductsShareReceiptPreparationAndBackendRequest() async {
        let requests = [self.request("monthly"), self.request("annual", group: "other-group")]
        self.offerings.stubbedPostOffersResults = [self.success("monthly-signature"), self.success("annual-signature")]

        let results = await self.sign(requests)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results[0].request === requests[0])
        XCTAssertTrue(results[1].request === requests[1])
        XCTAssertEqual(results.map { $0.offer?.signedData.signature }, ["monthly-signature", "annual-signature"])
        XCTAssertEqual(results.map { $0.offer?.signedData.identifier }, ["promo", "promo"])
        XCTAssertTrue(results.allSatisfy { $0.error == nil })
        XCTAssertEqual(self.offerings.invokedPostOffersCount, 1)
        XCTAssertEqual(self.offerings.invokedPostOffersParameters?.offers.map(\.subscriptionGroup),
                       ["group", "other-group"])
        XCTAssertEqual(self.offerings.invokedPostOffersParameters?.appUserID, Self.mockUserID)
        self.assertReceiptPreparationCount(1)
        if Self.storeKitVersion == .storeKit1 {
            XCTAssertEqual(self.offerings.invokedPostOffersParameters?.receipt,
                           .receipt(self.receiptFetcher.mockReceiptData))
            XCTAssertEqual(self.receiptParser.invokedReceiptHasTransactionsCount, 1)
            XCTAssertEqual(self.receiptFetcher.receiptDataReceivedRefreshPolicy, .onlyIfEmpty)
        } else {
            XCTAssertEqual(self.offerings.invokedPostOffersParameters?.receipt, .jws("jws"))
            XCTAssertEqual(self.mockTransactionFetcher.fetchReceiptCount.value, 0)
        }
    }

    func testSingleOfferAPIStillReturnsSignedOfferUsingSharedReceiptPreparation() async {
        let request = self.request("monthly")
        self.offerings.stubbedPostOfferCompletionResult = self.success("single-signature")
        let result: Result<PromotionalOffer, PurchasesError> = await withCheckedContinuation { continuation in
            self.orchestrator.promotionalOffer(forProductDiscount: request.discount, product: request.product) {
                continuation.resume(returning: $0)
            }
        }
        XCTAssertEqual(result.value?.signedData.signature, "single-signature")
        XCTAssertEqual(result.value?.signedData.identifier, "promo")
        XCTAssertEqual(result.value?.discount, request.discount)
        XCTAssertNil(result.error)
        self.assertReceiptPreparationCount(1)
        XCTAssertEqual(self.offerings.invokedPostOfferCount, 1)
    }

    func testSingleOfferAPIStillRejectsMissingHistoryWithoutSigning() async {
        self.receiptParser.stubbedReceiptHasTransactionsResult = false
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = nil
        let request = self.request("monthly")
        let result: Result<PromotionalOffer, PurchasesError> = await withCheckedContinuation { continuation in
            self.orchestrator.promotionalOffer(forProductDiscount: request.discount, product: request.product) {
                continuation.resume(returning: $0)
            }
        }
        XCTAssertEqual(result.error?.asPublicError.code, ErrorCode.ineligibleError.rawValue)
        XCTAssertNil(result.value)
        XCTAssertEqual(self.offerings.invokedPostOfferCount, 0)
    }

    func testEmptyInputDoesNoWork() async {
        let results = await self.sign([])
        XCTAssertTrue(results.isEmpty)
        self.assertReceiptPreparationCount(0)
        XCTAssertEqual(self.offerings.invokedPostOffersCount, 0)
    }

    func testInvalidRequestsDoNotPreventValidOffersAndPreserveOrder() async {
        let requests = [self.request("bad", offerID: ""),
                        self.request("valid"),
                        self.request("bad", group: nil)]
        self.offerings.stubbedPostOffersResults = [self.success("valid")]

        let results = await self.sign(requests)

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].error?.code, ErrorCode.productDiscountMissingIdentifierError.rawValue)
        XCTAssertEqual(results[1].offer?.signedData.signature, "valid")
        XCTAssertEqual(results[2].error?.code,
                       ErrorCode.productDiscountMissingSubscriptionGroupIdentifierError.rawValue)
        XCTAssertNil(results[0].offer)
        XCTAssertNil(results[2].offer)
        XCTAssertEqual(self.offerings.invokedPostOffersParameters?.offers.map(\.productIdentifier), ["valid"])
    }

    func testAllInvalidRequestsDoNoReceiptOrNetworkWork() async {
        let results = await self.sign([self.request("bad", offerID: ""), self.request("bad", group: "")])
        XCTAssertTrue(results.allSatisfy { $0.error != nil && $0.offer == nil })
        self.assertReceiptPreparationCount(0)
        XCTAssertEqual(self.offerings.invokedPostOffersCount, 0)
    }

    func testIntroductoryAndUnrelatedDiscountsAreRejectedLocally() async {
        let intro = self.request("intro", type: .introductory)
        let original = self.request("original")
        let unrelated = PromotionalOfferRequest(discount: self.request("other", offerID: "other").discount,
                                                product: original.product)
        let results = await self.sign([intro, unrelated])
        XCTAssertEqual(results.map { $0.error?.code },
                       Array(repeating: ErrorCode.invalidPromotionalOfferError.rawValue, count: 2))
        self.assertReceiptPreparationCount(0)
        XCTAssertEqual(self.offerings.invokedPostOffersCount, 0)
    }

    func testNoHistoryFailsEveryValidRequestWithoutSigning() async {
        self.receiptParser.stubbedReceiptHasTransactionsResult = false
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = nil

        let results = await self.sign([self.request("monthly"), self.request("annual")])

        XCTAssertEqual(results.map { $0.error?.code }, Array(repeating: ErrorCode.ineligibleError.rawValue, count: 2))
        XCTAssertTrue(results.allSatisfy { $0.offer == nil })
        self.assertReceiptPreparationCount(1)
        XCTAssertEqual(self.offerings.invokedPostOffersCount, 0)
    }

    func testMissingReceiptOrJWSDoesNotSignOffers() async {
        self.receiptFetcher.shouldReturnReceipt = false
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = StoreTransaction.from(
            transaction: MockStoreTransaction(jwsRepresentation: nil)
        )
        let results = await self.sign([self.request("monthly"), self.request("annual")])
        XCTAssertEqual(results.map { $0.error?.code }, Array(repeating: ErrorCode.ineligibleError.rawValue, count: 2))
        XCTAssertEqual(self.offerings.invokedPostOffersCount, 0)
    }

    func testBackendFailureForOneOfferPreservesOtherOffer() async {
        self.offerings.stubbedPostOffersResults = [self.success("valid"), .failure(.missingAppUserID())]
        let results = await self.sign([self.request("monthly"), self.request("annual")])
        XCTAssertEqual(results[0].offer?.signedData.signature, "valid")
        XCTAssertNil(results[0].error)
        XCTAssertNotNil(results[1].error)
        XCTAssertNil(results[1].offer)
    }

    func testUserIDIsCapturedBeforeReceiptPreparation() async {
        self.receiptFetcher.onReceiptData = { self.currentUserProvider.mockAppUserID = "new-user" }
        self.mockTransactionFetcher.onFirstVerifiedAutoRenewableTransaction.value = {
            self.currentUserProvider.mockAppUserID = "new-user"
        }
        self.offerings.stubbedPostOffersResults = [self.success("valid")]
        _ = await self.sign([self.request("monthly")])
        XCTAssertEqual(self.currentUserProvider.mockAppUserID, "new-user")
        XCTAssertEqual(self.offerings.invokedPostOffersParameters?.appUserID, Self.mockUserID)
    }

    func testXcodeReceiptIsFetchedOnceForBatch() async throws {
        guard Self.storeKitVersion == .storeKit2 else { throw XCTSkip("StoreKit 2 receipt path") }
        self.mockTransactionFetcher.stubbedFirstVerifiedAutoRenewableTransaction = StoreTransaction.from(
            transaction: MockStoreTransaction(jwsRepresentation: "jws", environment: .xcode)
        )
        let receipt = StoreKit2Receipt(environment: .xcode,
                                       subscriptionStatusBySubscriptionGroupId: [:],
                                       transactions: ["jws"],
                                       bundleId: "test",
                                       originalApplicationVersion: nil,
                                       originalPurchaseDate: nil)
        self.mockTransactionFetcher.stubbedReceipt = receipt
        self.offerings.stubbedPostOffersResults = [self.success("first"), self.success("second")]

        let results = await self.sign([self.request("monthly"), self.request("annual")])

        XCTAssertTrue(results.allSatisfy { $0.offer != nil })
        XCTAssertEqual(self.mockTransactionFetcher.fetchReceiptCount.value, 1)
        XCTAssertEqual(self.offerings.invokedPostOffersParameters?.receipt, .sk2receipt(receipt))
    }

    private func sign(_ requests: [PromotionalOfferRequest]) async -> [PromotionalOfferResult] {
        return await withCheckedContinuation { continuation in
            self.orchestrator.promotionalOffers(for: requests) { results in
                XCTAssertTrue(Thread.isMainThread)
                continuation.resume(returning: results)
            }
        }
    }

    private func assertReceiptPreparationCount(_ count: Int, file: StaticString = #filePath, line: UInt = #line) {
        if Self.storeKitVersion == .storeKit1 {
            XCTAssertEqual(self.receiptFetcher.receiptDataTimesCalled, count, file: file, line: line)
        } else {
            XCTAssertEqual(self.mockTransactionFetcher.firstVerifiedAutoRenewableTransactionCount.value,
                           count, file: file, line: line)
        }
    }

    private func success(_ signature: String) -> Result<PostOfferForSigningOperation.SigningData, BackendError> {
        return .success((signature, "key", UUID(), 12345))
    }

    private func request(_ productID: String,
                         offerID: String = "promo",
                         group: String? = "group",
                         type: StoreProductDiscount.DiscountType = .promotional) -> PromotionalOfferRequest {
        let discount = TestStoreProductDiscount(identifier: offerID, price: 1, localizedPriceString: "$1",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 1, unit: .month),
                                                numberOfPeriods: 1, type: type)
        let product = TestStoreProduct(localizedTitle: productID, price: 5, currencyCode: "USD",
                                       localizedPriceString: "$5", productIdentifier: productID,
                                       productType: .autoRenewableSubscription, localizedDescription: productID,
                                       subscriptionGroupIdentifier: group, discounts: [discount],
                                       locale: Locale(identifier: "en_US")).toStoreProduct()
        return .init(discount: discount.toStoreProductDiscount(), product: product)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
final class PromotionalOffersSK1Tests: PromotionalOffersSK2Tests {

    override class var storeKitVersion: StoreKitVersion { return .storeKit1 }

}
