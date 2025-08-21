//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingTests.swift
//
//  Created by Rick van der Linden on 21/08/2025.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class OfferingTests: StoreKitConfigTestCase {

    func testOfferingWithPresentedOfferingContext() async throws {

        let monthlyProduct = try await fetchSk2Product("com.revenuecat.monthly_4.99.1_week_intro")
        let monthlyPackage = Package(
            identifier: "monthlyPackage",
            packageType: .monthly,
            storeProduct: StoreProduct(
                sk2Product: monthlyProduct
            ),
            offeringIdentifier: "offering",
            webCheckoutUrl: nil
        )

        let annualProduct = try await fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        let annualPackage = Package(
            identifier: "annualPackage",
            packageType: .annual,
            storeProduct: StoreProduct(
                sk2Product: annualProduct
            ),
            offeringIdentifier: "offering",
            webCheckoutUrl: nil
        )

        let offering = Offering(
            identifier: "onboardingOffering",
            serverDescription: "",
            availablePackages: [
                monthlyPackage,
                annualPackage
            ],
            webCheckoutUrl: nil
        )

        let presentedOfferingContext = PresentedOfferingContext(
            offeringIdentifier: "onboardingOffering",
            placementIdentifier: "onboarding",
            targetingContext: .init(
                revision: 1,
                ruleId: "onboarding-rule-1"
            )
        )

        // all `availablePackages` should use the given `presentedOfferingContext`
        let offeringWithPresentedOfferingContext = offering.withPresentedOfferingContext(presentedOfferingContext)
        XCTAssert(offeringWithPresentedOfferingContext.availablePackages.allSatisfy {
            $0.presentedOfferingContext == presentedOfferingContext
        })
    }
}
