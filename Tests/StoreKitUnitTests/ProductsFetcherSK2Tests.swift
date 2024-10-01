//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsFetcherSK2Tests.swift
//
//  Created by Juanpe Catalán on 1/6/22.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class ProductsFetcherSK2Tests: StoreKitConfigTestCase {

    private var productsFetcherSK2: ProductsFetcherSK2!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.productsFetcherSK2 = ProductsFetcherSK2()
    }

    func testItFetchesProducts() async throws {
        let result = try await self.productsFetcherSK2.product(withIdentifier: Self.productID)
        expect(result.productIdentifier) == Self.productID

    }

}
