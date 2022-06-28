//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostAttributionDataTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendPostAttributionDataTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostAttributesPutsDataInDataKey() throws {
        self.httpClient.mock(
            requestPath: .postAttributionData(appUserID: Self.userID),
            response: .init(statusCode: .success)
        )

        let data: [String: AnyObject] = ["a": "b" as NSString, "c": "d" as NSString]

        backend.post(attributionData: data,
                     network: .adjust,
                     appUserID: Self.userID,
                     completion: nil)

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

}
