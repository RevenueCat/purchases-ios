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
            (Locale(identifier: "en_US"), Locale(identifier: "en_GB"), true, false, #line as UInt),
            (Locale(identifier: "ar_SA"), Locale(identifier: "ar-SA"), true, false, #line),
            (Locale(identifier: "ar"), Locale(identifier: "ar-SA"), true, false, #line),
            (Locale(identifier: "fr"), Locale(identifier: "fr_FR"), true, false, #line),
            (Locale(identifier: "fr"), Locale(identifier: "en_US"), false, false, #line),
            (Locale(identifier: "ar-SA"), Locale(identifier: "en_US"), false, false, #line),
            (Locale(identifier: "ar_SA"), Locale(identifier: "en_US"), false, false, #line),
            (Locale(identifier: "es"), Locale(identifier: "es"), true, false, #line),
            (Locale(identifier: "de-DE"), Locale(identifier: "de-CH"), true, false, #line),
            (Locale(identifier: "pt_BR"), Locale(identifier: "pt_PT"), true, false, #line),
            (Locale(identifier: "zh-CN"), Locale(identifier: "zh_TW"), true, false, #line),
            (Locale(identifier: "it"), Locale(identifier: "ja"), false, false, #line),
            (Locale(identifier: "en"), Locale(identifier: "de-DE"), false, false, #line),
            (Locale(identifier: "EN-US"), Locale(identifier: "en_us"), true, false, #line),
            (Locale(identifier: "sr-Latn"), Locale(identifier: "sr-Cyrl"), true, false, #line),
            (Locale(identifier: "az-Latn"), Locale(identifier: "ru-Cyrl"), false, false, #line),
            (Locale(identifier: "fil"), Locale(identifier: "fil-PH"), true, false, #line),
            (Locale(identifier: ""), Locale(identifier: ""), true, false, #line),
            (Locale(identifier: "es-MX"), Locale(identifier: "es-AR"), true, false, #line),
            (Locale(identifier: "no-NO"), Locale(identifier: "nb-NO"), true, false, #line),
            (Locale(identifier: "zh"), Locale(identifier: "ja"), false, false, #line),
            (Locale(identifier: "zh-Hant-TW"), Locale(identifier: "zh-Hans-CN"), true, false, #line),
            (Locale(identifier: "invalid-code"), Locale(identifier: "en-US"), false, false, #line),
            (Locale(identifier: "in"), Locale(identifier: "id"), true, false, #line),
            (Locale(identifier: "ko-KR"), Locale(identifier: "ko"), true, false, #line),
            // With Strict Matching
            (Locale(identifier: "en_US"), Locale(identifier: "en_GB"), false, true, #line),
            (Locale(identifier: "ar_SA"), Locale(identifier: "ar-SA"), true, true, #line),
            (Locale(identifier: "ar"), Locale(identifier: "ar-SA"), false, true, #line),
            (Locale(identifier: "fr"), Locale(identifier: "fr_FR"), true, true, #line),
            (Locale(identifier: "fr"), Locale(identifier: "en_US"), false, true, #line),
            (Locale(identifier: "ar-SA"), Locale(identifier: "en_US"), false, true, #line),
            (Locale(identifier: "ar_SA"), Locale(identifier: "en_US"), false, true, #line),
            (Locale(identifier: "es"), Locale(identifier: "es"), true, true, #line),
            (Locale(identifier: "de-DE"), Locale(identifier: "de-CH"), false, true, #line),
            (Locale(identifier: "pt_BR"), Locale(identifier: "pt_PT"), false, true, #line),
            (Locale(identifier: "zh-CN"), Locale(identifier: "zh_TW"), false, true, #line),
            (Locale(identifier: "it"), Locale(identifier: "ja"), false, true, #line),
            (Locale(identifier: "en"), Locale(identifier: "de-DE"), false, true, #line),
            (Locale(identifier: "EN-US"), Locale(identifier: "en_us"), true, true, #line),
            (Locale(identifier: "sr-Latn"), Locale(identifier: "sr-Cyrl"), false, true, #line),
            (Locale(identifier: "az-Latn"), Locale(identifier: "ru-Cyrl"), false, true, #line),
            (Locale(identifier: "fil"), Locale(identifier: "fil-PH"), true, true, #line),
            (Locale(identifier: ""), Locale(identifier: ""), true, true, #line),
            (Locale(identifier: "es-MX"), Locale(identifier: "es-AR"), false, true, #line),
            (Locale(identifier: "no-NO"), Locale(identifier: "nb-NO"), true, true, #line),
            (Locale(identifier: "zh"), Locale(identifier: "ja"), false, true, #line),
            (Locale(identifier: "zh-Hant-TW"), Locale(identifier: "zh-Hans-CN"), false, true, #line),
            (Locale(identifier: "invalid-code"), Locale(identifier: "en-US"), false, true, #line),
            (Locale(identifier: "in"), Locale(identifier: "id"), true, true, #line),
            (Locale(identifier: "ko-KR"), Locale(identifier: "ko"), true, true, #line)
        ]

        testCases.forEach { first, second, expectedResult, strict, line in
            XCTAssertEqual(
                expectedResult,
                first.sharesLanguageCode(with: second, strictMatching: strict),
                line: line
            )
        }
    }

}
