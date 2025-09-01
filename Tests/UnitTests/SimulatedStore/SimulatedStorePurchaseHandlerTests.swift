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

#if SIMULATED_STORE

class SimulatedStorePurchaseHandlerTests: TestCase {

    private var mockSimulatedStorePurchaseUI: MockSimulatedStorePurchaseUI!

    override func setUp() {
        super.setUp()
        self.mockSimulatedStorePurchaseUI = MockSimulatedStorePurchaseUI()
    }

    func testPurchaseProductCallsPurchaseUI() async {
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI)

        _ = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
    }

    func testSubsequentPurchaseProductCallsOnlyCallPurchaseUIOnce() async {

        let expectation = self.expectation(description: "All purchase product calls happened")

        mockSimulatedStorePurchaseUI.stubbedPurchaseResult.value = {
            await self.fulfillment(of: [expectation])
            return .cancel
        }
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI)

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
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI)

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
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI)

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
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI)

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
        let hander = SimulatedStorePurchaseHandler(purchaseUI: mockSimulatedStorePurchaseUI)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockSimulatedStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .failure = result {
            // Expected result
        } else {
            XCTFail("Expected .failure result, got \(result)")
        }
    }

    private static let testStoreProduct = TestStoreProduct(localizedTitle: "Title",
                                                           price: 1.99,
                                                           localizedPriceString: "$1.99",
                                                           productIdentifier: "product",
                                                           productType: .autoRenewableSubscription,
                                                           localizedDescription: "Description")
}

#endif // SIMULATED_STORE
