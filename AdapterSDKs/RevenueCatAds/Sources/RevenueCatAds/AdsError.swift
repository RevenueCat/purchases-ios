//
//  AdsError.swift
//
//  Created by RevenueCat.
//

import Foundation

/// An error reported by `RevenueCatAds`.
@_spi(Experimental) public struct AdsError: Error, CustomStringConvertible {

    /// The category of an ``AdsError``.
    ///
    /// Modeled as a struct with static constants (not an enum) so new codes can be added
    /// without breaking exhaustive `switch` statements in client code.
    public struct Code: Hashable, CustomStringConvertible {

        /// Stable string identifier of the code.
        public let rawValue: String

        /// ``RCAds/configure(with:)`` has not been called successfully.
        public static let notConfigured = Code(rawValue: "not_configured")
        /// The configuration could not be resolved or was rejected by the ad module.
        public static let invalidConfiguration = Code(rawValue: "invalid_configuration")
        /// The call is not allowed in the ad's current state (e.g. `load()` while already loading).
        public static let invalidState = Code(rawValue: "invalid_state")
        /// `present(from:)` was called before an ad finished loading.
        public static let notReady = Code(rawValue: "not_ready")
        /// The auction completed without a winning bid.
        public static let noFill = Code(rawValue: "no_fill")
        /// The ad failed to load for any other reason; see ``AdsError/underlyingError``.
        public static let loadFailed = Code(rawValue: "load_failed")

        // swiftlint:disable:next missing_docs
        public var description: String { self.rawValue }

    }

    /// The error category.
    public let code: Code
    /// Human-readable explanation.
    public let message: String
    /// The error reported by the underlying ad SDK or system, if any.
    public let underlyingError: Error?

    /// Creates an error.
    public init(code: Code, message: String, underlyingError: Error? = nil) {
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
    }

    // swiftlint:disable:next missing_docs
    public var description: String {
        if let underlyingError = self.underlyingError {
            return "AdsError(\(self.code)): \(self.message) (\(underlyingError.localizedDescription))"
        }
        return "AdsError(\(self.code)): \(self.message)"
    }

}

extension AdsError: LocalizedError {

    // swiftlint:disable:next missing_docs
    public var errorDescription: String? { self.message }

}
