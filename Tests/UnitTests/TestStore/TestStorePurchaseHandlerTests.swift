//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStorePurchaseHandlerTests.swift
//
//  Created by Antonio Pallares on 1/8/25.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

class TestStorePurchaseHandlerTests: TestCase {

    private var mockTestStorePurchaseUI: MockTestStorePurchaseUI!

    override func setUp() {
        super.setUp()
        self.mockTestStorePurchaseUI = MockTestStorePurchaseUI()
    }

    func testPurchaseProductCallsPurchaseUI() async {
        let hander = TestStorePurchaseHandler(purchaseUI: mockTestStorePurchaseUI)

        _ = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockTestStorePurchaseUI.invokedPresentPurchaseUI.value)
    }

    func testSubsequentPurchaseProductCallsOnlyCallPurchaseUIOnce() async {
        mockTestStorePurchaseUI.stubbedPurchaseResult.value = {
            try! await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return .cancel
        }
        let hander = TestStorePurchaseHandler(purchaseUI: mockTestStorePurchaseUI)

        async let result0 = hander.purchase(product: Self.testStoreProduct)
        async let result1 = hander.purchase(product: Self.testStoreProduct)
        async let result2 = hander.purchase(product: Self.testStoreProduct)

        let results = await (result0, result1, result2)

        XCTAssertTrue(self.mockTestStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockTestStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

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
        mockTestStorePurchaseUI.stubbedPurchaseResult.value = { return .simulateSuccess }
        let hander = TestStorePurchaseHandler(purchaseUI: mockTestStorePurchaseUI)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockTestStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockTestStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .success = result {
            // Expected result
        } else {
            XCTFail("Expected .success result, got \(result)")
        }
    }

    func testPurchaseProductWithSimulatedFailure() async {
        mockTestStorePurchaseUI.stubbedPurchaseResult.value = { return .simulateFailure }
        let hander = TestStorePurchaseHandler(purchaseUI: mockTestStorePurchaseUI)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockTestStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockTestStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .failure = result {
            // Expected result
        } else {
            XCTFail("Expected .failure result, got \(result)")
        }
    }

    func testPurchaseProductWithSimulatedCancel() async {
        mockTestStorePurchaseUI.stubbedPurchaseResult.value = { return .cancel }
        let hander = TestStorePurchaseHandler(purchaseUI: mockTestStorePurchaseUI)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockTestStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockTestStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

        if case .cancel = result {
            // Expected result
        } else {
            XCTFail("Expected .cancel result, got \(result)")
        }
    }

    func testPurchaseProductWithUIError() async {
        mockTestStorePurchaseUI.stubbedPurchaseResult.value = { return .error(ErrorUtils.unknownError()) }
        let hander = TestStorePurchaseHandler(purchaseUI: mockTestStorePurchaseUI)

        let result = await hander.purchase(product: Self.testStoreProduct)

        XCTAssertTrue(self.mockTestStorePurchaseUI.invokedPresentPurchaseUI.value)
        XCTAssertEqual(self.mockTestStorePurchaseUI.invokedPresentPurchaseUICount.value, 1)

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
