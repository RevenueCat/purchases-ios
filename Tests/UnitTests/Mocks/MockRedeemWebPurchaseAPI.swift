//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockRedeemWebPurchaseAPI.swift
//
//  Created by Antonio Rico on 11/06/24.

import Foundation
@testable import RevenueCat

class MockRedeemWebPurchaseAPI: RedeemWebPurchaseAPI {

    init() {
        super.init(backendConfig: MockBackendConfiguration())
    }

    var invokedPostRedeemWebPurchase = false
    var invokedPostRedeemWebPurchaseCount = 0
    var invokedPostRedeemWebPurchaseParameters: (appUserId: String, redemptionToken: String)?

    var stubbedPostRedeemWebPurchaseResult: Result<CustomerInfo, BackendError>?

    override func postRedeemWebPurchase(appUserID: String,
                                        redemptionToken: String,
                                        completion: @escaping RedeemWebPurchaseAPI.RedeemWebPurchaseResponseHandler) {
        self.invokedPostRedeemWebPurchase = true
        self.invokedPostRedeemWebPurchaseCount += 1
        self.invokedPostRedeemWebPurchaseParameters = (appUserID, redemptionToken)

        completion(self.stubbedPostRedeemWebPurchaseResult ?? .failure(.missingAppUserID()))
    }

}
