//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockAdsAPI.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation
@testable import RevenueCat

class MockAdsAPI: AdsAPI {

    init() {
        super.init(backendConfig: MockBackendConfiguration())
    }

    var invokedGetRewardVerificationStatus = false
    var invokedGetRewardVerificationStatusCount = 0
    var invokedGetRewardVerificationStatusParameters: (appUserID: String, clientTransactionID: String)?

    var stubbedGetRewardVerificationStatusResult: Result<RewardVerificationStatusResponse, BackendError>?

    override func getRewardVerificationStatus(
        appUserID: String,
        clientTransactionID: String,
        completion: @escaping RewardVerificationStatusResponseHandler
    ) {
        invokedGetRewardVerificationStatus = true
        invokedGetRewardVerificationStatusCount += 1
        invokedGetRewardVerificationStatusParameters = (appUserID, clientTransactionID)

        guard let result = stubbedGetRewardVerificationStatusResult else {
            preconditionFailure(
                "Expected stubbedGetRewardVerificationStatusResult to be set before calling getRewardVerificationStatus"
            )
        }

        completion(result)
    }
}
