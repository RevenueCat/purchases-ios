//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BillingPlanTypeTests.swift
//
//  Created by Will Taylor on 5/13/26.

import Foundation
import Nimble
import StoreKit
@testable import RevenueCat
import XCTest

class BillingPlanTypeTests: TestCase {
    func testEquality() {
        expect(BillingPlanType.monthly).to(equal(BillingPlanType.monthly))
        expect(BillingPlanType.upFront).to(equal(BillingPlanType.upFront))

        expect(BillingPlanType.monthly).toNot(equal(BillingPlanType.upFront))
    }

    func testPatternMatchingOperator() {
        expect(BillingPlanType.monthly ~= BillingPlanType.monthly).to(beTrue())
        expect(BillingPlanType.upFront ~= BillingPlanType.upFront).to(beTrue())

        expect(BillingPlanType.monthly ~= BillingPlanType.upFront).to(beFalse())
    }

    func testSwitchStatementWorks() {
        let billingPlanType = BillingPlanType.monthly

        switch billingPlanType {
        case .monthly:
            return
        case .upFront:
            fail("Switch should go through monthly case")
        default:
            fail("Switch should go through monthly case")
        }

        fail("Switch should go through monthly case")
    }
}

// MARK: - To/From StoreKit BillingPlanType
#if compiler(>=6.3.2)
extension BillingPlanTypeTests {

    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    func testFromStoreKitBillingPlanType() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        expect(BillingPlanType.from(storeKitBillingPlanType: .monthly)).to(equal(BillingPlanType.monthly))
        expect(BillingPlanType.from(storeKitBillingPlanType: .upFront)).to(equal(BillingPlanType.upFront))
    }

    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    func testSKBillingPlanTypeComputedProperty() throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()

        expect(BillingPlanType.monthly.skBillingPlanType)
            .to(equal(StoreKit.Product.SubscriptionInfo.BillingPlanType.monthly))

        expect(BillingPlanType.upFront.skBillingPlanType)
            .to(equal(StoreKit.Product.SubscriptionInfo.BillingPlanType.upFront))
    }
}
#endif
