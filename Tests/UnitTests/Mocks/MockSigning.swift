//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockSigning.swift
//
//  Created by Nacho Soto on 2/8/23.

@testable import RevenueCat

final class MockSigning: SigningType {

    struct VerificationRequest {
        let message: Data
        let nonce: Data
        let signature: String
        let publicKey: Signing.PublicKey
    }

    static var requests: [VerificationRequest] = []
    static var stubbedVerificationResult: Bool?

    static func verify(
        message: Data,
        nonce: Data,
        hasValidSignature signature: String,
        with publicKey: Signing.PublicKey
    ) -> Bool {
        Self.requests.append(.init(
            message: message,
            nonce: nonce,
            signature: signature,
            publicKey: publicKey
        ))

        return Self.stubbedVerificationResult!
    }

    static func resetData() {
        self.requests.removeAll()
        self.stubbedVerificationResult = nil
    }

}
