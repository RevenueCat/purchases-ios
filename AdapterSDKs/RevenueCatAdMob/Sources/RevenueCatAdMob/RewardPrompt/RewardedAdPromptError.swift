//
//  RewardedAdPromptError.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)

/// A failure while presenting a rewarded-ad prompt.
@available(iOS 15.0, *)
public struct RewardedAdPromptError: LocalizedError {

    /// The category of failure.
    public let code: Code

    /// The underlying error, when the failure originated in AdMob.
    public let underlyingError: Error?

    /// A description of the presentation failure.
    public var errorDescription: String? {
        switch self.code {
        case .presentationContextUnavailable:
            return "The rewarded ad could not be presented because no attached presentation controller is available."
        case .adFailedToPresent:
            if let underlyingError {
                return "The rewarded ad failed to present: \(underlyingError.localizedDescription)"
            } else {
                return "The rewarded ad failed to present."
            }
        default:
            return "The rewarded ad could not be presented."
        }
    }

    init(code: Code, underlyingError: Error? = nil) {
        self.code = code
        self.underlyingError = underlyingError
    }

    /// A category of rewarded-ad prompt failure.
    public struct Code: Sendable, Equatable, Hashable {

        /// No presentation controller is attached to the prompt's window.
        public static let presentationContextUnavailable = Code(rawValue: "presentation_context_unavailable")

        /// AdMob failed to present the loaded rewarded ad.
        public static let adFailedToPresent = Code(rawValue: "ad_failed_to_present")

        private let rawValue: String

        private init(rawValue: String) {
            self.rawValue = rawValue
        }

    }

}

#endif
