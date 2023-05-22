//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfflineCustomerInfoCreator.swift
//
//  Created by Nacho Soto on 5/18/23.

@testable import RevenueCat

class MockOfflineCustomerInfoCreator: OfflineCustomerInfoCreator {

    init() {
        super.init(
            purchasedProductsFetcher: MockPurchasedProductsFetcher(),
            productEntitlementMappingFetcher: MockProductEntitlementMappingFetcher(),
            creator: { CustomerInfo(from: $0, mapping: $1, userID: $2) }
        )
    }

    var stubbedCreatedResult: Result<CustomerInfo, Error> = .failure(ErrorUtils.customerInfoError())
    var createRequested = false
    var createRequestCount = 0

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func create(for userID: String) async throws -> CustomerInfo {
        self.createRequested = true
        self.createRequestCount += 1

        return try self.stubbedCreatedResult.get()
    }

}
