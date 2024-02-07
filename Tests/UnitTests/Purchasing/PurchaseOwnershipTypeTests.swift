//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseOwnershipTypeTests.swift
//
//  Created by Nacho Soto on 5/10/22.

import Nimble
@testable import RevenueCat
import XCTest

class PurchaseOwnershipTypeTests: TestCase {

    func testCodable() throws {
        for type in PurchaseOwnershipType.allCases {
            expect(try type.encodeAndDecode()) == type
        }
    }

    func testUnknownStringBecomesUnknown() throws {
        expect(try PurchaseOwnershipType.decode("\"invalid\"")) == .unknown
    }

    func testNullBecomesUnknown() throws {
        expect(try PurchaseOwnershipType.decode("null")) == .unknown
    }

}
