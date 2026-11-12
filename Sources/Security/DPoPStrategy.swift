//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DPoPStrategy.swift
//
//  Created by Dave DeLong on 11/9/26.

import CryptoKit
import Foundation
import Security

/// Signs DPoP proofs (RFC 9449), which bind IAM tokens to a P-256 key that never leaves this device.
///
/// There is one key per install, not per user: logging in with `link_to_id` requires a proof from the
/// same key the previous user's ID token was bound to.
protocol DPoPStrategy {

    /// The public half of the signing key.
    func publicKey() throws -> P256.Signing.PublicKey

    /// Signs `data` with ES256, returning the raw `r || s` signature JWS expects.
    func signature(for data: Data) throws -> Data

}

extension DPoPStrategy {

    /// Creates a single-use proof for one request.
    ///
    /// - Parameters:
    ///   - httpMethod: The request's HTTP method.
    ///   - url: The exact URL the request is sent to. The backend compares `htu` to it literally.
    ///   - accessToken: The access token sent with the request, if any.
    ///   - issuedAt: The proof's `iat`.
    /// - Returns: The value of the `DPoP` header.
    func proof(httpMethod: String, url: URL, accessToken: String?, issuedAt: Date) throws -> String {
        // the raw representation is the 32-byte x coordinate followed by the 32-byte y coordinate
        let rawPublicKey = try self.publicKey().rawRepresentation
        let header: [String: Any] = [
            "typ": "dpop+jwt",
            "alg": "ES256",
            "jwk": [
                "kty": "EC",
                "crv": "P-256",
                "x": rawPublicKey.prefix(32).base64URLEncodedString,
                "y": rawPublicKey.suffix(32).base64URLEncodedString
            ]
        ]

        var payload: [String: Any] = [
            "jti": UUID().uuidString,
            "htm": httpMethod,
            "htu": try Self.htu(for: url),
            "iat": Int(issuedAt.timeIntervalSince1970)
        ]
        if let accessToken {
            payload["ath"] = Data(accessToken.utf8).sha256.base64URLEncodedString
        }

        let encodedHeader = try JSONSerialization.data(withJSONObject: header).base64URLEncodedString
        let encodedPayload = try JSONSerialization.data(withJSONObject: payload).base64URLEncodedString
        let signingInput = encodedHeader + "." + encodedPayload

        let signature = try self.signature(for: Data(signingInput.utf8))
        return signingInput + "." + signature.base64URLEncodedString
    }

    /// The `htu` claim: the request URL without its query or fragment.
    private static func htu(for url: URL) throws -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.query = nil
        components.fragment = nil

        guard let htu = components.string else {
            throw URLError(.badURL)
        }
        return htu
    }

}

extension SecureItemStorage {

    /// Reads a stored DPoP key. A key that can't be restored is deleted, so that a new one can replace it.
    func readDPoPKey<Key>(identifier: String, restore: (Data) throws -> Key) -> Key? {
        let data: Data
        do {
            guard let storedData = try self.readItem(identifier: identifier) else { return nil }
            data = storedData
        } catch {
            Logger.warn(Strings.authentication.dpopKeyReadFailed(error))
            return nil
        }

        do {
            return try restore(data)
        } catch {
            // tokens bound to this key will be rejected and require a new login
            Logger.error(Strings.authentication.dpopKeyRestoreFailed(error))
            try? self.deleteItem(identifier: identifier)
            return nil
        }
    }

    /// Stores a new DPoP key, unless another process sharing this storage (e.g. an app extension)
    /// stored one first.
    ///
    /// - Returns: The key to use: `key` if it was stored, otherwise the one stored by the other process.
    func storeDPoPKey<Key>(_ key: Key,
                           representation: Data,
                           identifier: String,
                           restore: (Data) throws -> Key) throws -> Key {
        // DPoP keys never leave this device
        var attributes = SecureItemAttributes()
        attributes.includedInBackup = false

        if try self.addItem(identifier: identifier, contents: representation, attributes: attributes) {
            return key
        }

        guard let storedKey = self.readDPoPKey(identifier: identifier, restore: restore) else {
            throw SecureStorageError(rawValue: errSecItemNotFound)
        }
        return storedKey
    }

}
