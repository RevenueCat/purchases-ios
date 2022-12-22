//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptFetcherTests.swift
//
//  Created by Andrés Boedo on 8/3/21.

import Foundation
import XCTest

import Nimble
@testable import RevenueCat

class BaseReceiptFetcherTests: TestCase {

    fileprivate var receiptFetcher: ReceiptFetcher!
    fileprivate var mockRequestFetcher: MockRequestFetcher!
    fileprivate var mockBundle: MockBundle!
    fileprivate var mockSystemInfo: MockSystemInfo!
    fileprivate var mockReceiptParser: MockReceiptParser!
    fileprivate var clock: TestClock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockBundle = MockBundle()
        self.mockRequestFetcher = MockRequestFetcher()
        self.mockReceiptParser = MockReceiptParser()
        self.mockSystemInfo = try MockSystemInfo(platformInfo: nil,
                                                 finishTransactions: false,
                                                 bundle: self.mockBundle)
        self.clock = TestClock()

        self.receiptFetcher = ReceiptFetcher(requestFetcher: self.mockRequestFetcher,
                                             systemInfo: self.mockSystemInfo,
                                             receiptParser: self.mockReceiptParser,
                                             fileReader: self.createFileReader(),
                                             clock: self.clock)
    }

    func createFileReader() -> FileReader {
        return DefaultFileReader()
    }

}

final class ReceiptFetcherTests: BaseReceiptFetcherTests {

    func testReceiptDataWithRefreshPolicyNeverReturnsReceiptData() {
        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .never, completion: completion)
        }

        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyReturnsReceiptData() {
        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty, completion: completion)
        }

        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyAlwaysReturnsReceiptData() {
        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyNeverDoesntRefreshIfEmpty() {
        self.mockBundle.receiptURLResult = .emptyReceipt

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .never, completion: completion)
        }
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
        expect(receivedData).to(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfEmpty() {
        self.mockBundle.receiptURLResult = .emptyReceipt

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty, completion: completion)
        }

        expect(receivedData).toNot(beNil())
        expect(receivedData).to(beEmpty())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfNil() {
        self.mockBundle.receiptURLResult = .nilURL

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty, completion: completion)
        }

        expect(receivedData).toNot(beNil())
        expect(receivedData).to(beEmpty())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyDoesntRefreshIfTheresData() {
        self.mockBundle.receiptURLResult = .receiptWithData

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty, completion: completion)
        }

        expect(receivedData).toNot(beNil())
        expect(receivedData).toNot(beEmpty())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
    }

    func testReceiptDataWithRefreshPolicyAlwaysRefreshesEvenIfTheresData() {
        self.mockBundle.receiptURLResult = .receiptWithData

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        expect(receivedData).toNot(beNil())
        expect(receivedData).toNot(beEmpty())

        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 1
    }

    func testReceiptDataWithRefreshPolicyAlwaysDoesNotRefreshIfRequestedWithinThrottleDuration() {
        let _: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        self.clock.advance(by: ReceiptRefreshPolicy.alwaysRefreshThrottleDuration - .milliseconds(500))

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        expect(receivedData).toNot(beEmpty())

        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 1
    }

    func testReceiptDataWithRefreshPolicyAlwaysRefreshesWithinThrottleDurationIfNoReceiptData() {
        self.mockBundle.receiptURLResult = .emptyReceipt

        let _: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        self.clock.advance(by: ReceiptRefreshPolicy.alwaysRefreshThrottleDuration - .milliseconds(500))

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        expect(receivedData).toNot(beNil())

        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 2
    }

    func testReceiptDataWithRefreshPolicyAlwaysRefreshesAfterThrottleDuration() {
        let _: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        self.clock.advance(by: ReceiptRefreshPolicy.alwaysRefreshThrottleDuration + .seconds(1))

        let receivedData: Data? = waitUntilValue { completion in
            self.receiptFetcher.receiptData(refreshPolicy: .always, completion: completion)
        }

        expect(receivedData).toNot(beEmpty())

        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 2
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class RetryingReceiptFetcherTests: BaseReceiptFetcherTests {

    private var mockFileReader: MockFileReader!

    override func setUpWithError() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.mockFileReader = MockFileReader()

        try super.setUpWithError()
    }

    override func createFileReader() -> FileReader {
        return self.mockFileReader
    }

    func testSampleDataIsCorrect() {
        // Tests rely on these conditions
        expect(Self.validReceipt.containsActivePurchase(forProductIdentifier: Self.productID)) == true
        expect(Self.receiptWithoutPurchases.containsActivePurchase(forProductIdentifier: Self.productID)) == false
    }

    func testReturnsAfterFirstTryIfNoReceiptURL() async {
        self.mockBundle.receiptURLResult = .nilURL

        let data = await self.fetch(productIdentifier: "", retries: 1)
        expect(data) == Data()
    }

    func testReturnsAfterFirstTryIfDataIsCorrect() async {
        self.mock(receipt: Self.validReceipt)

        let data = await self.fetch(productIdentifier: Self.productID, retries: 1)
        expect(data) == Self.validReceipt.asData

        expect(self.mockReceiptParser.invokedParseParametersList) == [
            Self.validReceipt.asData
        ]
    }

    func testDoesNotRetryIfMaximumIsZeroEvenIfDataIsInvalid() async {
        self.mock(receipt: Self.receiptWithoutPurchases)

        let data = await self.fetch(productIdentifier: Self.productID, retries: 0)
        expect(data) == Self.receiptWithoutPurchases.asData

        expect(self.mockReceiptParser.invokedParseParametersList) == [
            Self.receiptWithoutPurchases.asData
        ]
    }

    func testStopsRetryingEvenIfDataIsInvalid() async {
        self.mock(receipt: Self.receiptWithoutPurchases)

        let invalidData = Self.receiptWithoutPurchases.asData

        let data = await self.fetch(productIdentifier: Self.productID, retries: 2)
        expect(data) == invalidData

        expect(self.mockReceiptParser.invokedParseParametersList) == [
            invalidData,
            invalidData,
            invalidData
        ]
        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 3
    }

    func testRetriesIfFirstReceiptIsInvalid() async {
        self.mock(receipts: [Self.receiptWithoutPurchases, Self.validReceipt])

        let data = await self.fetch(productIdentifier: Self.productID, retries: 1)
        expect(data) == Self.validReceipt.asData

        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 2
        expect(self.mockReceiptParser.invokedParseParametersList) == [
            Self.receiptWithoutPurchases.asData,
            Self.validReceipt.asData
        ]
    }

    func testRetriesIfFirstReceiptThrowsError() async {
        self.mock(receipts: [.failure(.receiptParsingError),
                             .success(Self.validReceipt)])

        let data = await self.fetch(productIdentifier: Self.productID, retries: 1)
        expect(data) == Self.validReceipt.asData

        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 2
        expect(self.mockReceiptParser.invokedParseParametersList) == [
            Self.validReceipt.asData,
            Self.validReceipt.asData
        ]
    }

    func testStopsRetryingEvenIfParsingReceiptKeepsThrowingError() async {
        let invalidData = self.mockReceiptWithInvalidData()

        let data = await self.fetch(productIdentifier: Self.productID, retries: 1)
        expect(data) == invalidData

        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 2
        expect(self.mockReceiptParser.invokedParseParametersList) == [
            invalidData,
            invalidData
        ]
    }

    func testStopsRetryingIfFindsValidReceipt() async {
        self.mock(receipts: [Self.receiptWithoutPurchases, Self.validReceipt])

        let data = await self.fetch(productIdentifier: Self.productID, retries: 2)
        expect(data) == Self.validReceipt.asData

        expect(self.mockRequestFetcher.refreshReceiptCalledCount) == 2
        expect(self.mockReceiptParser.invokedParseParametersList) == [
            Self.receiptWithoutPurchases.asData,
            Self.validReceipt.asData
        ]
    }

    // MARK: -

    private func fetch(productIdentifier: String, retries: Int) async -> Data {
        return await withCheckedContinuation { continuation in
            self.receiptFetcher.receiptData(refreshPolicy: .retryUntilProductIsFound(
                productIdentifier: productIdentifier,
                maximumRetries: retries
            )) {
                continuation.resume(returning: $0 ?? Data())
            }
        }
    }

    private func mock(receipt: AppleReceipt) {
        self.mock(receipts: [receipt])
    }

    private func mock(receipts: [AppleReceipt]) {
        self.mock(receipts: receipts.map(Result.success))
    }

    private func mock(receipts: [Result<AppleReceipt, PurchasesReceiptParser.Error>]) {
        precondition(!receipts.isEmpty)

        self.mockBundle.receiptURLResult = .receiptWithData
        self.mockFileReader.mockedURLContents[self.mockBundle.appStoreReceiptURL!] = receipts
            .compactMap { $0.value?.asData }
        self.mockReceiptParser.stubbedParseResults = receipts
    }

    private func mockReceiptWithInvalidData() -> Data {
        let invalidData = Data(repeating: 0, count: 10)

        self.mockBundle.receiptURLResult = .receiptWithData
        self.mockFileReader.mockedURLContents[self.mockBundle.appStoreReceiptURL!] = [invalidData]
        self.mockReceiptParser.stubbedParseResults = [
            .failure(.receiptParsingError)
        ]

        return invalidData
    }

    private static let productID = "com.revenuecat.test_product"

    private static let validReceipt = AppleReceipt(
        bundleId: "bundle",
        applicationVersion: "1.0",
        originalApplicationVersion: nil,
        opaqueValue: Data(),
        sha1Hash: Data(),
        creationDate: Date(),
        expirationDate: nil,
        inAppPurchases: [
            .init(
                quantity: 1,
                productId: RetryingReceiptFetcherTests.productID,
                transactionId: "transaction",
                originalTransactionId: nil,
                productType: .autoRenewableSubscription,
                purchaseDate: Date(),
                originalPurchaseDate: nil,
                expiresDate: Date().addingTimeInterval(100),
                cancellationDate: nil,
                isInTrialPeriod: false,
                isInIntroOfferPeriod: false,
                webOrderLineItemId: nil,
                promotionalOfferIdentifier: nil
            )
        ]
    )

    private static let receiptWithoutPurchases = AppleReceipt(
        bundleId: "bundle",
        applicationVersion: "1.0",
        originalApplicationVersion: nil,
        opaqueValue: Data(),
        sha1Hash: Data(),
        creationDate: Date(),
        expirationDate: nil,
        inAppPurchases: []
    )
}

// MARK: -

private extension AppleReceipt {

    var asData: Data {
        // Note: this is not how receipts are serialized as `Data`
        // but it's used as a way to mock its deserialization.
        // swiftlint:disable:next force_try
        return try! self.prettyPrintedData
    }

}
