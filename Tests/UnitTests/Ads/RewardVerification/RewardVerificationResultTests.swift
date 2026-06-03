//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationResultTests.swift
//

import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

final class RewardVerificationResultTests: XCTestCase {

    func testVerifiedProjectionsAndEquality() {
        let result = RewardVerificationResult.verified(.noReward)

        XCTAssertNotEqual(result, .failed)
        XCTAssertEqual(result.verifiedReward, .noReward)
        XCTAssertEqual(result, .verified(.noReward))
    }

    func testFailedProjectionsAndEquality() {
        let result = RewardVerificationResult.failed

        XCTAssertEqual(result, .failed)
        XCTAssertNil(result.verifiedReward)
    }

    func testUnsupportedRewardResult() {
        let result = RewardVerificationResult.verified(.unsupportedReward)
        XCTAssertEqual(result.verifiedReward, .unsupportedReward)
    }
}
