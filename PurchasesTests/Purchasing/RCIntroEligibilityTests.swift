//
//  IntroEligibilityTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/1/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble

@testable import RevenueCat

class IntroEligibilityTests: XCTestCase {
    func testInitWithEligibilityStatusCodeUnknown() throws {
        expect(try self.create(.unknown).status) == IntroEligibilityStatus.unknown
    }
    
    func testInitWithEligibilityStatusCodeIneligible() throws {
        expect(try self.create(.ineligible).status) == IntroEligibilityStatus.ineligible
    }

    func testInitWithEligibilityStatusCodeEligible() throws {
        expect(try self.create(.eligible).status) == IntroEligibilityStatus.eligible
    }
    
    func testInitWithEligibilityStatusCodeFailsIfInvalid() {
        expect(try IntroEligibility(eligibilityStatusCode: -1)).to(
            throwError(closure: { expect($0.localizedDescription).to(equal("😿 Invalid status code: -1"))})
        )
        expect(try IntroEligibility(eligibilityStatusCode: 3)).to(
            throwError(closure: { expect($0.localizedDescription).to(equal("😿 Invalid status code: 3"))})
        )
    }

    private func create(_ code: IntroEligibilityStatus) throws -> IntroEligibility {
        return try IntroEligibility(eligibilityStatusCode: NSNumber(value: code.rawValue))
    }
}
