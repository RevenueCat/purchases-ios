//
//  IntroEligibilityTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/1/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble

@testable import PurchasesCoreSwift

class IntroEligibilityTests: XCTestCase {
    func testInitWithEligibilityStatusCodeUnknown() {
        let introElegibility = try! IntroEligibility(eligibilityStatusCode: NSNumber(value: IntroEligibilityStatus.unknown.rawValue))
        expect(introElegibility.status) == IntroEligibilityStatus.unknown
    }
    
    func testInitWithEligibilityStatusCodeIneligible() {
        let introElegibility = try! IntroEligibility(eligibilityStatusCode: NSNumber(value: IntroEligibilityStatus.ineligible.rawValue))
        expect(introElegibility.status) == IntroEligibilityStatus.ineligible
    }

    func testInitWithEligibilityStatusCodeEligible() {
        let introElegibility = try! IntroEligibility(eligibilityStatusCode: NSNumber(value: IntroEligibilityStatus.eligible.rawValue))
        expect(introElegibility.status) == IntroEligibilityStatus.eligible
    }
    
    func testInitWithEligibilityStatusCodeFailsIfInvalid() {
        expect(try IntroEligibility(eligibilityStatusCode: -1)).to(
            throwError(closure: { expect($0.localizedDescription).to(equal("😿 Invalid status code: -1"))})
        )
        expect(try IntroEligibility(eligibilityStatusCode: 3)).to(
            throwError(closure: { expect($0.localizedDescription).to(equal("😿 Invalid status code: 3"))})
        )
    }
}
