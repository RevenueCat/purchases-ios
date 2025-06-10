//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockVirtualCurrenciesAPI.swift
//
//  Created by Will Taylor on 6/10/25.

import Foundation
@testable import RevenueCat

class MockVirtualCurrenciesAPI: VirtualCurrenciesAPI {

    init() {
        super.init(backendConfig: MockBackendConfiguration())
    }

    var invokedGetVirtualCurrencies = false
    var invokedGetVirtualCurrenciesCount = 0
    var invokedGetVirtualCurrenciesParameters: (appUserId: String, isAppBackgrounded: Bool)?

    var stubbedGetVirtualCurrenciesResult: Result<VirtualCurrenciesResponse, BackendError>?

    override func getVirtualCurrencies(
        appUserID: String,
        isAppBackgrounded: Bool,
        completion: @escaping VirtualCurrenciesResponseHandler
    ) {
        invokedGetVirtualCurrencies = true
        invokedGetVirtualCurrenciesCount += 1
        invokedGetVirtualCurrenciesParameters = (appUserID, isAppBackgrounded)

        completion(stubbedGetVirtualCurrenciesResult ?? .failure(.missingAppUserID()))
    }
}
