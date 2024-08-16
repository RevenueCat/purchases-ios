//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocaleExtensionsTests.swift
//
//  Created by Nacho Soto on 6/21/23.

import Nimble
import XCTest

@testable import RevenueCat

class LocaleExtensionsTests: TestCase {

    func testCurrencyCode() {
        expect(Locale(identifier: "en_US").rc_currencyCode) == "USD"
    }

    func testMissingCurrencyCode() {
        expect(Locale(identifier: "").rc_currencyCode).to(beNil())
    }

    func testLanguageCodeCode() {
        expect(Locale(identifier: "en_US").rc_languageCode) == "en"
        expect(Locale(identifier: "en-IN").rc_languageCode) == "en"
        expect(Locale(identifier: "en").rc_languageCode) == "en"
    }

    func testMissingLanguageCode() {
        // This difference is with running iOS 16 tests with Xcode 15
        // and iOS 15 tests with Xcode 14
        if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            expect(Locale(identifier: "").rc_languageCode).to("en")
        } else {
            expect(Locale(identifier: "").rc_languageCode).to(beNil())
        }
    }

    func testRemovingRegion() {
        expect(Locale(identifier: "en_US").removingRegion?.identifier) == "en"
        expect(Locale(identifier: "en-IN").removingRegion?.identifier) == "en"
        expect(Locale(identifier: "en_ES").removingRegion?.identifier) == "en"
        expect(Locale(identifier: "en").removingRegion?.identifier) == "en"

        // This difference is with running iOS 16 tests with Xcode 15
        // and iOS 15 tests with Xcode 14
        if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            expect(Locale(identifier: "").removingRegion).to("en")
        } else {
            expect(Locale(identifier: "").removingRegion).to(beNil())
        }
    }

}
