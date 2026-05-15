//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InstallmentsInfoFactoryTests.swift
//
//  Created by Will Taylor on 5/11/26.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

#if compiler(>=6.3.2)
@available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
class InstallmentsInfoFactoryTests: TestCase {

    private typealias BillingPlanType = StoreKit.Product.SubscriptionInfo.BillingPlanType
    private typealias CommitmentPeriod = StoreKit.Product.SubscriptionPeriod

    private let factory = InstallmentsInfoFactory()

    func testBuildInstallmentsInfoForMonthlyBillingPlanAndMonthlyCommitment() throws {
        let installmentsInfo = try XCTUnwrap(
            self.buildInstallmentsInfo(commitmentPeriod: .monthly, commitmentTotalDisplayPrice: "$4.99")
        )

        expect(installmentsInfo.installmentsCount) == 1
        expect(installmentsInfo.commitmentTotalPeriod) == SubscriptionPeriod(value: 1, unit: .month)
        expect(installmentsInfo.commitmentTotalPrice) == Self.decimal(cents: 499)
        expect(installmentsInfo.commitmentTotalDisplayPrice) == "$4.99"
        expect(installmentsInfo.installmentBillingPrice) == Self.decimal(cents: 499)
        expect(installmentsInfo.installmentBillingDisplayPrice) == "$4.99"
    }

    func testBuildInstallmentsInfoForMonthlyBillingPlanAndEveryTwoMonthsCommitment() throws {
        let installmentsInfo = try XCTUnwrap(
            self.buildInstallmentsInfo(commitmentPeriod: .everyTwoMonths, commitmentTotalDisplayPrice: "$9.98")
        )

        expect(installmentsInfo.installmentsCount) == 2
        expect(installmentsInfo.commitmentTotalPeriod) == SubscriptionPeriod(value: 2, unit: .month)
        expect(installmentsInfo.commitmentTotalPrice) == Self.decimal(cents: 998)
        expect(installmentsInfo.commitmentTotalDisplayPrice) == "$9.98"
        expect(installmentsInfo.installmentBillingPrice) == Self.decimal(cents: 499)
        expect(installmentsInfo.installmentBillingDisplayPrice) == "$4.99"
    }

    func testBuildInstallmentsInfoForMonthlyBillingPlanAndEveryThreeMonthsCommitment() throws {
        let installmentsInfo = try XCTUnwrap(
            self.buildInstallmentsInfo(commitmentPeriod: .everyThreeMonths, commitmentTotalDisplayPrice: "$14.97")
        )

        expect(installmentsInfo.installmentsCount) == 3
        expect(installmentsInfo.commitmentTotalPeriod) == SubscriptionPeriod(value: 3, unit: .month)
        expect(installmentsInfo.commitmentTotalPrice) == Self.decimal(cents: 1497)
        expect(installmentsInfo.commitmentTotalDisplayPrice) == "$14.97"
        expect(installmentsInfo.installmentBillingPrice) == Self.decimal(cents: 499)
        expect(installmentsInfo.installmentBillingDisplayPrice) == "$4.99"
    }

    func testBuildInstallmentsInfoForMonthlyBillingPlanAndEverySixMonthsCommitment() throws {
        let installmentsInfo = try XCTUnwrap(
            self.buildInstallmentsInfo(commitmentPeriod: .everySixMonths, commitmentTotalDisplayPrice: "$29.94")
        )

        expect(installmentsInfo.installmentsCount) == 6
        expect(installmentsInfo.commitmentTotalPeriod) == SubscriptionPeriod(value: 6, unit: .month)
        expect(installmentsInfo.commitmentTotalPrice) == Self.decimal(cents: 2994)
        expect(installmentsInfo.commitmentTotalDisplayPrice) == "$29.94"
        expect(installmentsInfo.installmentBillingPrice) == Self.decimal(cents: 499)
        expect(installmentsInfo.installmentBillingDisplayPrice) == "$4.99"
    }

    func testBuildInstallmentsInfoForMonthlyBillingPlanAndYearlyCommitment() throws {
        let installmentsInfo = try XCTUnwrap(
            self.buildInstallmentsInfo(commitmentPeriod: .yearly, commitmentTotalDisplayPrice: "$59.88")
        )

        expect(installmentsInfo.installmentsCount) == 12
        expect(installmentsInfo.commitmentTotalPeriod) == SubscriptionPeriod(value: 1, unit: .year)
        expect(installmentsInfo.commitmentTotalPrice) == Self.decimal(cents: 5988)
        expect(installmentsInfo.commitmentTotalDisplayPrice) == "$59.88"
        expect(installmentsInfo.installmentBillingPrice) == Self.decimal(cents: 499)
        expect(installmentsInfo.installmentBillingDisplayPrice) == "$4.99"
    }

    func testBuildInstallmentsInfoReturnsNilForUpFrontBillingPlan() {
        let installmentsInfo = self.buildInstallmentsInfo(
            billingPlanType: .upFront,
            commitmentPeriod: .monthly
        )

        expect(installmentsInfo).to(beNil())
    }

    func testBuildInstallmentsInfoReturnsNilForUnknownBillingPlan() {
        let installmentsInfo = self.buildInstallmentsInfo(
            billingPlanType: BillingPlanType(rawValue: "unknown"),
            commitmentPeriod: .monthly
        )

        expect(installmentsInfo).to(beNil())
    }

    func testBuildInstallmentsInfoReturnsNilForUnsupportedCommitmentPeriod() {
        let installmentsInfo = self.buildInstallmentsInfo(commitmentPeriod: .weekly)

        expect(installmentsInfo).to(beNil())
    }

}

@available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
private extension InstallmentsInfoFactoryTests {

    private func buildInstallmentsInfo(
        billingPlanType: BillingPlanType = .monthly,
        commitmentPeriod: CommitmentPeriod,
        billingPrice: Decimal = InstallmentsInfoFactoryTests.decimal(cents: 499),
        billingDisplayPrice: String = "$4.99",
        commitmentTotalDisplayPrice: String = "$0"
    ) -> InstallmentsInfo? {
        return self.factory.buildInstallmentsInfo(
            billingPlanType: billingPlanType,
            commitmentPeriod: commitmentPeriod,
            billingPrice: billingPrice,
            billingDisplayPrice: billingDisplayPrice,
            commitmentTotalDisplayPrice: commitmentTotalDisplayPrice
        )
    }

    static func decimal(cents: Int) -> Decimal {
        return Decimal(cents) / 100
    }

}
#endif
