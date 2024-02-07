//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPurchasedProductsFetcher.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation
@testable import RevenueCat
import StoreKit

final class MockPurchasedProductsFetcher: PurchasedProductsFetcherType {

    var invokedFetch = false
    var invokedFetchCount = 0
    var stubbedResult: Result<[PurchasedSK2Product], Error> = .failure(ErrorCode.invalidAppUserIdError)

    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product] {
        self.invokedFetch = true
        self.invokedFetchCount += 1

        return try self.stubbedResult.get()
    }

    var invokedClearCache = false
    var invokedClearCacheCount = 0

    func clearCache() {
        self.invokedClearCache = true
        self.invokedClearCacheCount += 1
    }

}
