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

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testRequestContainsSignatureHeader() throws {
        self.httpClient.mock(
            requestPath: .health,
            response: .init(statusCode: .success, validationResult: .validated)
        )

        let error = waitUntilValue { completed in
            self.internalAPI.healthRequest(signatureVerification: true, completion: completed)
        }

        expect(error).to(beNil())
    }

    func testRequestFailsIfSignatureVerificationFails() throws {
        self.httpClient.mock(
            requestPath: .health,
            response: .init(statusCode: .success, validationResult: .failedValidation)
        )

        let error = waitUntilValue { completed in
            self.internalAPI.healthRequest(signatureVerification: true, completion: completed)
        }

        expect(error).to(matchError(BackendError.networkError(.signatureVerificationFailed(path: .health))))
    }

}
