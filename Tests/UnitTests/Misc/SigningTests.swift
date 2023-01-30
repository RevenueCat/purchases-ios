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
        let nonce = "nonce"
        let signature = "this is not a signature"

        expect(Signing.verify(message: message.asData,
                              nonce: nonce.asData,
                              hasValidSignature: signature,
                              with: self.key)) == false

        logger.verifyMessageWasLogged("Signature is not base64: \(signature)")
    }

    func testVerifySignatureReturnsFalseAndLogsError() throws {
        let logger = TestLogHandler()

        expect(Signing.verify(message: "Hello World".asData,
                              nonce: "nonce".asData,
                              hasValidSignature: "invalid signature".asData.base64EncodedString(),
                              with: self.key)) == false

        logger.verifyMessageWasLogged("Signature failed validation")
    }

    func testVerifySignatureWithValidSignature() throws {
        let message = "Hello World"
        let nonce = "nonce"
        let salt = "salt"
        let signature = try self.sign(message: message, nonce: nonce, salt: salt)
        let fullSignature = salt.asData + signature
        let fullMessage = salt.asData + nonce.asData + message.asData

        expect(Signing.verify(message: fullMessage,
                              nonce: nonce.asData,
                              hasValidSignature: fullSignature.base64EncodedString(),
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

    func sign(message: String, nonce: String, salt: String) throws -> Data {
        var error: Unmanaged<CFError>?
        let fullMessage = salt.asData + nonce.asData + message.asData
        guard let signature = SecKeyCreateSignature(self.key,
                                                    Signing.keyAlgorithm,
                                                    fullMessage as CFData,
                                                    &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return signature as Data
    }
}
