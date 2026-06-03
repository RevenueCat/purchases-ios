//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InstallmentsInfoTests.swift
//
//  Created by Will Taylor on 6/1/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class InstallmentsInfoTests: TestCase {

    func testProperties() {
        let installmentsInfo = Self.installmentsInfo()

        expect(installmentsInfo.commitmentInstallmentsCount) == 12
        expect(installmentsInfo.commitmentInstallmentPeriod) == SubscriptionPeriod(value: 1, unit: .month)
        expect(installmentsInfo.installmentBillingPrice) == 0.99
        expect(installmentsInfo.installmentBillingDisplayPrice) == "$0.99"
        expect(installmentsInfo.commitmentTotalPeriod) == SubscriptionPeriod(value: 12, unit: .month)
        expect(installmentsInfo.commitmentTotalPrice) == 11.88
        expect(installmentsInfo.commitmentTotalDisplayPrice) == "$11.88"
        expect(installmentsInfo.billingPlanType) == .monthly
    }

    func testHash() {
        let lhs = Self.installmentsInfo()
        let rhs = Self.installmentsInfo()

        expect(lhs.hash) == rhs.hash
    }

    func testEquals() {
        let installmentsInfo1 = Self.installmentsInfo()
        let installmentsInfo2 = Self.installmentsInfo()
        let differentBillingPlanType = Self.installmentsInfo(billingPlanType: .upFront)

        expect(installmentsInfo1) == installmentsInfo1
        expect(installmentsInfo1) == installmentsInfo2
        expect(installmentsInfo1) != differentBillingPlanType
    }
}

private extension InstallmentsInfoTests {

    static func installmentsInfo(
        billingPlanType: BillingPlanType = .monthly
    ) -> InstallmentsInfo {
        return InstallmentsInfo(
            commitmentInstallmentsCount: 12,
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
            installmentBillingPrice: 0.99,
            installmentBillingDisplayPrice: "$0.99",
            commitmentTotalPeriod: SubscriptionPeriod(value: 12, unit: .month),
            commitmentTotalPrice: 11.88,
            commitmentTotalDisplayPrice: "$11.88",
            billingPlanType: billingPlanType
        )
    }
}
