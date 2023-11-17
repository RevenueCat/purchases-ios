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
        self.httpClient.mock(requestPath: .health, response: .init(statusCode: .success))

        let error = waitUntilValue { completed in
            self.internalAPI.healthRequest(signatureVerification: false, completion: completed)
        }

        expect(error).to(beNil())
    }

    func testHealthRequestIsNotAuthenticated() throws {
        waitUntil { completed in
            self.internalAPI.healthRequest(signatureVerification: false) { _ in
                completed()
            }
        }

        let request = try XCTUnwrap(self.httpClient.calls.onlyElement)

        expect(request.headers.keys).toNot(contain(HTTPClient.RequestHeader.authorization.rawValue))
    }

    func testHealthRequestWithFailure() {
        let expectedError: NetworkError = .offlineConnection()

        self.httpClient.mock(requestPath: .health, response: .init(error: expectedError))

        let error = waitUntilValue { completed in
            self.internalAPI.healthRequest(signatureVerification: false, completion: completed)
        }

        expect(error).to(matchError(BackendError.networkError(expectedError)))
    }

}
