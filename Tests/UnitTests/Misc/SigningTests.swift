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

class SigningTests: TestCase {

    private var key: Signing.PublicKey!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.key = try Self.createRandomKey()
    }

    func testVerifySignatureWithInvalidSignatureReturnsFalseAndLogsError() throws {
        let logger = TestLogHandler()

        let message = "Hello World"
        let signature = "this is not a signature"

        expect(Signing.verify(message: message.asData,
                              hasValidSignature: signature,
                              with: self.key)) == false

        logger.verifyMessageWasLogged("Signature is not base64: \(signature)")
    }

    func testVerifySignatureReturnsFalseAndLogsError() throws {
        let logger = TestLogHandler()

        expect(Signing.verify(message: "Hello World".asData,
                              hasValidSignature: "invalid signature".asData.base64EncodedString(),
                              with: self.key)) == false

        logger.verifyMessageWasLogged("Signature failed validation")
    }

    func testVerifySignatureWithValidSignature() throws {
        let message = "Hello World"
        let signature = try self.sign(message: message)

        expect(Signing.verify(message: message.asData,
                              hasValidSignature: signature.base64EncodedString(),
                              with: self.key)) == true
    }

}

private extension SigningTests {

    static func createRandomKey() throws -> Signing.PublicKey {
        let tag = "com.revenuecat.SigningKeys\(UUID().uuidString)".asData

        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits: 384,
            kSecPrivateKeyAttrs: [
                    kSecAttrIsPermanent: true,
                    kSecAttrApplicationTag: tag
                ]
        ]

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return key
    }

    func sign(message: String) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(self.key,
                                                    Signing.keyAlgorithm,
                                                    Data(message.utf8) as CFData,
                                                    &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return signature as Data
    }
}
