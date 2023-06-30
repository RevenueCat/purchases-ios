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

    fileprivate typealias PrivateKey = Curve25519.Signing.PrivateKey
    fileprivate typealias PublicKey = Curve25519.Signing.PublicKey

    private let (privateKey, publicKey) = SigningTests.createRandomKey()
    private let (privateIntermediateKey, publicIntermediateKey) = SigningTests.createRandomKey()

    private var signing: Signing!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.signing = .init(apiKey: Self.apiKey)
    }

    func testLoadDefaultPublicKey() throws {
        let key = try XCTUnwrap(Signing.loadPublicKey() as? PublicKey)

        expect(key.rawRepresentation).toNot(beEmpty())
    }

    func testVerifySignatureWithInvalidSignatureReturnsFalseAndLogsError() throws {
        let logger = TestLogHandler()

        let message = "Hello World"
        let nonce = "nonce"
        let requestDate: UInt64 = 1677005916012
        let signature = "this is not a signature"

        expect(self.signing.verify(
            signature: signature,
            with: .init(
                path: Self.mockPath,
                message: message.asData,
                nonce: nonce.asData,
                etag: nil,
                requestDate: requestDate
            ),
            publicKey: Signing.loadPublicKey()
        )) == false

        logger.verifyMessageWasLogged("Signature is not base64: \(signature)")
    }

    func testVerifySignatureWithExpiredIntermediateSignatureReturnsFalseAndLogsError() throws {
        let message = "Hello World"
        let nonce = "0123456789ab"
        let etag: String? = nil
        let requestDate = Date().millisecondsSince1970
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: Self.intermediateKeyPastExpiration)
        let salt = Self.createSalt()
        let parameters: Signing.SignatureParameters = .init(
            path: Self.mockPath,
            message: message.asData,
            nonce: nonce.asData,
            etag: etag,
            requestDate: requestDate
        )

        let signature = try self.sign(parameters: parameters, salt: salt.asData)
        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            signature: signature
        )

        let logger = TestLogHandler()

        expect(self.signing.verify(
            signature: fullSignature.base64EncodedString(),
            with: parameters,
            publicKey: self.publicKey
        )) == false

        logger.verifyMessageWasLogged("Intermediate key expired", level: .warn)
    }

    func testVerifySignatureWithInvalidIntermediateSignatureExpirationReturnsFalseAndLogsError() throws {
        let message = "Hello World"
        let nonce = "0123456789ab"
        let etag = "etag"
        let requestDate = Date().millisecondsSince1970
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: nil)
        let salt = Self.createSalt()
        let parameters: Signing.SignatureParameters = .init(
            path: Self.mockPath,
            message: message.asData,
            nonce: nonce.asData,
            etag: etag,
            requestDate: requestDate
        )

        let signature = try self.sign(parameters: parameters, salt: salt.asData)
        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            signature: signature
        )

        let logger = TestLogHandler()

        expect(self.signing.verify(
            signature: fullSignature.base64EncodedString(),
            with: parameters,
            publicKey: self.publicKey
        )) == false

        logger.verifyMessageWasLogged(Strings.signing.intermediate_key_invalid(Self.invalidIntermediateKeyExpiration),
                                      level: .warn)
    }

    func testVerifySignatureWithInvalidSignature() throws {
        expect(self.signing.verify(
            signature: "invalid signature".asData.base64EncodedString(),
            with: .init(
                path: Self.mockPath,
                message: "Hello World".asData,
                nonce: "nonce".asData,
                etag: nil,
                requestDate: 1677005916012
            ),
            publicKey: Signing.loadPublicKey()
        )) == false
    }

    func testVerifySignatureLogsWarningWhenIntermediateSignatureIsInvalid() throws {
        let logger = TestLogHandler()

        let signature = String(repeating: "x", count: Signing.SignatureComponent.totalSize)
            .asData

        _ = self.signing.verify(
            signature: signature.base64EncodedString(),
            with: .init(
                path: Self.mockPath,
                message: "Hello World".asData,
                nonce: "nonce".asData,
                etag: nil,
                requestDate: 1677005916012
            ),
            publicKey: Signing.loadPublicKey()
        )

        logger.verifyMessageWasLogged("Intermediate key failed verification",
                                      level: .warn)
    }

    func testVerifySignatureLogsWarningWhenFail() throws {
        let logger = TestLogHandler()

        let message = "Hello World"
        let nonce = "nonce"
        let requestDate: UInt64 = 1677005916012
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: Self.intermediateKeyFutureExpiration)
        let salt = Self.createSalt()

        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            // Invalid signature
            signature: String(repeating: "x", count: Signing.SignatureComponent.payload.size).asData
        )
        expect(
            self.signing.verify(
                signature: fullSignature.base64EncodedString(),
                with: .init(
                    path: Self.mockPath,
                    message: message.asData,
                    nonce: nonce.asData,
                    etag: nil,
                    requestDate: requestDate
                ),
                publicKey: self.publicKey
            )
        ) == false

        logger.verifyMessageWasLogged(Strings.signing.signature_failed_verification,
                                      level: .warn)
    }

    func testVerifySignatureLogsWarningWhenSizeIsIncorrect() throws {
        let logger = TestLogHandler()

        let signature = "invalid signature".asData

        _ = self.signing.verify(
            signature: signature.base64EncodedString(),
            with: .init(
                path: Self.mockPath,
                message: "Hello World".asData,
                nonce: "nonce".asData,
                etag: nil,
                requestDate: 1677005916012
            ),
            publicKey: Signing.loadPublicKey()
        )

        logger.verifyMessageWasLogged(Strings.signing.signature_invalid_size(signature),
                                      level: .warn)
    }

    func testVerifySignatureWithValidSignature() throws {
        let message = "Hello World"
        let nonce = "nonce"
        let requestDate: UInt64 = 1677005916012
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: Self.intermediateKeyFutureExpiration)
        let salt = Self.createSalt()

        let signature = try self.sign(
            parameters: .init(
                path: Self.mockPath,
                message: message.asData,
                nonce: nonce.asData,
                etag: nil,
                requestDate: requestDate
            ),
            salt: salt.asData
        )
        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            signature: signature
        )

        expect(self.signing.verify(
            signature: fullSignature.base64EncodedString(),
            with: .init(
                path: Self.mockPath,
                message: message.asData,
                nonce: nonce.asData,
                etag: nil,
                requestDate: requestDate
            ),
            publicKey: self.publicKey
        )) == true
    }

    func testVerifySignatureWithValidSignatureIncludingEtag() throws {
        let message = "Hello World"
        let nonce = "nonce"
        let requestDate: UInt64 = 1677005916012
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: Self.intermediateKeyFutureExpiration)
        let etag = "97d4f0d2353d784a"
        let salt = Self.createSalt()

        let signature = try self.sign(
            parameters: .init(
                path: Self.mockPath,
                message: message.asData,
                nonce: nonce.asData,
                etag: etag,
                requestDate: requestDate
            ),
            salt: salt.asData
        )
        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            signature: signature
        )

        expect(self.signing.verify(
            signature: fullSignature.base64EncodedString(),
            with: .init(
                path: Self.mockPath,
                message: message.asData,
                nonce: nonce.asData,
                etag: etag,
                requestDate: requestDate
            ),
            publicKey: self.publicKey
        )) == true
    }

    /*
     Instructions for updating these signatures:
     - Perform request in the comment (adding canary header if required)
     - Update `requestDate` to match the response
     - Update `expectedSignature` to match the response
     - Update `response` to match
     - Update `etag` (if applicable) to match the response
     */

    func testVerifyKnownSignatureWithNonceAndEtag() throws {
        /*
         Signature retrieved with:
        curl -v 'https://api.revenuecat.com/v1/subscribers/login' \
        -X GET \
        -H 'X-Nonce: MTIzNDU2Nzg5MGFi' \
        -H 'Authorization: Bearer {api_key}'
         */

        // swiftlint:disable line_length
        let response = """
        {"request_date":"2023-06-30T22:58:52Z","request_date_ms":1688165932212,"subscriber":{"entitlements":{},"first_seen":"2023-06-30T22:04:54Z","last_seen":"2023-06-30T22:04:54Z","management_url":null,"non_subscriptions":{},"original_app_user_id":"login","original_application_version":null,"original_purchase_date":null,"other_purchases":{},"subscriptions":{}}}\n
        """
        let expectedSignature = "XX8Mh8DTcqPC5A48nncRU3hDkL/v3baxxqLIWnWJzg1tTAAA7ok0iXupT2bjju/BSHVmgxc0XiwTZXBmsGuWEXa9lsyoFi9HMF4aAIOs4Y+lYE2i4USJCP7ev07QZk7D2b6ZBU2RTz0mVMohVliMOU7TKpW6/g3g1TUCJaTVYGBI0TZU1LSvtbrnTV9WZLOFva5A0w/PaaEi5Kd7F3Pc3Ytd/JWU2W+GzCbr7fcEYaHCMz0A"
        // swiftlint:enable line_length

        let nonce = try XCTUnwrap(Data(base64Encoded: "MTIzNDU2Nzg5MGFi"))
        let requestDate: UInt64 = 1688165932214
        let etag = "bc03094946db5488"

        expect(
            self.signing.verify(
                signature: expectedSignature,
                with: .init(
                    path: .getCustomerInfo(appUserID: "login"),
                    message: response.asData,
                    nonce: nonce,
                    etag: etag,
                    requestDate: requestDate
                ),
                publicKey: Signing.loadPublicKey()
            )
        ) == true
    }

    func testVerifyKnownSignatureWithNoNonceAndNoEtag() throws {
        /*
         Signature retrieved with:
        curl -v 'https://api.revenuecat.com/v1/subscribers/test/offerings' \
        -X GET \
        -H 'Authorization: Bearer {api_key}' \
        -H 'X-Platform: iOS'
         */

        // swiftlint:disable line_length
        let response = """
        {"current_offering_id":"default","offerings":[{"description":"Default","identifier":"default","metadata":null,"packages":[{"identifier":"$rc_monthly","platform_product_identifier":"ns_599_1m_1w0"},{"identifier":"$rc_annual","platform_product_identifier":"ns_3999_1y_1w0"}]}]}\n
        """
        let expectedSignature = "XX8Mh8DTcqPC5A48nncRU3hDkL/v3baxxqLIWnWJzg1tTAAA7ok0iXupT2bjju/BSHVmgxc0XiwTZXBmsGuWEXa9lsyoFi9HMF4aAIOs4Y+lYE2i4USJCP7ev07QZk7D2b6ZBbkS7vAEXt1c/Afax+p77HE+FOdasE/exztEfLohmttwAC86LxciXvuRB6GRlwdlqOG4hRBBkHju1/bwy+mOxXC7Hh6X6YGbypREKGdlX3kB"
        // swiftlint:enable line_length

        let requestDate: UInt64 = 1688165984163

        expect(
            self.signing.verify(
                signature: expectedSignature,
                with: .init(
                    path: .getOfferings(appUserID: "test"),
                    message: response.asData,
                    nonce: nil,
                    etag: nil,
                    requestDate: requestDate
                ),
                publicKey: Signing.loadPublicKey()
            )
        ) == true
    }

    func testVerifyKnownSignatureOfEmptyResponseWithNonceAndNoEtag() throws {
        /*
         Signature retrieved with:
        curl -v 'https://api.revenuecat.com/v1/health' \
        -X GET \
        -H 'X-Nonce: MTIzNDU2Nzg5MGFi' \
        -H 'Authorization: Bearer appl_fFVBVAoYujMZJnepIziGKVjnZBz'
         */

        // swiftlint:disable line_length
        let response = "\"\"\n"
        let expectedSignature = "XX8Mh8DTcqPC5A48nncRU3hDkL/v3baxxqLIWnWJzg1tTAAA7ok0iXupT2bjju/BSHVmgxc0XiwTZXBmsGuWEXa9lsyoFi9HMF4aAIOs4Y+lYE2i4USJCP7ev07QZk7D2b6ZBfwqq2zwcwl4sR4A+QeqyqH7kfS95aH84r25cplyx7Kp/BWRqIxusPNFqvsGEUoq8neKKp6zBQb5nJGtUr2ot4i8LsEHPWf85LcPo6ODl+YB"
        // swiftlint:enable line_length

        let nonce = try XCTUnwrap(Data(base64Encoded: "MTIzNDU2Nzg5MGFi"))
        let requestDate: UInt64 = 1688165654691

        expect(
            self.signing.verify(
                signature: expectedSignature,
                with: .init(
                    path: .health,
                    message: response.asData,
                    nonce: nonce,
                    etag: nil,
                    requestDate: requestDate
                ),
                publicKey: Signing.loadPublicKey()
            )
        ) == true
    }

    func testVerifyKnownSignatureOf304Response() throws {
        /*
         Signature retrieved with:
        curl -v 'https://api.revenuecat.com/v1/subscribers/login' \
        -X GET \
        -H 'X-Nonce: MTIzNDU2Nzg5MGFi' \
        -H 'Authorization: Bearer {api_key}' \
        -H 'X-RevenueCat-ETag: 97d4f0d2353d784a' \
         */

        // swiftlint:disable line_length
        let expectedSignature = "XX8Mh8DTcqPC5A48nncRU3hDkL/v3baxxqLIWnWJzg1tTAAA7ok0iXupT2bjju/BSHVmgxc0XiwTZXBmsGuWEXa9lsyoFi9HMF4aAIOs4Y+lYE2i4USJCP7ev07QZk7D2b6ZBXDYl4jSnJUxrC4e1pg/WVvPvwyGJjUSnnt5m1xi2QiNU5RjnLy3ursE/t9gO/a61He1kYPgC3XznHPPypn4Zn4CcCyOnPmKtwQB0eCHlOUI"
        // swiftlint:enable line_length

        let nonce = try XCTUnwrap(Data(base64Encoded: "MTIzNDU2Nzg5MGFi"))
        let requestDate: UInt64 = 1688165833071
        let etag = "bc03094946db5488"

        expect(
            self.signing.verify(
                signature: expectedSignature,
                with: .init(
                    path: .getCustomerInfo(appUserID: "login"),
                    message: nil, // 304 response
                    nonce: nonce,
                    etag: etag,
                    requestDate: requestDate
                ),
                publicKey: Signing.loadPublicKey()
            )
        ) == true
    }

    func testVerifyKnownSignatureWithAnonymousUser() throws {
        /*
         Signature retrieved with:
        curl -v 'https://api.revenuecat.com/v1/subscribers/$RCAnonymousID:1af512a3b9c848899fe427f39dd69f2b ' \
        -X GET \
        -H 'X-Nonce: MTIzNDU2Nzg5MGFi' \
        -H 'Authorization: Bearer {api_key}'
         */

        // swiftlint:disable line_length
        let response = """
        {"request_date":"2023-06-30T23:37:00Z","request_date_ms":1688168220782,"subscriber":{"entitlements":{},"first_seen":"2023-06-30T23:06:23Z","last_seen":"2023-06-30T23:06:23Z","management_url":null,"non_subscriptions":{},"original_app_user_id":"$RCAnonymousID:1af512a3b9c848899fe427f39dd69f2b","original_application_version":null,"original_purchase_date":null,"other_purchases":{},"subscriptions":{}}}\n
        """
        let expectedSignature = "XX8Mh8DTcqPC5A48nncRU3hDkL/v3baxxqLIWnWJzg1tTAAA7ok0iXupT2bjju/BSHVmgxc0XiwTZXBmsGuWEXa9lsyoFi9HMF4aAIOs4Y+lYE2i4USJCP7ev07QZk7D2b6ZBd7KiUCEJTjINdtwp/JQnyicaDVRm1+NoytWsv40T8I19xx1tnfhL4msRwK5R1YTNxcjBp1r3GRTjRS2agP29hBfdEF+Bi5hL/YoXrYJ52MA"
        // swiftlint:enable line_length

        let nonce = try XCTUnwrap(Data(base64Encoded: "MTIzNDU2Nzg5MGFi"))
        let requestDate: UInt64 = 1688168220782
        let etag = "a896a69e4b31304d"

        expect(
            self.signing.verify(
                signature: expectedSignature,
                with: .init(
                    path: .getCustomerInfo(appUserID: "$RCAnonymousID:1af512a3b9c848899fe427f39dd69f2b"),
                    message: response.asData,
                    nonce: nonce,
                    etag: etag,
                    requestDate: requestDate
                ),
                publicKey: Signing.loadPublicKey()
            )
        ) == true
    }

    func testResponseVerificationWithNoProvidedKey() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse<Data?>(statusCode: .success, responseHeaders: [:], body: Data())
        let verifiedResponse = response.verify(signing: self.signing, request: request, publicKey: nil)

        expect(verifiedResponse.verificationResult) == .notRequested
    }

    func testResponseVerificationWithNoSignatureInResponse() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let logger = TestLogHandler()

        let response = HTTPResponse<Data?>(statusCode: .success, responseHeaders: [:], body: Data())
        let verifiedResponse = response.verify(signing: self.signing, request: request, publicKey: self.publicKey)

        expect(verifiedResponse.verificationResult) == .failed

        logger.verifyMessageWasLogged(Strings.signing.signature_was_requested_but_not_provided(request),
                                      level: .warn)
    }

    func testResponseVerificationWithInvalidSignature() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: .health)
        let response = HTTPResponse<Data?>(
            statusCode: .success,
            responseHeaders: [
                HTTPClient.ResponseHeader.signature.rawValue: "invalid_signature"
            ],
            body: Data()
        )
        let verifiedResponse = response.verify(signing: self.signing, request: request, publicKey: self.publicKey)

        expect(verifiedResponse.verificationResult) == .failed
    }

    func testResponseVerificationWithNonceWithValidSignature() throws {
        let message = "Hello World"
        let nonce = "0123456789ab"
        let requestDate = Date().millisecondsSince1970
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: Self.intermediateKeyFutureExpiration)
        let salt = Self.createSalt()
        let request = HTTPRequest(method: .get, path: .health, nonce: nonce.asData)

        let signature = try self.sign(parameters: .init(path: request.path,
                                                        message: message.asData,
                                                        nonce: nonce.asData,
                                                        etag: nil,
                                                        requestDate: requestDate),
                                      salt: salt.asData)
        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            signature: signature
        )

        let response = HTTPResponse<Data?>(
            statusCode: .success,
            responseHeaders: [
                HTTPClient.ResponseHeader.signature.rawValue: fullSignature.base64EncodedString(),
                HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate)
            ],
            body: message.asData
        )
        let verifiedResponse = response.verify(signing: self.signing, request: request, publicKey: self.publicKey)

        expect(verifiedResponse.verificationResult) == .verified
    }

    func testResponseVerificationWithNonceAndEtag() throws {
        let nonce = "0123456789ab"
        let etag = "97d4f0d2353d784a"
        let requestDate = Date().millisecondsSince1970
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: Self.intermediateKeyFutureExpiration)
        let salt = Self.createSalt()
        let request = HTTPRequest(method: .get, path: .health, nonce: nonce.asData)

        let signature = try self.sign(parameters: .init(path: request.path,
                                                        message: nil,
                                                        nonce: nonce.asData,
                                                        etag: etag,
                                                        requestDate: requestDate),
                                      salt: salt.asData)
        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            signature: signature
        )

        let response = HTTPResponse<Data?>(
            statusCode: .success,
            responseHeaders: [
                HTTPClient.ResponseHeader.signature.rawValue: fullSignature.base64EncodedString(),
                HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate),
                HTTPClient.ResponseHeader.eTag.rawValue: etag
            ],
            body: nil
        )
        let verifiedResponse = response.verify(signing: self.signing, request: request, publicKey: self.publicKey)

        expect(verifiedResponse.verificationResult) == .verified
    }

    func testResponseVerificationWithoutNonceWithValidSignature() throws {
        let message = "Hello World"
        let requestDate = Date().millisecondsSince1970
        let intermediateKey = try self.createIntermediatePublicKeyData(expiration: Self.intermediateKeyFutureExpiration)
        let salt = Self.createSalt()
        let request = HTTPRequest(method: .get, path: .health, nonce: nil)

        let signature = try self.sign(parameters: .init(path: request.path,
                                                        message: message.asData,
                                                        nonce: nil,
                                                        etag: nil,
                                                        requestDate: requestDate),
                                      salt: salt.asData)
        let fullSignature = Self.fullSignature(
            intermediateKey: intermediateKey,
            salt: salt,
            signature: signature
        )

        let response = HTTPResponse<Data?>(
            statusCode: .success,
            responseHeaders: [
                HTTPClient.ResponseHeader.signature.rawValue: fullSignature.base64EncodedString(),
                HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate)
            ],
            body: message.asData
        )
        let verifiedResponse = response.verify(signing: self.signing, request: request, publicKey: self.publicKey)

        expect(verifiedResponse.verificationResult) == .verified
    }

    func testResponseVerificationWithoutNonceAndNoSignatureReturnsNotRequested() throws {
        let message = "Hello World"
        let requestDate = Date().millisecondsSince1970

        let logger = TestLogHandler()

        let request = HTTPRequest(method: .get, path: .health, nonce: nil)
        let response = HTTPResponse<Data?>(
            statusCode: .success,
            responseHeaders: [
                HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate)
            ],
            body: message.asData
        )
        let verifiedResponse = response.verify(signing: self.signing, request: request, publicKey: self.publicKey)

        expect(verifiedResponse.verificationResult) == .notRequested

        logger.verifyMessageWasNotLogged(Strings.signing.signature_was_requested_but_not_provided(request),
                                         allowNoMessages: true)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension SigningTests {

    static func createRandomKey() -> (PrivateKey, PublicKey) {
        let key = PrivateKey()

        return (key, key.publicKey)
    }

    func sign(parameters: Signing.SignatureParameters, salt: Data) throws -> Data {
        return try self.sign(key: self.privateIntermediateKey, parameters: parameters, salt: salt)
    }

    func sign(key: PrivateKey, parameters: Signing.SignatureParameters, salt: Data) throws -> Data {
        return try key.signature(for: salt + Self.apiKey.asData + parameters.asData)
    }

    static func fullSignature(intermediateKey: Data, salt: String, signature: Data) -> Data {
        return intermediateKey + salt.asData + signature
    }

    static func createSalt() -> String {
        return Array(repeating: "a", count: Signing.SignatureComponent.salt.size).joined()
    }

    /// - Parameter expiration: pass `nil` to create a "0" expiration date.
    func createIntermediatePublicKeyData(expiration: Date?) throws -> Data {
        let intermediateKey = self.publicIntermediateKey.rawRepresentation
        let expiration = expiration.map(\.dataRepresentation) ?? Self.invalidIntermediateKeyExpiration
        let signature = try self.privateKey.signature(for: expiration + intermediateKey)

        precondition(intermediateKey.count == Signing.SignatureComponent.intermediatePublicKey.size)
        precondition(expiration.count == Signing.SignatureComponent.intermediateKeyExpiration.size)
        precondition(signature.count == Signing.SignatureComponent.intermediateKeySignature.size)

        return intermediateKey + expiration + signature
    }

    static let intermediateKeyFutureExpiration = Date().addingTimeInterval(DispatchTimeInterval.days(5).seconds)
    static let intermediateKeyPastExpiration = Date().addingTimeInterval(DispatchTimeInterval.days(5).seconds * -1)
    static let invalidIntermediateKeyExpiration = Data(
        repeating: 0,
        count: Signing.SignatureComponent.intermediateKeyExpiration.size
    )

    static let apiKey = "appl_fFVBVAoYujMZJnepIziGKVjnZBz"
    static let mockPath: HTTPRequest.Path = .getCustomerInfo(appUserID: "user")

}

private extension Date {

    /// Khepri encodes expiration as UInt32 little-endian of the number of days since 1970
    var dataRepresentation: Data {
        let days = DispatchTimeInterval(self.timeIntervalSince1970).days
        return UInt32(days).littleEndianData
    }

}
