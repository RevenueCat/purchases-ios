//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageVariablesTests.swift
//
//  Created by Nacho Soto on 8/4/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageVariablesTests: TestCase {

    func testAppplicationName() {
        expect(TestData.monthlyPackage.applicationName) == "xctest"
    }

    func testLocalizedPrice() {
        expect(TestData.weeklyPackage.localizedPriceString) == "$1.99"
        expect(TestData.monthlyPackage.localizedPriceString) == "$6.99"
        expect(TestData.annualPackage.localizedPriceString) == "$53.99"
        expect(TestData.lifetimePackage.localizedPriceString) == "$119.49"
    }

    func testLocalizedPricePerMonth() {
        expect(TestData.weeklyPackage.localizedPricePerMonth) == "$7.96"
        expect(TestData.monthlyPackage.localizedPricePerMonth) == "$6.99"
        expect(TestData.threeMonthPackage.localizedPricePerMonth) == "$6.99"
        expect(TestData.sixMonthPackage.localizedPricePerMonth) == "$6.99"
        expect(TestData.annualPackage.localizedPricePerMonth) == "$4.49"
        expect(TestData.lifetimePackage.localizedPricePerMonth) == "$119.49"
    }

    func testEnglishLocalizedPricePerPeriod() {
        expect(TestData.weeklyPackage.localizedPricePerPeriod(Self.english)) == "$1.99/wk"
        expect(TestData.monthlyPackage.localizedPricePerPeriod(Self.english)) == "$6.99/mo"
        expect(TestData.threeMonthPackage.localizedPricePerPeriod(Self.english)) == "$4.99/3mo"
        expect(TestData.sixMonthPackage.localizedPricePerPeriod(Self.english)) == "$7.99/6mo"
        expect(TestData.annualPackage.localizedPricePerPeriod(Self.english)) == "$53.99/yr"
        expect(TestData.lifetimePackage.localizedPricePerPeriod(Self.english)) == "$119.49"
    }

    func testSpanishLocalizedPricePerPeriod() {
        expect(TestData.weeklyPackage.localizedPricePerPeriod(Self.spanish)) == "$1.99/sem"
        expect(TestData.monthlyPackage.localizedPricePerPeriod(Self.spanish)) == "$6.99/m."
        expect(TestData.threeMonthPackage.localizedPricePerPeriod(Self.spanish)) == "$4.99/3m"
        expect(TestData.sixMonthPackage.localizedPricePerPeriod(Self.spanish)) == "$7.99/6m"
        expect(TestData.annualPackage.localizedPricePerPeriod(Self.spanish)) == "$53.99/año"
        expect(TestData.lifetimePackage.localizedPricePerPeriod(Self.spanish)) == "$119.49"
    }

    func testEnglishLocalizedPriceAndPerMonth() {
        expect(TestData.weeklyPackage.localizedPriceAndPerMonth(Self.english)) == "$1.99 ($7.96/mo)"
        expect(TestData.monthlyPackage.localizedPriceAndPerMonth(Self.english)) == "$6.99/mo"
        expect(TestData.threeMonthPackage.localizedPriceAndPerMonth(Self.english)) == "$4.99 ($1.66/mo)"
        expect(TestData.sixMonthPackage.localizedPriceAndPerMonth(Self.english)) == "$7.99 ($1.33/mo)"
        expect(TestData.annualPackage.localizedPriceAndPerMonth(Self.english)) == "$53.99 ($4.49/mo)"
        expect(TestData.lifetimePackage.localizedPriceAndPerMonth(Self.english)) == "$119.49"
    }

    func testSpanishLocalizedPriceAndPerMonth() {
        expect(TestData.weeklyPackage.localizedPriceAndPerMonth(Self.spanish)) == "$1.99 ($7.96/m.)"
        expect(TestData.monthlyPackage.localizedPriceAndPerMonth(Self.spanish)) == "$6.99/m."
        expect(TestData.threeMonthPackage.localizedPriceAndPerMonth(Self.spanish)) == "$4.99 ($1.66/m.)"
        expect(TestData.sixMonthPackage.localizedPriceAndPerMonth(Self.spanish)) == "$7.99 ($1.33/m.)"
        expect(TestData.annualPackage.localizedPriceAndPerMonth(Self.spanish)) == "$53.99 ($4.49/m.)"
        expect(TestData.lifetimePackage.localizedPriceAndPerMonth(Self.spanish)) == "$119.49"
    }

    func testProductName() {
        expect(TestData.weeklyPackage.productName) == "Weekly"
        expect(TestData.monthlyPackage.productName) == "Monthly"
        expect(TestData.threeMonthPackage.productName) == "3 months"
        expect(TestData.sixMonthPackage.productName) == "6 months"
        expect(TestData.annualPackage.productName) == "Annual"
        expect(TestData.lifetimePackage.productName) == "Lifetime"
    }

    func testEnglishPeriodName() {
        expect(TestData.weeklyPackage.periodName(Self.english)) == "Weekly"
        expect(TestData.monthlyPackage.periodName(Self.english)) == "Monthly"
        expect(TestData.threeMonthPackage.periodName(Self.english)) == "3 Month"
        expect(TestData.sixMonthPackage.periodName(Self.english)) == "6 Month"
        expect(TestData.annualPackage.periodName(Self.english)) == "Annual"
        expect(TestData.lifetimePackage.periodName(Self.english)) == "Lifetime"
    }

    func testSpanishPeriodName() {
        expect(TestData.weeklyPackage.periodName(Self.spanish)) == "Semanalmente"
        expect(TestData.monthlyPackage.periodName(Self.spanish)) == "Mensual"
        expect(TestData.threeMonthPackage.periodName(Self.spanish)) == "3 meses"
        expect(TestData.sixMonthPackage.periodName(Self.spanish)) == "6 meses"
        expect(TestData.annualPackage.periodName(Self.spanish)) == "Anual"
        expect(TestData.lifetimePackage.periodName(Self.spanish)) == "Toda la vida"
    }

    func testEnglishIntroductoryOfferDuration() {
        expect(TestData.weeklyPackage.introductoryOfferDuration(Self.english)).to(beNil())
        expect(TestData.monthlyPackage.introductoryOfferDuration(Self.english)) == "7 days"
        expect(TestData.annualPackage.introductoryOfferDuration(Self.english)) == "14 days"
        expect(TestData.lifetimePackage.introductoryOfferDuration(Self.english)).to(beNil())
    }

    func testSpanishIntroductoryOfferDuration() {
        expect(TestData.weeklyPackage.introductoryOfferDuration(Self.spanish)).to(beNil())
        expect(TestData.monthlyPackage.introductoryOfferDuration(Self.spanish)) == "7 días"
        expect(TestData.annualPackage.introductoryOfferDuration(Self.spanish)) == "14 días"
        expect(TestData.lifetimePackage.introductoryOfferDuration(Self.spanish)).to(beNil())
    }

    func testIntroductoryOfferPrice() {
        expect(TestData.weeklyPackage.localizedIntroductoryOfferPrice).to(beNil())
        expect(TestData.monthlyPackage.localizedIntroductoryOfferPrice) == "$0.00"
        expect(TestData.annualPackage.localizedIntroductoryOfferPrice) == "$1.99"
        expect(TestData.lifetimePackage.localizedIntroductoryOfferPrice).to(beNil())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageVariablesTests {

    static let english: Locale = .init(identifier: "en_US")
    static let spanish: Locale = .init(identifier: "es_ES")

}
