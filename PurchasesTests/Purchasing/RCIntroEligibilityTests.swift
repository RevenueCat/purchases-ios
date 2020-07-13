//
//  RCIntroEligibilityTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/1/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble
@testable import Purchases

class RCIntroEligibilityTests: XCTestCase {
    func testInitWithEligibilityStatusCodeUnknown() {
        let introElegibility = RCIntroEligibility(eligibilityStatusCode: NSNumber(value: IntroEligibilityStatus.unknown.rawValue))
        expect(introElegibility?.status) == RCIntroEligibilityStatus.unknown
    }
    
    func testInitWithEligibilityStatusCodeIneligible() {
        let introElegibility = RCIntroEligibility(eligibilityStatusCode: NSNumber(value: IntroEligibilityStatus.ineligible.rawValue))
        expect(introElegibility?.status) == RCIntroEligibilityStatus.ineligible
    }

    func testInitWithEligibilityStatusCodeEligible() {
        let introElegibility = RCIntroEligibility(eligibilityStatusCode: NSNumber(value: IntroEligibilityStatus.eligible.rawValue))
        expect(introElegibility?.status) == RCIntroEligibilityStatus.eligible
    }
    
    func testInitWithEligibilityStatusCodeFailsIfInvalid() {
        expect { RCIntroEligibility(eligibilityStatusCode: -1) } .to(raiseException())
        expect { RCIntroEligibility(eligibilityStatusCode: 3) } .to(raiseException())
    }
}
