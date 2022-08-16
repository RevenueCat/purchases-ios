//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseBackendTest.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import SnapshotTesting
import XCTest

@testable import RevenueCat

class BaseBackendTests: TestCase {

    private(set) var systemInfo: SystemInfo!
    private(set) var httpClient: MockHTTPClient!
    private(set) var operationDispatcher: MockOperationDispatcher!
    private(set) var backend: Backend!
    private(set) var offerings: OfferingsAPI!
    private(set) var identity: IdentityAPI!

    static let apiKey = "asharedsecret"
    static let userID = "user"

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: true)
        self.httpClient = self.createClient()
        self.operationDispatcher = MockOperationDispatcher()

        let attributionFetcher = AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                    systemInfo: self.systemInfo)
        let backendConfig = BackendConfiguration(httpClient: self.httpClient,
                                                 operationDispatcher: operationDispatcher,
                                                 operationQueue: MockBackend.QueueProvider.createBackendQueue(),
                                                 dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate))

        let customer = CustomerAPI(backendConfig: backendConfig, attributionFetcher: attributionFetcher)
        self.identity = IdentityAPI(backendConfig: backendConfig)
        self.offerings = OfferingsAPI(backendConfig: backendConfig)
        self.backend = Backend(backendConfig: backendConfig,
                               customerAPI: customer,
                               identityAPI: self.identity,
                               offeringsAPI: self.offerings)
    }

    func createClient() -> MockHTTPClient {
        XCTFail("This method must be overriden by subclasses")
        return self.createClient(#file)
    }

}

extension BaseBackendTests {

    final func createClient(_ file: StaticString) -> MockHTTPClient {
        let eTagManager = MockETagManager(userDefaults: MockUserDefaults())

        return MockHTTPClient(apiKey: Self.apiKey,
                              systemInfo: self.systemInfo,
                              eTagManager: eTagManager,
                              sourceTestFile: file)
    }

}

extension BaseBackendTests {

    static let serverErrorResponse = [
        "code": "7225",
        "message": "something is bad up in the cloud"
    ]

    static let validCustomerResponse: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2017-08-30T02:40:36Z"
                ]
            ]
        ]
    ]

}
