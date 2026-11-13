//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  KeychainDPoPStrategy.swift
//
//  Created by Dave DeLong on 11/10/26.

import CryptoKit
import Foundation

/// A ``DPoPStrategy`` whose private key is stored in secure storage, for devices without a Secure Enclave.
final class KeychainDPoPStrategy: DPoPStrategy {

    static let storageIdentifier = "RC-dpop-keychain-key"

    private let storage: any SecureItemStorage
    private let cachedKey: Atomic<P256.Signing.PrivateKey?> = Atomic(nil)

    init(storage: any SecureItemStorage) {
        self.storage = storage
    }

    /// Whether a key has already been stored.
    var hasStoredKey: Bool {
        return (try? self.storage.containsItem(identifier: Self.storageIdentifier)) == true
    }

    func publicKey() throws -> P256.Signing.PublicKey {
        return try self.privateKey().publicKey
    }

    func signature(for data: Data) throws -> Data {
        return try self.privateKey().signature(for: data).rawRepresentation
    }

}

private extension KeychainDPoPStrategy {

    func privateKey() throws -> P256.Signing.PrivateKey {
        // the lock is held while loading so that concurrent callers don't each create a key
        return try self.cachedKey.modify { cached in
            if let cached { return cached }

            let key = try self.loadOrCreateKey()
            cached = key
            return key
        }
    }

    func loadOrCreateKey() throws -> P256.Signing.PrivateKey {
        let restore = { (data: Data) in try P256.Signing.PrivateKey(rawRepresentation: data) }

        if let key = self.storage.readDPoPKey(identifier: Self.storageIdentifier, restore: restore) {
            return key
        }

        let newKey = P256.Signing.PrivateKey()
        return try self.storage.storeDPoPKey(newKey,
                                             representation: newKey.rawRepresentation,
                                             identifier: Self.storageIdentifier,
                                             restore: restore)
    }

}
