//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocaleLayoutDirectionTests.swift
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class LocaleLayoutDirectionTests: TestCase {

    func testLeftToRightLocale() {
        XCTAssertEqual(Locale(identifier: "en_US").rcLayoutDirection, .leftToRight)
    }

    func testHebrewLocaleIsRightToLeft() {
        XCTAssertEqual(Locale(identifier: "he").rcLayoutDirection, .rightToLeft)
    }

    func testSaudiArabicLocaleIsRightToLeft() {
        XCTAssertEqual(Locale(identifier: "ar_SA").rcLayoutDirection, .rightToLeft)
    }

    func testResolverDoesNotOverrideDirectionByDefault() {
        XCTAssertNil(PaywallLayoutDirectionResolver.resolve(
            editorLayoutDirection: nil,
            preferredLocale: Locale(identifier: "he"),
            honorsPreferredLocaleLayoutDirection: false
        ))
    }

    func testResolverHonorsPreferredLocaleWhenOptedIn() {
        XCTAssertEqual(PaywallLayoutDirectionResolver.resolve(
            editorLayoutDirection: nil,
            preferredLocale: Locale(identifier: "he"),
            honorsPreferredLocaleLayoutDirection: true
        ), .rightToLeft)
    }

    func testResolverUsesEditorLocaleSetting() {
        XCTAssertEqual(PaywallLayoutDirectionResolver.resolve(
            editorLayoutDirection: .locale,
            preferredLocale: Locale(identifier: "ar_SA"),
            honorsPreferredLocaleLayoutDirection: false
        ), .rightToLeft)
    }

    func testResolverEditorForceDirectionOverridesSdkOptIn() {
        XCTAssertEqual(PaywallLayoutDirectionResolver.resolve(
            editorLayoutDirection: .ltr,
            preferredLocale: Locale(identifier: "he"),
            honorsPreferredLocaleLayoutDirection: true
        ), .leftToRight)

        XCTAssertEqual(PaywallLayoutDirectionResolver.resolve(
            editorLayoutDirection: .rtl,
            preferredLocale: Locale(identifier: "en_US"),
            honorsPreferredLocaleLayoutDirection: false
        ), .rightToLeft)
    }

}

#endif
