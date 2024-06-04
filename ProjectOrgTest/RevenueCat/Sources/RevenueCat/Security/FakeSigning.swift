//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FakeSigning.swift
//
//  Created by Nacho Soto on 6/13/23.

import Foundation

#if DEBUG

/// A `SigningType` implementation that always fails, used for testing.
/// - Seealso: `InternalDangerousSettingsType.forceSignatureFailures`
final class FakeSigning: SigningType {

    func verify(
        signature: String,
        with parameters: Signing.SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> Bool {
        return false
    }

    static let `default`: FakeSigning = .init()

}

#endif
