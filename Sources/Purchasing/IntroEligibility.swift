//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroEligibility.swift
//
//  Created by Joshua Liebowitz on 7/6/21.
//

import Foundation

/**
 * Enum of different possible states for intro price eligibility status.
 * * ``IntroEligibilityStatus/unknown`` RevenueCat doesn't have enough information to determine eligibility.
 * * ``IntroEligibilityStatus/ineligible`` The user is not eligible for a free trial or intro pricing for this
 * product.
 * * ``IntroEligibilityStatus/eligible`` The user is eligible for a free trial or intro pricing for this product.
 */
@objc(RCIntroEligibilityStatus) public enum IntroEligibilityStatus: Int {

    /**
     RevenueCat doesn't have enough information to determine eligibility.
     */
    case unknown = 0

    /**
     The user is not eligible for a free trial or intro pricing for this product.
     */
    case ineligible

    /**
     The user is eligible for a free trial or intro pricing for this product.
     */
    case eligible

    /**
     There is no free trial or intro pricing for this product.
     */
    case noIntroOfferExists

}

extension IntroEligibilityStatus: CaseIterable, Sendable {}

extension IntroEligibilityStatus: CustomStringConvertible {

    // swiftlint:disable:next missing_docs
    public var description: String {
        switch self {
        case .eligible: return "\(type(of: self)).eligible"
        case .ineligible: return "\(type(of: self)).ineligible"
        case .noIntroOfferExists: return "\(type(of: self)).noIntroOfferExists"

        case .unknown: fallthrough
        @unknown default:
            return "\(type(of: self)).unknown"
        }
    }

}

extension IntroEligibilityStatus {

    /// - Returns: `true` if this eligibility is ``IntroEligibilityStatus/isEligible``.
    public var isEligible: Bool {
        switch self {
        case .unknown, .ineligible, .noIntroOfferExists:
            return false
        case .eligible:
            return true
        }
    }

}

private extension IntroEligibilityStatus {

    enum IntroEligibilityStatusError: LocalizedError {
        case invalidStatusCode(Int)

        var errorDescription: String? {
            switch self {
            case .invalidStatusCode(let code):
                return "😿 Invalid status code: \(code)"
            }
        }
    }

    init(statusCode: Int) throws {
        guard let result = Self.mapping[statusCode] else {
            throw IntroEligibilityStatusError.invalidStatusCode(statusCode)
        }

        self = result
    }

    private static let mapping: [Int: IntroEligibilityStatus] = Dictionary(
        uniqueKeysWithValues: IntroEligibilityStatus.allCases.map { ($0.rawValue, $0) }
    )
}

// Note about the need for `IntroEligibility`: it only holds a `IntroEligibilityStatus`
// so one might think it's redundant, but it's actually the only way for the APIs that
// a dictionary of Product Identifier -> Eligibility to work in Objective-C.
// `[String: IntroEligibilityStatus]` can't be represented in Obj-C, other than through
// `[String: NSNumber]`, which would be a worse API.

/**
 Holds the introductory price status
 */
@objc(RCIntroEligibility) public final class IntroEligibility: NSObject {

    /**
     The introductory price eligibility status
     */
    @objc public let status: IntroEligibilityStatus

    init(eligibilityStatus status: IntroEligibilityStatus) {
        self.status = status
    }

    @objc private override init() {
        self.status = .unknown
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }

        return other.status == self.status
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.status)

        return hasher.finalize()
    }

}

extension IntroEligibility {

    public override var description: String {
        switch self.status {
        case .eligible:
            return "Eligible for trial or introductory price."
        case .ineligible:
            return "Not eligible for trial or introductory price."
        case .noIntroOfferExists:
            return "Product does not have trial or introductory price."

        case .unknown: fallthrough
        @unknown default:
            return "Unknown status"
        }
    }

    public override var debugDescription: String {
        let name = "\(type(of: self))"

        switch self.status {
        case .eligible:
            return "\(name).eligible"
        case .ineligible:
            return "\(name).ineligible"
        case .noIntroOfferExists:
            return "\(name).noIntroOfferExists"
        case .unknown:
            return "\(name).unknown"
        @unknown default:
            return "Unknown"
        }
    }

}

extension IntroEligibility: Sendable {}
