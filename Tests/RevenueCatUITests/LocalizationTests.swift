//
//  LocalizationTests.swift
//  
//
//  Created by Nacho Soto on 7/12/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

// swiftlint:disable type_name

class BaseLocalizationTests: TestCase {

    fileprivate var locale: Locale { fatalError("Must be overriden") }

}

// MARK: - Abbreviated Unit

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class AbbreviatedUnitEnglishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "en_US") }

    func testDay() {
        verify(.day, "day")
    }

    func testMonth() {
        verify(.month, "mo")
    }

    func testYear() {
        verify(.year, "y")
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class AbbreviatedUnitSpanishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "es_ES") }

    func testDay() {
        verify(.day, "día")
    }

    func testMonth() {
        verify(.month, "mes")
    }

    func testYear() {
        verify(.year, "año")
    }

}

// MARK: - SubscriptionPeriod

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class SubscriptionPeriodEnglishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "en_US") }

    func testDayPeriod() {
        verify(1, .day, "1 day")
        verify(7, .day, "7 days")
    }

    func testsWeekPeriod() {
        verify(1, .week, "1 week")
        verify(3, .week, "3 weeks")
    }

    func testMonthPeriod() {
        verify(1, .month, "1 month")
        verify(3, .month, "3 months")
    }

    func testYearPeriod() {
        verify(1, .year, "1 year")
        verify(3, .year, "3 years")
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class SubscriptionPeriodSpanishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "es_ES") }

    func testDayPeriod() {
        verify(1, .day, "1 día")
        verify(7, .day, "7 días")
    }

    func testWeekPeriod() {
        verify(1, .week, "1 semana")
        verify(3, .week, "3 semanas")
    }

    func testMonthPeriod() {
        verify(1, .month, "1 mes")
        verify(3, .month, "3 meses")
    }

    func testYearPeriod() {
        verify(1, .year, "1 año")
        verify(3, .year, "3 años")
    }

}

// MARK: - PackageType

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class PackageTypeEnglishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "en_US") }

    func testLocalization() {
        verify(.annual, "Annual")
        verify(.sixMonth, "6 month")
        verify(.threeMonth, "3 month")
        verify(.twoMonth, "2 month")
        verify(.monthly, "Monthly")
        verify(.weekly, "Weekly")
    }

    func testOtherValues() {
        verify(.custom, "")
        verify(.lifetime, "")
        verify(.unknown, "")
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class PackageTypeSpanishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "es_ES") }

    func testLocalization() {
        verify(.annual, "Anual")
        verify(.sixMonth, "6 meses")
        verify(.threeMonth, "3 meses")
        verify(.twoMonth, "2 meses")
        verify(.monthly, "Mensual")
        verify(.weekly, "Semanal")
    }

    func testOtherValues() {
        verify(.custom, "")
        verify(.lifetime, "")
        verify(.unknown, "")
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class PackageTypeOtherLanguageLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "fr") }

    func testLocalizationDefaultsToEnglish() {
        verify(.annual, "Annual")
        verify(.sixMonth, "6 month")
        verify(.threeMonth, "3 month")
        verify(.twoMonth, "2 month")
        verify(.monthly, "Monthly")
        verify(.weekly, "Weekly")
    }

    func testOtherValues() {
        verify(.custom, "")
        verify(.lifetime, "")
        verify(.unknown, "")
    }
}

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension BaseLocalizationTests {

    func verify(
        _ value: Int,
        _ unit: SubscriptionPeriod.Unit,
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = Localization.localizedDuration(for: SubscriptionPeriod(value: value, unit: unit),
                                                    locale: self.locale)
        expect(file: file, line: line, result) == expected
    }

    func verify(
        _ unit: NSCalendar.Unit,
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = Localization.abbreviatedUnitLocalizedString(for: unit,
                                                                 locale: self.locale)
        expect(file: file, line: line, result) == expected
    }

    func verify(
        _ packageType: PackageType,
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = Localization.localized(packageType: packageType,
                                            locale: self.locale)
        expect(file: file, line: line, result) == expected
    }

}
