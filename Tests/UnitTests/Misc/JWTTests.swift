//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  JWTTests.swift
//
//  Created by RevenueCat on 8/12/26.

import Nimble
import XCTest

@testable import RevenueCat

class JWTTests: TestCase {

    func testInitParsesHeader() throws {
        let jwt = try JWT(from: Self.validToken())

        expect(jwt.header["alg"] as? String) == "none"
        expect(jwt.header["typ"] as? String) == "JWT"
    }

    func testInitParsesPayload() throws {
        let jwt = try JWT(from: Self.validToken())

        expect(jwt.payload["iss"] as? String) == "https://issuer.example.com"
        expect(jwt.payload["rc.app_user_id"] as? String) == "test-user-123"
        expect(jwt.payload["amr"] as? [String]) == ["pwd", "otp"]
    }

    func testInitParsesSignature() throws {
        let jwt = try JWT(from: Self.validToken())

        expect(String(data: jwt.signature, encoding: .utf8)) == "signature-bytes"
    }

    func testIssuerProperty() throws {
        let jwt = try JWT(from: Self.validToken())

        expect(jwt.issuer) == "https://issuer.example.com"
    }

    func testAppUserIDProperty() throws {
        let jwt = try JWT(from: Self.validToken())

        expect(jwt.appUserID) == "test-user-123"
    }

    func testAmrProperty() throws {
        let jwt = try JWT(from: Self.validToken())

        expect(jwt.amr) == ["pwd", "otp"]
    }

    func testOptionalClaimsAreNilWhenNotPresent() throws {
        let token = try Self.makeToken(header: ["alg": "none"], payload: ["sub": "abc"])
        let jwt = try JWT(from: token)

        expect(jwt.issuer).to(beNil())
        expect(jwt.appUserID).to(beNil())
        expect(jwt.amr).to(beNil())
    }

    func testInitThrowsWithFewerThanThreeSegments() throws {
        let token = try Self.makeToken(header: ["alg": "none"], payload: ["sub": "abc"])
        let headerAndPayload = token.split(separator: ".").prefix(2).joined(separator: ".")

        expect { try JWT(from: headerAndPayload) }.to(throwError(errorType: JWT.Error.self))
    }

    func testInitThrowsWithMoreThanThreeSegments() throws {
        let token = try Self.makeToken(header: ["alg": "none"], payload: ["sub": "abc"])

        expect { try JWT(from: "\(token).extra") }.to(throwError(errorType: JWT.Error.self))
    }

    func testInitThrowsWithInvalidBase64Header() throws {
        let token = try Self.makeToken(header: ["alg": "none"], payload: ["sub": "abc"])
        let parts = token.split(separator: ".")
        let invalidToken = "not!valid.\(parts[1]).\(parts[2])"

        expect { try JWT(from: invalidToken) }.to(throwError(errorType: JWT.Error.self))
    }

    func testInitThrowsWithInvalidBase64Signature() throws {
        let token = try Self.makeToken(header: ["alg": "none"], payload: ["sub": "abc"])
        let parts = token.split(separator: ".")
        let invalidToken = "\(parts[0]).\(parts[1]).not!valid"

        expect { try JWT(from: invalidToken) }.to(throwError(errorType: JWT.Error.self))
    }

    func testInitThrowsWhenPayloadIsNotAJSONObject() throws {
        let header = try Self.base64URL(from: "{\"alg\":\"none\"}")
        let arrayPayload = try Self.base64URL(from: "[1,2,3]")
        let signature = try Self.base64URL(from: "sig")

        let token = "\(header).\(arrayPayload).\(signature)"

        expect { try JWT(from: token) }.to(throwError(errorType: JWT.Error.self))
    }

    func testInitThrowsWhenHeaderIsNotValidJSON() throws {
        let invalidHeader = try Self.base64URL(from: "not json")
        let payload = try Self.base64URL(from: "{\"sub\":\"abc\"}")
        let signature = try Self.base64URL(from: "sig")

        let token = "\(invalidHeader).\(payload).\(signature)"

        expect { try JWT(from: token) }.to(throwError())
    }

}

private extension JWTTests {

    static func validToken() throws -> String {
        return try Self.makeToken(
            header: ["alg": "none", "typ": "JWT"],
            payload: [
                "iss": "https://issuer.example.com",
                "rc.app_user_id": "test-user-123",
                "amr": ["pwd", "otp"]
            ]
        )
    }

    static func makeToken(header: [String: Any], payload: [String: Any]) throws -> String {
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        let signatureData = try XCTUnwrap("signature-bytes".data(using: .utf8))

        return [headerData, payloadData, signatureData]
            .map { Self.base64URLString(from: $0) }
            .joined(separator: ".")
    }

    static func base64URL(from string: String) throws -> String {
        let data = try XCTUnwrap(string.data(using: .utf8))
        return Self.base64URLString(from: data)
    }

    static func base64URLString(from data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}
