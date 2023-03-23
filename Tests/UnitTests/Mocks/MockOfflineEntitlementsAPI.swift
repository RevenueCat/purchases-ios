//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfflineEntitlementsAPI.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation
@testable import RevenueCat

class MockOfflineEntitlementsAPI: OfflineEntitlementsAPI {

    var stubbedProductEntitlementMappingResponse: Result<ProductEntitlementMappingResponse, BackendError> =
        .failure(.missingAppUserID())

    override func getProductEntitlementMapping(withRandomDelay randomDelay: Bool,
                                               completion: @escaping ProductEntitlementMappingResponseHandler) {
        completion(self.stubbedProductEntitlementMappingResponse)
    }

}
