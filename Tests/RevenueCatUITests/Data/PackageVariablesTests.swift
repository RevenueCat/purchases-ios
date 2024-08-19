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

// swiftlint:disable type_body_length file_length

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

    func testLocalizedPricePerWeek() {
        expect(TestData.weeklyPackage.localizedPricePerWeek()) == "$1.99"
        expect(TestData.monthlyPackage.localizedPricePerWeek()) == "$1.60"
        expect(TestData.threeMonthPackage.localizedPricePerWeek()) == "$0.38"
        expect(TestData.sixMonthPackage.localizedPricePerWeek()) == "$0.30"
        expect(TestData.annualPackage.localizedPricePerWeek()) == "$1.03"
        expect(TestData.lifetimePackage.localizedPricePerWeek()) == "$119.49"
    }

    func testLocalizedPricePerMonth() {
        expect(TestData.weeklyPackage.localizedPricePerMonth()) == "$8.64"
        expect(TestData.monthlyPackage.localizedPricePerMonth()) == "$6.99"
        expect(TestData.threeMonthPackage.localizedPricePerMonth()) == "$1.66"
        expect(TestData.sixMonthPackage.localizedPricePerMonth()) == "$1.33"
        expect(TestData.annualPackage.localizedPricePerMonth()) == "$4.49"
        expect(TestData.lifetimePackage.localizedPricePerMonth()) == "$119.49"
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

    func testArabicLocalizedPricePerPeriod() {
        let arabicPrice = "٣.٩٩ درهم"

        expect(TestData.weeklyPackage.with(arabicPrice, Self.arabic).localizedPricePerPeriod(Self.arabic))
        == "٣.٩٩ درهم/أسبوع"
        expect(TestData.monthlyPackage.with(arabicPrice, Self.arabic).localizedPricePerPeriod(Self.arabic))
        == "٣.٩٩ درهم/شهر"
        expect(TestData.threeMonthPackage.with(arabicPrice, Self.arabic).localizedPricePerPeriod(Self.arabic))
        == "٣.٩٩ درهم/3شهر"
        expect(TestData.sixMonthPackage.with(arabicPrice, Self.arabic).localizedPricePerPeriod(Self.arabic))
        == "٣.٩٩ درهم/6شهر"
        expect(TestData.annualPackage.with(arabicPrice, Self.arabic).localizedPricePerPeriod(Self.arabic))
        == "٣.٩٩ درهم/سنة"
        expect(TestData.lifetimePackage.with(arabicPrice, Self.arabic).localizedPricePerPeriod(Self.arabic))
        == "٣.٩٩ درهم"
    }

    func testEnglishLocalizedPricePerPeriodFull() {
        expect(TestData.weeklyPackage.localizedPricePerPeriodFull(Self.english)) == "$1.99/week"
        expect(TestData.monthlyPackage.localizedPricePerPeriodFull(Self.english)) == "$6.99/month"
        expect(TestData.threeMonthPackage.localizedPricePerPeriodFull(Self.english)) == "$4.99/3months"
        expect(TestData.sixMonthPackage.localizedPricePerPeriodFull(Self.english)) == "$7.99/6months"
        expect(TestData.annualPackage.localizedPricePerPeriodFull(Self.english)) == "$53.99/year"
        expect(TestData.lifetimePackage.localizedPricePerPeriodFull(Self.english)) == "$119.49"
    }

    func testSpanishLocalizedPricePerPeriodFull() {
        expect(TestData.weeklyPackage.localizedPricePerPeriodFull(Self.spanish)) == "$1.99/semana"
        expect(TestData.monthlyPackage.localizedPricePerPeriodFull(Self.spanish)) == "$6.99/mes"
        expect(TestData.threeMonthPackage.localizedPricePerPeriodFull(Self.spanish)) == "$4.99/3meses"
        expect(TestData.sixMonthPackage.localizedPricePerPeriodFull(Self.spanish)) == "$7.99/6meses"
        expect(TestData.annualPackage.localizedPricePerPeriodFull(Self.spanish)) == "$53.99/año"
        expect(TestData.lifetimePackage.localizedPricePerPeriodFull(Self.spanish)) == "$119.49"
    }

    func testEnglishLocalizedPriceAndPerMonth() {
        expect(TestData.weeklyPackage.localizedPriceAndPerMonth(Self.english)) == "$1.99/wk ($8.64/mo)"
        expect(TestData.monthlyPackage.localizedPriceAndPerMonth(Self.english)) == "$6.99/mo"
        expect(TestData.threeMonthPackage.localizedPriceAndPerMonth(Self.english)) == "$4.99/3mo ($1.66/mo)"
        expect(TestData.sixMonthPackage.localizedPriceAndPerMonth(Self.english)) == "$7.99/6mo ($1.33/mo)"
        expect(TestData.annualPackage.localizedPriceAndPerMonth(Self.english)) == "$53.99/yr ($4.49/mo)"
        expect(TestData.lifetimePackage.localizedPriceAndPerMonth(Self.english)) == "$119.49"
    }

    func testSpanishLocalizedPriceAndPerMonth() {
        expect(TestData.weeklyPackage.localizedPriceAndPerMonth(Self.spanish)) == "$1.99/sem ($8.64/m.)"
        expect(TestData.monthlyPackage.localizedPriceAndPerMonth(Self.spanish)) == "$6.99/m."
        expect(TestData.threeMonthPackage.localizedPriceAndPerMonth(Self.spanish)) == "$4.99/3m ($1.66/m.)"
        expect(TestData.sixMonthPackage.localizedPriceAndPerMonth(Self.spanish)) == "$7.99/6m ($1.33/m.)"
        expect(TestData.annualPackage.localizedPriceAndPerMonth(Self.spanish)) == "$53.99/año ($4.49/m.)"
        expect(TestData.lifetimePackage.localizedPriceAndPerMonth(Self.spanish)) == "$119.49"
    }

    func testArabicLocalizedPriceAndPerMonth() {
        let arabicPrice = "٣.٩٩ درهم"

        expect(TestData.weeklyPackage.with(arabicPrice, Self.arabic).localizedPriceAndPerMonth(Self.arabic))
            .to(equalIgnoringRTL("٣.٩٩ درهم/أسبوع (‏8.64 ‏د.إ.‏/شهر)"))
        expect(TestData.monthlyPackage.with(arabicPrice, Self.arabic).localizedPriceAndPerMonth(Self.arabic))
            .to(equalIgnoringRTL("٣.٩٩ درهم/شهر"))
        expect(TestData.threeMonthPackage.with(arabicPrice, Self.arabic).localizedPriceAndPerMonth(Self.arabic))
            .to(equalIgnoringRTL("٣.٩٩ درهم/3شهر (‏1.66 ‏د.إ.‏/شهر)"))
        expect(TestData.sixMonthPackage.with(arabicPrice, Self.arabic).localizedPriceAndPerMonth(Self.arabic))
            .to(equalIgnoringRTL("٣.٩٩ درهم/6شهر (‏1.33 ‏د.إ.‏/شهر)"))
        expect(TestData.annualPackage.with(arabicPrice, Self.arabic).localizedPriceAndPerMonth(Self.arabic))
            .to(equalIgnoringRTL("٣.٩٩ درهم/سنة (‏4.49 ‏د.إ.‏/شهر)"))
        expect(TestData.lifetimePackage.with(arabicPrice, Self.arabic).localizedPriceAndPerMonth(Self.arabic))
        == arabicPrice
    }

    func testEnglishLocalizedPriceAndPerMonthFull() {
        expect(TestData.weeklyPackage.localizedPriceAndPerMonthFull(Self.english)) == "$1.99/week ($8.64/month)"
        expect(TestData.monthlyPackage.localizedPriceAndPerMonthFull(Self.english)) == "$6.99/month"
        expect(TestData.threeMonthPackage.localizedPriceAndPerMonthFull(Self.english)) == "$4.99/3months ($1.66/month)"
        expect(TestData.sixMonthPackage.localizedPriceAndPerMonthFull(Self.english)) == "$7.99/6months ($1.33/month)"
        expect(TestData.annualPackage.localizedPriceAndPerMonthFull(Self.english)) == "$53.99/year ($4.49/month)"
        expect(TestData.lifetimePackage.localizedPriceAndPerMonthFull(Self.english)) == "$119.49"
    }

    func testSpanishLocalizedPriceAndPerMonthFull() {
        expect(TestData.weeklyPackage.localizedPriceAndPerMonthFull(Self.spanish)) == "$1.99/semana ($8.64/mes)"
        expect(TestData.monthlyPackage.localizedPriceAndPerMonthFull(Self.spanish)) == "$6.99/mes"
        expect(TestData.threeMonthPackage.localizedPriceAndPerMonthFull(Self.spanish)) == "$4.99/3meses ($1.66/mes)"
        expect(TestData.sixMonthPackage.localizedPriceAndPerMonthFull(Self.spanish)) == "$7.99/6meses ($1.33/mes)"
        expect(TestData.annualPackage.localizedPriceAndPerMonthFull(Self.spanish)) == "$53.99/año ($4.49/mes)"
        expect(TestData.lifetimePackage.localizedPriceAndPerMonthFull(Self.spanish)) == "$119.49"
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
        expect(TestData.weeklyPackage.periodNameOrIdentifier(Self.english)) == "Weekly"
        expect(TestData.monthlyPackage.periodNameOrIdentifier(Self.english)) == "Monthly"
        expect(TestData.threeMonthPackage.periodNameOrIdentifier(Self.english)) == "3 Month"
        expect(TestData.sixMonthPackage.periodNameOrIdentifier(Self.english)) == "6 Month"
        expect(TestData.annualPackage.periodNameOrIdentifier(Self.english)) == "Annual"
        expect(TestData.lifetimePackage.periodNameOrIdentifier(Self.english)) == "Lifetime"
        expect(TestData.customPackage.periodNameOrIdentifier(Self.english)) == "Custom"
        expect(TestData.unknownPackage.periodNameOrIdentifier(Self.english)) == "Unknown"
    }

    func testSpanishPeriodName() {
        expect(TestData.weeklyPackage.periodNameOrIdentifier(Self.spanish)) == "Semanalmente"
        expect(TestData.monthlyPackage.periodNameOrIdentifier(Self.spanish)) == "Mensual"
        expect(TestData.threeMonthPackage.periodNameOrIdentifier(Self.spanish)) == "3 meses"
        expect(TestData.sixMonthPackage.periodNameOrIdentifier(Self.spanish)) == "6 meses"
        expect(TestData.annualPackage.periodNameOrIdentifier(Self.spanish)) == "Anual"
        expect(TestData.lifetimePackage.periodNameOrIdentifier(Self.spanish)) == "Toda la vida"
        expect(TestData.customPackage.periodNameOrIdentifier(Self.spanish)) == "Custom"
        expect(TestData.unknownPackage.periodNameOrIdentifier(Self.spanish)) == "Unknown"
    }

    func testEnglishPeriodAbbreviation() {
        expect(TestData.weeklyPackage.periodNameAbbreviation(Self.english)) == "wk"
        expect(TestData.monthlyPackage.periodNameAbbreviation(Self.english)) == "mo"
        expect(TestData.threeMonthPackage.periodNameAbbreviation(Self.english)) == "3mo"
        expect(TestData.sixMonthPackage.periodNameAbbreviation(Self.english)) == "6mo"
        expect(TestData.annualPackage.periodNameAbbreviation(Self.english)) == "yr"
        expect(TestData.lifetimePackage.periodNameAbbreviation(Self.english)).to(beNil())
        expect(TestData.customPackage.periodNameAbbreviation(Self.english)) == "yr"
        expect(TestData.unknownPackage.periodNameAbbreviation(Self.english)) == "yr"
    }

    func testSpanishPeriodAbbreviation() {
        expect(TestData.weeklyPackage.periodNameAbbreviation(Self.spanish)) == "sem"
        expect(TestData.monthlyPackage.periodNameAbbreviation(Self.spanish)) == "m."
        expect(TestData.threeMonthPackage.periodNameAbbreviation(Self.spanish)) == "3m"
        expect(TestData.sixMonthPackage.periodNameAbbreviation(Self.spanish)) == "6m"
        expect(TestData.annualPackage.periodNameAbbreviation(Self.spanish)) == "año"
        expect(TestData.lifetimePackage.periodNameAbbreviation(Self.spanish)).to(beNil())
        expect(TestData.customPackage.periodNameAbbreviation(Self.spanish)) == "año"
        expect(TestData.unknownPackage.periodNameAbbreviation(Self.spanish)) == "año"
    }

    func testEnglishPeriodLength() {
        expect(TestData.weeklyPackage.periodLength(Self.english)) == "week"
        expect(TestData.monthlyPackage.periodLength(Self.english)) == "month"
        expect(TestData.threeMonthPackage.periodLength(Self.english)) == "3months"
        expect(TestData.sixMonthPackage.periodLength(Self.english)) == "6months"
        expect(TestData.annualPackage.periodLength(Self.english)) == "year"
        expect(TestData.lifetimePackage.periodLength(Self.english)).to(beNil())
        expect(TestData.customPackage.periodLength(Self.english)) == "year"
        expect(TestData.unknownPackage.periodLength(Self.english)) == "year"
    }

    func testSpanishPeriodLength() {
        expect(TestData.weeklyPackage.periodLength(Self.spanish)) == "semana"
        expect(TestData.monthlyPackage.periodLength(Self.spanish)) == "mes"
        expect(TestData.threeMonthPackage.periodLength(Self.spanish)) == "3meses"
        expect(TestData.sixMonthPackage.periodLength(Self.spanish)) == "6meses"
        expect(TestData.annualPackage.periodLength(Self.spanish)) == "año"
        expect(TestData.lifetimePackage.periodLength(Self.spanish)).to(beNil())
        expect(TestData.customPackage.periodLength(Self.spanish)) == "año"
        expect(TestData.unknownPackage.periodLength(Self.spanish)) == "año"
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
        expect(TestData.weeklyPackage.localizedIntroductoryOfferPrice()).to(beNil())
        expect(TestData.monthlyPackage.localizedIntroductoryOfferPrice()) == "$0.00"
        expect(TestData.annualPackage.localizedIntroductoryOfferPrice()) == "$1.99"
        expect(TestData.lifetimePackage.localizedIntroductoryOfferPrice()).to(beNil())
    }

    func testEnglishRelativeDiscount() {
        expect(TestData.weeklyPackage.localizedRelativeDiscount(nil, Self.english)).to(beNil())
        expect(TestData.weeklyPackage.localizedRelativeDiscount(0.372, Self.english)) == "37% off"
    }

    func testSpanishRelativeDiscount() {
        expect(TestData.weeklyPackage.localizedRelativeDiscount(nil, Self.spanish)).to(beNil())
        expect(TestData.weeklyPackage.localizedRelativeDiscount(0.372, Self.spanish)) == "37% de descuento"
    }

    func testEnglishSubscriptionDuration() {
        expect(TestData.weeklyPackage.subscriptionDuration(Self.english)) == "1 week"
        expect(TestData.monthlyPackage.subscriptionDuration(Self.english)) == "1 month"
        expect(TestData.threeMonthPackage.subscriptionDuration(Self.english)) == "3 months"
        expect(TestData.sixMonthPackage.subscriptionDuration(Self.english)) == "6 months"
        expect(TestData.annualPackage.subscriptionDuration(Self.english)) == "1 year"
        expect(TestData.lifetimePackage.subscriptionDuration(Self.english)) == "Lifetime"
    }

    func testSpanishSubscriptionDuration() {
        expect(TestData.weeklyPackage.subscriptionDuration(Self.spanish)) == "1 semana"
        expect(TestData.monthlyPackage.subscriptionDuration(Self.spanish)) == "1 mes"
        expect(TestData.threeMonthPackage.subscriptionDuration(Self.spanish)) == "3 meses"
        expect(TestData.sixMonthPackage.subscriptionDuration(Self.spanish)) == "6 meses"
        expect(TestData.annualPackage.subscriptionDuration(Self.spanish)) == "1 año"
        expect(TestData.lifetimePackage.subscriptionDuration(Self.spanish)) == "Toda la vida"
    }

    func testEnglishNormalizedSubscriptionDuration() {
        expect(TestData.weeklyPackage.normalizedSubscriptionDuration(Self.english)) == "1 week"
        expect(TestData.monthlyPackage.normalizedSubscriptionDuration(Self.english)) == "1 month"
        expect(TestData.threeMonthPackage.normalizedSubscriptionDuration(Self.english)) == "3 months"
        expect(TestData.sixMonthPackage.normalizedSubscriptionDuration(Self.english)) == "6 months"
        expect(TestData.annualPackage.normalizedSubscriptionDuration(Self.english)) == "12 months"
        expect(TestData.lifetimePackage.normalizedSubscriptionDuration(Self.english)) == "Lifetime"
    }

    func testSpanishNormalizedSubscriptionDuration() {
        expect(TestData.weeklyPackage.normalizedSubscriptionDuration(Self.spanish)) == "1 semana"
        expect(TestData.monthlyPackage.normalizedSubscriptionDuration(Self.spanish)) == "1 mes"
        expect(TestData.threeMonthPackage.normalizedSubscriptionDuration(Self.spanish)) == "3 meses"
        expect(TestData.sixMonthPackage.normalizedSubscriptionDuration(Self.spanish)) == "6 meses"
        expect(TestData.annualPackage.normalizedSubscriptionDuration(Self.spanish)) == "12 meses"
        expect(TestData.lifetimePackage.normalizedSubscriptionDuration(Self.spanish)) == "Toda la vida"
    }

    func testPriceRounding() {

        // test rounding on
        expect(TestData.monthlyPackage
            .localizedPriceAndPerMonthFull(Self.english, showZeroDecimalPlacePrices: true)) == "$6.99/month"
        expect(TestData.monthlyPackage.localizedPricePerMonth(showZeroDecimalPlacePrices: true)) == "$6.99"
        expect(TestData.threeMonthPackage.localizedPricePerMonth(showZeroDecimalPlacePrices: true)) == "$1.66"
        expect(TestData.annualPackage60.localizedPricePerMonth(showZeroDecimalPlacePrices: true)) == "$5"
        expect(TestData
            .annualPackage60
            .localizedPriceAndPerMonthFull(Self.english, showZeroDecimalPlacePrices: true)) == "$60/year ($5/month)"
        expect(TestData
            .annualPackage
            .localizedPriceAndPerMonthFull(Self.english,
                                           showZeroDecimalPlacePrices: true)) == "$53.99/year ($4.49/month)"

        expect(TestData
            .annualPackage60Taiwan
            .localizedPriceAndPerMonthFull(Locale.taiwan,
                                           showZeroDecimalPlacePrices: true)) == "$60/年 ($5/個月)"

        expect(TestData
            .threeMonthPackageThailand
            .localizedPriceAndPerMonthFull(Locale.taiwan,
                                           showZeroDecimalPlacePrices: true)) == "฿5/3個月 (฿1.66/個月)"

        expect(TestData
            .threeMonthPackageThailand
            .localizedPriceAndPerMonthFull(Locale.thailand,
                                           showZeroDecimalPlacePrices: true)) == "฿5/3เดือน (฿1.66/เดือน)"

        // test rounding off
        expect(TestData
            .monthlyPackage
            .localizedPriceAndPerMonthFull(Self.english, showZeroDecimalPlacePrices: false)) == "$6.99/month"
        expect(TestData.monthlyPackage.localizedPricePerMonth(showZeroDecimalPlacePrices: false)) == "$6.99"
        expect(TestData.annualPackage60.localizedPricePerMonth(showZeroDecimalPlacePrices: false)) == "$5.00"
        expect(TestData
            .annualPackage60
            .localizedPriceAndPerMonthFull(Self.english,
                                           showZeroDecimalPlacePrices: false)) == "$60.00/year ($5.00/month)"
        expect(TestData
            .annualPackage
            .localizedPriceAndPerMonthFull(Self.english,
                                           showZeroDecimalPlacePrices: false)) == "$53.99/year ($4.49/month)"

        expect(TestData
            .annualPackage60Taiwan
            .localizedPriceAndPerMonthFull(Locale.taiwan,
                                           showZeroDecimalPlacePrices: false)) == "$60.00/年 ($5.00/個月)"

        expect(TestData
            .threeMonthPackageThailand
            .localizedPriceAndPerMonthFull(Locale.thailand,
                                           showZeroDecimalPlacePrices: false)) == "฿5.00/3เดือน (฿1.66/เดือน)"

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageVariablesTests {

    static let english: Locale = .init(identifier: "en_US")
    static let spanish: Locale = .init(identifier: "es_ES")
    static let arabic: Locale = .init(identifier: "ar_AE")

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension Package {

    func with(_ newLocalizedPrice: String, _ locale: Locale) -> Package {
        return .init(
            identifier: self.identifier,
            packageType: self.packageType,
            storeProduct: self.storeProduct
                .toTestProduct()
                .with(newLocalizedPrice, locale)
                .toStoreProduct(),
            offeringIdentifier: self.offeringIdentifier
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension TestStoreProduct {

    func with(_ newLocalizedPrice: String, _ locale: Locale) -> Self {
        var copy = self
        copy.localizedPriceString = newLocalizedPrice
        copy.locale = locale

        return copy
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension StoreProduct {

    func toTestProduct() -> TestStoreProduct {
        return .init(
            localizedTitle: self.localizedTitle,
            price: self.price,
            localizedPriceString: self.localizedPriceString,
            productIdentifier: self.productIdentifier,
            productType: self.productType,
            localizedDescription: self.localizedDescription,
            subscriptionGroupIdentifier: self.subscriptionGroupIdentifier,
            subscriptionPeriod: self.subscriptionPeriod,
            isFamilyShareable: self.isFamilyShareable
        )
    }

}
