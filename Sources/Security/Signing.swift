//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Signing.swift
//
//  Created by Nacho Soto on 1/13/23.

import CryptoKit
import Foundation

/// A type that can verify signatures.
protocol SigningType {

    func verify(
        signature: String,
        with parameters: Signing.SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> Bool

}

/// Utilities for handling signature verification.
final class Signing: SigningType {

    /// An object that represents a cryptographic key.
    typealias PublicKey = SigningPublicKey

    /// Parameters used for signature creation / verification.
    struct SignatureParameters {

        var path: HTTPRequestPath
        var message: Data?
        var requestHeaders: HTTPRequest.Headers
        var requestBody: HTTPRequestBody?
        var nonce: Data?
        var etag: String?
        var requestDate: UInt64

    }

    private let apiKey: String
    private let clock: ClockType

    init(apiKey: String, clock: ClockType = Clock.default) {
        self.apiKey = apiKey
        self.clock = clock
    }

    /// Parses the binary `key` and returns a `PublicKey`
    static func loadPublicKey() -> PublicKey {
        func fail(_ error: CustomStringConvertible) -> Never {
            // This would crash the SDK, but the key is known at compile time
            // so if it's encoded incorrectly we would know during tests
            fatalError(error.description)
        }

        guard let key = Data(base64Encoded: Self.publicKey) else {
            fail(Strings.signing.invalid_public_key(Self.publicKey))
        }

        do {
            return try Self.createPublicKey(with: key)
        } catch {
            fail(Strings.signing.invalid_public_key(error.localizedDescription))
        }
    }

    func verify(
        signature: String,
        with parameters: SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> Bool {
        guard let signature = Data(base64Encoded: signature) else {
            Logger.warn(Strings.signing.signature_not_base64(signature))
            return false
        }

        guard signature.count == SignatureComponent.totalSize else {
            Logger.warn(Strings.signing.signature_invalid_size(signature))
            return false
        }

        guard let intermediatePublicKey = Self.extractAndVerifyIntermediateKey(
            from: signature,
            publicKey: publicKey,
            clock: self.clock
        ) else {
            return false
        }

        let salt = signature.component(.salt)
        let payload = signature.component(.payload)
        let messageToVerify = parameters.signature(salt: salt, apiKey: self.apiKey)

        #if DEBUG
        Logger.verbose(Strings.signing.verifying_signature(
            signature: signature,
            publicKey: intermediatePublicKey.rawRepresentation,
            parameters: parameters,
            salt: salt,
            payload: payload,
            message: messageToVerify
        ))
        #endif

        let isValid = intermediatePublicKey.isValidSignature(payload, for: messageToVerify)

        if isValid {
            Logger.verbose(Strings.signing.signature_passed_verification)
        } else {
            Logger.warn(Strings.signing.signature_failed_verification)
        }

        return isValid
    }

    static func verificationMode(
        with setting: Configuration.EntitlementVerificationMode
    ) -> ResponseVerificationMode {
        switch setting {
        case .disabled: return .disabled
        case .informational: return .informational(Self.loadPublicKey())
        case .enforced: return .enforced(Self.loadPublicKey())
        }
    }

    /// - Returns: `ResponseVerificationMode.enforced`
    /// This is useful while ``Configuration.EntitlementVerificationMode`` is unavailable.
    static func enforcedVerificationMode() -> ResponseVerificationMode {
        return .enforced(Self.loadPublicKey())
    }

    // MARK: -

    /// The actual algorithm used to verify signatures.
    fileprivate typealias Algorithm = Curve25519.Signing.PublicKey

    private static let publicKey = "UC1upXWg5QVmyOSwozp755xLqquBKjjU+di6U8QhMlM="

}

extension Signing {

    /// Verification level with a loaded `PublicKey`
    /// - Seealso: ``Configuration/EntitlementVerificationMode``
    enum ResponseVerificationMode {

        case disabled
        case informational(PublicKey)
        case enforced(PublicKey)

        static let `default`: Self = .informational(Signing.loadPublicKey())

        var publicKey: PublicKey? {
            switch self {
            case .disabled: return nil
            case let .informational(key): return key
            case let .enforced(key): return key
            }
        }

        var isEnabled: Bool {
            switch self {
            case .disabled: return false
            case .informational, .enforced: return true
            }
        }

        var isEnforced: Bool {
            switch self {
            case .disabled, .informational: return false
            case .enforced: return true
            }
        }

    }

}

/// A type representing a public key that can be used to validate signatures
/// The current type used is `CryptoKit.Curve25519.Signing.PublicKey`
protocol SigningPublicKey {

    func isValidSignature(_ signature: Data, for data: Data) -> Bool
    var rawRepresentation: Data { get }

}

extension Signing.Algorithm: SigningPublicKey {}

// MARK: - Internal implementation (visible for tests)

extension Signing {

    enum SignatureComponent: CaseIterable, Comparable {

        case intermediatePublicKey
        case intermediateKeyExpiration
        case intermediateKeySignature
        case salt
        case payload

        var size: Int {
            switch self {
            case .intermediatePublicKey: return 32
            case .intermediateKeyExpiration: return 4
            case .intermediateKeySignature: return 64
            case .salt: return 16
            case .payload: return 64
            }
        }

        static let totalSize: Int = Self.allCases.map(\.size).sum()

        /// Number of bytes where the component begins
        fileprivate var offset: Int {
            // swiftlint:disable:next force_unwrapping
            return Self.offsets[self]!
        }

        fileprivate static let offsets: [SignatureComponent: Int] = Set(Self.allCases)
            .dictionaryWithValues { component in
                Self.allCases
                    .prefix(while: { $0 != component })
                    .map(\.size)
                    .sum()
            }
    }

}

extension Signing.SignatureParameters {

    init(
        path: HTTPRequest.Path,
        message: Data? = nil,
        requestHeaders: HTTPRequest.Headers = [:],
        requestBody: HTTPRequestBody? = nil,
        nonce: Data? = nil,
        etag: String? = nil,
        requestDate: UInt64
    ) {
        self.path = path
        self.message = message
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.nonce = nonce
        self.etag = etag
        self.requestDate = requestDate
    }

    func signature(salt: Data, apiKey: String) -> Data {
        let apiKey = self.path.authenticated ? apiKey : ""
        return salt + apiKey.asData + self.asData
    }

    var asData: Data {
        let nonce: Data = self.nonce ?? .init()
        let path: Data = self.path.relativePath.asData
        let postParameterHash: Data = self.requestBody?.postParameterHeader?.asData ?? .init()
        let headerParametersHash: Data = HTTPRequest.headerParametersForSignatureHeader(
            headers: self.requestHeaders,
            path: self.path
        )?
        .asData ?? .init()
        let requestDate: Data = String(self.requestDate).asData
        let etag: Data = (self.etag ?? "").asData
        let message: Data = self.message ?? .init()

        return (
            nonce +
            path +
            postParameterHash +
            headerParametersHash +
            requestDate +
            etag +
            message
        )
    }

}

extension Signing.SignatureParameters: CustomDebugStringConvertible {

    var debugDescription: String {
        return """
        SignatureParameters(" +
            path: '\(self.path.relativePath)'
            message: '\(self.messageString.trimmingWhitespacesAndNewLines)'
            headerParametersHash: '\(HTTPRequest.headerParametersForSignatureHeader(
                headers: self.requestHeaders,
                path: self.path
            ) ?? "")'
            headers: '\(self.requestHeaders)'
            postParameterHeader: '\(self.requestBody?.postParameterHeader ?? "")'
            nonce: '\(self.nonce?.base64EncodedString() ?? "")'
            etag: '\(self.etag ?? "")'
            requestDate: \(self.requestDate)
        )
        """
    }

    private var messageString: String {
        return self.message.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

}

// MARK: - Private

private final class BundleToken: NSObject {}

private extension Signing {

    static func createPublicKey(with data: Data) throws -> PublicKey {
        return try Algorithm(rawRepresentation: data)
    }

    static func extractAndVerifyIntermediateKey(
        from signature: Data,
        publicKey: Signing.PublicKey,
        clock: ClockType
    ) -> Signing.PublicKey? {
        let intermediatePublicKey = signature.component(.intermediatePublicKey)
        let intermediateKeyExpiration = signature.component(.intermediateKeyExpiration)
        let intermediateKeySignature = signature.component(.intermediateKeySignature)

        guard publicKey.isValidSignature(intermediateKeySignature,
                                         for: intermediateKeyExpiration + intermediatePublicKey) else {
            Logger.warn(Strings.signing.intermediate_key_failed_verification(signature: intermediateKeySignature))
            return nil
        }

        guard let expirationDate = Self.extractAndVerifyIntermediateKeyExpiration(intermediateKeyExpiration,
                                                                                  clock) else {
            return nil
        }

        Logger.verbose(Strings.signing.intermediate_key_creating(expiration: expirationDate,
                                                                 data: intermediatePublicKey))

        do {
            return try Self.createPublicKey(with: intermediatePublicKey)
        } catch {
            Logger.error(Strings.signing.intermediate_key_failed_creation(error))
            return nil
        }
    }

    /// - Returns: `nil` if the key is expired or has an invalid expiration date.
    private static func extractAndVerifyIntermediateKeyExpiration(
        _ expirationData: Data,
        _ clock: ClockType
    ) -> Date? {
        let daysSince1970 = UInt32(littleEndian32Bits: expirationData)

        guard daysSince1970 > 0 else {
            Logger.warn(Strings.signing.intermediate_key_invalid(expirationData))
            return nil
        }

        let expirationDate = Date(daysSince1970: daysSince1970)
        guard expirationDate.timeIntervalSince(clock.now) >= 0 else {
            Logger.warn(Strings.signing.intermediate_key_expired(expirationDate, expirationData))
            return nil
        }

        return expirationDate
    }

}

// MARK: - Extensions

private extension Data {

    /// Extracts `Signing.SignatureComponent` from the receiver.
    func component(_ component: Signing.SignatureComponent) -> Data {
        let offset = component.offset
        let size = component.size

        return self.subdata(in: offset ..< offset + size)
    }

}

private extension Date {

    init(daysSince1970: UInt32) {
        self.init(timeIntervalSince1970: DispatchTimeInterval.days(Int(daysSince1970)).seconds)
    }

}
