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

    var invokedGetAdMobSSVStatus = false
    var invokedGetAdMobSSVStatusCount = 0
    var invokedGetAdMobSSVStatusParameters: (appUserID: String, clientTransactionID: String)?

    var stubbedGetAdMobSSVStatusResult: Result<AdMobSSVStatusResponse, BackendError>?

    override func getAdMobSSVStatus(
        appUserID: String,
        clientTransactionID: String,
        completion: @escaping AdMobSSVStatusResponseHandler
    ) {
        invokedGetAdMobSSVStatus = true
        invokedGetAdMobSSVStatusCount += 1
        invokedGetAdMobSSVStatusParameters = (appUserID, clientTransactionID)

        guard let result = stubbedGetAdMobSSVStatusResult else {
            preconditionFailure("Expected stubbedGetAdMobSSVStatusResult to be set before calling getAdMobSSVStatus")
        }

        completion(result)
    }
}
