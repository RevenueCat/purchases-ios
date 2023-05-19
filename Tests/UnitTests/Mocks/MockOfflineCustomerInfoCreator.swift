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

}
