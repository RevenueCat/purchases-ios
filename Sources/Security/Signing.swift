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

// swiftlint:disable file_length

/// A type that can verify signatures.
protocol SigningType {

    func verificationResult(
        for signature: String,
        with parameters: Signing.SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> SignatureVerificationResult

}

/// Utilities for handling signature verification.
final class Signing: SigningType {

    /// An object that represents a cryptographic key.
    typealias PublicKey = SigningPublicKey
    typealias PublicKeyFactory = (Data) throws -> PublicKey

    /// Parameters used for signature creation / verification.
    struct SignatureParameters {

        var path: HTTPRequestPath
        var iamEnabled: Bool
        var message: Data?
        var requestHeaders: HTTPRequest.Headers
        var requestBody: HTTPRequestBody?
        var nonce: Data?
        var etag: String?
        var requestDate: UInt64
        var useFallbackPath: Bool

    }

    private let apiKey: String
    private let clock: ClockType
    private let publicKeyFactory: PublicKeyFactory

    init(apiKey: String, clock: ClockType = Clock.default) {
        self.apiKey = apiKey
        self.clock = clock
        self.publicKeyFactory = Self.createPublicKey
    }

    init(apiKey: String, clock: ClockType, publicKeyFactory: @escaping PublicKeyFactory) {
        self.apiKey = apiKey
        self.clock = clock
        self.publicKeyFactory = publicKeyFactory
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

    func verificationResult(
        for signature: String,
        with parameters: SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> SignatureVerificationResult {
        guard let signature = Data(base64Encoded: signature) else {
            Logger.warn(Strings.signing.signature_not_base64(signature))
            return .failed(.invalidSignatureFormat)
        }

        guard signature.count == SignatureComponent.totalSize else {
            Logger.warn(Strings.signing.signature_invalid_size(signature))
            return .failed(.invalidSignatureFormat)
        }

        let intermediatePublicKey: Signing.PublicKey
        do {
            intermediatePublicKey = try Self.extractAndVerifyIntermediateKey(
                from: signature,
                publicKey: publicKey,
                clock: self.clock,
                publicKeyFactory: self.publicKeyFactory
            )
        } catch let error as IntermediateKeyError {
            return .failed(.init(error))
        } catch {
            return .failed(.unknown)
        }

        let authValue = parameters.requestHeaders.bearerAuthorizationValue ?? self.apiKey

        let salt = signature.component(.salt)
        let payload = signature.component(.payload)
        let messageToVerify = parameters.signature(salt: salt, authValue: authValue)

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
            return .verified
        } else {
            Logger.warn(Strings.signing.signature_failed_verification)
            return .failed(.payloadSignatureMismatch)
        }
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
        iamEnabled: Bool,
        message: Data? = nil,
        requestHeaders: HTTPRequest.Headers = [:],
        requestBody: HTTPRequestBody? = nil,
        nonce: Data? = nil,
        etag: String? = nil,
        requestDate: UInt64,
        useFallbackPath: Bool = false
    ) {
        self.path = path
        self.iamEnabled = iamEnabled
        self.message = message
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.nonce = nonce
        self.etag = etag
        self.requestDate = requestDate
        self.useFallbackPath = useFallbackPath
    }

    func signature(salt: Data, authValue: String) -> Data {
        let auth = self.path.authenticated ? authValue : ""
        return salt + auth.asData + self.asData
    }

    var asData: Data {
        let nonce: Data = self.nonce ?? .init()
        let relativePath: String
        if useFallbackPath, let fallbackRelativePath = self.path.fallbackRelativePath {
            relativePath = fallbackRelativePath
        } else {
            relativePath = self.iamEnabled ? self.path.relativeIAMPath : self.path.relativePath
        }
        let path: Data = relativePath.asData
        let postParameterHash: Data = self.requestBody?.postParameterHeader?.asData ?? .init()
        let headerParametersHash: Data = HTTPRequest.headerParametersForSignatureHeader(
            headers: self.requestHeaders,
            path: self.path
        )?
        .asData ?? .init()
        let requestDate: Data = String(self.requestDate).asData
        let etag: Data = (self.etag ?? "").asData
        let message: Data = self.message ?? .init()

        return (nonce + path + postParameterHash + headerParametersHash + requestDate + etag + message)
    }

}

extension Signing.SignatureParameters: CustomDebugStringConvertible {

    var debugDescription: String {
        return """
        SignatureParameters(" +
            path: '\(self.iamEnabled ? self.path.relativeIAMPath : self.path.relativePath)'
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

// swiftlint:disable:next private_over_fileprivate
fileprivate enum IntermediateKeyError: Error {

    case invalidSignature
    case invalidExpiration
    case expired
    case invalidKey

}

fileprivate extension SignatureVerificationResult.FailureReason {

    init(_ error: IntermediateKeyError) {
        switch error {
        case .invalidSignature:
            self = .invalidIntermediateKeySignature
        case .invalidExpiration:
            self = .unknown
        case .expired:
            self = .intermediateKeyExpired
        case .invalidKey:
            self = .invalidIntermediateKey
        }
    }

}

private extension Signing {

    static func createPublicKey(with data: Data) throws -> PublicKey {
        return try Algorithm(rawRepresentation: data)
    }

    static func extractAndVerifyIntermediateKey(
        from signature: Data,
        publicKey: Signing.PublicKey,
        clock: ClockType,
        publicKeyFactory: PublicKeyFactory
    ) throws -> Signing.PublicKey {
        let intermediatePublicKey = signature.component(.intermediatePublicKey)
        let intermediateKeyExpiration = signature.component(.intermediateKeyExpiration)
        let intermediateKeySignature = signature.component(.intermediateKeySignature)

        guard publicKey.isValidSignature(intermediateKeySignature,
                                         for: intermediateKeyExpiration + intermediatePublicKey) else {
            Logger.warn(Strings.signing.intermediate_key_failed_verification(signature: intermediateKeySignature))
            throw IntermediateKeyError.invalidSignature
        }

        let expirationDate = try Self.extractAndVerifyIntermediateKeyExpiration(intermediateKeyExpiration, clock)

        Logger.verbose(Strings.signing.intermediate_key_creating(expiration: expirationDate,
                                                                 data: intermediatePublicKey))

        do {
            return try publicKeyFactory(intermediatePublicKey)
        } catch {
            Logger.error(Strings.signing.intermediate_key_failed_creation(error))
            throw IntermediateKeyError.invalidKey
        }
    }

    private static func extractAndVerifyIntermediateKeyExpiration(
        _ expirationData: Data,
        _ clock: ClockType
    ) throws -> Date {
        let daysSince1970 = UInt32(littleEndian32Bits: expirationData)

        guard daysSince1970 > 0 else {
            Logger.warn(Strings.signing.intermediate_key_invalid(expirationData))
            throw IntermediateKeyError.invalidExpiration
        }

        let expirationDate = Date(daysSince1970: daysSince1970)
        guard expirationDate.timeIntervalSince(clock.now) >= 0 else {
            Logger.warn(Strings.signing.intermediate_key_expired(expirationDate, expirationData))
            throw IntermediateKeyError.expired
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
