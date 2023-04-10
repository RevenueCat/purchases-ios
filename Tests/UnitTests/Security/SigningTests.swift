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
        let requestDate: UInt64 = 1677005916012
        let signature = "this is not a signature"

        expect(Signing.verify(
            signature: signature,
            with: .init(
                message: message.asData,
                nonce: nonce.asData,
                requestDate: requestDate
            ),
            publicKey: Signing.loadPublicKey()
        )) == false

        logger.verifyMessageWasLogged("Signature is not base64: \(signature)")
    }

    func testVerifySignatureWithInvalidSignature() throws {
        expect(Signing.verify(
            signature: "invalid signature".asData.base64EncodedString(),
            with: .init(
                message: "Hello World".asData,
                nonce: "nonce".asData,
                requestDate: 1677005916012
            ),
            publicKey: Signing.loadPublicKey()
        )) == false
    }

    func testVerifySignatureLogsWarningWhenFail() throws {
        let logger = TestLogHandler()

        _ = Signing.verify(signature: "invalid signature".asData.base64EncodedString(),
                           with: .init(
                            message: "Hello World".asData,
                            nonce: "nonce".asData,
                            requestDate: 1677005916012
                           ),
                           publicKey: Signing.loadPublicKey())

        logger.verifyMessageWasLogged("Signature failed verification", level: .warn)
    }

    func testVerifySignatureWithValidSignature() throws {
        let message = "Hello World"
        let nonce = "nonce"
        let requestDate: UInt64 = 1677005916012
        let salt = Self.createSalt()

        let signature = try self.sign(
            parameters: .init(
                message: message.asData,
                nonce: nonce.asData,
                requestDate: requestDate
            ),
            salt: salt.asData
        )
        let fullSignature = salt.asData + signature

        expect(Signing.verify(
            signature: fullSignature.base64EncodedString(),
            with: .init(
                message: message.asData,
                nonce: nonce.asData,
                requestDate: requestDate
            ),
            publicKey: self.publicKey
        )) == true
    }

    func testVerifyKnownSignatureWithNoETag() throws {
        /*
         Signature retrieved with:
        curl -v 'https://api.revenuecat.com/v1/subscribers/login' \
        -X GET \
        -H 'X-Nonce: MTIzNDU2Nzg5MGFi' \
        -H 'Authorization: Bearer {api_key}' \
        -H 'Host: api.revenuecat.com'
         */

        // swiftlint:disable line_length
        let response = """
        {"request_date":"2023-02-21T18:58:36Z","request_date_ms":1677005916011,"subscriber":{"entitlements":{},"first_seen":"2023-02-21T18:58:35Z","last_seen":"2023-02-21T18:58:35Z","management_url":null,"non_subscriptions":{},"original_app_user_id":"login","original_application_version":null,"original_purchase_date":null,"other_purchases":{},"subscriptions":{}}}\n
        """
        let expectedSignature = "2bm3QppRywK5ULyCRLS5JJy9sq+84IkMk0Ue4LsywEp87t0tDObpzPlu30l4Desq9X65UFuosqwCLMizruDHbKvPqQLce0hrIuZpgic+cQ8="
        // swiftlint:enable line_length

        let nonce = try XCTUnwrap(Data(base64Encoded: "MTIzNDU2Nzg5MGFi"))
        let requestDate: UInt64 = 1677005916012

        expect(
            Signing.verify(
                signature: expectedSignature,
                with: .init(
                    message: response.asData,
                    nonce: nonce,
                    requestDate: requestDate
                ),
                publicKey: Signing.loadPublicKey()
            )
        ) == true
    }

    func testVerifyKnownSignatureWithETag() throws {
        /*
         Signature retrieved with:
         curl -v 'https://api.revenuecat.com/v1/subscribers/login' \
         -X GET \
         -H 'X-Nonce: MTIzNDU2Nzg5MGFi' \
         -H 'Authorization: Bearer {api_key}' \
         -H 'X-RevenueCat-ETag: b7bd9a697c7fd1a2 \
         -H 'Host: api.revenuecat.com'
         */

        let nonce = try XCTUnwrap(Data(base64Encoded: "MTIzNDU2Nzg5MGFi"))
        let requestDate: UInt64 = 1677013582768
        let eTag = "b7bd9a697c7fd1a2"

        // swiftlint:disable:next line_length
        let expectedSignature = "IbHvwMBfhgF6Et6AH2KigMF9to3O8Ioh/z9GlG/8mhBInfd8wkzdhp/p/QOucYJZYe7nwKRCtuGjC5d3iBqdX53WUHCpT0IVFo1dzZFAegU="

        expect(
            Signing.verify(
                signature: expectedSignature,
                with: .init(
                    message: eTag.asData,
                    nonce: nonce,
                    requestDate: requestDate
                ),
                publicKey: Signing.loadPublicKey()
            )
        ) == true
    }

    func testResponseVerificationWithNoProvidedKey() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse.create(with: Data(),
                                           statusCode: .success,
                                           headers: [:],
                                           request: request,
                                           publicKey: nil)

        expect(response.verificationResult) == .notRequested
    }

    func testResponseVerificationWithNoSignatureInResponse() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse.create(with: Data(),
                                           statusCode: .success,
                                           headers: [:],
                                           request: request,
                                           publicKey: self.publicKey)

        expect(response.verificationResult) == .failed
    }

    func testResponseVerificationWithInvalidSignature() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse.create(
            with: Data(),
            statusCode: .success,
            headers: [
                HTTPClient.ResponseHeader.signature.rawValue: "invalid_signature"
            ],
            request: request,
            publicKey: self.publicKey
        )

        expect(response.verificationResult) == .failed
    }

    func testResponseVerificationWithValidSignature() throws {
        let message = "Hello World"
        let nonce = "0123456789ab"
        let requestDate = Date().millisecondsSince1970
        let salt = Self.createSalt()

        let signature = try self.sign(parameters: .init(message: message.asData,
                                                        nonce: nonce.asData,
                                                        requestDate: requestDate),
                                      salt: salt.asData)
        let fullSignature = salt.asData + signature

        let request = HTTPRequest(method: .get, path: .health, nonce: nonce.asData)
        let response = HTTPResponse.create(
            with: message.asData,
            statusCode: .success,
            headers: [
                HTTPClient.ResponseHeader.signature.rawValue: fullSignature.base64EncodedString(),
                HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate)
            ],
            request: request,
            publicKey: self.publicKey
        )

        expect(response.verificationResult) == .verified
    }

    func testResponseVerificationWithETagValidSignature() throws {
        let message = "Hello World"
        let nonce = "0123456789ab"
        let etag = "etag"
        let requestDate = Date().millisecondsSince1970
        let salt = Self.createSalt()

        let signature = try self.sign(parameters: .init(message: etag.asData,
                                                        nonce: nonce.asData,
                                                        requestDate: requestDate),
                                      salt: salt.asData)
        let fullSignature = salt.asData + signature

        let request = HTTPRequest(method: .get, path: .logIn, nonce: nonce.asData)
        let response = HTTPResponse.create(
            with: message.asData,
            statusCode: .notModified,
            headers: [
                HTTPClient.ResponseHeader.signature.rawValue: fullSignature.base64EncodedString(),
                HTTPClient.ResponseHeader.eTag.rawValue: etag,
                HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate)
            ],
            request: request,
            publicKey: self.publicKey
        )

        expect(response.verificationResult) == .verified
    }

    func testVerificationResultWithSameCachedAndResponseResult() {
        expect(VerificationResult.from(cache: .notRequested, response: .notRequested)) == .notRequested
        expect(VerificationResult.from(cache: .verified, response: .verified)) == .verified
        expect(VerificationResult.from(cache: .verifiedOnDevice, response: .verifiedOnDevice)) == .verifiedOnDevice
        expect(VerificationResult.from(cache: .failed, response: .failed)) == .failed
    }

    func testVerificationNotRequestedCachedResult() {
        expect(VerificationResult.from(cache: .notRequested,
                                       response: .verified)) == .verified
        expect(VerificationResult.from(cache: .notRequested,
                                       response: .verifiedOnDevice)) == .verifiedOnDevice
        expect(VerificationResult.from(cache: .notRequested,
                                       response: .failed)) == .failed
    }

    func testVerifiedCachedResult() {
        expect(VerificationResult.from(cache: .verified,
                                       response: .notRequested)) == .notRequested
        expect(VerificationResult.from(cache: .verifiedOnDevice,
                                       response: .notRequested)) == .notRequested
        expect(VerificationResult.from(cache: .verified,
                                       response: .failed)) == .failed
        expect(VerificationResult.from(cache: .verifiedOnDevice,
                                       response: .failed)) == .failed
    }

    func testFailedVerificationCachedResult() {
        expect(VerificationResult.from(cache: .failed,
                                       response: .notRequested)) == .notRequested
        expect(VerificationResult.from(cache: .failed,
                                       response: .verified)) == .verified
        expect(VerificationResult.from(cache: .failed,
                                       response: .verifiedOnDevice)) == .verifiedOnDevice
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension SigningTests {

    private static func createRandomKey() -> (PrivateKey, PublicKey) {
        let key = PrivateKey()

        return (key, key.publicKey)
    }

    private func sign(parameters: Signing.SignatureParameters, salt: Data) throws -> Data {
        return try self.sign(key: self.privateKey, parameters: parameters, salt: salt)
    }

    private func sign(key: PrivateKey, parameters: Signing.SignatureParameters, salt: Data) throws -> Data {
        return try key.signature(for: salt + parameters.asData)
    }

    private static func createSalt() -> String {
        return Array(repeating: "a", count: Signing.saltSize).joined()
    }

}
