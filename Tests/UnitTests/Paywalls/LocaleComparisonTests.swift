//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocaleComparisonTests.swift
//
//  Created by Jacob Zivan Rakidzich on 11/7/25.

import Foundation
@testable import RevenueCat
import XCTest

final class LocaleComparisonTests: TestCase {

    func test_sharesLanguageCode() {
        let testCases = [
            TestCase(first: "en_US", second: "en_GB", expectedResult: true, strict: false, line: #line),
            TestCase(first: "ar_SA", second: "ar-SA", expectedResult: true, strict: false, line: #line),
            TestCase(first: "ar", second: "ar-SA", expectedResult: true, strict: false, line: #line),
            TestCase(first: "fr", second: "fr_FR", expectedResult: true, strict: false, line: #line),
            TestCase(first: "fr", second: "en_US", expectedResult: false, strict: false, line: #line),
            TestCase(first: "ar-SA", second: "en_US", expectedResult: false, strict: false, line: #line),
            TestCase(first: "ar_SA", second: "en_US", expectedResult: false, strict: false, line: #line),
            TestCase(first: "es", second: "es", expectedResult: true, strict: false, line: #line),
            TestCase(first: "de-DE", second: "de-CH", expectedResult: true, strict: false, line: #line),
            TestCase(first: "pt_BR", second: "pt_PT", expectedResult: true, strict: false, line: #line),
            TestCase(first: "zh-CN", second: "zh_TW", expectedResult: true, strict: false, line: #line),
            TestCase(first: "it", second: "ja", expectedResult: false, strict: false, line: #line),
            TestCase(first: "en", second: "de-DE", expectedResult: false, strict: false, line: #line),
            TestCase(first: "EN-US", second: "en_us", expectedResult: true, strict: false, line: #line),
            TestCase(first: "sr-Latn", second: "sr-Cyrl", expectedResult: true, strict: false, line: #line),
            TestCase(first: "az-Latn", second: "ru-Cyrl", expectedResult: false, strict: false, line: #line),
            TestCase(first: "fil", second: "fil-PH", expectedResult: true, strict: false, line: #line),
            TestCase(first: "", second: "", expectedResult: true, strict: false, line: #line),
            TestCase(first: "es-MX", second: "es-AR", expectedResult: true, strict: false, line: #line),
            // Same language, new + deprecated codes
            TestCase(first: "no-NO", second: "nb-NO", expectedResult: true, strict: false, line: #line),
            TestCase(first: "zh", second: "ja", expectedResult: false, strict: false, line: #line),
            TestCase(first: "zh-Hant-TW", second: "zh-Hans-CN", expectedResult: true, strict: false, line: #line),
            TestCase(first: "invalid-code", second: "en-US", expectedResult: false, strict: false, line: #line),
            // Same language, new + deprecated codes
            TestCase(first: "in", second: "id", expectedResult: true, strict: false, line: #line),
            TestCase(first: "ko-KR", second: "ko", expectedResult: true, strict: false, line: #line),
            // With Strict Matching
            TestCase(first: "en_US", second: "en_GB", expectedResult: false, strict: true, line: #line),
            TestCase(first: "ar_SA", second: "ar-SA", expectedResult: true, strict: true, line: #line),
            TestCase(first: "ar", second: "ar-SA", expectedResult: false, strict: true, line: #line),
            TestCase(first: "fr", second: "en_US", expectedResult: false, strict: true, line: #line),
            TestCase(first: "ar-SA", second: "en_US", expectedResult: false, strict: true, line: #line),
            TestCase(first: "ar_SA", second: "en_US", expectedResult: false, strict: true, line: #line),
            TestCase(first: "es", second: "es", expectedResult: true, strict: true, line: #line),
            TestCase(first: "de-DE", second: "de-CH", expectedResult: false, strict: true, line: #line),
            TestCase(first: "pt_BR", second: "pt_PT", expectedResult: false, strict: true, line: #line),
            TestCase(first: "zh-CN", second: "zh_TW", expectedResult: false, strict: true, line: #line),
            TestCase(first: "it", second: "ja", expectedResult: false, strict: true, line: #line),
            TestCase(first: "en", second: "de-DE", expectedResult: false, strict: true, line: #line),
            TestCase(first: "EN-US", second: "en_us", expectedResult: true, strict: true, line: #line),
            TestCase(first: "sr-Latn", second: "sr-Cyrl", expectedResult: false, strict: true, line: #line),
            TestCase(first: "az-Latn", second: "ru-Cyrl", expectedResult: false, strict: true, line: #line),
            TestCase(first: "", second: "", expectedResult: true, strict: true, line: #line),
            TestCase(first: "es-MX", second: "es-AR", expectedResult: false, strict: true, line: #line),
            // Same language, new + deprecated codes
            TestCase(first: "no-NO", second: "nb-NO", expectedResult: true, strict: true, line: #line),
            TestCase(first: "zh", second: "ja", expectedResult: false, strict: true, line: #line),
            TestCase(first: "zh-Hant-TW", second: "zh-Hans-CN", expectedResult: false, strict: true, line: #line),
            TestCase(first: "invalid-code", second: "en-US", expectedResult: false, strict: true, line: #line),
            // Same language, new + deprecated codes
            TestCase(first: "in", second: "id", expectedResult: true, strict: true, line: #line)
        ]

        testCases.forEach { testCase in
            XCTAssertEqual(
                testCase.expectedResult,
                testCase.first
                    .sharesLanguageCode(with: testCase.second, stricterMatching: testCase.strict),
                line: testCase.line
            )
        }
    }

    struct TestCase {
        let first: Locale
        let second: Locale
        let expectedResult: Bool
        let strict: Bool
        let line: UInt

        init(first: String, second: String, expectedResult: Bool, strict: Bool, line: UInt) {
            self.first = Locale(identifier: first)
            self.second = Locale(identifier: second)
            self.expectedResult = expectedResult
            self.strict = strict
            self.line = line
        }
    }
}
