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
            (Locale(identifier: "en_US"), Locale(identifier: "en_GB"), true, #line as UInt),
            (Locale(identifier: "ar_SA"), Locale(identifier: "ar-SA"), true, #line),
            (Locale(identifier: "ar"), Locale(identifier: "ar-SA"), true, #line),
            (Locale(identifier: "fr"), Locale(identifier: "fr_FR"), true, #line),
            (Locale(identifier: "fr"), Locale(identifier: "en_US"), false, #line),
            (Locale(identifier: "ar-SA"), Locale(identifier: "en_US"), false, #line),
            (Locale(identifier: "ar_SA"), Locale(identifier: "en_US"), false, #line),
            (Locale(identifier: "es"), Locale(identifier: "es"), true, #line),
            (Locale(identifier: "de-DE"), Locale(identifier: "de-CH"), true, #line),
            (Locale(identifier: "pt_BR"), Locale(identifier: "pt_PT"), true, #line),
            (Locale(identifier: "zh-CN"), Locale(identifier: "zh_TW"), true, #line),
            (Locale(identifier: "it"), Locale(identifier: "ja"), false, #line),
            (Locale(identifier: "en"), Locale(identifier: "de-DE"), false, #line),
            (Locale(identifier: "EN-US"), Locale(identifier: "en_us"), true, #line),
            (Locale(identifier: "sr-Latn"), Locale(identifier: "sr-Cyrl"), true, #line),
            (Locale(identifier: "az-Latn"), Locale(identifier: "ru-Cyrl"), false, #line),
            (Locale(identifier: "fil"), Locale(identifier: "fil-PH"), true, #line),
            (Locale(identifier: ""), Locale(identifier: ""), true, #line),
            (Locale(identifier: "es-MX"), Locale(identifier: "es-AR"), true, #line),
            (Locale(identifier: "no-NO"), Locale(identifier: "nb-NO"), true, #line),
            (Locale(identifier: "zh"), Locale(identifier: "ja"), false, #line),
            (Locale(identifier: "zh-Hant-TW"), Locale(identifier: "zh-Hans-CN"), true, #line),
            (Locale(identifier: "invalid-code"), Locale(identifier: "en-US"), false, #line),
            (Locale(identifier: "in"), Locale(identifier: "id"), true, #line),
            (Locale(identifier: "ko-KR"), Locale(identifier: "ko"), true, #line)
        ]

        testCases.forEach { first, second, expectedResult, line in
            XCTAssertEqual(expectedResult, first.sharesLanguageCode(with: second), line: line)
        }
    }

}
