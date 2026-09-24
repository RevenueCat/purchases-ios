//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizationTests.swift
//
//  Created by Nacho Soto on 7/12/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

// swiftlint:disable type_name file_length

class BaseLocalizationTests: TestCase {

    fileprivate var locale: Locale { fatalError("Must be overriden") }

}

// MARK: - Abbreviated Unit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class AbbreviatedUnitEnglishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "en_US") }

    func testDay() {
        verify(.day, "day")
    }

    func testWeek() {
        verify(.week, "wk")
    }

    func testMonth() {
        verify(.month, "mo")
    }

    func testTwoMonths() {
        verify(.init(2, .month), "2mo")
    }

    func testThreeMonths() {
        verify(.init(3, .month), "3mo")
    }

    func testSixMonths() {
        verify(.init(6, .month), "6mo")
    }

    func testYear() {
        verify(.year, "yr")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class AbbreviatedUnitSpanishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "es_ES") }

    func testDay() {
        verify(.day, "día")
    }

    func testWeek() {
        verify(.week, "sem")
    }

    func testMonth() {
        verify(.month, "m.")
    }

    func testTwoMonths() {
        verify(.init(2, .month), "2m")
    }

    func testThreeMonths() {
        verify(.init(3, .month), "3m")
    }

    func testSixMonths() {
        verify(.init(6, .month), "6m")
    }

    func testYear() {
        verify(.year, "año")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class AbbreviatedUnitJapaneseLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "ja_JP") }

    func testDay() {
        verify(.day, "日")
    }

    func testWeek() {
        verify(.week, "週間")
    }

    func testMonth() {
        verify(.month, "か月")
    }

    func testTwoMonths() {
        verify(.init(2, .month), "2か月")
    }

    func testThreeMonths() {
        verify(.init(3, .month), "3か月")
    }

    func testSixMonths() {
        verify(.init(6, .month), "6か月")
    }

    func testYear() {
        verify(.year, "年")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class AbbreviatedUnitGermanLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "de_DE") }

    func testDay() {
        verify(.day, "Tag")
    }

    func testWeek() {
        verify(.week, "Woche")
    }

    func testMonth() {
        verify(.month, "Monat")
    }

    func testTwoMonths() {
        verify(.init(2, .month), "2Monate")
    }

    func testThreeMonths() {
        verify(.init(3, .month), "3Monate")
    }

    func testSixMonths() {
        verify(.init(6, .month), "6Monate")
    }

    func testYear() {
        verify(.year, "Jahr")
    }

}

// MARK: - SubscriptionPeriod

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
        verify(6, .month, "6 months")
    }

    func testYearPeriod() {
        verify(1, .year, "1 year")
        verify(3, .year, "3 years")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class SubscriptionPeriodGermanLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "de_DE") }

    func testDayPeriod() {
        verify(1, .day, "1 Tag")
        verify(7, .day, "7 Tage")
    }

    func testsWeekPeriod() {
        verify(1, .week, "1 Woche")
        verify(3, .week, "3 Wochen")
    }

    func testMonthPeriod() {
        verify(1, .month, "1 Monat")
        verify(3, .month, "3 Monate")
        verify(6, .month, "6 Monate")
    }

    func testYearPeriod() {
        verify(1, .year, "1 Jahr")
        verify(3, .year, "3 Jahre")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageTypeEnglishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "en_US") }

    func testLocalization() {
        verify(.annual, "Annual")
        verify(.sixMonth, "6 Month")
        verify(.threeMonth, "3 Month")
        verify(.twoMonth, "2 Month")
        verify(.monthly, "Monthly")
        verify(.weekly, "Weekly")
        verify(.lifetime, "Lifetime")
    }

    func testOtherValues() {
        verify(.custom, nil)
        verify(.unknown, nil)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageTypeGermanLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "de_DE") }

    func testLocalization() {
        verify(.annual, "Jährlich")
        verify(.sixMonth, "6 Monate")
        verify(.threeMonth, "3 Monate")
        verify(.twoMonth, "2 Monate")
        verify(.monthly, "Monatlich")
        verify(.weekly, "Wöchentlich")
        verify(.lifetime, "Lebenslang")
    }

    func testOtherValues() {
        verify(.custom, nil)
        verify(.unknown, nil)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageTypeSpanishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "es_ES") }

    func testLocalization() {
        verify(.annual, "Anual")
        verify(.sixMonth, "6 meses")
        verify(.threeMonth, "3 meses")
        verify(.twoMonth, "2 meses")
        verify(.monthly, "Mensual")
        verify(.weekly, "Semanalmente")
        verify(.lifetime, "Toda la vida")
    }

    func testOtherValues() {
        verify(.custom, nil)
        verify(.unknown, nil)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageTypeLocalizationWithOnlyLanguageTests: BaseLocalizationTests {

    // This is encoded as `fr_CA`, so we test that only language works too.
    override var locale: Locale { return .init(identifier: "fr") }

    func testLocalization() {
        verify(.annual, "Annuel")
        verify(.sixMonth, "6 mois")
        verify(.threeMonth, "3 mois")
        verify(.twoMonth, "2 mois")
        verify(.monthly, "Mensuel")
        verify(.weekly, "Hebdomadaire")
        verify(.lifetime, "Durée de vie")
    }

    func testOtherValues() {
        verify(.custom, nil)
        verify(.unknown, nil)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageTypeOtherLanguageLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "ci") }

    func testLocalizationDefaultsToEnglish() {
        verify(.annual, "Annual")
        verify(.sixMonth, "6 Month")
        verify(.threeMonth, "3 Month")
        verify(.twoMonth, "2 Month")
        verify(.monthly, "Monthly")
        verify(.weekly, "Weekly")
        verify(.lifetime, "Lifetime")
    }

    func testOtherValues() {
        verify(.custom, nil)
        verify(.unknown, nil)
    }
}

// MARK: - Discount

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class DiscountEnglishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "en_US") }

    func testLocalization() {
        verify(0, "0% off")
        verify(0.1, "10% off")
        verify(0.331, "33% off")
        verify(0.5, "50% off")
        verify(1, "100% off")
        verify(1.1, "110% off")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class DiscountSpanishLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "es_ES") }

    func testLocalization() throws {
        verify(0, "0% de descuento")
        verify(0.1, "10% de descuento")
        verify(0.331, "33% de descuento")
        verify(0.5, "50% de descuento")
        verify(1, "100% de descuento")
        verify(1.1, "110% de descuento")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class DiscountOtherLanguageLocalizationTests: BaseLocalizationTests {

    override var locale: Locale { return .init(identifier: "ci") }

    func testLocalizationDefaultsToEnglish() {
        verify(1, "100% off")
    }

}

// MARK: - Helpers

/// iOS 16 and 17 differ slightly in how Arabic strings are encoded, iOS 16 having an additional RTL marker (U+200F)
/// This allows comparing strings ignoring those markers.
func equalIgnoringRTL(_ expectedValue: String?) -> Nimble.Matcher<String> {
    let escapedValue = stringify(expectedValue?.escapedUnicode)
    return Matcher.define("equal to <\(escapedValue)> ignoring RTL marks") { actualExpression, msg in
        if let actual = try actualExpression.evaluate(), let expected = expectedValue {
            return MatcherResult(
                bool: actual.removingRTLMarkers == expected.removingRTLMarkers,
                message: msg.appended(details: "Escaped: <\(actual.escapedUnicode)>")
            )
        }

        return MatcherResult(status: .fail, message: msg)
    }
}

// MARK: - Private

private extension SubscriptionPeriod {

    convenience init(_ value: Int, _ unit: Unit) {
        self.init(value: value, unit: unit)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BaseLocalizationTests {

    func verify(
        _ value: Int,
        _ unit: SubscriptionPeriod.Unit,
        _ expected: String,
        file: FileString = #filePath,
        line: UInt = #line
    ) {
        let result = Localization.localizedDuration(for: SubscriptionPeriod(value: value, unit: unit),
                                                    locale: self.locale)
        expect(file: file, line: line, result) == expected
    }

    func verify(
        _ unit: SubscriptionPeriod.Unit,
        _ expected: String,
        file: FileString = #filePath,
        line: UInt = #line
    ) {
        self.verify(.init(1, unit), expected, file: file, line: line)
    }

    func verify(
        _ period: SubscriptionPeriod,
        _ expected: String,
        file: FileString = #filePath,
        line: UInt = #line
    ) {
        let result = Localization.abbreviatedUnitLocalizedString(for: period,
                                                                 locale: self.locale)
        expect(file: file, line: line, result) == expected
    }

    func verify(
        _ packageType: PackageType,
        _ expected: String?,
        file: FileString = #filePath,
        line: UInt = #line
    ) {
        let result = Localization.localized(packageType: packageType,
                                            locale: self.locale)
        if let expected {
            expect(file: file, line: line, result) == expected
        } else {
            expect(file: file, line: line, result).to(beNil())
        }
    }

    func verify(
        _ discount: Double,
        _ expected: String,
        file: FileString = #filePath,
        line: UInt = #line
    ) {
        let result = Localization.localized(discount: discount,
                                            locale: self.locale)
        expect(file: file, line: line, result) == expected
    }

}

private extension String {

    var escapedUnicode: String {
        var escapedString = ""
        escapedString.reserveCapacity(self.unicodeScalars.count)

        for scalar in self.unicodeScalars {
            if scalar.isASCII {
                escapedString.append(String(scalar))
            } else {
                escapedString.append("\\u{\(String(scalar.value, radix: 16))}")
            }
        }

        return escapedString
    }

    var removingRTLMarkers: Self {
        return self.removeCharacters(from: Self.rtlMarker)
    }

    private func removeCharacters(from set: CharacterSet) -> String {
        return String(self.unicodeScalars.filter { !set.contains($0) })
    }

    private static let rtlMarker: CharacterSet = .init(charactersIn: "\u{200f}")

}

// MARK: - Locale.swiftUILayoutDirection

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class LocaleLayoutDirectionTests: TestCase {

    // RTL languages
    func testHebrewIsRTL() {
        expect(Locale(identifier: "he").swiftUILayoutDirection) == .rightToLeft
    }

    func testHebrewRegionIsRTL() {
        expect(Locale(identifier: "he-IL").swiftUILayoutDirection) == .rightToLeft
    }

    func testArabicIsRTL() {
        expect(Locale(identifier: "ar").swiftUILayoutDirection) == .rightToLeft
    }

    func testArabicRegionIsRTL() {
        expect(Locale(identifier: "ar_AE").swiftUILayoutDirection) == .rightToLeft
    }

    func testFarsiIsRTL() {
        expect(Locale(identifier: "fa").swiftUILayoutDirection) == .rightToLeft
    }

    func testUrduIsRTL() {
        expect(Locale(identifier: "ur").swiftUILayoutDirection) == .rightToLeft
    }

    // LTR languages
    func testEnglishIsLTR() {
        expect(Locale(identifier: "en").swiftUILayoutDirection) == .leftToRight
    }

    func testEnglishRegionIsLTR() {
        expect(Locale(identifier: "en_US").swiftUILayoutDirection) == .leftToRight
    }

    func testFrenchIsLTR() {
        expect(Locale(identifier: "fr-FR").swiftUILayoutDirection) == .leftToRight
    }

    func testJapaneseIsLTR() {
        expect(Locale(identifier: "ja").swiftUILayoutDirection) == .leftToRight
    }

    func testUnknownLocaleDefaultsToLTR() {
        expect(Locale(identifier: "").swiftUILayoutDirection) == .leftToRight
    }

}

// MARK: - Locale.selectPreferredLocale

// Verifies that layout direction derives from the content locale actually chosen by
// selectPreferredLocale, not from the raw device/override locale.
// Critical case: RTL device language + LTR-only paywall → content resolves to LTR → layout is LTR.

class PaywallsV2LocaleResolutionTests: TestCase {

    // RTL device, LTR-only paywall → resolved locale is LTR (nil → falls back to default en_US)
    func testRTLDeviceWithLTROnlyPaywallResolvesToLTR() {
        let chosen = Locale.selectPreferredLocale(
            from: [Locale(identifier: "en_US")],
            preferredLocales: [Locale(identifier: "ar")]
        ) ?? Locale(identifier: "en_US")
        expect(chosen.swiftUILayoutDirection) == .leftToRight
    }

    // RTL override, paywall has RTL localization → resolved locale is RTL
    func testRTLOverrideWithRTLPaywallResolvesToRTL() {
        let chosen = Locale.selectPreferredLocale(
            from: [Locale(identifier: "en_US"), Locale(identifier: "he")],
            preferredLocales: [Locale(identifier: "he-IL"), Locale(identifier: "en_US")]
        )
        expect(chosen?.swiftUILayoutDirection) == .rightToLeft
    }

    // No preferred locale match → returns nil (caller falls back to defaultLocale)
    func testNoMatchReturnsNil() {
        let chosen = Locale.selectPreferredLocale(
            from: [Locale(identifier: "en_US")],
            preferredLocales: [Locale(identifier: "ja")]
        )
        expect(chosen).to(beNil())
    }

    // Exact region match takes priority over language-only match
    func testExactRegionMatchTakesPriority() {
        let chosen = Locale.selectPreferredLocale(
            from: [Locale(identifier: "en_US"), Locale(identifier: "en_CA")],
            preferredLocales: [Locale(identifier: "en_CA")]
        )
        expect(chosen) == Locale(identifier: "en_CA")
    }

    // Language-only match returned when exact region unavailable
    func testLanguageMatchFallsBackWhenNoRegionMatch() {
        let chosen = Locale.selectPreferredLocale(
            from: [Locale(identifier: "en_US"), Locale(identifier: "fr_FR")],
            preferredLocales: [Locale(identifier: "fr_CA")]
        )
        expect(chosen) == Locale(identifier: "fr_FR")
    }

    // `Locale.preferredLanguages` uses hyphens, paywall locales use underscores
    func testHyphenatedPreferredLocaleMatchesExactRegion() {
        let chosen = Locale.selectPreferredLocale(
            from: ["en_AU", "en_CA", "en_GB", "en_US"].map { Locale(identifier: $0) },
            preferredLocales: [Locale(identifier: "en-GB")]
        )
        expect(chosen) == Locale(identifier: "en_GB")
    }

    func testHyphenatedPreferredLocalesMatchRegionalVariants() {
        let portuguese = ["pt_BR", "pt_PT"].map { Locale(identifier: $0) }
        let spanish = ["es_ES", "es_MX"].map { Locale(identifier: $0) }

        expect(Locale.selectPreferredLocale(from: portuguese, preferredLocales: [Locale(identifier: "pt-BR")]))
            == Locale(identifier: "pt_BR")
        expect(Locale.selectPreferredLocale(from: portuguese, preferredLocales: [Locale(identifier: "pt-PT")]))
            == Locale(identifier: "pt_PT")
        expect(Locale.selectPreferredLocale(from: spanish, preferredLocales: [Locale(identifier: "es-MX")]))
            == Locale(identifier: "es_MX")
    }

    // Available locales usually come from a Dictionary, so their order is not stable
    func testLanguageOnlyMatchDoesNotDependOnOrderOfAvailableLocales() {
        let identifiers = ["en_US", "en_GB", "en_CA", "en_AU"]
        let orders = [identifiers, identifiers.reversed(), Array(identifiers[2...] + identifiers[..<2])]

        let chosen = Set(orders.map { order in
            Locale.selectPreferredLocale(
                from: order.map { Locale(identifier: $0) },
                preferredLocales: [Locale(identifier: "en-IE")]
            )
        })
        expect(chosen) == [Locale(identifier: "en_AU")]
    }

    func testScriptMatchTakesPriorityOverLanguageOnlyMatch() {
        let chinese = ["zh_Hans", "zh_Hant"].map { Locale(identifier: $0) }

        expect(Locale.selectPreferredLocale(from: chinese, preferredLocales: [Locale(identifier: "zh-Hant-TW")]))
            == Locale(identifier: "zh_Hant")
        expect(Locale.selectPreferredLocale(from: chinese, preferredLocales: [Locale(identifier: "zh-Hans-CN")]))
            == Locale(identifier: "zh_Hans")
    }

    func testScriptIsInferredFromRegion() {
        let chosen = Locale.selectPreferredLocale(
            from: [Locale(identifier: "zh_Hans"), Locale(identifier: "zh_Hant")],
            preferredLocales: [Locale(identifier: "zh_TW")]
        )
        expect(chosen) == Locale(identifier: "zh_Hant")
    }

}
