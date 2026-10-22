//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendSignatureVerificationTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendSignatureVerificationTests: BaseBackendTests {

    override var verificationMode: Configuration.EntitlementVerificationMode {
        return .informational
    }

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testRequestContainsSignatureHeader() throws {
        self.httpClient.mock(
            requestPath: .health,
            response: .init(statusCode: .success, verificationResult: .verified)
        )

        let error = waitUntilValue { completed in
            self.internalAPI.healthRequest(signatureVerification: true, completion: completed)
        }

        expect(error).to(beNil())
    }

    func testRequestFailsIfSignatureVerificationFails() throws {
        let expectedError: NetworkError = .signatureVerificationFailed(path: HTTPRequest.Path.health, code: .success)

        self.httpClient.mock(
            requestPath: .health,
            response: .init(error: expectedError)
        )

        let error = waitUntilValue { completed in
            self.internalAPI.healthRequest(signatureVerification: true, completion: completed)
        }

        expect(error).to(matchError(BackendError.networkError(expectedError)))
    }

}
