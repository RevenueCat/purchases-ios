//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostAdServicesTokenTests.swift
//
//  Created by Madeline Beyl on 4/27/22.

import Foundation

import Nimble
import XCTest

@testable import RevenueCat

class BackendPostAdServicesTokenTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostAdServicesCallsHttpClient() throws {
        self.httpClient.mock(
            requestPath: .postAdServicesToken(appUserID: Self.userID),
            response: .init(statusCode: .success)
        )

        waitUntil { completed in
            self.backend.post(adServicesToken: "asdf", appUserID: "asdf") { _ in
                completed()
            }
        }
        expect(self.httpClient.calls).to(haveCount(1))
    }

}
