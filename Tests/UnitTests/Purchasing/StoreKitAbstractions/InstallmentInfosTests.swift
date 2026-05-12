//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InstallmentInfosTests.swift
//
//  Created by Will Taylor on 5/12/26.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

#if compiler(>=6.3.2)
@available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
class InstallmentInfosTests: TestCase {

    func testBillingPlanTypeReturnsMonthlyForMonthlyCommitmentInstallmentPeriod() {
        let installmentsInfo = self.buildInstallmentsInfo(
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month)
        )

        expect(installmentsInfo.billingPlanType) == .monthly
    }

    func testBillingPlanTypeReturnsNilForEveryTwoMonthsCommitmentInstallmentPeriod() {
        let installmentsInfo = self.buildInstallmentsInfo(
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 2, unit: .month)
        )

        expect(installmentsInfo.billingPlanType).to(beNil())
    }

    func testBillingPlanTypeReturnsNilForWeeklyCommitmentInstallmentPeriod() {
        let installmentsInfo = self.buildInstallmentsInfo(
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .week)
        )

        expect(installmentsInfo.billingPlanType).to(beNil())
    }

    func testBillingPlanTypeReturnsNilForYearlyCommitmentInstallmentPeriod() {
        let installmentsInfo = self.buildInstallmentsInfo(
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .year)
        )

        expect(installmentsInfo.billingPlanType).to(beNil())
    }

}

@available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
private extension InstallmentInfosTests {

    func buildInstallmentsInfo(
        commitmentInstallmentPeriod: RevenueCat.SubscriptionPeriod
    ) -> InstallmentsInfo {
        return InstallmentsInfo(
            commitmentInstallmentsCount: 1,
            commitmentInstallmentPeriod: commitmentInstallmentPeriod,
            installmentBillingPrice: Self.decimal(cents: 499),
            installmentBillingDisplayPrice: "$4.99",
            commitmentTotalPeriod: commitmentInstallmentPeriod,
            commitmentTotalPrice: Self.decimal(cents: 499),
            commitmentTotalDisplayPrice: "$4.99"
        )
    }

    static func decimal(cents: Int) -> Decimal {
        return Decimal(cents) / 100
    }

}
#endif
