//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimulatedStorePurchaseHandlerTests.swift
//
//  Created by Antonio Pallares on 1/8/25.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

class SimulatedStorePurchaseHandlerTests: TestCase {

    private var mockSimulatedStorePurchaseUI: MockSimulatedStorePurchaseUI!
    private var mockDateProvider: DateProvider!

    override func setUp() {
        super.setUp()
        self.mockSimulatedStorePurchaseUI = MockSimulatedStorePurchaseUI()
        self.mockDateProvider = MockDateProvider(stubbedNow: Self.mockDate)
    }

    func testPurchaseProductCallsPurchaseUI() async {
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI,
                                                   dateProvider: self.mockDateProvider)

        _ = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
    }

    func testSubsequentPurchaseProductCallsOnlyCallPurchaseUIOnce() async {

        let expectation = self.expectation(description: "All purchase product calls happened")

        mockSimulatedStorePurchaseUI.stubbedPurchaseResult.value = {
            #if compiler(>=5.9)
            await self.fulfillment(of: [expectation])
            #else
            self.wait(for: [expectation], timeout: 2)
            #endif
            return .cancel
        }
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI,
                                                   dateProvider: self.mockDateProvider)

        async let result0 = hander.purchase(product: Self.testStoreProduct)

        await expect(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value).toEventually(beTrue())
        await expect(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value).toEventually(equal(1))

        async let result1 = hander.purchase(product: Self.testStoreProduct)
        async let result2 = hander.purchase(product: Self.testStoreProduct)

        expectation.fulfill()

        let results = await (result0, result1, result2)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .cancel = results.0 {
            // Expected result
        } else {
            XCTFail("Expected .cancel result, got \(results.0)")
        }

        if case .failure = results.1 {
            // Expected result
        } else {
            XCTFail("Expected .failure result, got \(results.1)")
        }

        if case .failure = results.2 {
            // Expected result
        } else {
            XCTFail("Expected .failure result, got \(results.2)")
        }
    }

    func testPurchaseProductWithSimulatedSuccess() async {
        mockSimulatedStorePurchaseUI.stubbedPurchaseResult.value = { return .simulateSuccess }
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI,
                                                   dateProvider: self.mockDateProvider)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .success = result {
            // Expected result
        } else {
            XCTFail("Expected .success result, got \(result)")
        }
    }

    func testPurchaseProductWithSimulatedFailure() async {
        mockSimulatedStorePurchaseUI.stubbedPurchaseResult.value = { return .simulateFailure }
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI,
                                                   dateProvider: self.mockDateProvider)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .failure = result {
            // Expected result
        } else {
            XCTFail("Expected .failure result, got \(result)")
        }
    }

    func testPurchaseProductWithSimulatedCancel() async {
        mockSimulatedStorePurchaseUI.stubbedPurchaseResult.value = { return .cancel }
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI,
                                                   dateProvider: self.mockDateProvider)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .cancel = result {
            // Expected result
        } else {
            XCTFail("Expected .cancel result, got \(result)")
        }
    }

    func testPurchaseProductWithUIError() async {
        mockSimulatedStorePurchaseUI.stubbedPurchaseResult.value = { return .error(ErrorUtils.unknownError()) }
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI,
                                                   dateProvider: self.mockDateProvider)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .failure = result {
            // Expected result
        } else {
            XCTFail("Expected .failure result, got \(result)")
        }
    }

    func testStoreTransactionWhenPurchasingProduct() async throws {
        mockSimulatedStorePurchaseUI.stubbedPurchaseResult.value = { return .simulateSuccess }
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI,
                                                   dateProvider: self.mockDateProvider)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .success(let transaction) = result {
            expect(transaction.productIdentifier).to(equal(Self.testStoreProduct.productIdentifier))
            expect(transaction.purchaseDate) == Self.mockDate
            XCTAssertNil(transaction.jwsRepresentation)

            // Expect a specific token format for the transactionIdentifier property
            let token = try XCTUnwrap(transaction.transactionIdentifier)
            expect(token.hasPrefix("test_1756796794912_")).to(beTrue())
            var uuidSuffix = token
            uuidSuffix.removeFirst("test_1756796794912_".count)
            XCTAssertNotNil(UUID(uuidString: uuidSuffix))
        } else {
            XCTFail("Expected .success result, got \(result)")
        }
    }

    private static let testStoreProduct = TestStoreProduct(localizedTitle: "Title",
                                                           price: 1.99,
                                                           localizedPriceString: "$1.99",
                                                           productIdentifier: "product",
                                                           productType: .autoRenewableSubscription,
                                                           localizedDescription: "Description")

    private static let mockDate = Date(millisecondsSince1970: 1756796794912) // Sep 02 2025 07:06:34.912 UTC
}
