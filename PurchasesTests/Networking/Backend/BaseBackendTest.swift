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

class BaseBackendTests: XCTestCase {

    private(set) var systemInfo: SystemInfo!
    private(set) var httpClient: MockHTTPClient!
    private(set) var backend: Backend!

    static let apiKey = "asharedsecret"
    static let userID = "user"

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo = try SystemInfo(platformInfo: nil, finishTransactions: true)
        self.httpClient = self.createClient()
        self.backend = Backend(httpClient: self.httpClient, apiKey: Self.apiKey)
    }

    override class func setUp() {
        XCTestObservationCenter.shared.addTestObserver(CurrentTestCaseTracker.shared)
    }

    override class func tearDown() {
        XCTestObservationCenter.shared.removeTestObserver(CurrentTestCaseTracker.shared)
    }

    func createClient() -> MockHTTPClient {
        XCTFail("This method must be overriden by subclasses")
        return self.createClient(#file)
    }

}

extension BaseBackendTests {

    final func createClient(_ file: StaticString) -> MockHTTPClient {
        let eTagManager = MockETagManager(userDefaults: MockUserDefaults())

        return MockHTTPClient(systemInfo: self.systemInfo, eTagManager: eTagManager, sourceTestFile: file)
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
