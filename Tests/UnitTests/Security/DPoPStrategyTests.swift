//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DPoPStrategyTests.swift
//
//  Created by Dave DeLong on 11/9/26.

import CryptoKit
import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class DPoPStrategyTests: TestCase {

    private static let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var strategy: KeychainDPoPStrategy!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.strategy = KeychainDPoPStrategy(storage: MockSecureItemStorage())
    }

    // MARK: - Header

    func testProofHeaderDescribesAnES256DPoPProof() throws {
        let proof = try JWT(from: try self.makeProof())

        expect(proof.header["typ"] as? String) == "dpop+jwt"
        expect(proof.header["alg"] as? String) == "ES256"
    }

    func testProofHeaderContainsThePublicKeyAsAJWK() throws {
        let proof = try JWT(from: try self.makeProof())
        let jwk = try XCTUnwrap(proof.header["jwk"] as? [String: String])
        let publicKey = try self.strategy.publicKey()

        expect(jwk["kty"]) == "EC"
        expect(jwk["crv"]) == "P-256"
        expect(jwk["d"]).to(beNil())
        expect(try Self.publicKey(from: jwk).rawRepresentation) == publicKey.rawRepresentation
    }

    // MARK: - Signature

    func testProofSignatureVerifiesWithTheEmbeddedKey() throws {
        let rawProof = try self.makeProof()
        let proof = try JWT(from: rawProof)
        let jwk = try XCTUnwrap(proof.header["jwk"] as? [String: String])

        let signingInput = rawProof.split(separator: ".").prefix(2).joined(separator: ".")
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: proof.signature)

        expect(try Self.publicKey(from: jwk).isValidSignature(signature, for: Data(signingInput.utf8))) == true
    }

    // MARK: - Claims

    func testProofClaimsDescribeTheRequest() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com/v1/subscribers/user"))
        let proof = try JWT(from: try self.strategy.proof(httpMethod: "POST",
                                                          url: url,
                                                          accessToken: nil,
                                                          issuedAt: Self.now))

        expect(proof.payload["htm"] as? String) == "POST"
        expect(proof.payload["htu"] as? String) == "https://api.revenuecat.com/v1/subscribers/user"
        expect(proof.payload["iat"] as? Int) == 1_800_000_000
        expect(proof.payload["jti"] as? String).toNot(beEmpty())
    }

    func testProofHasNoAccessTokenHashWithoutAnAccessToken() throws {
        let proof = try JWT(from: try self.makeProof(accessToken: nil))

        expect(proof.payload.keys).toNot(contain("ath"))
    }

    func testProofContainsTheAccessTokenHash() throws {
        let proof = try JWT(from: try self.makeProof(accessToken: "access-token"))

        // base64url(SHA-256("access-token"))
        expect(proof.payload["ath"] as? String) == "Pxa-1wifRlPl7yG_0oJNfzqq7MelmOfonFgOFgapzFI"
    }

    func testEachProofHasAUniqueIdentifier() throws {
        let first = try JWT(from: try self.makeProof())
        let second = try JWT(from: try self.makeProof())

        expect(first.payload["jti"] as? String) != second.payload["jti"] as? String
    }

    // MARK: - htu

    func testHTUDropsTheQueryAndFragment() throws {
        let htu = try self.htu(for: "https://api.revenuecat.com/v1/subscribers/user?a=1&b=2#fragment")

        expect(htu) == "https://api.revenuecat.com/v1/subscribers/user"
    }

    func testHTUKeepsThePathExactlyAsSent() throws {
        let htu = try self.htu(for: "https://api.revenuecat.com/v1/subscribers/dave%40revenuecat.com")

        expect(htu) == "https://api.revenuecat.com/v1/subscribers/dave%40revenuecat.com"
    }

    func testHTUKeepsAnExplicitPort() throws {
        let htu = try self.htu(for: "http://localhost:8000/v1/subscribers/user")

        expect(htu) == "http://localhost:8000/v1/subscribers/user"
    }

}

private extension DPoPStrategyTests {

    func makeProof(accessToken: String? = nil) throws -> String {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com/v1/subscribers/user"))
        return try self.strategy.proof(httpMethod: "GET", url: url, accessToken: accessToken, issuedAt: Self.now)
    }

    func htu(for urlString: String) throws -> String? {
        let url = try XCTUnwrap(URL(string: urlString))
        let proof = try self.strategy.proof(httpMethod: "GET", url: url, accessToken: nil, issuedAt: Self.now)
        return try JWT(from: proof).payload["htu"] as? String
    }

    static func publicKey(from jwk: [String: String]) throws -> P256.Signing.PublicKey {
        let xCoordinate = try XCTUnwrap(jwk["x"].flatMap { Data(base64URLEncoded: $0) })
        let yCoordinate = try XCTUnwrap(jwk["y"].flatMap { Data(base64URLEncoded: $0) })
        return try P256.Signing.PublicKey(rawRepresentation: xCoordinate + yCoordinate)
    }

}
