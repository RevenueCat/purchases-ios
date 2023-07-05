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
        let signature: String
        let parameters: Signing.SignatureParameters
        let publicKey: Signing.PublicKey
    }

    var requests: [VerificationRequest] = []
    var stubbedVerificationResult: Bool?

    func verify(
        signature: String,
        with parameters: Signing.SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> Bool {
        self.requests.append(.init(
            signature: signature,
            parameters: parameters,
            publicKey: publicKey
        ))

        return self.stubbedVerificationResult!
    }

}
