//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PeriodTypeTests.swift
//
//  Created by Nacho Soto on 5/10/22.

import Nimble
@testable import RevenueCat
import XCTest

class PeriodTypeTests: TestCase {

    func testCodable() throws {
        for type in PeriodType.allCases {
            expect(try type.encodeAndDecode()) == type
        }
    }

    func testUnknownStringThrows() throws {
        expect(try PeriodType.decode("\"invalid\"")).to(throwError(errorType: CodableError.self))
    }

}
