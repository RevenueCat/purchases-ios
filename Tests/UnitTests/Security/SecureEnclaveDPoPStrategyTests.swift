//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SecureEnclaveDPoPStrategyTests.swift
//
//  Created by Dave DeLong on 11/10/26.

import CryptoKit
import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class SecureEnclaveDPoPStrategyTests: TestCase {

    private var storage: MockSecureItemStorage!
    private var fallback: KeychainDPoPStrategy!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.storage = MockSecureItemStorage()
        self.fallback = KeychainDPoPStrategy(storage: self.storage)
    }

    func testUsesAnExistingFallbackKeyInsteadOfCreatingAnEnclaveKey() throws {
        let fallbackKey = try self.fallback.publicKey()

        let strategy = SecureEnclaveDPoPStrategy(storage: self.storage, fallback: self.fallback)

        expect(try strategy.publicKey().rawRepresentation) == fallbackKey.rawRepresentation
        expect(self.storage.storedItems[SecureEnclaveDPoPStrategy.storageIdentifier]).to(beNil())
    }

    func testFallsBackToTheKeychainKeyWhenTheEnclaveCannotCreateAKey() throws {
        try XCTSkipIf(SecureEnclaveDPoPStrategy.isAvailable, "Requires a device without a Secure Enclave")

        let strategy = SecureEnclaveDPoPStrategy(storage: self.storage, fallback: self.fallback)
        let publicKey = try strategy.publicKey()

        let fallbackKey = try self.fallback.publicKey()
        expect(publicKey.rawRepresentation) == fallbackKey.rawRepresentation
        expect(self.storage.storedItems[SecureEnclaveDPoPStrategy.storageIdentifier]).to(beNil())
        expect(self.fallback.hasStoredKey) == true
    }

    func testFallbackSignaturesVerifyWithThePublicKey() throws {
        try XCTSkipIf(SecureEnclaveDPoPStrategy.isAvailable, "Requires a device without a Secure Enclave")

        let strategy = SecureEnclaveDPoPStrategy(storage: self.storage, fallback: self.fallback)
        let data = Data("signing input".utf8)

        let signature = try P256.Signing.ECDSASignature(rawRepresentation: try strategy.signature(for: data))

        expect(try strategy.publicKey().isValidSignature(signature, for: data)) == true
    }

}
