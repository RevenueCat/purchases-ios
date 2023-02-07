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

import CryptoKit
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class SigningTests: TestCase {

    private typealias PrivateKey = Curve25519.Signing.PrivateKey
    private typealias PublicKey = Curve25519.Signing.PublicKey

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()
    }

    func testLoadDefaultPublicKey() throws {
        let key = try XCTUnwrap(try Signing.loadPublicKey() as? PublicKey)

        expect(key.rawRepresentation).toNot(beEmpty())
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
            "Check the underlying error for more details. Failed to load public key. " +
            "Ensure that it's a valid ed25519 key."
        })
    }

    func testVerifySignatureWithInvalidSignatureReturnsFalseAndLogsError() throws {
        let logger = TestLogHandler()

        let message = "Hello World"
        let nonce = "nonce"
        let signature = "this is not a signature"

        expect(Signing.verify(message: message.asData,
                              nonce: nonce.asData,
                              hasValidSignature: signature,
                              with: try Signing.loadPublicKey())) == false

        logger.verifyMessageWasLogged("Signature is not base64: \(signature)")
    }

    func testVerifySignatureReturnsFalseAndLogsError() throws {
        let logger = TestLogHandler()

        expect(Signing.verify(message: "Hello World".asData,
                              nonce: "nonce".asData,
                              hasValidSignature: "invalid signature".asData.base64EncodedString(),
                              with: try Signing.loadPublicKey())) == false

        logger.verifyMessageWasLogged("Signature failed validation")
    }

    func testVerifySignatureWithValidSignature() throws {
        let (privateKey, publicKey) = Self.createRandomKey()
        let message = "Hello World"
        let nonce = "nonce"
        let salt = Array(repeating: "a", count: Signing.saltSize).joined()

        let signature = try self.sign(key: privateKey, message: message, nonce: nonce, salt: salt)
        let fullSignature = salt.asData + signature

        expect(Signing.verify(message: message.asData,
                              nonce: nonce.asData,
                              hasValidSignature: fullSignature.base64EncodedString(),
                              with: publicKey)) == true
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension SigningTests {

    private static func createRandomKey() -> (PrivateKey, PublicKey) {
        let key = PrivateKey()

        return (key, key.publicKey)
    }

    private func sign(key: PrivateKey, message: String, nonce: String, salt: String) throws -> Data {
        let fullMessage = salt.asData + nonce.asData + message.asData

        return try key.signature(for: fullMessage)
    }

}
