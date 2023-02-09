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

    private let (privateKey, publicKey) = SigningTests.createRandomKey()

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()
    }

    func testLoadDefaultPublicKey() throws {
        let key = try XCTUnwrap(Signing.loadPublicKey() as? PublicKey)

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
                              with: Signing.loadPublicKey())) == false

        logger.verifyMessageWasLogged("Signature is not base64: \(signature)")
    }

    func testVerifySignatureWithInvalidSignature() throws {
        expect(Signing.verify(message: "Hello World".asData,
                              nonce: "nonce".asData,
                              hasValidSignature: "invalid signature".asData.base64EncodedString(),
                              with: Signing.loadPublicKey())) == false
    }

    func testVerifySignatureLogsWarningWhenFail() throws {
        let logger = TestLogHandler()

        _ = Signing.verify(message: "Hello World".asData,
                           nonce: "nonce".asData,
                           hasValidSignature: "invalid signature".asData.base64EncodedString(),
                           with: Signing.loadPublicKey())

        logger.verifyMessageWasLogged("Signature failed validation", level: .warn)
    }

    func testVerifySignatureWithValidSignature() throws {
        let message = "Hello World"
        let nonce = "nonce"
        let salt = Self.createSalt()

        let signature = try self.sign(message: message, nonce: nonce, salt: salt)
        let fullSignature = salt.asData + signature

        expect(Signing.verify(message: message.asData,
                              nonce: nonce.asData,
                              hasValidSignature: fullSignature.base64EncodedString(),
                              with: self.publicKey)) == true
    }

    func testVerifyKnownSignature() throws {
        /*
         Signature retrieved with:
        curl -v 'https://api.revenuecat.com/v1/subscribers/identify' \
        -X POST \
        -H 'X-Nonce: MTIzNDU2Nzg5MGFi' \
        -H 'Authorization: Bearer {api_key}' \
        -H 'content-type: application/json' \
        -H 'Host: api.revenuecat.com' \
        -H 'Connection: close' \
        -H 'Content-Length: 54' \
        -d '{"app_user_id": "test", "new_app_user_id": "new_user"}'
         */

        // swiftlint:disable line_length
        let response = """
        {"request_date":"2023-02-14T17:10:11Z","request_date_ms":1676394611556,"subscriber":{"entitlements":{},"first_seen":"2023-02-07T18:26:02Z","last_seen":"2023-02-07T18:26:02Z","management_url":null,"non_subscriptions":{},"original_app_user_id":"new_user","original_application_version":null,"original_purchase_date":null,"other_purchases":{},"subscriptions":{}}}\n
        """
        let expectedSignature = "Jmax3TdnBIe0/zFeHT5KJrFNoGxWtQAOuYTjnEXDHa0z3/npDG9nRB4vrUkt/ZxVh7SU+P++O3LnObxeuz3tFAILs75bxIqXwp6LqdV7Tgo="
        // swiftlint:enable line_length

        let nonce = try XCTUnwrap(Data(base64Encoded: "MTIzNDU2Nzg5MGFi"))

        expect(
            Signing.verify(message: response.asData,
                           nonce: nonce,
                           hasValidSignature: expectedSignature,
                           with: Signing.loadPublicKey())
        ) == true
    }

    func testResponseValidationWithNoProvidedKey() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse.create(with: Data(),
                                           statusCode: .success,
                                           headers: [:],
                                           request: request,
                                           publicKey: nil)

        expect(response.validationResult) == .notRequested
    }

    func testResponseValidationWithNoSignatureInResponse() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse.create(with: Data(),
                                           statusCode: .success,
                                           headers: [:],
                                           request: request,
                                           publicKey: self.publicKey)

        expect(response.validationResult) == .failedValidation
    }

    func testResponseValidationWithInvalidSignature() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse.create(
            with: Data(),
            statusCode: .success,
            headers: [
                HTTPClient.responseSignatureHeaderName: "invalid_signature"
            ],
            request: request,
            publicKey: self.publicKey
        )

        expect(response.validationResult) == .failedValidation
    }

    func testResponseValidationWithValidSignature() throws {
        let message = "Hello World"
        let nonce = "0123456789ab"
        let salt = Self.createSalt()

        let signature = try self.sign(message: message, nonce: nonce, salt: salt)
        let fullSignature = salt.asData + signature

        let request = HTTPRequest(method: .get, path: .health, nonce: nonce.asData)
        let response = HTTPResponse.create(
            with: message.asData,
            statusCode: .success,
            headers: [
                HTTPClient.responseSignatureHeaderName: fullSignature.base64EncodedString()
            ],
            request: request,
            publicKey: self.publicKey
        )

        expect(response.validationResult) == .validated
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension SigningTests {

    private static func createRandomKey() -> (PrivateKey, PublicKey) {
        let key = PrivateKey()

        return (key, key.publicKey)
    }

    private func sign(message: String, nonce: String, salt: String) throws -> Data {
        return try self.sign(key: self.privateKey,
                             message: message.asData,
                             nonce: nonce.asData,
                             salt: salt.asData)
    }
    private func sign(key: PrivateKey, message: Data, nonce: Data, salt: Data) throws -> Data {
        return try key.signature(for: salt + nonce + message)
    }

    private static func createSalt() -> String {
        return Array(repeating: "a", count: Signing.saltSize).joined()
    }

}
