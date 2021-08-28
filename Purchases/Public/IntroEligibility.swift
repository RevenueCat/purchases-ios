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
 * * .unknown RevenueCat doesn't have enough information to determine eligibility.
 * * .ineligible The user is not eligible for a free trial or intro pricing for this
 * product.
 * * .eligible The user is eligible for a free trial or intro pricing for this product.
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
        switch statusCode {
        case 0:
            self = .unknown
        case 1:
            self = .ineligible
        case 2:
            self = .eligible
        default:
            throw IntroEligibilityStatusError.invalidStatusCode(statusCode)
        }
    }
}

/**
 Holds the introductory price status
 */
@objc(RCIntroEligibility) public class IntroEligibility: NSObject {

    /**
     The introductory price eligibility status
     */
    @objc public let status: IntroEligibilityStatus

    @objc required public init(eligibilityStatus status: IntroEligibilityStatus) {
        self.status = status
    }

    @objc public init(eligibilityStatusCode statusCode: NSNumber) throws {
        self.status = try IntroEligibilityStatus(statusCode: statusCode.intValue)
    }

    @objc public override init() {
        self.status = .unknown
    }

    public override var description: String {
        switch status {
        case .eligible:
            return "Eligible for trial or introductory price."
        case .ineligible:
            return "Not eligible for trial or introductory price."
        default:
            return "Status indeterminate."
        }
    }

}
