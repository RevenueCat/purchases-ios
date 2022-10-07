//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendInternalTests.swift
//
//  Created by Nacho Soto on 10/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendInternalTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testHealthRequestWithSuccess() {
        var finished: Bool = false
        var error: Error?

        self.httpClient.mock(requestPath: .health, response: .init(statusCode: .success))

        self.internalAPI.healthRequest {
            error = $0
            finished = true
        }

        expect(finished).toEventually(beTrue())
        expect(error).to(beNil())
    }

    func testHealthRequestIsNotAuthenticated() {
        var finished = false

        self.internalAPI.healthRequest { _ in
            finished = true
        }

        expect(finished).toEventually(beTrue())
        expect(self.httpClient.calls.onlyElement?.headers).to(beEmpty())
    }

    func testHealthRequestWithFailure() {
        var finished: Bool = false
        var error: Error?

        let expectedError: NetworkError = .offlineConnection()

        self.httpClient.mock(requestPath: .health, response: .init(error: expectedError))

        self.internalAPI.healthRequest {
            error = $0
            finished = true
        }

        expect(finished).toEventually(beTrue())
        expect(error).to(matchError(BackendError.networkError(expectedError)))
    }

}
