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

    override func setUp() {
        super.setUp()
        self.productsFetcherSK2 = ProductsFetcherSK2()
    }

    func testCachedProductsAreEmptyAfterClearingCachedProductCorrectly() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        _ = try await productsFetcherSK2.product(withIdentifier: Self.productID)

        var cachedProducts = await productsFetcherSK2.cachedProductsByIdentifier
        expect(cachedProducts).notTo(beEmpty())

        await productsFetcherSK2.clearCache()

        cachedProducts = await productsFetcherSK2.cachedProductsByIdentifier
        expect(cachedProducts).to(beEmpty())
    }

}
