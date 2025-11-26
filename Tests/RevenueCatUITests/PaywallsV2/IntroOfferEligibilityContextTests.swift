//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroOfferEligibilityContextTests.swift
//
//  Created by Facundo Menzella on 11/2/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Nimble
import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class IntroOfferEligibilityContextTests: TestCase {

    func testEligibilityUnknownUntilComputed() {
        let context = IntroOfferEligibilityContext(
            introEligibilityChecker: .producing(eligibility: .eligible)
        )

        expect(context.isEligible(package: TestData.packageWithIntroOffer)) == false
    }

    func testComputedEligibilityOverridesInitialFalse() async {
        let context = IntroOfferEligibilityContext(
            introEligibilityChecker: .producing(eligibility: .ineligible)
        )
        let package = TestData.packageWithIntroOffer

        expect(context.isEligible(package: package)) == true

        await context.computeEligibility(for: [package])

        expect(context.isEligible(package: package)) == false
    }

}
