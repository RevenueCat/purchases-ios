//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SigningTests.swift
//
//  Created by Nacho Soto on 1/13/23.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
class SigningTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS12APIAvailableOrSkipTest()
    }

    func testLoadDefaultPublicKey() throws {
        let key = try Signing.loadPublicKey()

        let attributes = try XCTUnwrap(SecKeyCopyAttributes(key) as? [CFString: Any])
        expect(attributes[kSecAttrKeyType] as? String) == kSecAttrKeyTypeRSA as String
        expect(attributes[kSecAttrKeyClass] as? String) == kSecAttrKeyClassPublic as String
        expect(attributes[kSecAttrKeySizeInBits] as? Int) == 2048

        XCTExpectFailure("This needs the final production key") {
             expect(attributes[kSecAttrIssuer] as? String) == "RevenueCat"
        }
    }

    func testThrowsErrorIfPublicKeyFileDoesNotExist() throws {
        let url = try XCTUnwrap(URL(string: "not_existing_file.cer"))

        expect {
            try Signing.loadPublicKey(in: url)
        }.to(throwError { error in
            expect(error).to(matchError(ErrorCode.configurationError))
            expect(error.localizedDescription) == "There is an issue with your configuration. " +
            "Check the underlying error for more details. Could not find public key 'not_existing_file.cer'"
        })
    }

    func testThrowsErrorIfPublicKeyFileCannotBeParsed() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "invalid_certificate",
                                                           withExtension: "cer"))

        expect {
            try Signing.loadPublicKey(in: url)
        }.to(throwError { error in
            expect(error).to(matchError(ErrorCode.configurationError))
            expect(error.localizedDescription) == "There is an issue with your configuration. " +
            "Check the underlying error for more details. Failed to load certificate. " +
            "Ensure that it's a valid X.509 certificate."
        })
    }

}
