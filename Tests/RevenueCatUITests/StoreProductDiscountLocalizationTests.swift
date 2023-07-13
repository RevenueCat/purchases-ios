//
//  SubscriptionPeriodLocalizationTests.swift
//  
//
//  Created by Nacho Soto on 7/12/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

// swiftlint:disable type_name

class BaseSubscriptionPeriodLocalizationTests: TestCase {

    fileprivate var locale: Locale { fatalError("Must be overriden") }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
class SubscriptionPeriodEnglishLocalizationTests: BaseSubscriptionPeriodLocalizationTests {

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
class SubscriptionPeriodSpanishLocalizationTests: BaseSubscriptionPeriodLocalizationTests {

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

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension BaseSubscriptionPeriodLocalizationTests {

    func verify(
        _ value: Int,
        _ unit: SubscriptionPeriod.Unit,
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = SubscriptionPeriod(value: value, unit: unit)
            .localizedDuration(for: self.locale)
        expect(file: file, line: line, result) == expected
    }

}
