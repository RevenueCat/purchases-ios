//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMJWTVerifier.swift
//
//  Created by RevenueCat.

import Foundation
import Security

/// Verifies IAM ID tokens (RS256 JWTs) and extracts their claims.
///
/// Verification steps:
/// 1. Decode the JWT header to obtain the key ID (`kid`).
/// 2. Decode the JWT payload to obtain the issuer (`iss`), from which the project ID is derived.
/// 3. Fetch the project's public keys from `/<project_id>/.well-known/jwks.json`.
/// 4. Locate the JWK matching `kid` and reconstruct the RSA public key.
/// 5. Verify the RS256 signature over `base64url(header).base64url(payload)`.
/// 6. Return the verified ``IDTokenClaims``.
final class IAMJWTVerifier {

    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    /// Verifies `idToken` and calls `completion` with the decoded claims on success,
    /// or `nil` if verification fails for any reason.
    func verify(idToken: String, completion: @escaping (IDTokenClaims?) -> Void) {
        let parts = idToken.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            completion(nil)
            return
        }

        let headerPart = String(parts[0])
        let payloadPart = String(parts[1])
        let signaturePart = String(parts[2])

        guard
            let headerData = Data(base64URLEncoded: headerPart),
            let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
            let kid = header["kid"] as? String
        else {
            completion(nil)
            return
        }

        guard
            let payloadData = Data(base64URLEncoded: payloadPart),
            let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
            let sub = payload["sub"] as? String,
            let iss = payload["iss"] as? String
        else {
            completion(nil)
            return
        }

        guard let projectID = Self.projectID(from: iss) else {
            completion(nil)
            return
        }

        // Build JWKS URL: {baseURL}/auth/{project_id}/.well-known/jwks.json
        guard let jwksURL = URL(string: "auth/\(projectID)/.well-known/jwks.json",
                                relativeTo: self.baseURL) else {
            completion(nil)
            return
        }

        self.fetchJWKS(from: jwksURL) { jwks in
            guard let jwks else {
                completion(nil)
                return
            }

            guard
                let jwk = jwks.first(where: { $0["kid"] as? String == kid }),
                let nString = jwk["n"] as? String,
                let eString = jwk["e"] as? String,
                let nData = Data(base64URLEncoded: nString),
                let eData = Data(base64URLEncoded: eString),
                let publicKey = Self.rsaPublicKey(n: nData, e: eData)
            else {
                completion(nil)
                return
            }

            let signedData = Data((headerPart + "." + payloadPart).utf8)
            guard
                let signature = Data(base64URLEncoded: signaturePart),
                Self.verifyRS256(message: signedData, signature: signature, key: publicKey)
            else {
                completion(nil)
                return
            }

            let iat = (payload["iat"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
            let exp = (payload["exp"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()

            let audience: [String]
            if let single = payload["aud"] as? String {
                audience = [single]
            } else if let array = payload["aud"] as? [String] {
                audience = array
            } else {
                audience = []
            }

            completion(IDTokenClaims(
                subject: sub,
                issuer: iss,
                audience: audience,
                issuedAt: iat,
                expiration: exp,
                rawClaims: payload
            ))
        }
    }

    // MARK: - Private

    private func fetchJWKS(from url: URL, completion: @escaping ([[String: Any]]?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, _ in
            guard
                let data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let keys = json["keys"] as? [[String: Any]]
            else {
                completion(nil)
                return
            }
            completion(keys)
        }.resume()
    }

    /// Extracts the project ID from the issuer string.
    ///
    /// Handles two formats:
    /// - URL: `https://api.revenuecat.com/auth/proj1ab2c3d4` → `proj1ab2c3d4`
    /// - Plain ID: `proj1ab2c3d4` → `proj1ab2c3d4`
    private static func projectID(from issuer: String) -> String? {
        if let url = URL(string: issuer), url.scheme != nil {
            let component = url.lastPathComponent
            return component.isEmpty ? nil : component
        }
        return issuer.isEmpty ? nil : issuer
    }

    /// Creates an RSA public key from a JWK's base64url-decoded `n` (modulus) and `e` (exponent).
    private static func rsaPublicKey(n: Data, e: Data) -> SecKey? {
        let der = buildRSAPublicKeyDER(n: n, e: e)
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic
        ]
        return SecKeyCreateWithData(der as CFData, attributes as CFDictionary, nil)
    }

    /// Verifies an RS256 signature. `message` is the raw signed bytes (not hashed);
    /// `SecKeyVerifySignature` with `.rsaSignatureMessagePKCS1v15SHA256` hashes internally.
    private static func verifyRS256(message: Data, signature: Data, key: SecKey) -> Bool {
        var error: Unmanaged<CFError>?
        return SecKeyVerifySignature(
            key,
            .rsaSignatureMessagePKCS1v15SHA256,
            message as CFData,
            signature as CFData,
            &error
        )
    }

    // MARK: - DER encoding

    /// Builds a DER-encoded PKCS#1 RSAPublicKey: SEQUENCE { INTEGER n, INTEGER e }.
    private static func buildRSAPublicKeyDER(n: Data, e: Data) -> Data {
        return derEncodeSequence(derEncodeInteger(n) + derEncodeInteger(e))
    }

    private static func derEncodeInteger(_ data: Data) -> Data {
        var bytes = [UInt8](data)
        // Prepend 0x00 if the high bit is set to keep the value positive (DER signed integer)
        if let first = bytes.first, first & 0x80 != 0 {
            bytes.insert(0x00, at: 0)
        }
        return Data([0x02]) + derLength(bytes.count) + Data(bytes)
    }

    private static func derEncodeSequence(_ data: Data) -> Data {
        return Data([0x30]) + derLength(data.count) + data
    }

    private static func derLength(_ length: Int) -> Data {
        if length < 0x80 {
            return Data([UInt8(length)])
        } else if length < 0x100 {
            return Data([0x81, UInt8(length)])
        } else {
            return Data([0x82, UInt8(length >> 8), UInt8(length & 0xff)])
        }
    }

}

// MARK: - Data base64url helpers

private extension Data {

    /// Decodes a Base64URL-encoded string (RFC 4648 §5), with or without padding.
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        self.init(base64Encoded: base64)
    }

}
