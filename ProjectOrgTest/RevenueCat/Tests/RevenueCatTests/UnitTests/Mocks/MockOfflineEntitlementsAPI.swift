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

    init() {
        super.init(backendConfig: MockBackendConfiguration())
    }

    var invokedGetProductEntitlementMapping = false
    var invokedGetProductEntitlementMappingCount = 0
    var invokedGetProductEntitlementMappingParameter: Bool?

    var stubbedGetProductEntitlementMappingResult: Result<ProductEntitlementMappingResponse, BackendError>?

    override func getProductEntitlementMapping(
        isAppBackgrounded: Bool,
        completion: @escaping ProductEntitlementMappingResponseHandler
    ) {
        self.invokedGetProductEntitlementMapping = true
        self.invokedGetProductEntitlementMappingCount += 1
        self.invokedGetProductEntitlementMappingParameter = isAppBackgrounded

        completion(self.stubbedGetProductEntitlementMappingResult ?? .failure(.missingAppUserID()))
    }

}
