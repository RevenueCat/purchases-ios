//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SecureEnclaveDPoPStrategy.swift
//
//  Created by Dave DeLong on 11/10/26.

import CryptoKit
import Foundation
import Security

/// A ``DPoPStrategy`` whose private key lives in the Secure Enclave.
///
/// If the Secure Enclave can't create a key, this uses `fallback` instead, and keeps using it once it has
/// stored a key, so that tokens bound to that key stay valid.
final class SecureEnclaveDPoPStrategy: DPoPStrategy {

    static let storageIdentifier = "RC-dpop-secure-enclave-key"

    static var isAvailable: Bool { SecureEnclave.isAvailable }

    private enum SigningKey {
        case secureEnclave(SecureEnclave.P256.Signing.PrivateKey)
        case fallback
    }

    private let storage: any SecureItemStorage
    private let fallback: KeychainDPoPStrategy
    private let cachedKey: Atomic<SigningKey?> = Atomic(nil)

    init(storage: any SecureItemStorage, fallback: KeychainDPoPStrategy) {
        self.storage = storage
        self.fallback = fallback
    }

    func publicKey() throws -> P256.Signing.PublicKey {
        switch try self.signingKey() {
        case .secureEnclave(let key):
            return key.publicKey
        case .fallback:
            return try self.fallback.publicKey()
        }
    }

    func signature(for data: Data) throws -> Data {
        switch try self.signingKey() {
        case .secureEnclave(let key):
            return try key.signature(for: data).rawRepresentation
        case .fallback:
            return try self.fallback.signature(for: data)
        }
    }

    private func signingKey() throws -> SigningKey {
        // the lock is held while loading so that concurrent callers don't each create a key
        return try self.cachedKey.modify { cached in
            if let cached { return cached }

            let key = try self.loadOrCreateKey()
            cached = key
            return key
        }
    }

    private func loadOrCreateKey() throws -> SigningKey {
        let restore = { (data: Data) in try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: data) }

        if let key = self.storage.readDPoPKey(identifier: Self.storageIdentifier, restore: restore) {
            return .secureEnclave(key)
        }

        // a stored fallback key means creating an enclave key failed before
        if self.fallback.hasStoredKey {
            return .fallback
        }

        let newKey: SecureEnclave.P256.Signing.PrivateKey
        do {
            newKey = try SecureEnclave.P256.Signing.PrivateKey(accessControl: try makeAccessControl())
        } catch {
            Logger.warn(Strings.authentication.dpopSecureEnclaveKeyCreationFailed(error))
            return .fallback
        }

        return .secureEnclave(try self.storage.storeDPoPKey(newKey,
                                                            representation: newKey.dataRepresentation,
                                                            identifier: Self.storageIdentifier,
                                                            restore: restore))
    }

    /// Usable after first unlock so background requests can sign, and never migrated off this device.
    private func makeAccessControl() throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(nil,
                                                                  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                                                  .privateKeyUsage,
                                                                  &error) else {
            throw error.map { $0.takeRetainedValue() as Error } ?? SecureStorageError(rawValue: errSecParam)
        }
        return accessControl
    }

}
